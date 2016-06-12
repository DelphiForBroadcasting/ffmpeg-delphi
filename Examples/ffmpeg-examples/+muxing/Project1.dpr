(*
 * Copyright (c) 2003 Fabrice Bellard
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
 * libavformat API example.
 *
 * Output a media file in any supported libavformat format. The default
 * codecs are used.
 * @example muxing.c
 *)

program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  avutil in '../../../libavutil/avutil.pas',
  avcodec in '../../../libavcodec/avcodec.pas',
  avformat in '../../../libavformat/avformat.pas',
  swresample in '../../../libswresample/swresample.pas',
  swscale in '../../../libswscale/swscale.pas';


(* 5 seconds stream duration *)
const
  STREAM_DURATION   : int64   = 10;
  STREAM_FRAME_RATE           = 25; (* 25 images/s *)
  STREAM_PIX_FMT              = AV_PIX_FMT_YUV420P; (* default pix_fmt *) //yuv444p10
  SCALE_FLAGS       : integer = SWS_BICUBIC;

type
// a wrapper around a single output AVStream
  POutputStream = ^TOutputStream;
  TOutputStream = record
    st            : PAVStream;

    (* pts of the next frame that will be generated *)
    next_pts      : int64;
    samples_count : integer;

    frame         : PAVFrame;
    tmp_frame     : PAVFrame;

    t             : Single;
    tincr         : Single;
    tincr2        : Single; //Double;

    sws_ctx       : PSwsContext;
    swr_ctx       : PSwrContext;
  end;


procedure log_packet(const fmt_ctx: PAVFormatContext; const pkt: PAVPacket);
var
  time_base : PAVRational;
  i         : integer;
  streams   : PPAVStream;
begin
  streams := fmt_ctx^.streams;
  for i := 0 to fmt_ctx^.nb_streams-1 do
  begin
    if(streams^.index = pkt^.stream_index) then
    begin
      time_base := @streams^.time_base;
      writeln(format('pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d',
        [string(av_ts2str(pkt^.pts)), string(av_ts2timestr(pkt^.pts, time_base)),
        string(av_ts2str(pkt^.dts)), string(av_ts2timestr(pkt^.dts, time_base)),
        string(av_ts2str(pkt^.duration)), string(av_ts2timestr(pkt^.duration, time_base)),
        pkt^.stream_index]));
      break;
    end;
    inc(streams);
  end;
end;

function write_frame(fmt_ctx: PAVFormatContext; const time_base: PAVRational; st: PAVStream; pkt: PAVPacket): integer;
begin
  (* rescale output packet timestamp values from codec to stream timebase *)
  av_packet_rescale_ts(pkt, time_base^, st^.time_base);
  pkt^.stream_index := st^.index;

  (* Write the compressed frame to the media file. *)
  log_packet(fmt_ctx, pkt);
  result  :=  av_interleaved_write_frame(fmt_ctx, pkt);
end;

(* Add an output stream. *)
procedure add_stream(ost: POutputStream; oc: PAVFormatContext;
                       var codec: PAVCodec; codec_id: TAVCodecID);
var
  c : PAVCodecContext;
  i : integer;
