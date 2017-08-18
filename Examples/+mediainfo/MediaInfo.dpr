(*
 * Copyright (c) 2012 Stefano Sabatini
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
 * @file
 * Demuxing and decoding example.
 *
 * Show how to use the libavformat and libavcodec API to demux and
 * decode audio and video data.
 * @example demuxing_decoding.c
 *)


program MediaInfo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinApi.Windows,
  System.Rtti,
  System.SysUtils,
  System.JSON,
  System.Classes,
  avutil in '../../Include/libavutil/avutil.pas',
  avcodec in '../../Include/libavcodec/avcodec.pas',
  avformat in '../../Include/libavformat/avformat.pas',
  avfilter in '../../Include/libavfilter/avfilter.pas',
  swresample in '../../Include/libswresample/swresample.pas',
  postprocess in '../../Include/libpostproc/postprocess.pas',
  avdevice in '../../Include/libavdevice/avdevice.pas',
  swscale in '../../Include/libswscale/swscale.pas',
  FH.FFMPEG.PROBE in '../../Include/FH.FFMPEG.PROBE.pas';


procedure usage();
begin
  writeln(format('Usage: %s -i [filename] -probe', [ParamStr(0)]));
  writeln(format('Usage: %s -i [filename] -s [stream index] -o [offset packet] -dump [filename]', [ParamStr(0)]));
  writeln(format('Usage: %s -i [filename] -s [stream index] -o [offset packet] -decode -dump [filename]', [ParamStr(0)]));
end;

label
  finish;


var

  sample_flag           : integer;
  sample_size           : integer;

  video_dst_data: array[0..3] of PByte = (nil, nil, nil, nil);
  video_dst_linesize: array[0..3] of Integer;
  video_dst_bufsize: Integer;

  i                     : integer;
  j                     : integer;
  ret                   : integer = 0;
  pkt                   : TAVPacket;
  fmt_ctx               : PAVFormatContext = nil;
  opt_dic               : PAVDictionary = nil;
  st                    : PAVStream = nil;
  codec_ctx             : PAVCodecContext = nil;
  codec                 : PAVCodec = nil;
  video_dst_file        : TFileStream;
  frame                 : PAVFrame = nil;
  input_file            : string;
  stream_index          : integer;
  offset_packet         : integer;
  cur_offset_packet     : integer = 0;
  dump_file             : string;
  is_probe              : boolean = false;
  is_debug              : boolean = false;
  temp_str              : string;

  LJSONObject           : TJSONObject;
begin
  try
    ReportMemoryLeaksOnShutdown := true;

    stream_index := 0;
    offset_packet := 0;

    if (ParamCount < 1 ) then
    begin
      usage();
      exit;
    end;

    if not FindCmdLineSwitch('i', input_file, True) then
    begin
      usage();
      exit;
    end;

    if FindCmdLineSwitch('probe', True) then
      is_probe := true;

    if FindCmdLineSwitch('debug', True) then
      is_debug := true;

   if (ParamCount > 3) then
    begin
      if FindCmdLineSwitch('s', temp_str, True) then
      begin
        stream_index := strtoint(temp_str);
      end;
      if FindCmdLineSwitch('o', temp_str, True) then
      begin
        offset_packet := strtoint(temp_str);
      end;
      if not FindCmdLineSwitch('dump', dump_file, True) then
      begin
        dump_file := 'dump.raw';
      end;
    end else
      is_probe := true;

    TMediaInfo.Create(input_file).SetAsync(false).Error(
      procedure(const Sender: TObject; AMessage: string)
      begin
        SetConsoleTextAttribute(GetStdHandle( STD_OUTPUT_HANDLE), 7);
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED);
        Writeln(AMessage);
      end).Probe(
      procedure(const Sender: TObject; const JSONObject : TJSONObject)
      begin
        SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
        Writeln(JSONObject.ToJSON);
      end);

    readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
