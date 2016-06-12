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



var
  VERSION ,
  MAJOR, MINOR , MICRO: longint;
begin
  try

    av_register_all();


    if System.SysUtils.FileExists(format('%s.dll', [LIB_AVFORMAT])) then
    begin
      writeln('');
      writeln(format('Configuration: %s', [string(avformat_configuration)]));
      writeln('');
      writeln(format('License: %s', [string(avformat_license)]));

      VERSION:=avformat_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_AVFORMAT    %s.dll   %s', [LIB_AVFORMAT, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;
    if System.SysUtils.FileExists(format('%s.dll', [LIB_AVUTIL])) then
    begin
      VERSION:=avutil_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_AVUTIL:     %s.dll     %s', [LIB_AVUTIL, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;
    if System.SysUtils.FileExists(format('%s.dll', [LIB_POSTPROC])) then
    begin
      VERSION:=postproc_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_POSTPROC:   %s.dll   %s', [LIB_POSTPROC, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;
    if System.SysUtils.FileExists(format('%s.dll', [LIB_AVCODEC])) then
    begin
      VERSION:=avcodec_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_AVCODEC:    %s.dll    %s', [LIB_AVCODEC, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;
    if System.SysUtils.FileExists(format('%s.dll', [LIB_AVFILTER])) then
    begin
      VERSION:=avfilter_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_AVFILTER:    %s.dll   %s', [LIB_AVFILTER, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;
    if System.SysUtils.FileExists(format('%s.dll', [LIB_AVDEVICE])) then
    begin
      VERSION:=avdevice_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_AVDEVICE:   %s.dll   %s', [LIB_AVDEVICE, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;
    if System.SysUtils.FileExists(format('%s.dll', [LIB_SWSCALE])) then
    begin
      VERSION:=swscale_version();
      MAJOR:= VERSION shr 16;
      MINOR:= VERSION shr 8 and $ff;
      MICRO:= VERSION and $ff;
      writeln(format('LIB_SWSCALE:    %s.dll     %s', [LIB_SWSCALE, AV_VERSION(MAJOR, MINOR, MICRO)]));
    end;

    readln;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
