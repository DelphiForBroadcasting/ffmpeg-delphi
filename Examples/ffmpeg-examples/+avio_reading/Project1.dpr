program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  avutil in '../../../libavutil/avutil.pas',
  avcodec in '../../../libavcodec/avcodec.pas',
  avformat in '../../../libavformat/avformat.pas',
  avfilter in '../../../libavfilter/avfilter.pas',
  swresample in '../../../libswresample/swresample.pas',
  postprocess in '../../../libpostproc/postprocess.pas',
  avdevice in '../../../libavdevice/avdevice.pas',
  swscale in '../../../libswscale/swscale.pas';

{$MINENUMSIZE 4}

type
  PBuffer_data = ^TBuffer_data;
  TBuffer_data = record
    ptr   : Pointer;
    size  : integer; ///< size left in the buffer
  end;

function read_packet(opaque: Pointer; buf: PByte; buf_size: integer): integer;  stdcall;
var
  bd : pBuffer_data;
begin
  bd := opaque;
  buf_size := FFMIN(buf_size, bd^.size);
  writeln(format('ptr:%p size:%d', [bd^.ptr, bd^.size]));

  (* copy internal buffer data to buf *)
  move(PByte(bd^.ptr)^, buf^, buf_size);
  inc(PByte(bd^.ptr), buf_size);
  dec(bd^.size, buf_size);

  result := buf_size;
end;


label
  finish;

var
  fmt_ctx               : PAVFormatContext;
  avio_ctx              : PAVIOContext;
  buffer                : PByte;
  avio_ctx_buffer       : PByte;
  buffer_size           : integer;
  avio_ctx_buffer_size  : integer;
  input_filename        : PAnsiChar;
  ret                   : integer;
  bd                    : TBuffer_data;
begin
  try
    fmt_ctx := nil;
    avio_ctx := nil;
    buffer := nil;
    avio_ctx_buffer := nil;
    buffer_size := 0;
    avio_ctx_buffer_size := 4096;
    input_filename := nil;
    ret := 0;
    fillchar(bd, sizeof(TBuffer_data), #0);

    if (ParamCount <> 1) then
    begin
      writeln(format('Usage: %s [filename]', [ParamStr(0)]));
      writeln('API example program to show how to read from a custom buffer');
      writeln('accessed through AVIOContext.');
      readln;
      exit;
    end;

    input_filename := PAnsiChar(ansistring(ParamStr(1)));

    (* register codecs and formats and other lavf/lavc components *)
    av_register_all();
               (* slurp file content into buffer *)
    ret := av_file_map(input_filename, buffer, buffer_size, 0, nil);
    if (ret < 0) then
        goto finish;

    (* fill opaque structure used by the AVIOContext read callback *)
    bd.ptr  := buffer;
    bd.size := buffer_size;


    fmt_ctx := avformat_alloc_context();
    if not assigned(fmt_ctx) then
    begin
      ret := ENOMEM;
      goto finish;
    end;

    avio_ctx_buffer := av_malloc(avio_ctx_buffer_size);
    if not assigned(avio_ctx_buffer) then
    begin
      ret := ENOMEM;
      goto finish;
    end;
    avio_ctx := avio_alloc_context(PAnsiChar(avio_ctx_buffer), avio_ctx_buffer_size, 0, @bd, @read_packet, nil, nil);
    if not assigned(avio_ctx) then
    begin
      ret := ENOMEM;
      goto finish;
    end;
    fmt_ctx^.pb := avio_ctx;

    ret := avformat_open_input(fmt_ctx, nil, nil, nil);
    if (ret < 0) then
    begin
      writeln('Could not open input');
      goto finish;
    end;

    ret := avformat_find_stream_info(fmt_ctx, nil);
    if (ret < 0)  then
    begin
      writeln('Could not find stream information');
      goto finish;
    end;

    av_dump_format(fmt_ctx, 0, input_filename, 0);

    finish:
    begin
      avformat_close_input(fmt_ctx);
      (* note: the internal buffer could have changed, and be != avio_ctx_buffer *)
      if assigned(avio_ctx) then
      begin
        av_freep(@avio_ctx^.buffer);
        av_freep(@avio_ctx);
      end;
      av_file_unmap(buffer, buffer_size);

      if (ret <> 0) then
      begin
        writeln(Format('Error occurred: %s', [av_err2str(ret)]));
      end;
    end;

    readln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
