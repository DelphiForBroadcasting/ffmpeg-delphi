unit FH.FFMPEG.PROBE;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.JSON,
  System.IOUtils,
  avutil,
  avcodec,
  avformat,
  avfilter,
  swresample,
  postprocess,
  avdevice,
  swscale;

type
  TMediaInfoError = reference to procedure(const Sender: TObject; AMessage: string);
  TMediaInfoProbe = reference to procedure(const Sender: TObject; const JSONObject : TJSONObject);

type
  IMediaInfo = interface
    function SetMedia(const FileName: string): IMediaInfo;
    function Error(const AValue: TMediaInfoError): IMediaInfo;
    procedure Probe(const AValue: TMediaInfoProbe);
    function SetAsync(const AValue: boolean): IMediaInfo;
    procedure Abort;
  end;

  TMediaInfo = class(TInterfacedObject, IMediaInfo)
  private
    FAsync                  : boolean;
    FAbort                  : boolean;
    FAsyncThread            : TThread;

    FFormatContext          : PAVFormatContext;

    FFileName               : string;
    FOnError                : TMediaInfoError;

    procedure DoError(AMessage: string);
    procedure DoProbe(const AValue: TMediaInfoProbe);

    procedure AsyncThreadOnTerminate(Sender: TObject);
  protected
    function SetMedia(const FileName: string): IMediaInfo;
    procedure Probe(const AValue: TMediaInfoProbe);
    function Error(const AValue: TMediaInfoError): IMediaInfo;
    function SetAsync(const AValue: boolean): IMediaInfo;
    procedure Abort;
  public
    constructor Create(); overload;
    destructor Destroy; override;
    class function Create(const FileName: string): IMediaInfo; overload; static;

    property FormatContext : PAVFormatContext read FFormatContext;

    class function DumpMetadata(AMetadata: PAVDictionary): TJSONArray; static;
    class function DumpStream(fmt_ctx: PAVFormatContext; stream_id: integer): TJSONObject; static;
    class function DumpFormat(fmt_ctx: PAVFormatContext): TJSONObject; static;
  end;


function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;

implementation

function PPtrIdx(P: PPAVStream; I: Integer): PAVStream;
begin
  Inc(P, I);
  Result := P^;
end;

class function TMediaInfo.DumpMetadata(AMetadata: PAVDictionary): TJSONArray;
var
  LDictionaryEntry  : PAVDictionaryEntry;
  LJSONArray        : TJSONArray;
begin
  LJSONArray := TJSONArray.Create;
  try
    LDictionaryEntry := nil;
    if not assigned(AMetadata) then
      exit;
    repeat
      LDictionaryEntry := av_dict_get(AMetadata, '', LDictionaryEntry, AV_DICT_IGNORE_SUFFIX);
      if assigned(LDictionaryEntry) then
          LJSONArray.AddElement(TJSONObject.Create(TJSONPair.Create(LDictionaryEntry^.key, TJSONString.Create(LDictionaryEntry^.value))));
    until not assigned(LDictionaryEntry);

  finally
    result := LJSONArray.Clone as TJSONArray;
    FreeAndNil(LJSONArray);
  end;
end;

class function TMediaInfo.DumpStream(fmt_ctx: PAVFormatContext; stream_id: integer): TJSONObject;
var
  LJSONObject           : TJSONObject;
  LJSONObjectEx1        : TJSONObject;
  LJSONObjectEx2        : TJSONObject;
  st                    : PAVStream;
  buf                   : array[0..255] of ansichar;
  display_aspect_ratio  : TAVRational;
  fps                   : integer;
  tbr                   : integer;
  tbn                   : integer;
  tbc                   : integer;
  ration                : double;
  v                     : int64;
  bits_per_sample       : integer;
  bit_rate              : integer;