begin
  (* find the encoder *)
  codec := avcodec_find_encoder(codec_id);
  if not assigned(codec) then
  begin
    writeln(Format('Could not find encoder for %s',  [avcodec_get_name(codec_id)]));
    exit;
  end;

  ost^.st := avformat_new_stream(oc, codec);
  if not assigned(ost^.st) then
  begin
    writeln('Could not allocate stream');
    exit;;
  end;

  ost^.st^.id := oc^.nb_streams-1;
  c := ost^.st^.codec;

  case codec^.type_ of
    AVMEDIA_TYPE_AUDIO:
    begin
      if assigned(codec^.sample_fmts) then
        c^.sample_fmt := TAVSampleFormat(codec^.sample_fmts^)
      else
        c^.sample_fmt := AV_SAMPLE_FMT_FLTP;

      c^.bit_rate    := 64000;
      c^.sample_rate := 44100;
      if assigned(codec^.supported_samplerates) then
      begin
        c^.sample_rate := codec^.supported_samplerates^;
        (*
        for (i = 0; (*codec)->supported_samplerates[i]; i++)
        begin
          if ((*codec)->supported_samplerates[i] == 44100) then
            c^.sample_rate := 44100;
        end;
        *)
      end;
      c^.channels       := av_get_channel_layout_nb_channels(c^.channel_layout);
      c^.channel_layout := AV_CH_LAYOUT_STEREO;
      if assigned(codec^.channel_layouts) then
      begin
        c^.channel_layout := codec^.channel_layouts^;
        (*
        for (i = 0; (*codec)->channel_layouts[i]; i++)
        begin
          if ((*codec)->channel_layouts[i] == AV_CH_LAYOUT_STEREO) then
            c^.channel_layout := AV_CH_LAYOUT_STEREO;
        end;
        }
        *)
      end;
      c^.channels := av_get_channel_layout_nb_channels(c^.channel_layout);
      ost^.st^.time_base.num := 1;
      ost^.st^.time_base.den := c^.sample_rate;

    end;
    AVMEDIA_TYPE_VIDEO:
    begin
      c^.codec_id := codec_id;

      c^.bit_rate := 800000;
      (* Resolution must be a multiple of two. *)
      c^.width    := 720;
      c^.height   := 576;
      (* timebase: This is the fundamental unit of time (in seconds) in terms
       * of which frame timestamps are represented. For fixed-fps content,
       * timebase should be 1/framerate and timestamp increments should be
       * identical to 1. *)
      ost^.st^.time_base.num := 1;
      ost^.st^.time_base.den := STREAM_FRAME_RATE;
      c^.time_base := ost^.st^.time_base;

      c^.gop_size := 12; (* emit one intra frame every twelve frames at most *)
      c^.pix_fmt := STREAM_PIX_FMT;
      if (c^.codec_id = CODEC_ID_MPEG2VIDEO) then
      begin
        (* just for testing, we also add B frames *)
        c^.max_b_frames := 2;
      end;
      if (c^.codec_id = CODEC_ID_MPEG1VIDEO) then
      begin
        (* Needed to avoid using macroblocks in which some coeffs overflow.
         * This does not happen with normal video, it just happens here as
         * the motion of the chroma plane does not match the luma plane. *)
        c^.mb_decision := 2;
      end;
    end;
  end;

  (* Some formats want stream headers to be separate. *)
   if ((oc^.oformat^.flags and AVFMT_GLOBALHEADER) > 0) then
       c^.flags := c^.flags or CODEC_FLAG_GLOBAL_HEADER;
end;

(**************************************************************)
(* audio output *)

function alloc_audio_frame(sample_fmt : TAVSampleFormat;
                           channel_layout: UInt64;
                           sample_rate: integer; nb_samples: integer): PAVFrame;
var
  frame : PAVFrame;
  ret   : integer;
begin
  result := nil;
  frame := av_frame_alloc();
  if not assigned(frame) then
  begin
    writeln('Error allocating an audio frame');
    exit;
  end;


  frame^.format := integer(sample_fmt);
  frame^.channel_layout := channel_layout;
  frame^.sample_rate := sample_rate;
  frame^.nb_samples := nb_samples;

  if (nb_samples > 0) then
  begin
    ret := av_frame_get_buffer(frame, 0);
    if (ret < 0) then
    begin
      writeln('Error allocating an audio buffer');
      exit;
    end;
  end;


  result := frame;
end;

procedure open_audio(oc: PAVFormatContext; codec: PAVCodec; ost: POutputStream; opt_arg: PAVDictionary);
var
  c           : PAVCodecContext;
  nb_samples  : integer;
  ret         : integer;
  opt         : PAVDictionary;
