(*
    tutorial03.c
    A pedagogical video player that will stream through every video frame as fast as it can
    and play audio (out of sync).

    This tutorial was written by Stephen Dranger (dranger@gmail.com).

    Code based on FFplay, Copyright (c) 2003 Fabrice Bellard,
    and a tutorial by Martin Bohme (boehme@inb.uni-luebeckREMOVETHIS.de)

    Conversion to Delphi by Oleksandr Nazaruk (mail@freehand.com.ua)
    Tested on Windows 8.1 64bit rus, compiled with Delphi XE5

    Run using

    tutorial03 myvideofile.mpg

    to play the video stream on your screen.
*)

program tutorial03;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Math,
  SDL2 in '../../../../svn/uses/trunk/Pascal-SDL-2-Headers-master/SDL2.pas',
  avutil in '../../Include/libavutil/avutil.pas',
  avcodec in '../../Include/libavcodec/avcodec.pas',
  avformat in '../../Include/libavformat/avformat.pas',
  swresample in '../../Include/libswresample/swresample.pas',
  postprocess in '../../Include/libpostproc/postprocess.pas',
  avdevice in '../../Include/libavdevice/avdevice.pas',
  swscale in '../../Include/libswscale/swscale.pas';

const
  SDL_AUDIO_BUFFER_SIZE = 1024;
  MAX_AUDIO_FRAME_SIZE      = 192000;

type
  PPacketQueue =^TPacketQueue;
  TPacketQueue = record
    first_pkt   : PAVPacketList;
    last_pkt    : PAVPacketList;
    nb_packets  : integer;
    size        : integer;
    mutex       : PSDL_mutex;
    cond        : PSDL_cond;
  end;

var
  audioq  : PPacketQueue = nil;
  quit    : boolean = false;