begin
  st := nil;
  fps := 0;
  tbr := 0;
  tbn := 0;
  tbc := 0;

  LJSONObject:= TJSONObject.Create;
  try
      //
    LJSONObject.AddPair(TJSONPair.Create('stream_index', TJSONNumber.Create(stream_id)));

    if (not assigned(fmt_ctx)) or (stream_id >= fmt_ctx^.nb_streams)  then
      exit;

    st := PPtrIdx(fmt_ctx^.streams, stream_id);

    //
    if (fmt_ctx^.iformat^.flags and AVFMT_SHOW_IDS) > 0 then
      LJSONObject.AddPair(TJSONPair.Create('stream_id', TJSONNumber.Create(st^.id)));


    if assigned(st^.codec) then
    begin

      //
      LJSONObjectEx1 := nil;
      LJSONObjectEx1 := TJSONObject.Create;
      try
        avcodec_string(@buf[0], length(buf), st^.codec, 0);
        LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(string(ansistring(PAnsiChar(@buf[0]))))));
        LJSONObjectEx1.AddPair(TJSONPair.Create('name', TJSONString.Create(string(ansistring(avcodec_get_name(st^.codec.codec_id))))));
        LJSONObjectEx2 := nil;
        LJSONObjectEx2 := TJSONObject.Create;
        try
          LJSONObjectEx2.AddPair(TJSONPair.Create('value', TJSONNumber.Create(st^.codec.codec_tag)));
          av_get_codec_tag_string(@buf[0], length(buf), st^.codec.codec_tag);
          LJSONObjectEx2.AddPair(TJSONPair.Create('string', TJSONString.Create(string(ansistring(PAnsiChar(@buf[0]))))));
        finally
          LJSONObjectEx1.AddPair('tag', LJSONObjectEx2);
        end;
      finally
        LJSONObject.AddPair('codec', LJSONObjectEx1);
      end;

      //
      LJSONObjectEx1 := nil;
      LJSONObjectEx1 := TJSONObject.Create;
      try
        LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d:%d', [st^.time_base.num, st^.time_base.den]))));
        LJSONObjectEx1.AddPair(TJSONPair.Create('num', TJSONNumber.Create(st^.time_base.num)));
        LJSONObjectEx1.AddPair(TJSONPair.Create('den', TJSONNumber.Create(st^.time_base.DEN)));
      finally
        LJSONObject.AddPair('time_base', LJSONObjectEx1);
      end;

      case st^.codec^.codec_type of
        AVMEDIA_TYPE_VIDEO:
          begin
            //
            LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('video')));

            //
            LJSONObjectEx1 := nil;
            LJSONObjectEx1 := TJSONObject.Create;
            try
              LJSONObjectEx1.AddPair(TJSONPair.Create('value',  TJSONNumber.Create(st^.codec.bit_rate)));
              LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d kb/s', [st^.codec.bit_rate div 1000]))));
            finally
              LJSONObject.AddPair('bitrate', LJSONObjectEx1);
            end;

            //
            LJSONObject.AddPair(TJSONPair.Create('pix_fmt', TJSONString.Create(string(ansistring(av_get_pix_fmt_name(st^.codec.pix_fmt))))));

            if st^.codec.color_range <> AVCOL_RANGE_UNSPECIFIED then
            LJSONObject.AddPair(TJSONPair.Create('color_range', TJSONString.Create(string(ansistring(av_color_range_name(st^.codec.color_range))))));

            if st^.codec.chroma_sample_location <> AVCHROMA_LOC_UNSPECIFIED then
            LJSONObject.AddPair(TJSONPair.Create('chroma_sample_location', TJSONString.Create(string(ansistring(av_chroma_location_name(st^.codec.chroma_sample_location))))));

            if st^.codec.width > 0 then
            begin
              LJSONObject.AddPair(TJSONPair.Create('width', TJSONNumber.Create(st^.codec.width)));
              LJSONObject.AddPair(TJSONPair.Create('height', TJSONNumber.Create(st^.codec.height)));

              if ((st^.codec.width <> st^.codec.coded_width) or (st^.codec.height <> st^.codec.coded_height)) then
              begin
                LJSONObject.AddPair(TJSONPair.Create('coded_width', TJSONNumber.Create(st^.codec.coded_width)));
                LJSONObject.AddPair(TJSONPair.Create('coded_height', TJSONNumber.Create(st^.codec.coded_height)));
              end;
            end;

           // display_aspect_ratio, sample_aspect_ratio
            if st^.codec^.sample_aspect_ratio.num > 0 then
            begin
              av_reduce(@display_aspect_ratio.num, @display_aspect_ratio.den, st^.codec^.width  * st^.codec.sample_aspect_ratio.num, st^.codec^.height * st^.codec.sample_aspect_ratio.den, 1024 * 1024);

              LJSONObjectEx1 := nil;
              LJSONObjectEx1 := TJSONObject.Create;
              try
                LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d:%d', [display_aspect_ratio.num, display_aspect_ratio.den]))));
                LJSONObjectEx1.AddPair(TJSONPair.Create('num', TJSONNumber.Create(display_aspect_ratio.num)));
                LJSONObjectEx1.AddPair(TJSONPair.Create('den', TJSONNumber.Create(display_aspect_ratio.den)));
              finally
                LJSONObject.AddPair('display_aspect_ratio', LJSONObjectEx1);
              end;

              LJSONObjectEx1 := nil;
              LJSONObjectEx1 := TJSONObject.Create;
              try
                LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d:%d', [st^.codec^.sample_aspect_ratio.num, st^.codec^.sample_aspect_ratio.den]))));
                LJSONObjectEx1.AddPair(TJSONPair.Create('num', TJSONNumber.Create(st^.codec^.sample_aspect_ratio.num)));
                LJSONObjectEx1.AddPair(TJSONPair.Create('den', TJSONNumber.Create(st^.codec^.sample_aspect_ratio.den)));
              finally
                LJSONObject.AddPair('sample_aspect_ratio', LJSONObjectEx1);
              end;
            end;

            fps := st^.avg_frame_rate.den and st^.avg_frame_rate.num;
            if (fps > 0) then
            begin
              LJSONObjectEx1 := nil;
              LJSONObjectEx1 := TJSONObject.Create;
              try
                ration := av_q2d(st^.avg_frame_rate);
                LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(ration)));
                v := round(ration * 100);
                if v > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.4f', [ration]))))
                else if (v mod 100) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%3.2f', [ration]))))
                else if (v mod (100 * 1000)) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0f', [ration]))))
                else
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0fk', [ration / 1000]))));
              finally
                LJSONObject.AddPair('fps', LJSONObjectEx1);
              end;
            end;

            tbr := st^.r_frame_rate.den and st^.r_frame_rate.num;
            if (tbr > 0) then
            begin
              LJSONObjectEx1 := nil;
              LJSONObjectEx1 := TJSONObject.Create;
              try
                ration := av_q2d(st^.r_frame_rate);
                LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(ration)));
                v := round(ration * 100);
                if v > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.4f', [ration]))))
                else if (v mod 100) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%3.2f', [ration]))))
                else if (v mod (100 * 1000)) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0f', [ration]))))
                else
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0fk', [ration / 1000]))));
              finally
                LJSONObject.AddPair('tbr', LJSONObjectEx1);
              end;
            end;

            tbn := st^.time_base.den and st^.time_base.num;
            if (tbn > 0)then
            begin
              LJSONObjectEx1 := nil;
              LJSONObjectEx1 := TJSONObject.Create;
              try
                ration := 1 / av_q2d(st^.time_base);
                LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(ration)));
                v := round(ration * 100);
                if v > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.4f', [ration]))))
                else if (v mod 100) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%3.2f', [ration]))))
                else if (v mod (100 * 1000)) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0f', [ration]))))
                else
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0fk', [ration / 1000]))));
              finally
                LJSONObject.AddPair('tbn', LJSONObjectEx1);
              end;
            end;

            tbc := st^.codec^.time_base.den and st^.codec^.time_base.num;
            if (tbc > 0) then
            begin
              LJSONObjectEx1 := nil;
              LJSONObjectEx1 := TJSONObject.Create;
              try
                ration := 1 / av_q2d(st^.codec^.time_base);
                LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(ration)));
                v := round(ration * 100);
                if v > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.4f', [ration]))))
                else if (v mod 100) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%3.2f', [ration]))))
                else if (v mod (100 * 1000)) > 0 then
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0f', [ration]))))
                else
                  LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%1.0fk', [ration / 1000]))));
              finally
                LJSONObject.AddPair('tbc', LJSONObjectEx1);
              end;
            end;
          end;

        AVMEDIA_TYPE_AUDIO:
          begin
            //
            LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('audio')));

            //
            bits_per_sample := av_get_bits_per_sample(st^.codec^.codec_id);
            if bits_per_sample > 0 then
              bit_rate := st^.codec^.sample_rate * st^.codec^.channels * bits_per_sample
            else bit_rate := st^.codec^.bit_rate;
            LJSONObjectEx1 := nil;
            LJSONObjectEx1 := TJSONObject.Create;
            try
              LJSONObjectEx1.AddPair(TJSONPair.Create('value',  TJSONNumber.Create(bit_rate)));
              LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d kb/s', [bit_rate div 1000]))));
            finally
              LJSONObject.AddPair('bitrate', LJSONObjectEx1);
            end;

            // channels
            LJSONObjectEx1 := nil;
            LJSONObjectEx1 := TJSONObject.Create;
            try
              LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(st^.codec^.channels)));
              LJSONObjectEx1.AddPair(TJSONPair.Create('layout', TJSONNumber.Create(st^.codec^.channel_layout)));
              av_get_channel_layout_string(@buf[0], length(buf), st^.codec^.channels, st^.codec^.channel_layout);
              LJSONObjectEx1.AddPair(TJSONPair.Create('layout_name', TJSONString.Create(string(ansistring(PAnsiChar(@buf[0]))))));
            finally
              LJSONObject.AddPair('channels', LJSONObjectEx1);
            end;
            //
            LJSONObject.AddPair(TJSONPair.Create('sample_rate', TJSONNumber.Create(st^.codec.sample_rate)));

            //
            LJSONObject.AddPair(TJSONPair.Create('sample_fmt', TJSONString.Create(string(ansistring(av_get_sample_fmt_name(st^.codec.sample_fmt))))));

            //
            if ((st^.codec.bits_per_raw_sample > 0) and (st^.codec.bits_per_raw_sample <> av_get_bytes_per_sample(st^.codec^.sample_fmt) * 8)) then
              LJSONObject.AddPair(TJSONPair.Create('bits_per_sample', TJSONNumber.Create(st^.codec^.bits_per_raw_sample)))
            else
            if bits_per_sample > 0 then
              LJSONObject.AddPair(TJSONPair.Create('bits_per_sample', TJSONNumber.Create(bits_per_sample)))

          end;
        AVMEDIA_TYPE_UNKNOWN: LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('unknown')));
        AVMEDIA_TYPE_DATA: LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('data')));
        AVMEDIA_TYPE_SUBTITLE: LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('subtitle')));
        AVMEDIA_TYPE_ATTACHMENT: LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('attachment')));
        AVMEDIA_TYPE_NB: LJSONObject.AddPair(TJSONPair.Create('type', TJSONString.Create('nb')));
      end;
    end;

  finally
    result := LJSONObject.Clone as TJSONObject;
    FreeAndNil(LJSONObject);
  end;
