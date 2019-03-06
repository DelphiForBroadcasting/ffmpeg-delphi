program dumpframe;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinApi.Windows,
  System.SysUtils,
  System.Classes,
  VCL.Graphics,
  Vcl.Imaging.jpeg,
  avutil in '../../include/libavutil/avutil.pas',
  avcodec in '../../include/libavcodec/avcodec.pas',
  avformat in '../../include/libavformat/avformat.pas',
  avfilter in '../../include/libavfilter/avfilter.pas',
  swresample in '../../include/libswresample/swresample.pas',
  postprocess in '../../include/libpostproc/postprocess.pas',
  avdevice in '../../include/libavdevice/avdevice.pas',
  swscale in '../../include/libswscale/swscale.pas';

function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;
begin
  Inc(P, I);
  Result := P^;
end;

procedure usage();
begin
  writeln(format('Usage: %s -i [filename] -o [frame number] -save [filename]', [ParamStr(0)]));
end;

procedure SaveToBitmap(frame_rgba: PAVFrame; width: integer; height: integer; var bitmap: TBitmap);
var
  i       : integer;
begin
  bitmap.PixelFormat := pf32bit;
  bitmap.Width := width;
  bitmap.Height := height;
  for i := 0 to bitmap.Height - 1 do
      CopyMemory ( bitmap.ScanLine [i], pointer (integer (frame_rgba.data [0]) + bitmap.Width * 4 * i), bitmap.Width * 4 );
end;

var
  ret                   : integer = 0;
  pkt                   : TAVPacket;
  fmt_ctx               : PAVFormatContext = nil;
  input_file            : string;
  st                    : PAVStream = nil;
  codec_ctx             : PAVCodecContext = nil;
  codec                 : PAVCodec = nil;
  frame                 : PAVFrame = nil;
  frame_rgba            : PAVFrame = nil;
  scale_ctx             : PSwsContext = nil;

  video_dst_data        : array[0..3] of PByte = (nil, nil, nil, nil);
  video_dst_linesize    : array[0..3] of Integer;
  video_dst_bufsize     : Integer;

  frame_index           : integer;
  read_frames           : integer;
  frameFinished         : integer;

  arg_o                 : string;
  jpeg_filename         : string;

  frame_bitmap          : TBitmap;
  frame_jpeg            : TJPEGImage;
begin
  try
    ReportMemoryLeaksOnShutdown := true;


    if (ParamCount < 3 ) then
    begin
      usage();
      exit;
    end;

    if not FindCmdLineSwitch('i', input_file, True) then
    begin
      usage();
      exit;
    end;

    if FindCmdLineSwitch('o', arg_o, True) then
    begin
      frame_index := strtoint(arg_o);
    end;

    if not FindCmdLineSwitch('save', jpeg_filename, True) then
    begin
      jpeg_filename := '.\dump.jpeg';
    end;

    (* register codecs and formats and other lavf/lavc components *)
    av_register_all();
    av_log_set_level(AV_LOG_DEBUG);

    fmt_ctx := avformat_alloc_context();
    if not assigned(fmt_ctx) then
    begin
      raise Exception.Create('Error allocate avformat context');
    end;

    ret := avformat_open_input(fmt_ctx, PAnsiChar(ansistring(input_file)), nil,  nil);
    if (ret < 0) then
    begin
      raise Exception.Create('Could not open input');
    end;

    ret := avformat_find_stream_info(fmt_ctx, nil);
    if (ret < 0)  then
    begin
      raise Exception.Create('Could not find stream information');
    end;

    av_dump_format(fmt_ctx, 0, PAnsiChar(ansistring(input_file)), 0);

    ret := av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, nil, 0);
    if ret < 0 then
    begin
      raise Exception.CreateFmt('Could not find %s stream', [string(ansistring(av_get_media_type_string(AVMEDIA_TYPE_VIDEO)))]);
    end;

    // get main video stram
    st := PPtrIdx(fmt_ctx^.streams, ret);
    codec_ctx := st.codec;

    (* find decoder for the stream *)
    codec := avcodec_find_decoder(codec_ctx.codec_id);
    if not Assigned(codec) then
    begin
     raise Exception.CreateFmt('Failed to find %s codec', [PAnsiChar(@st^.codec.codec_name[0])]);
    end;

    (* Init the decoders*)
    ret := avcodec_open2(codec_ctx, codec, nil);
    if ret < 0 then
    begin
      raise Exception.CreateFmt('Failed to open %s codec', [PAnsiChar(@st^.codec.codec_name[0])]);
    end;

    frame := av_frame_alloc();
    if not Assigned(frame) then
    begin
      raise Exception.Create('Could not allocate frame');
    end;

    frame_rgba := av_frame_alloc();
    if not Assigned(frame) then
    begin
      raise Exception.Create('Could not allocate frame');
    end;
    avpicture_alloc(PAVPicture(frame_rgba), PIX_FMT_RGB32, codec_ctx.width, codec_ctx.height );

    scale_ctx := sws_getContext(codec_ctx.width, codec_ctx.height, codec_ctx.pix_fmt,
                                  codec_ctx.width, codec_ctx.height, PIX_FMT_RGB32, SWS_BICUBIC, nil, nil, nil  );

    ret := av_seek_frame(fmt_ctx, st.index, frame_index, AVSEEK_FLAG_FRAME);
    if( ret < 0) then
    begin
      raise Exception.CreateFmt('Error seeking to frame', [frame_index]);
    end;

    read_frames := 0;
    av_init_packet(@pkt);
    pkt.data := nil;
    pkt.size := 0;
    while av_read_frame(fmt_ctx, @pkt) >= 0 do
    begin
      if pkt.stream_index = st.index then
      begin
        if codec_ctx^.codec_type = AVMEDIA_TYPE_VIDEO  then
        begin
          ret := avcodec_decode_video2(codec_ctx, frame, frameFinished, @pkt);
          if ret < 0 then
          begin
            raise Exception.CreateFmt('Error decoding video frame (%s)', [string(av_err2str(ret))]);
          end;

          if frameFinished > 0  then
          begin
            sws_scale(scale_ctx, @frame.data, @frame.linesize, 0, codec_ctx.height, @frame_rgba.data, @frame_rgba.linesize );

            frame_bitmap := TBitmap.Create;
            try
              SaveToBitmap(frame_rgba, codec_ctx.width, codec_ctx.height, frame_bitmap);
              frame_jpeg := TJPEGImage.Create;
              try
                frame_jpeg.Assign(frame_bitmap);
                frame_jpeg.CompressionQuality := 90;
                frame_jpeg.Compress;
                frame_jpeg.SaveToFile(jpeg_filename);
              finally
                FreeAndNil(frame_jpeg);
              end;
            finally
              FreeAndNil(frame_bitmap);
            end;

            break;
          end;
        end;
      end;
      av_free_packet(@pkt);
    end;


    avcodec_close(codec_ctx);
    avformat_close_input(fmt_ctx);
    av_frame_free(frame);
    av_frame_free(frame_rgba);

    readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
