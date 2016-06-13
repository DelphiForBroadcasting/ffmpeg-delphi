(*
    tutorial02.c
    A pedagogical video player that will stream through every video frame as fast as it can.

    This tutorial was written by Stephen Dranger (dranger@gmail.com).

    Code based on FFplay, Copyright (c) 2003 Fabrice Bellard,
    and a tutorial by Martin Bohme (boehme@inb.uni-luebeckREMOVETHIS.de)

    Conversion to Delphi by Oleksandr Nazaruk (mail@freehand.com.ua)
    Tested on Windows 8.1 64bit rus, compiled with Delphi XE5

    Run using

    tutorial02 myvideofile.mpg

    to play the video stream on your screen.
*)

program tutorial02;

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


var
  i, videoStream  : integer;
  src_filename    : ansistring;
  pFormatCtx      : PAVFormatContext = nil;
  pCodecCtx       : PAVCodecContext = nil;
  pCodec          : PAVCodec = nil;
  optionsDict     : PAVDictionary = nil;
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
    for i:=0 to pFormatCtx.nb_streams-1 do
    begin
      if pFormatCtx.streams^.codec.codec_type =  AVMEDIA_TYPE_VIDEO then
      begin
        videoStream := i;
        // Get a pointer to the codec context for the video stream
        pCodecCtx:=pFormatCtx.streams^.codec;
        break;
      end;
      inc(pFormatCtx.streams);
    end;

    if videoStream=-1 then
    begin
      writeln('Didn''t find a video stream');
      exit;
    end;

    // Find the decoder for the video stream
    pCodec:=avcodec_find_decoder(pCodecCtx.codec_id);
    if not assigned(pCodec) then
    begin
      writeln('Unsupported codec!');
      exit;
    end;

    // Open codec
    if avcodec_open2(pCodecCtx, pCodec, @optionsDict)<0 then
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
    screen:=SDL_CreateWindow('Tutorial_02', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, pCodecCtx.width, pCodecCtx.height, SDL_WINDOW_SHOWN );
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
        end;
      end;
      // Free the packet that was allocated by av_read_frame
      av_free_packet(@packet);

      SDL_PollEvent(@event);
      case event.type_ of
        SDL_QUITEV:
        begin
          SDL_Quit();
          exit;
        end;
      end;
    end;

    // Free the pFrameYUV420P image
    av_free(buffer);
    av_free(pFrameYUV420P);

    // Free the YUV frame
    av_free(pFrame);

    // Close the codec
    avcodec_close(pCodecCtx);

    if assigned(texture) then
    begin
      SDL_DestroyRenderer(texture);
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

    // Close the video file
    avformat_close_input(pFormatCtx);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.