end;

class function TMediaInfo.DumpFormat(fmt_ctx: PAVFormatContext): TJSONObject;
var
  hours, min, sec, ms : integer;
  heigh, width        : Integer;
  i                   : integer;
  LJSONObject         : TJSONObject;
  LJSONArrray         : TJSONArray;
  LJSONObjectEx1      : TJSONObject;
  LJSONNumber         : TJSONNumber;
begin
  LJSONObject := TJSONObject.Create;
  try
    if not assigned(fmt_ctx) or not assigned(fmt_ctx^.iformat) then exit;

    //
    LJSONObjectEx1 := nil;
    LJSONObjectEx1 := TJSONObject.Create;
    try
      LJSONObjectEx1.AddPair(TJSONPair.Create('name', TJSONString.Create(string(ansistring(fmt_ctx^.iformat^.name)))));
      LJSONObjectEx1.AddPair(TJSONPair.Create('long_name', TJSONString.Create(string(ansistring(fmt_ctx^.iformat^.long_name)))));
    finally
      LJSONObject.AddPair('format', LJSONObjectEx1);
    end;

    //
    LJSONObject.AddPair(TJSONPair.Create('metadata', DumpMetadata(fmt_ctx^.metadata)));

    //
    if (fmt_ctx^.duration <> AV_NOPTS_VALUE) then
    begin
      ms      := (fmt_ctx^.duration mod AV_TIME_BASE) * 100 div AV_TIME_BASE;
      sec     := round(fmt_ctx^.duration / AV_TIME_BASE) mod 60;
      min     := (sec div 60) mod 60;
      hours   := sec  div 3600;
      LJSONObjectEx1 := nil;
      LJSONObjectEx1 := TJSONObject.Create;
      try
        LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(fmt_ctx^.duration)));
        LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%02.2d:%02.2d:%02.2d:%02.2d',[hours, min, sec, ms]))));
      finally
        LJSONObject.AddPair('duration', LJSONObjectEx1);
      end;
    end;

    //
    if (fmt_ctx^.start_time <> AV_NOPTS_VALUE) then
    begin
      sec := fmt_ctx^.start_time div AV_TIME_BASE;
      ms   := abs(fmt_ctx^.start_time mod AV_TIME_BASE);
      LJSONObjectEx1 := nil;
      LJSONObjectEx1 := TJSONObject.Create;
      try
        LJSONObjectEx1.AddPair(TJSONPair.Create('value', TJSONNumber.Create(fmt_ctx^.start_time)));
        LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d.%06.6d', [sec, av_rescale(ms, 1000000, AV_TIME_BASE)]))));
      finally
        LJSONObject.AddPair('start_time', LJSONObjectEx1);
      end;
    end;

    //
    if fmt_ctx^.bit_rate > 0 then
    begin
      LJSONObjectEx1 := nil;
      LJSONObjectEx1 := TJSONObject.Create;
      try
        LJSONObjectEx1.AddPair(TJSONPair.Create('value',  TJSONNumber.Create(fmt_ctx^.bit_rate)));
        LJSONObjectEx1.AddPair(TJSONPair.Create('string', TJSONString.Create(Format('%d kb/s', [fmt_ctx^.bit_rate div 1000]))));
      finally
        LJSONObject.AddPair('bitrate', LJSONObjectEx1);
      end;
    end;

    //
    LJSONArrray := TJSONArray.Create;
    try
      for i := 0 to fmt_ctx^.nb_streams -1  do
      begin
        LJSONObjectEx1 := nil;
        LJSONObjectEx1 := DumpStream(fmt_ctx, i);
        LJSONArrray.AddElement(LJSONObjectEx1);

        // standart
        if LJSONObjectEx1.TryGetValue<TJSONNumber>('height', LJSONNumber) then
        begin
          heigh := LJSONNumber.AsInt64;
          if LJSONObjectEx1.TryGetValue<TJSONNumber>('width', LJSONNumber) then
          begin
            width := LJSONNumber.AsInt64;

            if ((width > 7680) and (heigh > 4320) and (width <= 11520) and (heigh <= 6480))  then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('12K')));
            end else
            if ((width > 3840) and (heigh > 2160)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('8K')));
            end else
            if ((width > 2560) and (heigh > 1600)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('4K')));
            end else
            if ((width > 1920) and (heigh > 1200)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('2K')));
            end else
            if ((width > 1920) and (heigh > 1080)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('WUXGA')));
            end else
            if ((width > 1280) and (heigh > 720)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('HD')));
            end else
            if ((width > 720) and (heigh > 576)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('HD')));
            end else
            if ((width >= 720) and (heigh >=480)) then
            begin
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('SD')));
            end else
              LJSONObject.AddPair(TJSONPair.Create('standard', TJSONString.Create('Unknown')));
          end;
        end;

      end;
    finally
      LJSONObject.AddPair(TJSONPair.Create('streams', LJSONArrray));
    end;

  finally
    result := LJSONObject.Clone as TJSONObject;
    FreeAndNil(LJSONObject);
  end;
