unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ComCtrls, math, SDL2, swscale, avformat, avcodec, avutil,
  Vcl.Buttons, Vcl.Imaging.jpeg, Vcl.ExtCtrls, Vcl.StdCtrls, System.ImageList,
  Vcl.ImgList;

type
  TAV_SYNC= (AV_SYNC_AUDIO_MASTER,
             AV_SYNC_VIDEO_MASTER,
             AV_SYNC_EXTERNAL_MASTER);

  int64 = System.Int64;

const
  SDL_AUDIO_BUFFER_SIZE         = 1024;
  MAX_AUDIO_FRAME_SIZE          = 192000;

  MAX_AUDIOQ_SIZE               = (5 * 16 * 1024);
  MAX_VIDEOQ_SIZE               = (5 * 256 * 1024);

  USE_AUDIO_DRIVER              = 'directsound';

  AV_SYNC_THRESHOLD             = 0.01;
  AV_NOSYNC_THRESHOLD           = 10.0;

  SAMPLE_CORRECTION_PERCENT_MAX = 10;
  AUDIO_DIFF_AVG_NB             = 20;

  FF_ALLOC_EVENT                = (SDL_USEREVENT);
  FF_REFRESH_EVENT              = (SDL_USEREVENT + 1);
  FF_QUIT_EVENT                 = (SDL_USEREVENT + 2);

  VIDEO_PICTURE_QUEUE_SIZE      = 1;

  DEFAULT_AV_SYNC_TYPE          = AV_SYNC_EXTERNAL_MASTER;

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

  PVideoPicture = ^TVideoPicture;
  TVideoPicture = record
    bmp           : PSDL_texture;
    width, height : integer; (* source height & width *)
    allocated     : integer;
    pts           : double;
    buffer        : PByte;
    pFrameYUV420P : PAVFrame;
  end;

  PVideoState = ^TVideoState;
  TVideoState = record
    pFormatCtx        : PAVFormatContext;
    videoStream       : integer;
    audioStream       : integer;

    av_sync_type      : TAV_SYNC;
    external_clock    : double; (* external clock base *)
    external_clock_time : int64;

    pause             : boolean;

    scale             : double;

    seek_req          : boolean;
    seek_flags        : integer;
    seek_pos          : int64;

    audio_clock       : double;
    audio_st          : PAVStream;
    audioq            : PPacketQueue;
    audio_frame       : TAVFrame;
    audio_buf         : array[0..((MAX_AUDIO_FRAME_SIZE * 3) div 2)] of Byte;
    audio_buf_size    : cardinal;
    audio_buf_index   : cardinal;
    audio_pkt         : TAVPacket;
    audio_pkt_data    : pByte;
    audio_pkt_size    : integer;
    audio_hw_buf_size : integer;

    audio_diff_cum    : double; (* used for AV difference average computation *)
    audio_diff_avg_coef   : double;
    audio_diff_threshold  : double;
    audio_diff_avg_count  : integer;

    frame_timer       : double;
    frame_last_pts    : double;
    frame_last_delay  : double;
    video_clock       : double; ///<pts of last decoded frame / predicted pts of next decoded frame


    video_current_pts : double; ///<current displayed pts (different from video_clock if frame fifos are used)
    video_current_pts_time  : int64;  ///<time (av_gettime) at which we updated video_current_pts - used to have running video pts


    video_st          : PAVStream;
    videoq            : PPacketQueue;

    pictq             : array[0..VIDEO_PICTURE_QUEUE_SIZE] of TVideoPicture;
    pictq_size        : integer;
    pictq_rindex      : integer;
    pictq_windex      : integer;
    pictq_mutex       : PSDL_mutex;
    pictq_cond        : PSDL_cond;

    parse_tid         : PSDL_Thread;
    video_tid         : PSDL_Thread;

    filename          : array[0..1024] of ansichar;
    quit              : boolean;

    io_context        : PAVIOContext;
    sws_ctx           : PSwsContext;
  end;

type
  TDataMessage = record
    Msg: DWORD;
    Data: Pointer;
  end;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    Open1: TMenuItem;
    N2: TMenuItem;
    Savesa1: TMenuItem;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Open1Click(Sender: TObject);
    procedure packet_queue_flush(var q: PPacketQueue);
    function packet_queue_get(var q: PPacketQueue; var pkt: TAVPacket; block: integer): integer;
    function packet_queue_put(var q: PPacketQueue; pkt: PAVPacket): integer;
    procedure packet_queue_init(var q: PPacketQueue);
    function audio_decode_frame(var is_: PVideoState; var pts_ptr: double): integer;
    function synchronize_audio(var is_ : PVideoState; samples: PSmallInt; var samples_size: integer; pts: double): integer;
    function get_master_clock(is_ : PVideoState): double;
    function get_external_clock(is_ : PVideoState): double;
    function get_video_clock(is_ : PVideoState): double;
    function get_audio_clock(is_: PVideoState): double;

    procedure doScale(incr : double);
    procedure doSeek(const incr : double);
    procedure stream_seek(var is_: PVideoState; pos: int64; rel: double);

    function stream_component_open(var is_: PVideoState; stream_index: integer): integer;

    function synchronize_video(var is_: PVideoState; var src_frame: PAVFrame; pts_: double): double;
    function queue_picture(var is_: PVideoState; pFrame: PAVFrame; pts: double): integer;
    procedure alloc_picture(userdata: pointer);
    procedure video_refresh_timer(userdata: pointer);
    procedure video_display(is_: PVideoState);
    procedure schedule_refresh(var is_: PVideoState; delay: integer);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure OnAllocReceived(var Msg: TDataMessage); message FF_ALLOC_EVENT;
    procedure OnRefreshReceived(var Msg: TDataMessage); message FF_REFRESH_EVENT;
    procedure OnQuitReceived(var Msg: TDataMessage); message FF_QUIT_EVENT;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
    { Private declarations }
  public
    global_video_pkt_pts :  int64;

  end;