begin
  opt := nil;

  c := ost^.st^.codec;

  (* open it *)
  av_dict_copy(@opt, opt_arg, 0);
  ret := avcodec_open2(c, codec, @opt);
  av_dict_free(opt);
  if (ret < 0) then
  begin
    writeln(format('Could not open audio codec: %s', [av_err2str(ret)]));
    exit;
  end;
  (* init signal generator *)
  ost^.t     := 0;
  ost^.tincr := 2 * M_PI * 110.0 / c^.sample_rate;
  (* increment frequency by 110 Hz per second *)
  ost^.tincr2 := 2 * M_PI * 110.0 / c^.sample_rate / c^.sample_rate;



  if (c^.codec^.capabilities and CODEC_CAP_VARIABLE_FRAME_SIZE) > 0 then
    nb_samples := 10000
  else
    nb_samples := c^.frame_size;

  ost^.frame     := alloc_audio_frame(c^.sample_fmt, c^.channel_layout,
                                       c^.sample_rate, nb_samples);
  ost^.tmp_frame := alloc_audio_frame(AV_SAMPLE_FMT_S16, c^.channel_layout,
                                       c^.sample_rate, nb_samples);
  (* create resampler context *)
  ost^.swr_ctx := swr_alloc();
  if not assigned(ost^.swr_ctx) then
  begin
    writeln('Could not allocate resampler context');
    exit;
  end;

  (* set options *)
  av_opt_set_int       (ost^.swr_ctx, PAnsiChar('in_channel_count'),   c^.channels,         0);
  av_opt_set_int       (ost^.swr_ctx, PAnsiChar('in_sample_rate'),     c^.sample_rate,      0);
  av_opt_set_sample_fmt(ost^.swr_ctx, PAnsiChar('in_sample_fmt'),      AV_SAMPLE_FMT_S16,  0);
  av_opt_set_int       (ost^.swr_ctx, PAnsiChar('out_channel_count'),  c^.channels,         0);
  av_opt_set_int       (ost^.swr_ctx, PAnsiChar('out_sample_rate'),    c^.sample_rate,      0);
  av_opt_set_sample_fmt(ost^.swr_ctx, PAnsiChar('out_sample_fmt'),     c^.sample_fmt,       0);

  (* initialize the resampling context *)
  ret := swr_init(ost^.swr_ctx);
  if (ret < 0) then
  begin
    writeln('Failed to initialize the resampling context');
    exit;
  end;
end;

(* Prepare a 16 bit dummy audio frame of 'frame_size' samples and
 * 'nb_channels' channels. *)
function get_audio_frame(ost: POutputStream): PAVFrame;
var
  j, i, v : integer;
  q       : PSmallInt;
  frame   : PAVFrame;
begin
  result := nil;
  frame := ost^.tmp_frame;
  q := PSmallInt(frame.data[0]);

  (* check if we want to generate more frames *)
  if (av_compare_ts(ost^.next_pts, ost^.st^.codec^.time_base, STREAM_DURATION, av_make_q(1,1)) >= 0) then
    exit;

  for j := 0 to frame^.nb_samples-1 do
  begin
    v := round(sin(ost^.t) * 10000);
    for i := 0 to ost^.st^.codec^.channels-1 do
    begin
      q^ := v;
      inc(q);
    end;
    ost^.t     := ost^.t + ost^.tincr;
    ost^.tincr := ost^.tincr + ost^.tincr2;
  end;
  frame^.pts := ost^.next_pts;
  inc(ost^.next_pts, frame^.nb_samples);

  result := frame;
end;

(*
 * encode one audio frame and send it to the muxer
 * return 1 when encoding is finished, 0 otherwise
 *)
function write_audio_frame(oc: PAVFormatContext; ost: POutputStream): boolean;
var
  c               : PAVCodecContext;
  pkt             : TAVPacket; // data and size must be 0;
  frame           : PAVFrame;
  ret             : integer;
  got_packet      : integer;
  dst_nb_samples  : integer;