end;


(* ------------------------------------------------------------------------- *)
constructor TMediaInfo.Create();
begin
  inherited Create;
  FASync := True;

  av_register_all();
  //av_log_set_level(AV_LOG_DEBUG);

  FFormatContext := nil;
  FFormatContext := avformat_alloc_context();
  if not assigned(FFormatContext) then
  begin
    DoError('Error alloc format context!')
  end;
end;

destructor TMediaInfo.Destroy;
begin
  if assigned(FFormatContext.iformat) then
    avformat_close_input(FFormatContext);

  if assigned(FFormatContext) then
    avformat_free_context(FFormatContext);

  inherited Destroy;
end;

class function TMediaInfo.Create(const FileName: string): IMediaInfo;
begin
  result := TMediaInfo.Create();
  result.SetMedia(FileName);
end;
procedure TMediaInfo.AsyncThreadOnTerminate(Sender: TObject);
begin
  self._Release;
end;

procedure TMediaInfo.Abort;
begin
  FAbort := true;
end;

procedure TMediaInfo.DoError(AMessage: string);
begin
  if Assigned(Self.FOnError) then
    Self.FOnError(Self, AMessage);
end;

function TMediaInfo.SetMedia(const FileName: string): IMediaInfo;
begin
  FFileName := FileName;
  result := self;
