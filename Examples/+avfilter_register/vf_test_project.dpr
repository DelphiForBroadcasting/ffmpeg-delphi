program vf_test_project;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Vcl.Graphics,
  avutil in '../../Include/libavutil/avutil.pas',
  avcodec in '../../Include/libavcodec/avcodec.pas',
  avformat in '../../Include/libavformat/avformat.pas',
  avfilter in '../../Include/libavfilter/avfilter.pas',
  swresample in '../../Include/libswresample/swresample.pas',
  postprocess in '../../Include/libpostproc/postprocess.pas',
  avdevice in '../../Include/libavdevice/avdevice.pas',
  swscale in '../../Include/libswscale/swscale.pas',
  vf_test in 'vf_test.pas';

var
  fmt_ctx             : PAVFormatContext = nil;
  dec_ctx             : PAVCodecContext = nil;
  buffersink_ctx      : PAVFilterContext = nil;
  buffersrc_ctx       : PAVFilterContext = nil;
  filter_graph        : PAVFilterGraph = nil;
  video_stream_index  : integer = -1;

  input_file          : string;

function open_input_file(filename: PAnsiChar): integer;
var
  ret : integer;
  dec : PAVCodec;
  i   : integer;
begin
  dec:=nil;
  ret := avformat_open_input(fmt_ctx, filename, nil, nil);
  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot open input file\n');
    exit(ret);
  end;

  ret := avformat_find_stream_info(fmt_ctx, nil);
  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot find stream information\n');
    exit(ret);
  end;

  (* select the video stream *)
  ret := av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, dec, 0);
  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot find a video stream in the input file\n');
    exit(ret);
  end;

  video_stream_index := ret;

  for I := 0 to fmt_ctx.nb_streams-1 do
  begin
    if i=video_stream_index then
    begin
      dec_ctx:=fmt_ctx.streams^.codec;
      break;
    end;
    inc(fmt_ctx.streams);
  end;

  av_opt_set_int(dec_ctx, 'refcounted_frames', 1, 0);

  (* init the video decoder *)
  ret := avcodec_open2(dec_ctx, dec, nil);
  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot open video decoder\n');
    exit(ret);
  end;

  result:=0;
end;



function init_filter_graph(var pGraph: PAVFilterGraph; var pSrc1: PAVFilterContext; var pSink: PAVFilterContext): integer;
var
  tFilterGraph      : PAVFilterGraph;
  tBufferContext1   : PAVFilterContext;
  tBuffer1          : PAVFilter;
  tColorContext     : PAVFilterContext;
  tColor            : PAVFilter;
  tSmptebarsContext : PAVFilterContext;
  tSmptebars        : PAVFilter;
  tFormat           : PAVFilter;
  tFormatContext    : PAVFilterContext;
  tTestContext      : PAVFilterContext;
  tTest             : PAVFilter;
  tBufferSinkContext: PAVFilterContext;
  tBufferSink       : PAVFilter;

  tError            : integer;

  tOptionsDict      : PAVDictionary;
  args              : ansistring;