begin
  result := false;
  fillchar(pkt, sizeof(TAVPacket), #0);
  av_init_packet(@pkt);
  c := ost^.st^.codec;

  frame := get_audio_frame(ost);

  if assigned(frame) then
  begin
    (* convert samples from native format to destination codec format, using the resampler *)
    (* compute destination number of samples *)
    dst_nb_samples := av_rescale_rnd(swr_get_delay(ost^.swr_ctx, c^.sample_rate) + frame^.nb_samples,
                                            c^.sample_rate, c^.sample_rate, AV_ROUND_UP);
    //v_assert0(dst_nb_samples == frame->nb_samples);

    (* when we pass a frame to the encoder, it may keep a reference to it
     * internally;
     * make sure we do not overwrite it here
     *)
    ret := av_frame_make_writable(ost^.frame);
    if (ret < 0) then
      exit;

    (* convert to destination format *)
    ret := swr_convert(ost^.swr_ctx, ost^.frame^.data[0], dst_nb_samples,
                              frame^.data[0], frame^.nb_samples);
    if (ret < 0) then
    begin
      writeln('Error while converting');
      exit;
    end;
    frame := ost^.frame;

    frame^.pts := av_rescale_q(ost^.samples_count, av_make_q(1, c^.sample_rate), c^.time_base);
    inc(ost^.samples_count, dst_nb_samples);
  end;

  ret := avcodec_encode_audio2(c, @pkt, frame, got_packet);
  if (ret < 0) then
  begin
    writeln(format('Error encoding audio frame: %s', [av_err2str(ret)]));
    exit;
  end;

  if (got_packet >0 ) then
  begin
    ret := write_frame(oc, @c^.time_base, ost^.st, @pkt);
    if (ret < 0) then
    begin
      writeln(format('Error while writing audio frame: %s', [av_err2str(ret)]));
      exit;
    end;
  end;

  if (assigned(frame)  or (got_packet > 0)) then
    result := false
  else
    result := true;
end;

(**************************************************************)
(* video output *)

function alloc_picture(pix_fmt: TAVPixelFormat; width: integer; height: integer): PAVFrame;
var
  picture : PAVFrame;
  ret     : integer;
begin
  result := nil;
  picture := av_frame_alloc();
  if not assigned(picture) then
    exit;

  picture^.format := integer(pix_fmt);
  picture^.width  := width;
  picture^.height := height;

  (* allocate the buffers for the frame data *)
  ret := av_frame_get_buffer(picture, 32);
  if (ret < 0) then
  begin
    writeln('Could not allocate frame data.');
    exit;
  end;

  result := picture;
end;

procedure open_video(oc: PAVFormatContext; codec: PAVCodec; ost: POutputStream; opt_arg: PAVDictionary);
var
  ret     : integer;
  c       : PAVCodecContext;
  opt     : PAVDictionary;
begin
  opt := nil;
  c := ost^.st^.codec;
  av_dict_copy(@opt, opt_arg, 0);

  (* open the codec *)
  ret := avcodec_open2(c, codec, @opt);
  av_dict_free(opt);
  if (ret < 0) then
  begin
    writeln(format('Could not open video codec: %s', [av_err2str(ret)]));
    exit;
  end;

  (* allocate and init a re-usable frame *)
  ost^.frame := alloc_picture(c^.pix_fmt, c^.width, c^.height);
  if not assigned(ost^.frame) then
  begin
    writeln('Could not allocate video frame');
    exit;
  end;

  (* If the output format is not YUV420P, then a temporary YUV420P
   * picture is needed too. It is then converted to the required
   * output format. *)
  ost^.tmp_frame := nil;
  if (c^.pix_fmt <> AV_PIX_FMT_YUV420P) then
  begin
    ost^.tmp_frame := alloc_picture(AV_PIX_FMT_YUV420P, c^.width, c^.height);
    if not assigned(ost^.tmp_frame) then
    begin
      writeln('Could not allocate temporary picture');
      exit;
    end;
  end;
end;


(* Prepare a dummy image. *)
Procedure fill_yuv_image(var pict : PAVFrame; frame_index: integer;
                           width: integer; height: integer);
var
  x, y, i,ret : integer;
begin
  (* when we pass a frame to the encoder, it may keep a reference to it
   * internally;
   * make sure we do not overwrite it here
   *)
   ret := av_frame_make_writable(pict);
   if (ret < 0) then
    exit;

  i := frame_index;
  (* Y *)
  for y := 0 to height-1 do
    for x := 0 to width-1 do
      pByte(pict^.data[0])[y * pict^.linesize[0] + x] := x + y + i * 3;

  (* Cb and Cr *)
  for y := 0 to (height div 2)-1 do
    for x := 0 to (width div 2)-1 do
    begin
      pByte(pict^.data[1])[y * pict^.linesize[1] + x] := 128 + y + i * 2;
      pByte(pict^.data[2])[y * pict^.linesize[2] + x] := 64 + x + i * 5;
    end;
end;

function get_video_frame(ost: POutputStream): PAVFrame;
var
  c     : PAVCodecContext;
begin
  result := nil;
  c := ost^.st^.codec;

  (* check if we want to generate more frames *)
  if (av_compare_ts(ost^.next_pts, ost^.st^.codec^.time_base, STREAM_DURATION, av_make_q(1, 1)) >= 0) then
    exit;

  if (c^.pix_fmt <> AV_PIX_FMT_YUV420P) then
  begin
    (* as we only generate a YUV420P picture, we must convert it
     * to the codec pixel format if needed *)
    if not assigned(ost^.sws_ctx) then
    begin
      ost^.sws_ctx := sws_getContext(c^.width, c^.height,
                                          AV_PIX_FMT_YUV420P,
                                          c^.width, c^.height,
                                          c^.pix_fmt,
                                          SCALE_FLAGS, 0, 0, 0);
      if not assigned(ost^.sws_ctx) then
      begin
        writeln('Could not initialize the conversion context');
        exit;
      end;
    end;
    fill_yuv_image(ost^.tmp_frame, ost^.next_pts, c^.width, c^.height);
    sws_scale(ost^.sws_ctx, @ost^.tmp_frame^.data, @ost^.tmp_frame^.linesize,
                  0, c^.height, @ost^.frame^.data, @ost^.frame^.linesize);
  end else
  begin
    fill_yuv_image(ost^.frame, ost^.next_pts, c^.width, c^.height);
  end;
  inc(ost^.next_pts);
  ost^.frame^.pts := ost^.next_pts;

  result := ost^.frame;
end;

(*
 * encode one video frame and send it to the muxer
 * return 1 when encoding is finished, 0 otherwise
 *)
function write_video_frame(oc: PAVFormatContext; ost: POutputStream): boolean;
var
  ret : integer;
  c : PAVCodecContext;
  frame : PAVFrame;
  got_packet : integer;
  pkt : TAVPacket;
begin
  result := false;
  got_packet := 0;
  c := ost^.st^.codec;

  frame := get_video_frame(ost);

  if (oc^.oformat^.flags and  AVFMT_RAWPICTURE) > 0 then
  begin
    (* a hack to avoid data copy with some raw video muxers *)

    av_init_packet(@pkt);

    if not assigned(frame) then
      exit;

    pkt.flags         := pkt.flags or AV_PKT_FLAG_KEY;
    pkt.stream_index  := ost^.st.index;
    pkt.data          := frame^.data[0];
    pkt.size          := sizeof(TAVPicture);

    pkt.pts := frame^.pts;
    pkt.dts := frame^.pts;
    av_packet_rescale_ts(@pkt, c^.time_base, ost^.st^.time_base);

    ret := av_interleaved_write_frame(oc, @pkt);
  end else
  begin
    fillchar(pkt, sizeof(TAVPacket), #0);
    av_init_packet(@pkt);

    (* encode the image *)
    ret := avcodec_encode_video2(c, @pkt, frame, got_packet);
    if (ret < 0) then
    begin
      writeln(format('Error encoding video frame: %s', [av_err2str(ret)]));
      exit;
    end;

    if (got_packet > 0) then
      ret := write_frame(oc, @c^.time_base, ost^.st, @pkt)
    else
      ret := 0;

  end;

  if (ret < 0) then
  begin
    writeln(format('Error while writing video frame: %s', [av_err2str(ret)]));
    exit;
  end;

  if (assigned(frame)  or (got_packet > 0)) then
    result := false
  else
    result := true;
end;

procedure close_stream(oc: PAVFormatContext; ost: POutputStream);
begin
  avcodec_close(ost^.st^.codec);
  av_frame_free(ost^.frame);
  av_frame_free(ost^.tmp_frame);
  sws_freeContext(ost^.sws_ctx);
  swr_free(ost^.swr_ctx);
end;


(**************************************************************)
(* media file output *)
var

  video_st    : TOutputStream;
  audio_st    : TOutputStream;
  filename    : PAnsiChar;
  fmt         : PAVOutputFormat;
  oc          : PAVFormatContext;
  audio_codec : PAVCodec;
  video_codec : PAVCodec;
  ret         : integer;
  have_audio  : integer;
  have_video  : integer;
  encode_video: boolean;
  encode_audio: boolean;
  opt         : PAVDictionary;
begin
  try
    have_video := 0;
    have_audio := 0;
    encode_video := false;
    encode_audio := false;
    opt := nil;

    (* Initialize libavcodec, and register all codecs and formats. *)
    av_register_all();
    if (ParamCount < 1) then
    begin
      writeln(format('usage: %s [output_file]'+#10#13+
               'API example program to output a media file with libavformat.'+#10#13+
               'This program generates a synthetic audio and video stream, encodes and'+#10#13+
               'muxes them into a file named output_file.'+#10#13+
               'The output format is automatically guessed according to the file extension.'+#10#13+
               'Raw images can also be output by using ''%%d'' in the filename.'+#10#13, [ParamStr(0)]));
      exit;
    end;

    filename := PansiChar(AnsiString(ParamStr(1)));

    if ((ParamCount > 2) and  (SameText(ParamStr(2),'-flags'))) then
    begin
      //av_dict_set(@opt, PAnsiChar(ParamStr(2)), PAnsiChar(ParamStr(3)), 0);  /// failed
    end;


    (* allocate the output media context *)
    avformat_alloc_output_context2(oc, nil, nil, filename);
    if not assigned(oc) then
    begin
      writeln('Could not deduce output format from file extension: using MPEG.');
      avformat_alloc_output_context2(oc, nil, PAnsiChar('mpeg'), filename);
    end;

    if not assigned(oc) then
      exit;

    fmt := oc.oformat;

    (* Add the audio and video streams using the default format codecs
     * and initialize the codecs. *)
    if (fmt^.video_codec <> AV_CODEC_ID_NONE) then
    begin
        add_stream(@video_st, oc, video_codec, fmt^.video_codec);
        have_video := 1;
        encode_video := true;
    end;

    if (fmt^.audio_codec <> AV_CODEC_ID_NONE) then
    begin
        add_stream(@audio_st, oc, audio_codec, fmt^.audio_codec);
        have_audio := 1;
        encode_audio := true;
    end;


    (* Now that all the parameters are set, we can open the audio and
     * video codecs and allocate the necessary encode buffers. *)
    if (have_video > 0) then
        open_video(oc, video_codec, @video_st, opt);

    if (have_audio > 0) then
        open_audio(oc, audio_codec, @audio_st, opt);

    av_dump_format(oc, 0, filename, 1);

    (* open the output file, if needed *)
    if (fmt^.flags and AVFMT_NOFILE) <=0 then
    begin
      ret := avio_open(oc^.pb, filename, AVIO_FLAG_WRITE);
      if (ret < 0) then
      begin
          writeln(Format('Could not open "%s": %s', [filename, av_err2str(ret)]));
          exit;
      end;
    end;

    (* Write the stream header, if any. *)
    ret := avformat_write_header(oc, @opt);
    if (ret < 0) then
    begin
      writeln(format('Error occurred when opening output file: %s', [av_err2str(ret)]));
      exit;
    end;

    while (encode_video or encode_audio) do
    begin
      (* select the stream to encode *)
      if (encode_video and (not encode_audio or (av_compare_ts(video_st.next_pts, video_st.st^.codec^.time_base, audio_st.next_pts, audio_st.st^.codec^.time_base) <= 0))) then
      begin
        encode_video :=  not write_video_frame(oc, @video_st);
      end else
      begin
        encode_audio := not write_audio_frame(oc, @audio_st);
      end
    end;

    (* Write the trailer, if any. The trailer must be written before you
     * close the CodecContexts open when you wrote the header; otherwise
     * av_write_trailer() may try to use memory that was freed on
     * av_codec_close(). *)
    av_write_trailer(oc);

    (* Close each codec. *)
    if (have_video > 0) then
      close_stream(oc, @video_st);
    if (have_audio > 0) then
      close_stream(oc, @audio_st);

    if (fmt.flags and AVFMT_NOFILE) < AVFMT_NOFILE then
    begin
      (* Close the output file. *)
      avio_close(oc^.pb);
    end;

    (* free the stream *)
    avformat_free_context(oc);

    readln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