var
  Form1: TForm1;

  screen              : PSDL_Window = nil;
  render              : PSDL_renderer = nil;
  texture             : PSDL_texture  = nil;

  (* Since we only have one decoding thread, the Big Struct
   can be global in case we need it. *)
  global_video_state  : PVideoState;

  flush_pkt           : TAVPacket;
  is_                 : PVideoState;
  FAudioDriver        : ansistring;

implementation

{$R *.dfm}

function decode_interrupt_cb(opaque: Pointer): integer; cdecl;
begin
  Result:=Ord((assigned(@global_video_state) and global_video_state.quit));
end;

function decode_thread(arg: pointer): LongInt; cdecl;
label
  fail;
var
  is_           : PVideoState;
  pFormatCtx    : PAVFormatContext;
  packet        : PAVPacket;
  pkt1          : TAVPacket;
  video_index   : integer;
  audio_index   : integer;
  i             : integer;
  io_dict       : PAVDictionary;
  callback      : TAVIOInterruptCB;
  pStream       : PPAVStream;
  event         : TDataMessage;
  stream_index  : integer;
  seek_target   : int64;
begin
  is_ := PVideoState(arg);

  pFormatCtx:= nil;
  packet := @pkt1;

  video_index := -1;
  audio_index := -1;

  io_dict := nil;


  is_.videoStream := -1;
  is_.audioStream := -1;

  global_video_state := is_;
// will interrupt blocking functions if we quit!
  callback.callback := decode_interrupt_cb;
  callback.opaque := is_;
  if avio_open2(is_.io_context, @is_.filename[0], 0, @callback, @io_dict)<0 then
  begin
    showmessage(format('Unable to open I/O for %s', [ansistring(is_.filename)]));
    result:=-1;
    exit;
  end;

  // Open video file
  if(avformat_open_input(pFormatCtx, @is_.filename[0], nil, nil)<>0) then
  begin
      showmessage(format('Could not open source file %s', [ansistring(is_.filename)]));
      result:=-1;
      exit;
  end;

  is_.pFormatCtx := pFormatCtx;

  // Retrieve stream information
  if avformat_find_stream_info(pFormatCtx , nil) < 0 then
  begin
    showmessage(format('Could not find stream information', []));
    result:=-1;
    exit;
  end;

  // Dump information about file onto standard error
  av_dump_format(pFormatCtx, 0, @is_.filename[0], 0);


  // Find the first video stream

   pStream:=pFormatCtx.streams;
   for i:=0 to pFormatCtx.nb_streams-1 do
   begin
      if ((pStream^.codec.codec_type =  AVMEDIA_TYPE_VIDEO) and (video_index<0)) then
      begin
        video_index := i;
      end else
      if ((pStream^.codec.codec_type =  AVMEDIA_TYPE_AUDIO) and (audio_index < 0)) then
      begin
        audio_index := i;
      end;
      inc(pStream);
   end;


  if (audio_index >= 0) then
    form1.stream_component_open(is_, audio_index);

  if(video_index >= 0) then
    form1.stream_component_open(is_, video_index);

  if ((is_.videoStream < 0) or (is_.audioStream < 0)) then
  begin
    showmessage(format('%s: could not open codecs', [ansistring(is_.filename)]));
    goto fail;
  end;

  // main decode loop

  while True do
  begin
    if (is_.quit) then
      break;

    // seek stuff goes here
    if(is_.seek_req) then
    begin
      stream_index := -1;
      seek_target := is_.seek_pos;

      if (is_.videoStream >= 0)then
        stream_index := is_.videoStream
      else
      if(is_.audioStream >= 0) then
        stream_index := is_.audioStream;

      if(stream_index>=0)then
      begin
         pStream:=pFormatCtx.streams;
         for i:=0 to pFormatCtx.nb_streams-1 do
         begin
          if i=stream_index then
          begin
            seek_target := av_rescale_q(seek_target, AV_TIME_BASE_Q, pStream^.time_base);
            break;
          end;
            inc(pStream);
         end;
      end;

      if(av_seek_frame(is_.pFormatCtx, stream_index, seek_target, is_.seek_flags) < 0) then
      begin
	      showmessage(format('%s: error while seeking', [ansistring(is_.pFormatCtx.filename)]));
      end else
      begin
        if(is_.audioStream >= 0) then
        begin
          form1.packet_queue_flush(is_.audioq);
          form1.packet_queue_put(is_.audioq, @flush_pkt);
        end;
        if(is_.videoStream >= 0) then
        begin
          form1.packet_queue_flush(is_.videoq);
          form1.packet_queue_put(is_.videoq, @flush_pkt);
        end;
      end;
      is_.seek_req := false;
    end;

    // seek stuff goes here
    if((is_.audioq.size > MAX_AUDIOQ_SIZE) or
       (is_.videoq.size > MAX_VIDEOQ_SIZE)) then
    begin
      SDL_Delay(10);
      continue;
    end;

    if(av_read_frame(is_.pFormatCtx, packet) < 0) then
    begin
      if(is_.pFormatCtx.pb.error = 0) then
      begin
	      SDL_Delay(100); (* no error; wait for user input *)
	      continue;
      end else begin
	      break;
      end;
    end;
    // Is this a packet from the video stream?
    if(packet.stream_index = is_.videoStream) then
      form1.packet_queue_put(is_.videoq, packet)
    else if(packet.stream_index = is_.audioStream) then
      form1.packet_queue_put(is_.audioq, packet)
    else av_free_packet(@packet);
  end;
  (* all done - wait for it *)
  while (not is_.quit) do
    SDL_Delay(100);


  fail:
  begin
    event.Msg:=FF_QUIT_EVENT;
    event.Data:=nil;
    form1.Dispatch(event);
  end;
  result:=0;