procedure packet_queue_init(var q: PPacketQueue);
begin
  if not assigned(q) then
    new(q);
  fillchar(q^, sizeof(TPacketQueue), #0);
  q.mutex := SDL_CreateMutex();
  q.cond := SDL_CreateCond();
end;

function packet_queue_put(var q: PPacketQueue; pkt: PAVPacket): integer;
var
  pkt1  : PAVPacketList;
begin
  result:=-1;

  if not assigned(pkt) then
    exit;

  if(av_dup_packet(pkt) < 0) then
  begin
    result:=-1;
    exit;
  end;

  pkt1 := av_malloc(sizeof(TAVPacketList));
  if not assigned(pkt1) then
  begin
    result:=-1;
    exit;
  end;

  pkt1^.pkt := pkt^;
  pkt1^.next := nil;

  SDL_LockMutex(q.mutex);
  try

    if not assigned(q.last_pkt) then
      q.first_pkt := pkt1
    else
      q.last_pkt^.next := pkt1;

    q.last_pkt := pkt1;
    inc(q.nb_packets);
    q.size:=q.size+pkt1.pkt.size;
    SDL_CondSignal(q.cond);
  finally
    SDL_UnlockMutex(q.mutex);
  end;

  result:=0;
end;

function packet_queue_get(var q: PPacketQueue; var pkt: TAVPacket; block: integer): integer;
var
  pkt1  : PAVPacketList;
  ret   : integer;
begin
  result:=-1;
  ret:=-1;
  SDL_LockMutex(q.mutex);
  try
    while not quit do
    begin
      pkt1 := q.first_pkt;
      if Assigned(pkt1) then
      begin
        q.first_pkt := pkt1^.next;
        if not assigned(q.first_pkt) then
          q.last_pkt := nil;
        dec(q.nb_packets);
        q.size := q.size-pkt1^.pkt.size;
        pkt := pkt1^.pkt;
        av_free(pkt1);
        ret := 1;
        break;
      end else
      if (block)<=0 then
      begin
        ret := 0;
        break;
      end else begin
        SDL_CondWait(q.cond, q.mutex);
      end;
    end;
  finally
    SDL_UnlockMutex(q.mutex);
  end;

  result:=ret;
end;


function audio_decode_frame(aCodecCtx: PAVCodecContext; audio_buf: PByte; buf_size: integer): integer;
var
  pkt             : TAVPacket;
  audio_pkt_data  : PByte;
  audio_pkt_size  : integer;
  len1            : integer;
  data_size       : integer;
  buffer_size     : integer;
begin
  audio_pkt_size:=0;
  audio_pkt_data:=nil;
  data_size:=0;
  len1:=0;

  while True do
  begin
    while (audio_pkt_size > 0) do
    begin
      buffer_size := MAX_AUDIO_FRAME_SIZE;
      len1 := avcodec_decode_audio3(aCodecCtx, PSmallInt(audio_buf), @buffer_size, @pkt);
      if(len1 < 0) then
      begin
	      (* if error, skip frame *)
	      audio_pkt_size := 0;
	      break;
      end;
      inc(audio_pkt_data,len1);
      dec(audio_pkt_size,len1);
      inc(data_size, len1);
      if(data_size <= 0) then
      begin
	      (* No data yet, get more frames *)
	      continue;
      end;
      (* We have data, return it and come back for more later *)
      result:=data_size;
      exit;
    end;
    if assigned(pkt.data) then
      av_free_packet(@pkt);

    if quit then
    begin
      result:=-1;
      exit;
    end;

    if(packet_queue_get(audioq, pkt, 1) < 0) then
    begin
      result:=-1;
      exit;
    end;
    audio_pkt_data := pkt.data;
    audio_pkt_size := pkt.size;
  end;
end;

procedure audio_callback(userdata: Pointer; stream: PByte; len: LongInt); cdecl;
var
  aCodecCtx       : PAVCodecContext;
  audio_size      : integer;
  len1            : integer;
  audio_buf       : array[0..MAX_AUDIO_FRAME_SIZE] of PByte;
  audio_buf_size  : cardinal;
  audio_buf_index : cardinal;
begin
  aCodecCtx:=PAVCodecContext(userdata);
  audio_buf_size := 0;
  audio_buf_index := 0;

  while (len > 0) do
  begin
    if(audio_buf_index >= audio_buf_size) then
    begin
      (* We have already sent all our data; get more *)
      audio_size := audio_decode_frame(aCodecCtx, @audio_buf[0], audio_buf_size);
      if(audio_size < 0) then
      begin
	      (* If error, output silence *)
	      audio_buf_size := 1024; // arbitrary?
	      fillchar(audio_buf[0], audio_buf_size, #0);
      end else begin
	      audio_buf_size := audio_size;
      end;
      audio_buf_index := 0;
    end;
    len1 := audio_buf_size - audio_buf_index;
    if(len1 > len) then
      len1 := len;
    move(audio_buf[audio_buf_index], stream^, len1);
    dec(len, len1);
    inc(stream,len1);
    inc(audio_buf_index,len1);
  end;
end;


var
  i               : integer;
  videoStream     : integer;
  audioStream     : integer;
  src_filename    : ansistring;
  pFormatCtx      : PAVFormatContext = nil;
  aCodecCtx       : PAVCodecContext = nil;
  pCodecCtx       : PAVCodecContext = nil;
  pCodec          : PAVCodec = nil;
  pStream         : PPAVStream = nil;
  aCodec          : PAVCodec = nil;
  videoOptionsDict: PAVDictionary = nil;
  audioOptionsDict: PAVDictionary = nil;
  pFrame          : PAVFrame = nil;
  pFrameYUV420P   : PAVFrame = nil;
  packet          : TAVPacket;
  frameFinished   : integer;
  sws_ctx         : PSwsContext = nil;
  numBytes        : integer;
  buffer          : PByte;
  screen          : PSDL_Window = nil;
  texture         : PSDL_texture  = nil;
  render          : PSDL_renderer = nil;
  event           : TSDL_Event;
  wanted_spec     : TSDL_AudioSpec;
  spec            : TSDL_AudioSpec;
  pict            : TAVPicture;

begin
  try
    if (ParamCount < 1) then
    begin
      writeln('Please provide a movie file');
      exit;
    end;

    src_filename:=(AnsiString(ParamStr(1)));

    if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER)<0 then
    begin
      writeln(format('Could not initialize SDL - %s', [SDL_GetError()]));
      exit;
    end;

    // Register all formats and codecs
    av_register_all();

    // Open video file
    if (avformat_open_input(pFormatCtx, PAnsiChar(src_filename), nil, nil)<>0) then
    begin
      writeln(format('Could not open source file %s', [src_filename]));
      exit;
    end;

    // Retrieve stream information
    if avformat_find_stream_info(pFormatCtx , nil) < 0 then
    begin
      writeln(format('Could not find stream information', []));
      exit;
    end;

    // Dump information about file onto standard error
    av_dump_format(pFormatCtx, 0, PAnsiChar(src_filename), 0);

    // Find the first video stream
    videoStream:=-1;
    audioStream:=-1;
    pStream:=pFormatCtx.streams;
    for i:=0 to pFormatCtx.nb_streams-1 do
    begin
      if ((pStream^.codec.codec_type =  AVMEDIA_TYPE_VIDEO) and (videoStream<0)) then
      begin
        videoStream := i;
        // Get a pointer to the codec context for the video stream
        pCodecCtx:=pStream^.codec;
      end else
      if ((pStream^.codec.codec_type =  AVMEDIA_TYPE_AUDIO) and (audioStream < 0)) then
      begin
        audioStream := i;
        // Get a pointer to the codec context for the audio stream
        aCodecCtx:=pStream^.codec;
        wanted_spec.freq := aCodecCtx.sample_rate;
        wanted_spec.format := AUDIO_S16;
        wanted_spec.channels := aCodecCtx.channels;
        wanted_spec.silence := 0;
        wanted_spec.samples := SDL_AUDIO_BUFFER_SIZE;
        wanted_spec.callback := @audio_callback;
        wanted_spec.userdata := aCodecCtx;
      end;
      inc(pStream);
    end;

    if videoStream=-1 then
    begin
      writeln('Didn''t find a video stream');
      exit;
    end;

    if audioStream=-1 then
    begin
      writeln('Didn''t find a audio stream');
      exit;
    end;

    if(SDL_OpenAudio(@wanted_spec, @spec) <> 0) then
    begin
      writeln(format('SDL_OpenAudio: %s', [SDL_GetError()]));
      exit;
    end;

    aCodec := avcodec_find_decoder(aCodecCtx.codec_id);
    if not assigned(aCodec) then
    begin
      writeln('Unsupported codec!');
      exit;
    end;
    avcodec_open2(aCodecCtx, aCodec, @audioOptionsDict);

    // audio_st = pFormatCtx->streams[index]
    packet_queue_init(audioq);
    SDL_PauseAudio(0);

    // Find the decoder for the video stream
    pCodec:=avcodec_find_decoder(pCodecCtx.codec_id);
    if not assigned(pCodec) then
    begin
      writeln('Unsupported codec!');
      exit;
    end;

    // Open codec
    if avcodec_open2(pCodecCtx, pCodec, @videoOptionsDict)<0 then
    begin
      writeln('Could not open codec');
      exit;
    end;

    // Allocate video frame
    pFrame:=avcodec_alloc_frame;


    // Allocate an AVFrame structure
    pFrameYUV420P:=avcodec_alloc_frame();
    if not assigned(pFrameYUV420P) then
    begin
      writeln('Could not Allocate AVFrame structure');
      exit;
    end;

    // Determine required buffer size and allocate buffer
    numBytes:=avpicture_get_size(pCodecCtx.pix_fmt, pCodecCtx.width, pCodecCtx.height);
    buffer:=av_malloc(numBytes*sizeof(cardinal));

    sws_ctx :=
    sws_getContext
    (
        pCodecCtx.width,
        pCodecCtx.height,
        pCodecCtx.pix_fmt,
        pCodecCtx.width,
        pCodecCtx.height,
        PIX_FMT_YUV420P,
        SWS_BILINEAR,
        nil,
        nil,
        nil
    );

    // Assign appropriate parts of buffer to image planes in pFrameYUV420P
    // Note that pFrameRGB is an AVFrame, but AVFrame is a superset
    // of AVPicture
    avpicture_fill(PAVPicture(pFrameYUV420P), buffer, PIX_FMT_YUV420P, pCodecCtx.width, pCodecCtx.height);

    // Make a screen to put our video
    screen:=SDL_CreateWindow('Tutorial_03', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, pCodecCtx.width, pCodecCtx.height, SDL_WINDOW_SHOWN );
    if not assigned(screen) then
    begin
      writeln('SDL: could CreateWindow');
      exit;
    end;

    render := SDL_CreateRenderer(screen, -1, 0);

    // Allocate a place to put our YUV image on that screen
    texture:=SDL_CreateTexture(render, SDL_PIXELFORMAT_YV12, sint32(SDL_TEXTUREACCESS_STREAMING), pCodecCtx.width, pCodecCtx.height);


    // Read frames and save first five frames to disk
    i:=0;
    while(av_read_frame(pFormatCtx, @packet)>=0) do
    begin
      // Is this a packet from the video stream?
      if(packet.stream_index=videoStream) then
      begin
        // Decode video frame
        avcodec_decode_video2(pCodecCtx, pFrame, frameFinished, @packet);

        // Did we get a video frame?
        if frameFinished>0 then
        begin

	        pict.data[0] := pFrameYUV420P.data[0];
	        pict.data[1] := pFrameYUV420P.data[2];
	        pict.data[2] := pFrameYUV420P.data[1];

	        pict.linesize[0] := pFrameYUV420P.linesize[0];
	        pict.linesize[1] := pFrameYUV420P.linesize[2];
	        pict.linesize[2] := pFrameYUV420P.linesize[1];


	        // Convert the image into YUV format that SDL uses
          sws_scale
          (
            sws_ctx,
            @pFrame.data,
            @pFrame.linesize,
            0,
            pCodecCtx.height,
            @pict.data,
            @pict.linesize
          );


          SDL_UpdateTexture(texture, nil, buffer, pCodecCtx.width);
          SDL_RenderClear(Render);
          SDL_RenderCopy(Render, texture, nil, nil);
          SDL_RenderPresent(Render);
          // Free the packet that was allocated by av_read_frame
          av_free_packet(@packet);
        end;
      end else
      if(packet.stream_index=audioStream) then
      begin
        packet_queue_put(audioq, @packet);
      end else
      begin
        // Free the packet that was allocated by av_read_frame
        av_free_packet(@packet);
      end;
      SDL_PollEvent(@event);
      case event.type_ of
        SDL_QUITEV:
        begin
            quit:=true;
            SDL_Quit();
            exit;
        end;
      end;
    end;

    quit:=true;

    // Free the pFrameYUV420P image
    av_free(buffer);
    av_free(pFrameYUV420P);

    // Free the YUV frame
    av_free(pFrame);

    // Close the codec
    avcodec_close(pCodecCtx);

    if assigned(texture) then
    begin
      SDL_DestroyTexture(texture);
      texture := nil;
    end;

    if assigned(Render) then
    begin
      SDL_DestroyRenderer(Render);
      Render := nil;
    end;

    if assigned(screen) then
    begin
      SDL_DestroyWindow(screen);
      screen := nil;
    end;

    if assigned(audioq) then
      dispose(audioq);

    // Close the video file
    avformat_close_input(pFormatCtx);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.