end;

function TMediaInfo.Error(const AValue: TMediaInfoError): IMediaInfo;
begin
  Self.FOnError := AValue;
  result := Self;
end;

function TMediaInfo.SetAsync(const AValue: boolean): IMediaInfo;
begin
  Self.FAsync := AValue;
  result := Self;
end;

procedure TMediaInfo.Probe(const AValue: TMediaInfoProbe);
begin
  try
    if FASync then
    begin
      self._AddRef;

      FAsyncThread := TThread.CreateAnonymousThread(
        procedure()
        begin
          DoProbe(AValue);
        end
      );
      FAsyncThread.OnTerminate := AsyncThreadOnTerminate;
      FAsyncThread.FreeOnTerminate := true;
      FAsyncThread.Start;
    end else
    begin
     Self.DoProbe(AValue);
    end;

  except
    on E:Exception do
      DoError(E.Message);
  end;
end;

procedure TMediaInfo.DoProbe(const AValue: TMediaInfoProbe);
var
  LRet        : integer;
  LJSONObject : TJSONObject;
begin
  if not System.IOUtils.TFile.Exists(FFileName) then
      raise Exception.CreateFmt('File not exists, %s', [FFileName]);

  if (avformat_open_input(FFormatContext, PAnsiChar(ansistring(FFileName)), nil,  nil) < 0) then
    raise Exception.CreateFmt('Could not open file, %s', [FFileName]);

  if (avformat_find_stream_info(FFormatContext, nil) < 0)  then
    raise Exception.Create('Could not find stream information!');

  LJSONObject := TMediaInfo.DumpFormat(FFormatContext);
  try
    LJSONObject.AddPair(TJSONPair.Create('filename', TJSONString.Create(System.IOUtils.TPath.GetFileName(FFileName))));
    LJSONObject.AddPair(TJSONPair.Create('fullpath', TJSONString.Create(System.IOUtils.TPath.GetFullPath(FFileName))));
    if assigned(AValue) then
      AValue(Self, LJSONObject)
  finally
    FreeAndNil(LJSONObject);
  end;
end;


end.