end;

procedure our_release_buffer(c: PAVCodecContext; pic: PAVFrame);  cdecl;
begin
  if assigned(pic) then
  begin
    //if assigned(pic.opaque) then
    //  av_freep(pic.opaque);
  end;
  avcodec_default_release_buffer(c, pic);
end;

function our_get_buffer(c: PAVCodecContext; pic: PAVFrame): integer;  cdecl;
var
  ret : integer;
  pts : PInt64;
begin
  ret := avcodec_default_get_buffer(c, pic);
  pts := av_malloc(sizeof(PInt64));
  Int64(pts^) := form1.global_video_pkt_pts;
  pic^.opaque := pts;
  result:=ret;
end;


function video_thread(arg: Pointer): integer; cdecl;
var
  is_           : PVideoState;
  pkt1          : TAVPacket;
  packet        : TAVPacket;
  frameFinished : integer;
  pFrame        : PAVFrame;
  pts           : double;
begin
  is_:= PVideoState(arg);
  packet:= pkt1;                  //////////PAVPAcket

  pFrame := av_frame_alloc();

  while true do
  begin
    if(form1.packet_queue_get(is_.videoq, packet, 1) < 0) then
      // means we quit getting packets
      break;

    if(packet.data = flush_pkt.data) then
    begin
      avcodec_flush_buffers(is_.video_st.codec);
      continue;
    end;

    pts:=0;
    // Save global pts to be stored in pFrame in first call
    form1.global_video_pkt_pts := packet.pts;

    // Decode video frame
    avcodec_decode_video2(is_.video_st.codec, pFrame, frameFinished, @packet);

    if ((packet.dts = AV_NOPTS_VALUE)  and assigned(pFrame.opaque) and (int64(pFrame.opaque^) <> AV_NOPTS_VALUE))then
    begin
      pts := int64(pFrame.opaque^);
    end else
    if(packet.dts <> AV_NOPTS_VALUE) then
    begin
      pts := packet.dts
    end else pts := 0;


    pts := pts * av_q2d(is_.video_st.time_base);

    // Did we get a video frame?
    if (frameFinished)>0 then
    begin
      pts := form1.synchronize_video(is_, pFrame, pts);
      if(form1.queue_picture(is_, pFrame, pts) < 0) then	break;
    end;
    av_free_packet(@packet);
  end;
  av_free(pFrame);
  result:=0;
end;


procedure audio_callback(userdata: Pointer; stream: PUInt8; len: LongInt);  cdecl;
var
  is_             : PVideoState;
  audio_size      : integer;
  len1            : integer;
  pts             : double;