begin

  tOptionsDict := nil;

  (* Create a new filtergraph, which will contain all the filters. *)
  tFilterGraph := avfilter_graph_alloc();

  if not assigned(tFilterGraph) then
    exit(-1);

  // BUFFER FILTER 1
  tBuffer1 := avfilter_get_by_name('buffer');
  if not assigned(tBuffer1) then
    exit(-1);

  args:=format('video_size=%dx%d:pix_fmt=%d:time_base=%d/%d',
  [dec_ctx.width,
  dec_ctx.height,
  integer(dec_ctx.pix_fmt),
  dec_ctx.time_base.den,
  dec_ctx.time_base.num]);

  writeln(args);

  tError := avfilter_graph_create_filter(tBufferContext1, tBuffer1, 'src1', PAnsiChar(args), nil, tFilterGraph);
  if (tError < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot create buffer source');
    exit(-1);
  end;

  // TEST FILTER
  tTest := avfilter_get_by_name('fh-test');
  if not assigned(tTest) then
    exit(-1);

  tTestContext := avfilter_graph_alloc_filter(tFilterGraph, tTest, 'fh-test');
  if not assigned(tTestContext) then
    exit(-1);

  tTestContext.input_count := 1;
  tTestContext.nb_inputs := 1;
  tTestContext.output_count := 1;
  tTestContext.nb_outputs := 1;

  av_dict_set(tOptionsDict, PAnsiChar('opt1'), PAnsiChar('test1'), 0);
  av_dict_set(tOptionsDict, PAnsiChar('opt2'), PAnsiChar('test2'), 0);
  tError := avfilter_init_dict(tTestContext, @tOptionsDict);
  av_dict_free(tOptionsDict);
  if tError < 0 then
    exit(tError);

  // FORMAT FILTER
  tFormat := avfilter_get_by_name('format');
  if not assigned(tFormat) then
    exit(-1);

  tFormatContext := avfilter_graph_alloc_filter(tFilterGraph, tFormat, 'format');
  if not assigned(tFormatContext) then
    exit(-1);

  av_dict_set(tOptionsDict, PAnsiChar('pix_fmts'), PAnsiChar('bgra'), 0);
  tError := avfilter_init_dict(tFormatContext, @tOptionsDict);
  av_dict_free(tOptionsDict);
  if tError < 0 then
    exit(tError);



  // BUFFERSINK FILTER
  tBufferSink := avfilter_get_by_name('buffersink');
  if not assigned(tBufferSink) then
    exit(-1);

  tBufferSinkContext := avfilter_graph_alloc_filter(tFilterGraph, tBufferSink, 'sink');
  if not assigned(tBufferSinkContext) then
    exit(-1);

  //args:='pix_fmts=bgra|yuv420p';
  tError := avfilter_init_str(tBufferSinkContext, nil);
  if tError < 0 then
    exit(tError);

  // Linking graph
  tError := avfilter_link(tBufferContext1, 0, tTestContext, 0);
  tError := avfilter_link(tTestContext, 0, tFormatContext, 0);
  tError := avfilter_link(tFormatContext, 0, tBufferSinkContext, 0);

  if tError < 0 then
    exit(tError);


  tError := avfilter_graph_config(tFilterGraph, nil);
  if tError < 0 then
    exit(tError);

  pGraph := tFilterGraph;
  pSrc1 := tBufferContext1;
  pSink := tBufferSinkContext;
end;

procedure save_frame(const frame: PAVFrame; filename : string);
var
  bmp : TBitmap;
  i : integer;
begin
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.Width := frame.width;
    bmp.Height := frame.height;

    for i := 0 to bmp.Height - 1 do
    begin
      //CopyMemory ( bmp.ScanLine[i], pointer (integer (frame.data [0]) + bmp.Width * 4 * i), bmp.Width * 4 );
      move(pointer(integer(frame.data[0]) + bmp.Width * 4 * i)^, bmp.ScanLine[i]^, bmp.Width * 4);
    end;

    bmp.SaveToFile(filename);
  finally
    bmp.free;
  end;
end;


label
  end_;

var
  ret         : integer;
  packet      : TAVPacket;
  frame       : PAVFrame;
  filt_frame  : PAVFrame;
  got_frame   : integer;
  read_frames : integer;

begin
  try

    frame := av_frame_alloc();
    filt_frame := av_frame_alloc();


    if (not assigned(frame) or not assigned(filt_frame)) then
    begin
      writeln('Could not allocate frame');
      exit;
    end;

    if (ParamCount <> 2) then
    begin
      writeln(format('Usage: %s -i [filename]', [ParamStr(0)]));
      readln;
      exit;
    end;

    if not FindCmdLineSwitch('i', input_file, True) then
      exit;

    av_register_all();
    avfilter_register_all();
    av_log_set_level(AV_LOG_DEBUG);

    // register test filter
    ret := vf_test_register;
    if (ret < 0) then
        goto end_;

    ret := open_input_file(PAnsiChar(ansistring(input_file)));
    if (ret < 0) then
        goto end_;


    ret:=init_filter_graph(filter_graph, buffersrc_ctx, buffersink_ctx);
    if (ret < 0) then
        goto end_;

    read_frames:=0;
    (* read all packets *)
    while true do
    begin
      if read_frames>=2 then break;
      
      ret := av_read_frame(fmt_ctx, @packet);
      if (ret < 0) then break;

      if (packet.stream_index = video_stream_index) then
      begin
        got_frame := 0;
        ret := avcodec_decode_video2(dec_ctx, frame, got_frame, @packet);
        if (ret < 0) then
        begin
          av_log(nil, AV_LOG_ERROR, 'Error decoding video\n');
          break;
        end;

        if (got_frame>0) then
        begin
          frame.pts := av_frame_get_best_effort_timestamp(frame);

          (* push the decoded frame into the filtergraph *)
          if (av_buffersrc_add_frame_flags(buffersrc_ctx, frame, integer(AV_BUFFERSRC_FLAG_KEEP_REF)) < 0) then
          begin
            av_log(nil, AV_LOG_ERROR, 'Error while feeding the filtergraph');
            break;
          end;

          (* pull filtered frames from the filtergraph *)
          while true do
          begin
            ret := av_buffersink_get_frame(buffersink_ctx, filt_frame);
            if ((ret = -11) or (ret = AVERROR_EOF)) then
              break;
            if (ret < 0)then
              goto end_;
            save_frame(filt_frame, format('img_%d.bmp',[filt_frame.pts]));
            av_frame_unref(filt_frame);
          end;
          av_frame_unref(frame);
        end;
        inc(read_frames);
      end;
      av_free_packet(@packet);
    end;

    ret:=0;

    end_ :
    begin
        avfilter_graph_free(filter_graph);
        avcodec_close(dec_ctx);
        avformat_close_input(fmt_ctx);
        av_frame_free(frame);
        av_frame_free(filt_frame);

        if ((ret < 0) and (ret <> AVERROR_EOF)) then
        begin
          writeln(format('Error occurred: %s', [av_err2str(ret)]));
          readln;
          exit;
        end;
    end;

    writeln('Finish, press enter key.');
    readln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
