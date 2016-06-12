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


program demuxing;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinApi.Windows,
  System.SysUtils,
  System.Classes,
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

var
  fmt_ctx: PAVFormatContext = nil;
  video_dec_ctx: PAVCodecContext  = nil;
  audio_dec_ctx: PAVCodecContext;
  width, height: Integer;
  pix_fmt: TAVPixelFormat;
  video_stream: PAVStream = nil;
  audio_stream: PAVStream = nil;
  src_filename: string = '';
  video_dst_filename: string = '';
  audio_dst_filename: string = '';
  video_dst_file: THandle = INVALID_HANDLE_VALUE;
  audio_dst_file: Thandle = INVALID_HANDLE_VALUE;

  video_dst_data: array[0..3] of PByte = (nil, nil, nil, nil);
  video_dst_linesize: array[0..3] of Integer;
  video_dst_bufsize: Integer;

  video_stream_idx: Integer = -1;
  audio_stream_idx: Integer = -1;
  frame: PAVFrame = nil;
  pkt: TAVPacket;
  video_frame_count: Integer = 0;
  audio_frame_count: Integer = 0;

(* The different ways of decoding and managing data memory. You are not
 * supposed to support all the modes in your application but pick the one most
 * appropriate to your needs. Look for the use of api_mode in this example to
 * see what are the differences of API usage between them *)
const
  API_MODE_OLD                  = 0; (* old method, deprecated *)
  API_MODE_NEW_API_REF_COUNT    = 1; (* new method, using the frame reference counting *)
  API_MODE_NEW_API_NO_REF_COUNT = 2; (* new method, without reference counting *)

var
  api_mode: Integer = API_MODE_OLD;

function decode_packet(var got_frame: Integer; cached: Integer): Integer;
var
  ret: Integer;
  decoded: Integer;
  cached_str: string;
  unpadded_linesize: Cardinal;
