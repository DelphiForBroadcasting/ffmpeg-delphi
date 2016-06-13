(*
 * Copyright (c) 2013 Stefano Sabatini
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
 * Ported to Pascal by Oleksandr Nazaruk <mail@freehand.com.ua>  2016-02-04
 *
 *)

(**
 * @file
 * libavformat/libavcodec demuxing and muxing API example.
 *
 * Remux streams from one container format to another.
 * @example remuxing.c
 *)
program remuxing;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  avutil in '../../libavutil/avutil.pas',
  avcodec in '../../libavcodec/avcodec.pas',
  avformat in '../../libavformat/avformat.pas',
  avfilter in '../../libavfilter/avfilter.pas',
  swresample in '../../libswresample/swresample.pas',
  postprocess in '../../libpostproc/postprocess.pas',
  avdevice in '../../libavdevice/avdevice.pas',
  swscale in '../../libswscale/swscale.pas';

function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;
begin
  Inc(P, I);
  Result := P^;
end;

procedure log_packet(const fmt_ctx: PAVFormatContext; const pkt: PAVPacket; const tag: PAnsiChar);
var
  time_base: PAVRational;
begin
  time_base := @PAVStream(PPtrIdx(fmt_ctx.streams, pkt.stream_index)).time_base;

  writeln(Format('%s: pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d',
        [tag,
         av_ts2str(pkt.pts), av_ts2timestr(pkt.pts, time_base),
         av_ts2str(pkt.dts), av_ts2timestr(pkt.dts, time_base),
         av_ts2str(pkt.duration), av_ts2timestr(pkt.duration, time_base),
         pkt.stream_index]));
end;

var
  ofmt: PAVOutputFormat;
  ifmt_ctx, ofmt_ctx: PAVFormatContext;
  pkt: TAVPacket;
  in_filename, out_filename: string;
  ret, i: Integer;
  in_stream: PAVStream;
  out_stream: PAVStream;

label
  _end;

begin
  ReportMemoryLeaksOnShutdown := true;
  try
    ofmt := nil;
    ifmt_ctx := nil;
    ofmt_ctx := nil;


    if ParamCount < 4 then
    begin
      Writeln(ErrOutput, Format('usage: %s -i [input file] -o [output file]' + sLineBreak +
             'API example program to remux a media file with libavformat and libavcodec.' + sLineBreak +
             'The output format is guessed according to the file extension.',
             [ExtractFileName(ParamStr(0))]));
      Exit;
    end;

    if not FindCmdLineSwitch('i', in_filename, True) then
      exit;

    if not FindCmdLineSwitch('o', out_filename, True) then
      exit;

    av_register_all();
    av_log_set_level(AV_LOG_DEBUG);

    ret := avformat_open_input(ifmt_ctx, PAnsiChar(ansistring(in_filename)), nil, nil);
    if ret < 0 then
    begin
      Writeln(ErrOutput, Format('Could not open input file ''%s''', [in_filename]));
      goto _end;
    end;

    ret := avformat_find_stream_info(ifmt_ctx, nil);
    if ret < 0 then
    begin
      Writeln(ErrOutput, 'Failed to retrieve input stream information');
      goto _end;
    end;

    av_dump_format(ifmt_ctx, 0, PAnsiChar(ansistring(in_filename)), 0);

    avformat_alloc_output_context2(ofmt_ctx, nil, nil, PAnsiChar(ansistring(out_filename)));
    if not Assigned(ofmt_ctx) then
    begin
      Writeln(ErrOutput, 'Could not create output context');
      ret := AVERROR_UNKNOWN;
      goto _end;
    end;

    ofmt := ofmt_ctx.oformat;

    for i := 0 to ifmt_ctx.nb_streams - 1 do
    begin
      in_stream := PPtrIdx(ifmt_ctx.streams, i);
      out_stream := avformat_new_stream(ofmt_ctx, in_stream.codec.codec);
      if not Assigned(out_stream) then
      begin
        Writeln(ErrOutput, 'Failed allocating output stream');
        ret := AVERROR_UNKNOWN;
        goto _end;
      end;

      ret := avcodec_copy_context(out_stream.codec, in_stream.codec);
      if ret < 0 then
      begin
        Writeln(ErrOutput, 'Failed to copy context from input to output stream codec context');
        goto _end;
      end;
      out_stream.codec.codec_tag := 0;
      if (ofmt_ctx.oformat.flags and AVFMT_GLOBALHEADER) <> 0 then
        out_stream.codec.flags := out_stream.codec.flags or AV_CODEC_FLAG_GLOBAL_HEADER;
    end;
    av_dump_format(ofmt_ctx, 0, PAnsiChar(ansistring(out_filename)), 1);

    if (ofmt.flags and AVFMT_NOFILE) = 0 then
    begin
      ret := avio_open(ofmt_ctx.pb, PAnsiChar(ansistring(out_filename)), AVIO_FLAG_WRITE);
      if ret < 0 then
      begin
        Writeln(ErrOutput, Format('Could not open output file ''%s''', [out_filename]));
        goto _end;
      end;
    end;

    ret := avformat_write_header(ofmt_ctx, nil);
    if ret < 0 then
    begin
      Writeln(ErrOutput, 'Error occurred when opening output file');
      goto _end;
    end;

    while True do
    begin
      ret := av_read_frame(ifmt_ctx, @pkt);
      if ret < 0 then
        Break;

      in_stream  := PPtrIdx(ifmt_ctx.streams, pkt.stream_index);
      out_stream := PPtrIdx(ofmt_ctx.streams, pkt.stream_index);

      log_packet(ifmt_ctx, @pkt, 'in');

      (* copy packet *)
      pkt.pts := av_rescale_q_rnd(pkt.pts, in_stream.time_base, out_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
      pkt.dts := av_rescale_q_rnd(pkt.dts, in_stream.time_base, out_stream.time_base, integer(AV_ROUND_NEAR_INF) or integer(AV_ROUND_PASS_MINMAX));
      pkt.duration := av_rescale_q(pkt.duration, in_stream.time_base, out_stream.time_base);
      pkt.pos := -1;
      log_packet(ofmt_ctx, @pkt, 'out');

      ret := av_interleaved_write_frame(ofmt_ctx, @pkt);
      if ret < 0 then
      begin
        Writeln(ErrOutput, 'Error muxing packet');
        Break;
      end;
      av_free_packet(@pkt);
    end;

    av_write_trailer(ofmt_ctx);

    _end:

      avformat_close_input(ifmt_ctx);

    (* close output *)
    if Assigned(ofmt_ctx) and ((ofmt.flags and AVFMT_NOFILE) = 0) then
      avio_closep(@ofmt_ctx.pb);
    avformat_free_context(ofmt_ctx);

    if (ret < 0) and (ret <> AVERROR_EOF) then
    begin
      Writeln(ErrOutput, Format('Error occurred: %s', [av_err2str(ret)]));
      Exit;
    end;

    readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