begin
  is_:=PVideoState(userdata);

  while (len > 0) do
  begin
    if(is_.audio_buf_index >= is_.audio_buf_size) then
    begin
      (* We have already sent all our data; get more *)
      audio_size := form1.audio_decode_frame(is_, pts);
      if(audio_size < 0) then
      begin
	      (* If error, output silence *)
	      is_.audio_buf_size := 1024; // arbitrary?
	      fillchar(is_.audio_buf[0], is_.audio_buf_size, #0);
      end else begin
        audio_size := form1.synchronize_audio(is_, PSmallInt(@is_.audio_buf[0]), audio_size, pts);
	      is_.audio_buf_size := audio_size;
      end;
      is_.audio_buf_index := 0;
    end;
    len1 := is_.audio_buf_size - is_.audio_buf_index;
    if(len1 > len) then
      len1 := len;
    move(is_.audio_buf[is_.audio_buf_index], stream^, len1);
    dec(len, len1);
    inc(stream,len1);
    inc(is_.audio_buf_index,len1);
  end;
end;

function sdl_refresh_timer_cb(interval: cardinal; opaque : Pointer): cardinal; cdecl;
var
  event : TDataMessage;
begin

  event.Msg:=FF_REFRESH_EVENT;
  event.Data:=opaque;
  form1.Dispatch(event);

  result:=0; (* 0 means stop timer *)
end;

procedure TForm1.packet_queue_init(var q: PPacketQueue);
begin
  if not assigned(q) then
    new(q);
  fillchar(q^, sizeof(TPacketQueue), #0);
  q.mutex := SDL_CreateMutex();
  q.cond := SDL_CreateCond();
end;

function TForm1.packet_queue_put(var q: PPacketQueue; pkt: PAVPacket): integer;
var
  pkt1  : PAVPacketList;
begin
  result:=-1;

  if not assigned(pkt) then
    exit;

  if((pkt<>@flush_pkt) and (av_dup_packet(pkt) < 0)) then
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

function TForm1.packet_queue_get(var q: PPacketQueue; var pkt: TAVPacket; block: integer): integer;
var
  pkt1  : PAVPacketList;
  ret   : integer;
begin
  result:=-1;
  ret:=-1;
  SDL_LockMutex(q.mutex);
  try
    while true do
    begin
      if global_video_state.quit then
      begin
        result:=-1;
        break;
      end;
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

procedure TForm1.packet_queue_flush(var q: PPacketQueue);
var
  pkt, pkt1: PAVPacketList;
begin

  SDL_LockMutex(q.mutex);
  try
    pkt := q.first_pkt;
    while( pkt <> nil) do
    begin
      pkt1 := pkt^.next;
      av_free_packet(@pkt^.pkt);
      av_freep(@pkt);
      pkt := pkt1
    end;

    q.last_pkt := nil;
    q.first_pkt := nil;
    q.nb_packets := 0;
    q.size := 0;
  finally
    SDL_UnlockMutex(q.mutex);
  end;
end;

function TForm1.get_audio_clock(is_: PVideoState): double;
var
  pts           : double;
  hw_buf_size   : integer;
  bytes_per_sec : integer;
  n             : integer;
begin
  pts := is_.audio_clock; (* maintained in the audio thread *)
  hw_buf_size := is_.audio_buf_size - is_.audio_buf_index;
  bytes_per_sec := 0;
  n := is_.audio_st.codec.channels * 2;
  if assigned(is_.audio_st) then
    bytes_per_sec := is_.audio_st.codec.sample_rate * n;

  if(bytes_per_sec>0) then
    pts := pts - (hw_buf_size / bytes_per_sec);

  result:=pts;
end;

function TForm1.get_video_clock(is_ : PVideoState): double;
var
  delta : double;
begin
  delta := (av_gettime() - is_.video_current_pts_time) / 1000000.0;
  result:=is_.video_current_pts + delta;
end;

function TForm1.get_external_clock(is_ : PVideoState): double;
begin
  result:=av_gettime() / 1000000.0;
end;

function TForm1.get_master_clock(is_ : PVideoState): double;
begin
  if(is_.av_sync_type = AV_SYNC_VIDEO_MASTER) then
  begin
    result:=get_video_clock(is_);
  end else
  if(is_.av_sync_type = AV_SYNC_AUDIO_MASTER) then
  begin
    result:=get_audio_clock(is_);
  end else result:=get_external_clock(is_);
end;


(* Add or subtract samples to get a better sync, return new
   audio buffer size *)
function TForm1.synchronize_audio(var is_ : PVideoState; samples: PSmallInt; var samples_size: integer; pts: double): integer;
var
  n             : integer;
  ref_clock     : double;
  diff          : double;
  avg_diff      : double;
  wanted_size,
  min_size,
  max_size      : integer; (*, nb_samples *)
  samples_end   : PByte;
  q             : PByte;
  nb            : integer;
begin
  n := 2 * is_.audio_st.codec.channels;

  if(is_.av_sync_type <> AV_SYNC_AUDIO_MASTER) then
  begin
    ref_clock := get_master_clock(is_);
    diff := get_audio_clock(is_) - ref_clock;

    if(diff < AV_NOSYNC_THRESHOLD) then
    begin
      // accumulate the diffs
      is_.audio_diff_cum := diff + is_.audio_diff_avg_coef	* is_.audio_diff_cum;
      if (is_.audio_diff_avg_count < AUDIO_DIFF_AVG_NB) then
      begin
	      inc(is_.audio_diff_avg_count);
      end else
      begin
        avg_diff := is_.audio_diff_cum * (1.0 - is_.audio_diff_avg_coef);
        if (abs(avg_diff) >= is_.audio_diff_threshold) then
        begin
          wanted_size := integer(samples_size + (round(diff * is_.audio_st.codec.sample_rate) * n));
          min_size := samples_size * ((100 - SAMPLE_CORRECTION_PERCENT_MAX) div 100);
          max_size := samples_size * ((100 + SAMPLE_CORRECTION_PERCENT_MAX) div 100);
          if(wanted_size < min_size) then
          begin
            wanted_size := min_size;
          end else
          if (wanted_size > max_size) then
          begin
            wanted_size := max_size;
          end;
          if(wanted_size < samples_size) then
          begin
            (* remove samples *)
            samples_size := wanted_size;
          end else
          if(wanted_size > samples_size) then
          begin
            (* add samples by copying final sample*)
            nb := (samples_size - wanted_size);
            samples_end := Pointer(byte(samples) + samples_size - n);
            q := Pointer(byte(samples_end) + n);
            while(nb > 0) do
            begin
              move(samples_end^, q^, n);
              inc(q,n);
              nb := nb-n;
            end;
            samples_size := wanted_size;
          end;
        end;
      end;
    end else
    begin
      (* difference is TOO big; reset diff stuff *)
      is_.audio_diff_avg_count := 0;
      is_.audio_diff_cum := 0;
    end;
  end;
  result:=samples_size;
end;


function TForm1.audio_decode_frame(var is_: PVideoState; var pts_ptr: double): integer;
var
  pkt             : TAVPacket;    /////////// PAVPacket
  len1            : integer;
  data_size       : integer;
  pts             : double;
  n               : integer;
  got_frame       : integer;
begin
  data_size:=0;
  len1:=0;
  pkt:=is_.audio_pkt;

  while True do
  begin
    while (is_.audio_pkt_size > 0) do
    begin
      got_frame := 0;
      len1 := avcodec_decode_audio4(is_.audio_st.codec, @is_.audio_frame, got_frame, @pkt);
      if(len1 <= 0) then
      begin
	      (* if error, skip frame *)
	      is_.audio_pkt_size := 0;
	      break;
      end;
      if got_frame>0 then
      begin
        data_size := av_samples_get_buffer_size(0, is_.audio_st.codec.channels, is_.audio_frame.nb_samples, is_.audio_st.codec.sample_fmt, 1);
        CopyMemory(@is_.audio_buf[0], is_.audio_frame.data[0], data_size);
      end;
      inc(is_.audio_pkt_data,len1);
      dec(is_.audio_pkt_size,len1);
     // inc(data_size, len1);
      if(data_size <= 0) then
      begin
	      (* No data yet, get more frames *)
	      continue;
      end;

      pts := is_.audio_clock;
      pts_ptr := pts;
      n := 2 * is_.audio_st.codec.channels;
      is_.audio_clock :=is_.audio_clock + (data_size / (n * is_.audio_st.codec.sample_rate));

      (* We have data, return it and come back for more later *)
      result:=data_size;
      exit;
    end;
    if assigned(pkt.data) then
      av_free_packet(@pkt);

    if is_.quit then
    begin
      result:=-1;
      exit;
    end;

    (* next packet *)
    if(packet_queue_get(is_.audioq, pkt, 1) < 0) then
    begin
      result:=-1;
      exit;
    end;

    if (pkt.data = flush_pkt.data) then
    begin
      avcodec_flush_buffers(is_.audio_st.codec);
      continue;
    end;

    is_.audio_pkt_data := pkt.data;
    is_.audio_pkt_size := pkt.size;
    (* if update, update the audio clock w/pts *)
    if(pkt.pts <> AV_NOPTS_VALUE) then
      is_.audio_clock := av_q2d(is_.audio_st.time_base)*pkt.pts;
  end;
end;


procedure TForm1.Button1Click(Sender: TObject);
var
  src_filename        : ansistring;
begin
  if opendialog1.Execute then
  begin
    global_video_pkt_pts := AV_NOPTS_VALUE;
    new(is_);

    src_filename:=(AnsiString(opendialog1.FileName));

    StrPCopy(is_.filename, src_filename);

    is_.pictq_mutex := SDL_CreateMutex();
    is_.pictq_cond := SDL_CreateCond();

    schedule_refresh(is_, 40);

    is_.av_sync_type := DEFAULT_AV_SYNC_TYPE;
    is_.parse_tid := SDL_CreateThread(@decode_thread, nil, is_);
    if not assigned(is_.parse_tid) then
    begin
      av_free(is_);
      exit;
    end;

    av_init_packet(@flush_pkt);
    //flush_pkt.data := (unsigned char *)"FLUSH";
  end;

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  global_video_state.pause:= not global_video_state.pause;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  event : TDataMessage;
begin
    event.Msg:=FF_QUIT_EVENT;
    event.Data:=nil;
    form1.Dispatch(event);
end;

(* schedule a video refresh in 'delay' ms *)
procedure TForm1.schedule_refresh(var is_: PVideoState; delay: integer);
begin
  SDL_AddTimer(delay, @sdl_refresh_timer_cb, is_);
end;

procedure TForm1.video_display(is_: PVideoState);
var
  vp            : PVideoPicture;
  aspect_ratio  : float;
  w, h, x, y    : integer;
  texr          : TSDL_Rect;
  scale         : double;
  RenderRect    :  PSDL_Rect;
begin

  vp := @is_.pictq[is_.pictq_rindex];
  if assigned(vp.bmp) then
  begin
    if(is_.video_st.codec.sample_aspect_ratio.num = 0) then
    begin
      aspect_ratio := 0;
    end else
    begin
      aspect_ratio := av_q2d(is_.video_st.codec.sample_aspect_ratio) *
	    is_.video_st.codec.width / is_.video_st.codec.height;
    end;
    if (aspect_ratio <= 0.0)  then
    begin
      aspect_ratio := is_.video_st.codec.width /is_.video_st.codec.height;
    end;
    h := screen.h;
    w := (round(h * aspect_ratio)) and -3;
    if(w > screen.w) then
    begin
      w := screen.w;
      h := (round(w / aspect_ratio)) and -3;
    end;

    x := (screen.w - w) div 2;
    y := (screen.h - h) div 2;

    SDL_RenderClear(Render);
    SDL_RenderGetViewport(Render, RenderRect) ;

    // Software scale
    scale:=1.0+global_video_state.scale;
    if scale<>1 then
    begin
      texr.w:= round(RenderRect.W * scale);
      texr.h:= round(RenderRect.H * scale);
      texr.x:= (RenderRect.W-texr.w) div 2;
      texr.y:= (RenderRect.H-texr.h) div 2;
      SDL_RenderCopy(Render, vp.bmp, nil, @texr);
    end else
      SDL_RenderCopy(Render, vp.bmp, nil, nil);

    SDL_RenderPresent(Render);
  end;
end;

procedure TForm1.video_refresh_timer(userdata: pointer);
var
  is_             : PVideoState;
  vp              : PVideoPicture;
  actual_delay    : double;
  delay           : double;
  sync_threshold  : double;
  ref_clock       : double;
  diff            : double;
begin

  is_ := PVideoState(userdata);
  // vp is used in later tutorials for synchronization
  //VideoPicture *vp;

  if assigned(is_.video_st) then
  begin
    if (is_.pictq_size = 0) then
    begin
      schedule_refresh(is_, 1)
    end else
    begin
      vp := @is_.pictq[is_.pictq_rindex];

      is_.video_current_pts := vp.pts;
      is_.video_current_pts_time := av_gettime();

      delay := vp.pts - is_.frame_last_pts; (* the pts from last time *)
      if ((delay <= 0) or  (delay >= 1.0)) then
      begin
	      (* if incorrect delay, use previous one *)
        delay := is_.frame_last_delay;
      end;

      (* save for next time *)
      is_.frame_last_delay := delay;
      is_.frame_last_pts := vp.pts;


      (* update delay to sync to audio if not master source *)
      if(is_.av_sync_type <> AV_SYNC_VIDEO_MASTER) then
      begin
        ref_clock := get_master_clock(is_);
        diff := vp.pts - ref_clock;


        (* Skip or repeat the frame. Take delay into account
        FFPlay still doesn't "know if this is the best guess." *)
        if (delay > AV_SYNC_THRESHOLD) then
          sync_threshold := delay
        else
          sync_threshold := AV_SYNC_THRESHOLD;


        if(abs(diff) < AV_NOSYNC_THRESHOLD) then
        begin
          if (diff <= -sync_threshold) then
            delay := 0
          else
          if(diff >= sync_threshold) then
            delay := 2 * delay;
        end;
      end;

      is_.frame_timer := is_.frame_timer + delay;
      (* computer the REAL delay *)
      actual_delay := is_.frame_timer - (av_gettime() / 1000000.0);

      if(actual_delay < 0.010) then
      begin
	      (* Really it should skip the picture instead *)
	      actual_delay := 0.010;
      end;
      schedule_refresh(is_, round(actual_delay * 1000 + 0.5));

      (* show the picture! *)
      video_display(is_);

      (* update queue for next picture! *)
      inc(is_.pictq_rindex);
      if (is_.pictq_rindex = VIDEO_PICTURE_QUEUE_SIZE) then
      begin
	      is_.pictq_rindex := 0;
      end;
      SDL_LockMutex(is_.pictq_mutex);
      try
        dec(is_.pictq_size);
        SDL_CondSignal(is_.pictq_cond);
      finally
        SDL_UnlockMutex(is_.pictq_mutex);
      end;
    end;
  end else
  begin
    schedule_refresh(is_, 100);
  end;
end;

procedure TForm1.alloc_picture(userdata: pointer);
var
  is_         : PVideoState;
  vp          : PVideoPicture;
  numBytes    : integer;
begin
  is_ := PVideoState(userdata);

  vp := @is_.pictq[is_.pictq_windex];
  if assigned(vp.bmp) then
  begin
    // we already have one make another, bigger/smaller
    SDL_DestroyTexture(vp.bmp);
  end;

  if assigned(vp.pFrameYUV420P) then
  begin
    av_free(vp.pFrameYUV420P);
  end;

  if assigned(vp.buffer) then
  begin
    av_free(vp.buffer);
  end;


  // Allocate an AVFrame structure
  vp.pFrameYUV420P:= av_frame_alloc();
  if not assigned(vp.pFrameYUV420P) then
  begin
    showmessage('Could not Allocate AVFrame structure');
    exit;
  end;

  // Determine required buffer size and allocate buffer
  numBytes:=avpicture_get_size(is_.video_st.codec.pix_fmt, is_.video_st.codec.width, is_.video_st.codec.height);
  vp.buffer:=av_malloc(numBytes*sizeof(cardinal));

  // Assign appropriate parts of buffer to image planes in pFrameYUV420P
  // Note that pFrameRGB is an AVFrame, but AVFrame is a superset
  // of AVPicture
  avpicture_fill(PAVPicture(vp.pFrameYUV420P), vp.buffer, AV_PIX_FMT_YUV420P, is_.video_st.codec.width, is_.video_st.codec.height);

  // Allocate a place to put our YUV image on that screen
  vp.bmp:=SDL_CreateTexture(render, SDL_PIXELFORMAT_YV12, Integer(SDL_TEXTUREACCESS_STREAMING), is_.video_st.codec.width, is_.video_st.codec.height);

  vp.width := is_.video_st.codec.width;
  vp.height := is_.video_st.codec.height;

  SDL_LockMutex(is_.pictq_mutex);
  try
    vp.allocated := 1;
    SDL_CondSignal(is_.pictq_cond);
  finally
    SDL_UnlockMutex(is_.pictq_mutex);
  end;
end;

function TForm1.queue_picture(var is_: PVideoState; pFrame: PAVFrame; pts: double): integer;
var
  vp    : PVideoPicture;
  pict  : TAVPicture;
  event : TDataMessage;

begin

  (* wait until we have space for a new pic *)
  SDL_LockMutex(is_.pictq_mutex);
  try
    while ((is_.pictq_size >= VIDEO_PICTURE_QUEUE_SIZE) and	(not is_.quit)) do
    begin
      SDL_CondWait(is_.pictq_cond, is_.pictq_mutex);
    end;
  finally
    SDL_UnlockMutex(is_.pictq_mutex);
  end;

  if (is_.quit) then
  begin
    result:=-1;
    exit;
  end;

  // windex is set to 0 initially
  vp := @is_.pictq[is_.pictq_windex];

  (* allocate or resize the buffer! *)
  if ((not assigned(vp.bmp)) or
     (vp.width <> is_.video_st.codec.width) or
     (vp.height <> is_.video_st.codec.height)) then
  begin


    vp.allocated := 0;


    (* we have to do it in the main thread *)
    event.Msg:=FF_ALLOC_EVENT;
    event.Data:=Pointer(is_);
    self.Dispatch(event);

    (* wait until we have a picture allocated *)
    SDL_LockMutex(is_.pictq_mutex);
    try
      while ((vp.allocated=0) and (not is_.quit)) do
      begin
        SDL_CondWait(is_.pictq_cond, is_.pictq_mutex);
      end;
    finally
      SDL_UnlockMutex(is_.pictq_mutex);
    end;

    if (is_.quit) then
    begin
      result:=-1;
      exit;
    end;
  end;
  (* We have a place to put our picture on the queue *)
  (* If we are skipping a frame, do we set this to null
     but still return vp->allocated = 1? *)

  if assigned(vp.bmp) then
  begin


    pict.data[0] := vp.pFrameYUV420P.data[0];
    pict.data[1] := vp.pFrameYUV420P.data[2];
    pict.data[2] := vp.pFrameYUV420P.data[1];

    pict.linesize[0] := vp.pFrameYUV420P.linesize[0];
    pict.linesize[1] := vp.pFrameYUV420P.linesize[2];
    pict.linesize[2] := vp.pFrameYUV420P.linesize[1];


    // Convert the image into YUV format that SDL uses
    sws_scale
    (
    is_.sws_ctx,
    @pFrame.data,
    @pFrame.linesize,
    0,
    is_.video_st.codec.height,
    @pict.data,
    @pict.linesize
    );


    SDL_UpdateTexture(vp.bmp, nil, vp.buffer, is_.video_st.codec.width);

    vp.pts := pts;

    (* now we inform our display thread that we have a pic ready *)
    inc(is_.pictq_windex);
    if(is_.pictq_windex = VIDEO_PICTURE_QUEUE_SIZE) then
      is_.pictq_windex := 0;

    SDL_LockMutex(is_.pictq_mutex);
    try
      inc(is_.pictq_size);
    finally
      SDL_UnlockMutex(is_.pictq_mutex);
    end;
  end;
  result:=0;
end;

function TForm1.synchronize_video(var is_: PVideoState; var src_frame: PAVFrame; pts_: double): double;
var
  frame_delay : double;
  pts         : double;
begin
  pts:=pts_;

  if (pts <> 0) then
  begin
    (* if we have pts, set video clock to it *)
    is_.video_clock := pts;
  end else begin
    (* if we aren't given a pts, set it to the clock *)
    pts := is_.video_clock;
  end;
  (* update the video clock *)
  frame_delay := av_q2d(is_.video_st.codec.time_base);
  (* if we are repeating a frame, adjust clock accordingly *)
  frame_delay := frame_delay  + (src_frame.repeat_pict * (frame_delay * 0.5));
  is_.video_clock := is_.video_clock + frame_delay;
  result:=pts;
end;



function TForm1.stream_component_open(var is_: PVideoState; stream_index: integer): integer;
var
  pFormatCtx    : PAVFormatContext;
  codecCtx      : PAVCodecContext;
  codec         : PAVCodec;
  optionsDict   : PAVDictionary;
  wanted_spec   : TSDL_AudioSpec;
  spec          : TSDL_AudioSpec;
  pStreams      : PPAVStream;
  pStream       : PAVStream;
  i             : integer;
begin
  result:=-1;
  pStream :=  nil;
  pFormatCtx := is_.pFormatCtx;

  codecCtx := nil;
  codec := nil;
  optionsDict:= nil;


  if((stream_index < 0) or (stream_index >= pFormatCtx.nb_streams)) then
  begin
    result:=-1;
    exit;
  end;


  // Get a pointer to the codec context for the video stream
  pStreams:=pFormatCtx.streams;
  for i:=0 to pFormatCtx.nb_streams-1 do
  begin
    if i=stream_index then
    begin
      pStream:=pStreams^;
      codecCtx:=pStream.codec;
    end;
    inc(pStreams);
  end;


  if(codecCtx^.codec_type = AVMEDIA_TYPE_AUDIO) then
  begin
    // Set audio settings from codec info
    wanted_spec.freq := codecCtx^.sample_rate;
    wanted_spec.format := AUDIO_S16;
    wanted_spec.channels := codecCtx^.channels;
    wanted_spec.silence := 0;
    wanted_spec.samples := SDL_AUDIO_BUFFER_SIZE;
    wanted_spec.callback := @audio_callback;
    wanted_spec.userdata := is_;

    if(SDL_OpenAudio(@wanted_spec, @spec) <> 0) then
    begin
      showmessage(format('SDL_OpenAudio: %s', [SDL_GetError()]));
      exit;
    end;

    is_.audio_hw_buf_size := spec.size;

  end;

  codec := avcodec_find_decoder(codecCtx.codec_id);
  if ((not assigned(codec)) or (avcodec_open2(codecCtx, codec, @optionsDict)<0)) then
  begin
      showmessage('Unsupported codec!');
      exit;
  end;

  case codecCtx.codec_type of
    AVMEDIA_TYPE_AUDIO:
    begin
      is_.audioStream := stream_index;
      is_.audio_st := pStream;
      is_.audio_buf_size := 0;
      is_.audio_buf_index := 0;

      (* averaging filter for audio sync *)
      is_.audio_diff_avg_coef := exp(log10(0.01 / AUDIO_DIFF_AVG_NB));
      is_.audio_diff_avg_count := 0;
      (* Correct audio only if larger error than this *)
      is_.audio_diff_threshold := 2.0 * SDL_AUDIO_BUFFER_SIZE / codecCtx.sample_rate;



      fillchar(is_.audio_pkt, sizeof(is_.audio_pkt), #0);

      packet_queue_init(is_.audioq);
      SDL_PauseAudio(0);

     end;
    AVMEDIA_TYPE_VIDEO:
    begin
      is_.videoStream := stream_index;
      is_.video_st := pStream;

      is_.frame_timer := av_gettime() / 1000000.0;
      is_.frame_last_delay := 40e-3;
      is_.video_current_pts_time := av_gettime();



      packet_queue_init(is_.videoq);
      is_.video_tid := SDL_CreateThread(@video_thread, nil, is_);

      is_.sws_ctx :=
      sws_getContext
      (
          is_.video_st.codec.width,
          is_.video_st.codec.height,
          is_.video_st.codec.pix_fmt,
          is_.video_st.codec.width,
          is_.video_st.codec.height,
          AV_PIX_FMT_YUV420P,
          SWS_BILINEAR,
          nil,
          nil,
          nil
      );
      codecCtx.get_buffer := @our_get_buffer;
      codecCtx.release_buffer := @our_release_buffer;
    end;
  end;
  result:=0;
end;





procedure TForm1.stream_seek(var is_: PVideoState; pos: int64; rel: double);
begin
  if (not is_.seek_req) then
  begin
    is_.seek_pos := pos;
    if rel<0 then
      is_.seek_flags:=AVSEEK_FLAG_BACKWARD
    else
      is_.seek_flags:=0;
    is_.seek_req := true;
  end;
end;

procedure TForm1.doSeek(const incr : double);
var
  pos : double;
begin
  if ((incr<>0) and assigned(global_video_state)) then
  begin
    pos := get_master_clock(global_video_state);
    pos := pos+incr;
    stream_seek(global_video_state, round(pos * AV_TIME_BASE), incr);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var
  event : TDataMessage;
begin
    event.Msg:=FF_QUIT_EVENT;
    event.Data:=nil;
    form1.Dispatch(event);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i : integer;
begin

  // Register all formats and codecs
  av_register_all();

    if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER)<0 then
    begin
      showmessage(format('Could not initialize SDL - %s', [SDL_GetError()]));
    end;

    // List audio driver
    for I := 0 to SDL_GetNumAudioDrivers-1 do
      FAudioDriver:=SDL_GetAudioDriver(i);

    // Set audio driver
    FAudioDriver:=USE_AUDIO_DRIVER;
    SDL_AudioInit(PAnsiChar(FAudioDriver));

    // Make a screen to put our video
    screen:=SDL_CreateWindowFrom(Pointer(panel1.Handle));

    if not assigned(screen) then
    begin
      showmessage('SDL: could CreateWindow');
      exit;
    end;
    render := SDL_CreateRenderer(screen, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
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

  SDL_Quit();
end;

procedure TForm1.OnAllocReceived(var Msg: TDataMessage);
begin
  alloc_picture(MSG.Data);
end;

procedure TForm1.OnQuitReceived(var Msg: TDataMessage);
begin
  if assigned(is_) then
  begin
    is_.quit := true;
    (*
               * If the video has finished playing, then both the picture and
               * audio queues are waiting for more data.  Make them stop
               * waiting and terminate normally.
    *)
    SDL_CondSignal(is_.audioq.cond);
    SDL_CondSignal(is_.videoq.cond);
  end;
end;


procedure TForm1.OnRefreshReceived(var Msg: TDataMessage);
begin
  video_refresh_timer(MSG.Data);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    32: //space
    begin
      global_video_state.pause:= not global_video_state.pause;
    end;
    37: //left
    begin
      doSeek(-1);
    end;
    39: //right
    begin
      doSeek(1);
    end;
    38: //up
    begin
      doScale(0.1);
    end;
    40:  //down
    begin
      doScale(-0.1);
    end;
  end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if assigned(render) then
  begin
    //SDL_RenderSetLogicalSize(render, panel1.Width, panel1.Height);

    SDL_RenderSetViewport(render, nil);
    SDL_RenderClear(Render);
    SDL_RenderPresent(Render);
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  SDL_SetRenderDrawColor(render, 100, 100, 100, 0) ;
  SDL_RenderClear(Render);
  SDL_RenderPresent(Render);
end;

procedure TForm1.doScale(incr : double);
begin
  if ((incr<>0) and assigned(global_video_state)) then
  begin
    global_video_state.scale:=global_video_state.scale+incr;
  end;
end;


procedure TForm1.Open1Click(Sender: TObject);
begin
  Button1.Click;
end;

end.
