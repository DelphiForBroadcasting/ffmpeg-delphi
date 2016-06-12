(*
 * Copyright (c) 2010 Nicolas George
 * Copyright (c) 2011 Stefano Sabatini
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *)

 (**
 * Conversion to Pascal Copyright 2014 (c) Oleksandr Nazaruk <mail@freehand.com.ua>
 *
 *)

(**
 * @file
 * API example for decoding and filtering
 * @example filtering_video.c
 *)

program filtering_video;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Winapi.Windows,
  System.SysUtils,
  Vcl.Graphics,
  avutil in '../../../libavutil/avutil.pas',
  avcodec in '../../../libavcodec/avcodec.pas',
  avformat in '../../../libavformat/avformat.pas',
  avfilter in '../../../libavfilter/avfilter.pas',
  swresample in '../../../libswresample/swresample.pas',
  postprocess in '../../../libpostproc/postprocess.pas',
  avdevice in '../../../libavdevice/avdevice.pas',
  swscale in '../../../libswscale/swscale.pas';


const
  filter_descr : PAnsiChar = 'scale=720:480';



var
  fmt_ctx             : PAVFormatContext = nil;
  dec_ctx             : PAVCodecContext = nil;
  buffersink_ctx      : PAVFilterContext = nil;
  buffersrc_ctx       : PAVFilterContext = nil;
  filter_graph        : PAVFilterGraph = nil;
  video_stream_index  : integer = -1;

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


function init_filters(filters_descr: PAnsiChar): integer;
label
  end_;
var
  args        : ansistring;
  ret         : integer;
  buffersrc   : PAVFilter;
  buffersink  : PAVFilter;
  fDrawtext   : PAVFilter;
  fOverlay    : PAVFilter;
  fVFlip      : PAVFilter;
  outputs     : PAVFilterInOut;
  inputs      : PAVFilterInOut;
  pix_fmts    : array[0..1] of TAVPixelFormat;
begin

  ret := 0;
  Buffersrc  := avfilter_get_by_name('buffer');
  Buffersink := avfilter_get_by_name('buffersink');
  fDrawtext := avfilter_get_by_name('drawtext');
  fOverlay := avfilter_get_by_name('overlay');
  fVFlip := avfilter_get_by_name('vflip');
  //smtebars


  outputs := avfilter_inout_alloc();
  inputs  := avfilter_inout_alloc();

  pix_fmts[0] := AV_PIX_FMT_RGB32;
  pix_fmts[1] := AV_PIX_FMT_NONE;

  filter_graph := avfilter_graph_alloc();

  if (not assigned(outputs) or not assigned(inputs) or not assigned(filter_graph)) then
  begin
    ret := -ENOMEM;
    goto end_;
  end;


  (* buffer video source: the decoded frames from the decoder will be inserted here. *)
  args:=format('video_size=%dx%d:pix_fmt=%d:time_base=%d/%d:pixel_aspect=%d/%d',
  [dec_ctx.width,
  dec_ctx.height,
  integer(dec_ctx.pix_fmt),
  dec_ctx.time_base.den,
  dec_ctx.time_base.num,
  dec_ctx.sample_aspect_ratio.num,
  dec_ctx.sample_aspect_ratio.den]);

  args:=format('video_size=%dx%d:pix_fmt=%d:time_base=%d/%d',
  [dec_ctx.width,
  dec_ctx.height,
  integer(dec_ctx.pix_fmt),
  dec_ctx.time_base.den,
  dec_ctx.time_base.num]);

  writeln(args);

  ret := avfilter_graph_create_filter(buffersrc_ctx, buffersrc, 'in', PAnsiChar(args), nil, filter_graph);
  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot create buffer source\n');
    goto end_;
  end;


  (* buffer video sink: to terminate the filter chain. *)
  ret := avfilter_graph_create_filter(buffersink_ctx, buffersink, 'out',  nil, nil, filter_graph);
  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot create buffer source\n');
    goto end_;
  end;

  ret:=av_opt_set_bin(buffersink_ctx, 'pix_fmts',  PByte(@pix_fmts[0]), sizeof(pix_fmts[0]) , AV_OPT_SEARCH_CHILDREN);

  if (ret < 0) then
  begin
    av_log(nil, AV_LOG_ERROR, 'Cannot set output pixel format\n');
    goto end_;
  end;


  (* Endpoints for the filter graph. *)
  outputs.name       := av_strdup('in');
  outputs.filter_ctx := buffersrc_ctx;
  outputs.pad_idx    := 0;
  outputs.next       := nil;

  inputs.name       := av_strdup('out');
  inputs.filter_ctx := buffersink_ctx;
  inputs.pad_idx    := 0;
  inputs.next       := nil;

  ret := avfilter_graph_parse_ptr(filter_graph, filters_descr, inputs, outputs, nil);

  if (ret < 0) then
    goto end_;

  ret := avfilter_graph_config(filter_graph, nil);
  if (ret < 0) then
    goto end_;

  exit;

  end_:
    begin
      avfilter_inout_free(inputs);
      avfilter_inout_free(outputs);
      exit(ret);
    end;
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
      CopyMemory ( bmp.ScanLine [i], pointer (integer (frame.data [0]) + bmp.Width * 4 * i), bmp.Width * 4 );

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

    if (ParamCount <> 1) then
    begin
      writeln(format('Usage: %s file\n', [ParamStr(0)]));
      exit;
    end;

    av_register_all();
    avfilter_register_all();
    av_log_set_level(AV_LOG_DEBUG);

    ret := open_input_file(PAnsiChar(ansistring(ParamStr(1))));
    if (ret < 0) then
        goto end_;

    ret := init_filters(filter_descr);
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