begin
  decoded := pkt.size;

  got_frame := 0;

  if cached <> 0 then
    cached_str := '(cached)'
  else
    cached_str := '';

  if pkt.stream_index = video_stream_idx then
  begin
    (* decode video frame *)
    ret := avcodec_decode_video2(video_dec_ctx, frame, got_frame, @pkt);
    if ret < 0 then
    begin
      Writeln(ErrOutput, Format('Error decoding video frame (%s)', [string(av_err2str(ret))]));
      Result := ret;
      Exit;
    end;

    if got_frame <> 0 then
    begin

      if (frame.width <> width) or (frame.height <> height) or (frame.format <> Integer(pix_fmt)) then
      begin

        (* To handle this change, one could call av_image_alloc again and
         * decode the following frames into another rawvideo file. *)
        Writeln(Format('Error: Width, height and pixel format have to be ' +
                       'constant in a rawvideo file, but the width, height or ' +
                       'pixel format of the input video changed:' + sLineBreak +
                       'old: width = %d, height = %d, format = %s' + sLineBreak +
                       'new: width = %d, height = %d, format = %s',
                      [width, height, string(av_get_pix_fmt_name(pix_fmt)),
                       frame.width, frame.height, string(av_get_pix_fmt_name(TAVPixelFormat(frame.format)))]));
        Result := -1;
        Exit;
      end;

      Writeln(Format('video_frame%s n:%d coded_n:%d pts:%s',
            [cached_str,
             video_frame_count, frame.coded_picture_number,
             string(av_ts2timestr(frame.pts, @video_dec_ctx.time_base))]));
      Inc(video_frame_count);

      (* copy decoded frame to destination buffer:
       * this is required since rawvideo expects non aligned data *)
      av_image_copy(@video_dst_data[0], @video_dst_linesize[0],
                    @frame.data[0], @(frame.linesize[0]),
                    pix_fmt, width, height);



      (* write to rawvideo file *)
      FileWrite(video_dst_file, video_dst_data[0]^, video_dst_bufsize);
    end;
  end
  else if pkt.stream_index = audio_stream_idx then
  begin
    (* decode audio frame *)
    ret := avcodec_decode_audio4(audio_dec_ctx, frame, got_frame, @pkt);
    if ret < 0 then
    begin
      Writeln(ErrOutput, Format('Error decoding audio frame (%s)', [string(av_err2str(ret))]));
      Result := ret;
      Exit;
    end;
    (* Some audio decoders decode only part of the packet, and have to be
     * called again with the remainder of the packet data.
     * Sample: fate-suite/lossless-audio/luckynight-partial.shn
     * Also, some decoders might over-read the packet. *)
    if ret < pkt.size then
      decoded := ret
    else
      decoded := pkt.size;

    if got_frame <> 0 then
    begin
      unpadded_linesize := frame.nb_samples * av_get_bytes_per_sample(TAVSampleFormat(frame.format));
      Writeln(Format('audio_frame%s n:%d nb_samples:%d pts:%s',
            [cached_str,
             audio_frame_count, frame.nb_samples,
             string(av_ts2timestr(frame.pts, @audio_dec_ctx.time_base))]));
      Inc(audio_frame_count);

      (* Write the raw audio data samples of the first plane. This works
       * fine for packed formats (e.g. AV_SAMPLE_FMT_S16). However,
       * most audio decoders output planar audio, which uses a separate
       * plane of audio samples for each channel (e.g. AV_SAMPLE_FMT_S16P).
       * In other words, this code will write only the first audio channel
       * in these cases.
       * You should use libswresample or libavfilter to convert the frame
       * to packed data. *)
      FileWrite(audio_dst_file, PByte(frame.extended_data)^, unpadded_linesize);
    end;
  end;

  (* If we use the new API with reference counting, we own the data and need
   * to de-reference it when we don't use it anymore *)
  if (got_frame <> 0) and (api_mode = API_MODE_NEW_API_REF_COUNT) then
    av_frame_unref(frame);

  Result := decoded;
end;

function open_codec_context(stream_idx: PInteger;
  fmt_ctx: PAVFormatContext; type_: TAVMediaType): Integer;
var
  ret, stream_index: Integer;
  st: PAVStream;
  dec_ctx: PAVCodecContext;
  avdec: PAVCodec;
  opts: PAVDictionary;
begin
  opts := nil;

  ret := av_find_best_stream(fmt_ctx, type_, -1, -1, nil, 0);
  if ret < 0 then
  begin
    Writeln(ErrOutput, Format('Could not find %s stream in input file ''%s''',
            [string(av_get_media_type_string(type_)), src_filename]));
    Result := ret;
    Exit;
  end
  else
  begin
    stream_index := ret;
    st := PPtrIdx(fmt_ctx.streams, stream_index);

    (* find decoder for the stream *)
    dec_ctx := st.codec;
    avdec := avcodec_find_decoder(dec_ctx.codec_id);
    if not Assigned(avdec) then
    begin
      Writeln(ErrOutput, Format('Failed to find %s codec',
              [string(av_get_media_type_string(type_))]));
      Result := -22;
      Exit;
    end;

    (* Init the decoders, with or without reference counting *)
    if api_mode = API_MODE_NEW_API_REF_COUNT then
      av_dict_set(opts, 'refcounted_frames', '1', 0);
    ret := avcodec_open2(dec_ctx, avdec, @opts);
    if ret < 0 then
    begin
      Writeln(ErrOutput, Format('Failed to open %s codec',
              [string(av_get_media_type_string(type_))]));
      Result := ret;
      Exit;
    end;
    stream_idx^ := stream_index;
  end;

  Result := 0;
end;

function get_format_from_sample_fmt(const fmt: PPAnsiChar;
  sample_fmt: TAVSampleFormat): Integer;
type
  Psample_fmt_entry = ^Tsample_fmt_entry;
  Tsample_fmt_entry = record
    sample_fmt: TAVSampleFormat;
    fmt_be, fmt_le: PAnsiChar;
  end;
const
  sample_fmt_entries: array[0..4] of Tsample_fmt_entry = (
      (sample_fmt: AV_SAMPLE_FMT_U8;  fmt_be: 'u8';    fmt_le: 'u8'    ),
      (sample_fmt: AV_SAMPLE_FMT_S16; fmt_be: 's16be'; fmt_le: 's16le' ),
      (sample_fmt: AV_SAMPLE_FMT_S32; fmt_be: 's32be'; fmt_le: 's32le' ),
      (sample_fmt: AV_SAMPLE_FMT_FLT; fmt_be: 'f32be'; fmt_le: 'f32le' ),
      (sample_fmt: AV_SAMPLE_FMT_DBL; fmt_be: 'f64be'; fmt_le: 'f64le' )
    );
var
  i: Integer;
  entry: Psample_fmt_entry;
begin
  fmt^ := nil;

  for i := 0 to High(sample_fmt_entries) do
  begin
    entry := @sample_fmt_entries[i];
    if sample_fmt = entry.sample_fmt then
    begin
      fmt^ := entry.fmt_le; //AV_NE(entry.fmt_be, entry.fmt_le);
      Result := 0;
      Exit;
    end;
  end;

  Writeln(ErrOutput,
          Format('sample format %s is not supported as output format',
          [string(av_get_sample_fmt_name(sample_fmt))]));
  Result := -1;
end;


function dump_metadata(AMetadata: PAVDictionary): integer;
var
  tag : PAVDictionaryEntry;
begin
  result := -1;
  tag := nil;

  if not assigned(AMetadata) then
    exit;

  av_log(nil, AV_LOG_INFO, 'Metadata:'+#13#10);

  repeat
      tag := av_dict_get(AMetadata, '', tag, AV_DICT_IGNORE_SUFFIX);
      if assigned(tag) then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(format('   %s=%s', [tag^.key, tag^.value])+#13#10)));
  until not assigned(tag);

  av_log(nil, AV_LOG_INFO, #13#10);

end;

procedure dump_stream_format(fmt_ctx: PAVFormatContext; stream_id: cardinal);
var
  flags                 : integer;
  st                    : PAVStream;
  buf                   : array[0..255] of ansichar;
  is_output             : integer;
  display_aspect_ratio  : TAVRational;
  fps                   : integer;
  tbr                   : integer;
  tbn                   : integer;
  tbc                   : integer;
  ration                : double;
  v                     : int64;
begin
  st := nil;
  fps := 0;
  tbr := 0;
  tbn := 0;
  tbc := 0;
  flags := 0;
  is_output := 0;

  if not assigned(fmt_ctx) then
    exit;

  if stream_id > fmt_ctx^.nb_streams then
    exit;

  if assigned(fmt_ctx^.iformat) then
  begin
    flags :=  fmt_ctx^.iformat^.flags;
    is_output := 0;
  end else
  if assigned(fmt_ctx^.oformat) then
  begin
    flags :=  fmt_ctx^.oformat^.flags;
    is_output :=  1;
  end;

  Inc(fmt_ctx^.streams, stream_id);
  st := fmt_ctx^.streams^;

  avcodec_string(@buf[0], length(buf), st^.codec, is_output);

  av_log(nil, AV_LOG_INFO, PAnsiChar(ansistring(Format('    Stream #%d', [stream_id]))));


  if (flags and AVFMT_SHOW_IDS) > 0 then
  begin
        av_log(nil, AV_LOG_INFO, PAnsiChar(ansistring(Format('[0x%x]', [st^.id]))));
  end;

  av_log(nil, AV_LOG_DEBUG, PAnsiChar(ansistring(Format(', %d, %d/%d', [st^.codec_info_nb_frames, st^.time_base.num, st^.time_base.den]))));

  av_log(nil, AV_LOG_INFO, PAnsiChar(ansistring(Format(': %s', [string(PAnsiChar(@buf[0]))]))));

  if ((st^.sample_aspect_ratio.num > 0) and (av_cmp_q(st^.sample_aspect_ratio, st^.codec^.sample_aspect_ratio) > 0)) then
  begin
    av_reduce(@display_aspect_ratio.num, @display_aspect_ratio.den,
                  st^.codec^.width  * st^.sample_aspect_ratio.num,
                  st^.codec^.height * st^.sample_aspect_ratio.den,
                  1024 * 1024);
    av_log(nil, AV_LOG_INFO,  PAnsiChar(ansistring(Format(', SAR %d:%d DAR %d:%d',
               [st^.sample_aspect_ratio.num, st^.sample_aspect_ratio.den,
               display_aspect_ratio.num, display_aspect_ratio.den]))));
  end;


  if (st^.codec^.codec_type = AVMEDIA_TYPE_VIDEO) then
  begin
    fps := st^.avg_frame_rate.den and st^.avg_frame_rate.num;
    tbr := st^.r_frame_rate.den and st^.r_frame_rate.num;
    tbn := st^.time_base.den and st^.time_base.num;
    tbc := st^.codec^.time_base.den and st^.codec^.time_base.num;

    if ((fps > 0) or (tbr > 0) or (tbn > 0) or (tbc > 0)) then
      av_log(nil, AV_LOG_INFO, ' ');

    if (fps > 0) then
    begin
      ration := av_q2d(st^.avg_frame_rate);
      v := round(ration * 100);
      if v > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.4f fps ', [ration]))))
      else if (v mod 100) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%3.2f fps ', [ration]))))
      else if (v mod (100 * 1000)) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0f fps ', [ration]))))
      else
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0fk fps ', [ration / 1000]))));
    end;
    if (tbr > 0) then
    begin
      ration := av_q2d(st^.r_frame_rate);
      v := round(ration * 100);
      if v > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.4f tbr ', [ration]))))
      else if (v mod 100) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%3.2f tbr ', [ration]))))
      else if (v mod (100 * 1000)) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0f tbr ', [ration]))))
      else
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0fk tbr ', [ration / 1000]))));
    end;
    if (tbn > 0)then
    begin
      ration := 1 / av_q2d(st^.time_base);
      v := round(ration * 100);
      if v > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.4f tbn ', [ration]))))
      else if (v mod 100) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%3.2f tbn ', [ration]))))
      else if (v mod (100 * 1000)) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0f tbn ', [ration]))))
      else
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0fk tbn ', [ration / 1000]))));
    end;
    if (tbc > 0) then
    begin
      ration := 1 / av_q2d(st^.codec^.time_base);
      v := round(ration * 100);
      if v > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.4f tbc ', [ration]))))
      else if (v mod 100) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%3.2f tbc ', [ration]))))
      else if (v mod (100 * 1000)) > 0 then
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0f tbc ', [ration]))))
      else
        av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(Format('%1.0fk tbc ', [ration / 1000]))));
    end;
  end;
end;

function probe_format(fmt_ctx: PAVFormatContext): integer;
var
  hours, min, sec, ms : integer;
  i                   : integer;
begin
  result := -1;
  if not assigned(fmt_ctx) then
    exit;

  if assigned(fmt_ctx^.iformat) then
  begin
    av_log(nil, AV_LOG_INFO, PAnsiChar(AnsiString(format('Input: %s', [fmt_ctx^.iformat^.name])+#13#10)));
  end;

  dump_metadata(fmt_ctx^.metadata);

  av_log(nil, AV_LOG_INFO, '  Duration: ');
  if (fmt_ctx^.duration <> AV_NOPTS_VALUE) then
  begin
    ms      := (fmt_ctx^.duration mod AV_TIME_BASE) * 100 div AV_TIME_BASE;
    sec     := round(fmt_ctx^.duration / AV_TIME_BASE) mod 60;
    min     := (sec div 60) mod 60;
    hours   := sec  div 3600;
    av_log(nil, AV_LOG_INFO, PAnsiChar(ansistring(Format('%02.2d:%02.2d:%02.2d:%02.2d',[hours, min, sec, ms]))));
  end else
  begin
   av_log(nil, AV_LOG_INFO, 'N/A');
  end;


  if (fmt_ctx^.start_time <> AV_NOPTS_VALUE) then
  begin
    av_log(nil, AV_LOG_INFO, ', start: ');
    sec := fmt_ctx^.start_time div AV_TIME_BASE;
    ms   := abs(fmt_ctx^.start_time mod AV_TIME_BASE);
    av_log(nil, AV_LOG_INFO,  PAnsiChar(ansistring(Format('%d.%06.6d', [sec, av_rescale(ms, 1000000, AV_TIME_BASE)]))));
  end;

  av_log(nil, AV_LOG_INFO, ', bitrate: ');
  if fmt_ctx^.bit_rate > 0 then
    av_log(nil, AV_LOG_INFO, PAnsiChar(ansistring(Format('%d kb/s', [fmt_ctx^.bit_rate div 1000]))))
  else
    av_log(nil, AV_LOG_INFO, 'N/A');

  av_log(nil, AV_LOG_INFO, #13#10);

  for i := 0 to fmt_ctx^.nb_streams -1  do
  begin
    dump_stream_format(fmt_ctx, i);
  end;

  result := 0;
end;


var
  ret, got_frame: Integer;
  mode: string;
  orig_pkt: TAVPacket;
  sfmt: TAVSampleFormat;
  n_channels: Integer;
  fmt: PAnsiChar;
  packed_name: PAnsiChar;
  packed_str: string;
label
  _end;
begin
  try
    ReportMemoryLeaksOnShutdown := true;

    if (ParamCount <> 3) and (ParamCount <> 4) then
    begin
      Writeln(ErrOutput, Format('usage: %s [-refcount=<old|new_norefcount|new_refcount>] '+
              'input_file video_output_file audio_output_file'+#13#10+
              'API example program to show how to read frames from an input file.'+#13#10+
              'This program reads frames from a file, decodes them, and writes decoded'+#13#10+
              'video frames to a rawvideo file named video_output_file, and decoded'+#13#10+
              'audio frames to a rawaudio file named audio_output_file.'+#13#10#13#10+
              'If the -refcount option is specified, the program use the'+#13#10+
              'reference counting frame system which allows keeping a copy of'+#13#10+
              'the data for longer than one decode call. If unset, it''s using'+#13#10+
              'the classic old method.',
              [System.SysUtils.ExtractFilePath(ParamStr(0))]));
      Exit;
    end;
    if ParamCount = 4 then
    begin
      mode := Copy(ParamStr(1), Length('-refcount=') + 1, MaxInt);
      if mode = 'old' then
        api_mode := API_MODE_OLD
      else if mode = 'new_norefcount' then
        api_mode := API_MODE_NEW_API_NO_REF_COUNT
      else if mode = 'new_refcount' then
        api_mode := API_MODE_NEW_API_REF_COUNT
      else
      begin
        Writeln(ErrOutput, Format('unknow mode ''%s''', [mode]));
        Exit;
      end;
      src_filename := ParamStr(2);
      video_dst_filename := ParamStr(3);
      audio_dst_filename := ParamStr(4);
    end
    else
    begin
      src_filename := ParamStr(1);
      video_dst_filename := ParamStr(2);
      audio_dst_filename := ParamStr(3);
    end;

    (* register all formats and codecs *)
    av_register_all();

    (* open input file, and allocate format context *)
    if avformat_open_input(fmt_ctx, PAnsiChar(AnsiString(src_filename)), nil, nil) < 0 then
    begin
      Writeln(ErrOutput, Format('Could not open source file %s', [src_filename]));
      Exit;
    end;

    (* retrieve stream information *)
    if avformat_find_stream_info(fmt_ctx, nil) < 0 then
    begin
      Writeln(ErrOutput, 'Could not find stream information');
      Exit;
    end;

    if open_codec_context(@video_stream_idx, fmt_ctx, AVMEDIA_TYPE_VIDEO) >= 0 then
    begin
      video_stream := PPtrIdx(fmt_ctx.streams, video_stream_idx);
      video_dec_ctx := video_stream.codec;

      video_dst_file := FileCreate(video_dst_filename);
      if video_dst_file = INVALID_HANDLE_VALUE then
      begin
        Writeln(ErrOutput, Format('Could not open destination file %s', [video_dst_filename]));
        ret := 1;
        goto _end;
      end;

      (* allocate image where the decoded image will be put *)
      width := video_dec_ctx.width;
      height := video_dec_ctx.height;
      pix_fmt := video_dec_ctx.pix_fmt;
      ret := av_image_alloc(@video_dst_data[0], @video_dst_linesize[0],
                           width, height, pix_fmt, 1);
      if ret < 0 then
      begin
        Writeln(ErrOutput, 'Could not allocate raw video buffer');
        goto _end;
      end;
      video_dst_bufsize := ret;
    end;

    if open_codec_context(@audio_stream_idx, fmt_ctx, AVMEDIA_TYPE_AUDIO) >= 0 then
    begin
      audio_stream := PPtrIdx(fmt_ctx.streams, audio_stream_idx);
      audio_dec_ctx := audio_stream.codec;
      audio_dst_file := FileCreate(audio_dst_filename);
      if audio_dst_file = INVALID_HANDLE_VALUE then
      begin
        Writeln(ErrOutput, Format('Could not open destination file %s', [audio_dst_filename]));
        ret := 1;
        goto _end;
      end;
    end;

    (* dump input information to stderr *)
    av_dump_format(fmt_ctx, 0, PAnsiChar(AnsiString(src_filename)), 0);

    if not Assigned(audio_stream) and not Assigned(video_stream) then
    begin
      Writeln(ErrOutput, 'Could not find audio or video stream in the input, aborting');
      ret := 1;
      goto _end;
    end;

    (* When using the new API, you need to use the libavutil/frame.h API, while
     * the classic frame management is available in libavcodec *)
    if api_mode = API_MODE_OLD then
      frame := avcodec_alloc_frame()
    else
      frame := av_frame_alloc();
    if not Assigned(frame) then
    begin
      Writeln(ErrOutput, 'Could not allocate frame');
      ret := -12;
      goto _end;
    end;

    (* initialize packet, set data to NULL, let the demuxer fill it *)
    av_init_packet(@pkt);
    pkt.data := nil;
    pkt.size := 0;

    if Assigned(video_stream) then
      Writeln(Format('Demuxing video from file ''%s'' into ''%s''', [src_filename, video_dst_filename]));
    if Assigned(audio_stream) then
      Writeln(Format('Demuxing audio from file ''%s'' into ''%s''', [src_filename, audio_dst_filename]));

    (* read frames from the file *)
    while av_read_frame(fmt_ctx, @pkt) >= 0 do
    begin
      orig_pkt := pkt;
      repeat
        ret := decode_packet(got_frame, 0);
        if ret < 0 then
          Break;
        Inc(pkt.data, ret);
        Dec(pkt.size, ret);
      until pkt.size <= 0;
      av_free_packet(@orig_pkt);
    end;

    (* flush cached frames *)
    pkt.data := nil;
    pkt.size := 0;
    repeat
      decode_packet(got_frame, 1);
    until got_frame = 0;

    Writeln('Demuxing succeeded.');

    if Assigned(video_stream) then
    begin
      Writeln(Format('Play the output video file with the command:' + sLineBreak +
             'ffplay -f rawvideo -pix_fmt %s -video_size %dx%d %s',
            [string(av_get_pix_fmt_name(pix_fmt)), width, height,
             video_dst_filename]));
    end;

    if Assigned(audio_stream) then
    begin
      sfmt := audio_dec_ctx.sample_fmt;
      n_channels := audio_dec_ctx.channels;

      if av_sample_fmt_is_planar(sfmt) <> 0 then
      begin
        packed_name := av_get_sample_fmt_name(sfmt);
        if Assigned(packed_name) then
          packed_str := string(packed_name)
        else
          packed_str := '?';
        Writeln(Format('Warning: the sample format the decoder produced is planar ' +
               '(%s). This example will output the first channel only.',
               [packed_str]));
        sfmt := av_get_packed_sample_fmt(sfmt);
        n_channels := 1;
      end;

      ret := get_format_from_sample_fmt(@fmt, sfmt);
      if ret < 0 then
        goto _end;

      Writeln(Format('Play the output audio file with the command:' + sLineBreak +
             'ffplay -f %s -ac %d -ar %d %s',
            [string(fmt), n_channels, audio_dec_ctx.sample_rate,
             audio_dst_filename]));
    end;

  _end:
    avcodec_close(video_dec_ctx);
    avcodec_close(audio_dec_ctx);
    avformat_close_input(fmt_ctx);
    if video_dst_file <> INVALID_HANDLE_VALUE then
      FileClose(video_dst_file);
    if audio_dst_file <> INVALID_HANDLE_VALUE then
      FileClose(audio_dst_file);
    if api_mode = API_MODE_OLD then
      avcodec_free_frame(frame)
    else
      av_frame_free(frame);
    av_free(video_dst_data[0]);

    readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
