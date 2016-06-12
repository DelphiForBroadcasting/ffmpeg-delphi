program av_log;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  avutil in '../../../libavutil/avutil.pas',
  avcodec in '../../../libavcodec/avcodec.pas',
  avformat in '../../../libavformat/avformat.pas',
  swresample in '../../../libswresample/swresample.pas',
  postprocess in '../../../libpostproc/postprocess.pas',
  avdevice in '../../../libavdevice/avdevice.pas',
  swscale in '../../../libswscale/swscale.pas';


function vsnprintf(const format_: PAnsiChar; const arg: va_list): string;
var
  i, va_count, offset : integer;
  ConstArray : array of TVarRec;
  format_str: string;
  temp_extended : extended;
  temp_string   : string;
  format_type : string;
begin
  format_str := string(format_);
  va_count := 0;
  for i := 1 to length(format_str) do
    if format_str[i] = '%' then inc(va_count);

  SetLength(ConstArray, va_count);

  offset:=0;
  for I := 0 to va_count-1 do
  begin
    offset:=pos('%', format_str, offset+1);
    if format_str[offset+1]='.' then
      format_type:=copy(format_str,offset,4)
    else
    if format_str[offset+2]='.' then
      format_type:=copy(format_str,offset,5)
    else
    if ((format_str[offset+1]='I') and (format_str[offset+2]='6')
    and (format_str[offset+3]='4') and (format_str[offset+4]='d'))then
    begin
      format_type:='%d';
      format_str:=StringReplace(format_, '%I64d', '%d', [rfReplaceAll, rfIgnoreCase])
    end else
      format_type:=copy(format_str,offset,2);
    (* STRING *)
    if (((format_type[1]='%') and (format_type[2]='s'))
    or ((format_type[1]='%') and (format_type[4]='s'))
    or ((format_type[1]='%') and (format_type[5]='s')))then
    begin
      //str:=StuffString(str, offset, 2, PAnsiChar(vl[i]));
      ConstArray[I].VType := vtPChar;
      New(ConstArray[i].VPChar);
      if not assigned(arg[i]) then
      begin
        ConstArray[I].VPChar:= '';
        continue;
      end;
      ConstArray[I].VPChar := PAnsiChar(arg[i]);
      //ConstArray[i].VPChar^ := ;
    end;

    (*  d   = Decimal (integer)
        u 	= Unsigned decimal
        x 	= Hexadecimal}
    *)

    if (((format_type[1]='%') and (format_type[2]='d'))
    or ((format_type[1]='%') and (format_type[4]='d'))
    or ((format_type[1]='%') and (format_type[5]='d')))then
    begin
      //str:=StuffString(str, offset, 2, inttostr(Integer(vl[i])));
      ConstArray[I].VType := vtInteger;
      if not assigned(arg[i]) then
      begin
        ConstArray[I].VInteger:= 0;
        continue;
      end;
      try
        //ConstArray[I].VInteger:= StrToInt(PansiChar(vl[i]));
        ConstArray[I].VInteger:= Integer(arg[i]);
      except
        ConstArray[I].VInteger:= 0;
      end;
    end;

    (*  e 	 = Scientific
        f 	 = Fixed
        g 	 = General
        m 	 = Money
        n 	 = Number (floating)
    *)
    if (((format_type[1]='%') and (format_type[2]='f'))
    or ((format_type[1]='%') and (format_type[4]='f'))
    or ((format_type[1]='%') and (format_type[5]='f')))then
    begin
      //str:=StuffString(str, offset, 2, floattostr(extended(vl[i])));
      ConstArray[I].VType := vtExtended;
      new(ConstArray[I].vExtended);
      if not assigned(arg[i]) then
      begin
        ConstArray[I].vExtended:= 0;
        continue;
      end;
      temp_extended:=extended(arg[i]);
      try
        ConstArray[I].vExtended:= @temp_extended;
      except
        ConstArray[I].vExtended:= 0;
      end;
    end;

    (*  p 	 = Pointer
    *)
    if (((format_type[1]='%') and (format_type[2]='p'))
    or ((format_type[1]='%') and (format_type[4]='p'))
    or ((format_type[1]='%') and (format_type[5]='p')))then
    begin
      //str:=StuffString(str, offset, 2, inttostr(Integer(vl[i])));
      ConstArray[I].VType := vtPointer;
      if not assigned(arg[i]) then
      begin
        ConstArray[I].VPointer:= nil;
        continue;
      end;
      try
        //ConstArray[I].VInteger:= StrToInt(PansiChar(vl[i]));
        ConstArray[I].VPointer:= addr(arg[i]);
      except
        ConstArray[I].VPointer:= nil;
      end;
    end;

  end;

  try
    result:=format(format_str, ConstArray);
  except
    result:=format_;
  end;

end;



Procedure av_log_callback(ptr: pointer; level: integer; const fmt: PAnsiChar; const Args: array of const); stdcall;
begin
  writeln('AV_LOG: '+format(fmt, Args));
 // writeln('AV_LOG: '+vsnprintf(fmt, vl));
end;

label
  read;

var
  av_log_level_str  : string;
  av_log_level_int  : integer;
  vl: va_list;
  msg : ansistring;
begin
  try
    if (ParamCount <> 1) then
    begin
      writeln(format('usage: %s LOG_LEVL'+#10#13+
              ' **                                                                '+#10#13+
              ' * AV_LOG_QUIET                                                    '+#10#13+
              ' **                                                                '+#10#13+
              ' * Something went really wrong and we will crash now.              '+#10#13+
              ' * AV_LOG_PANIC                                                    '+#10#13+
              ' **                                                                '+#10#13+
              ' * Something went wrong and recovery is not possible.              '+#10#13+
              ' * For example, no header was found for a format which depends     '+#10#13+
              ' * on headers or an illegal combination of parameters is used.     '+#10#13+
              ' * AV_LOG_FATAL                                                    '+#10#13+
              ' **                                                                '+#10#13+
              ' * Something went wrong and cannot losslessly be recovered.        '+#10#13+
              ' * However, not all future data is affected.                       '+#10#13+
              ' * AV_LOG_ERROR                                                    '+#10#13+
              ' **                                                                '+#10#13+
              ' * Something somehow does not look correct. This may or may not    '+#10#13+
              ' * lead to problems. An example would be the use of "-vstrict -2". '+#10#13+
              ' * AV_LOG_WARNING                                                  '+#10#13+
              ' * AV_LOG_INFO                                                     '+#10#13+
              ' * AV_LOG_VERBOSE                                                  '+#10#13+
              ' **                                                                '+#10#13+
              ' * Stuff which is only useful for libav* developers.               '+#10#13+
              ' * AV_LOG_DEBUG;                                                   '+#10#13, [extractfilename(ParamStr(0))]));
      readln;
      exit;
    end;

    av_log_level_str:=PansiChar(AnsiString(ParamStr(1)));

    av_register_all();

    av_log_set_callback(@av_log_callback);

    if sametext(av_log_level_str, 'AV_LOG_DEBUG') then
      av_log_set_level(AV_LOG_DEBUG) else
    if sametext(av_log_level_str, 'AV_LOG_VERBOSE') then
      av_log_set_level(AV_LOG_VERBOSE) else
    if sametext(av_log_level_str, 'AV_LOG_INFO') then
      av_log_set_level(AV_LOG_INFO) else
    if sametext(av_log_level_str, 'AV_LOG_WARNING') then
      av_log_set_level(AV_LOG_WARNING) else
    if sametext(av_log_level_str, 'AV_LOG_ERROR') then
      av_log_set_level(AV_LOG_ERROR) else
    if sametext(av_log_level_str, 'AV_LOG_FATAL') then
      av_log_set_level(AV_LOG_FATAL) else
    if sametext(av_log_level_str, 'AV_LOG_PANIC') then
      av_log_set_level(AV_LOG_PANIC) else
    if sametext(av_log_level_str, 'AV_LOG_QUIET') then
      av_log_set_level(AV_LOG_QUIET);


    case av_log_get_level of
      AV_LOG_QUIET: writeln('SET LEVEL: AV_LOG_QUIET');
      AV_LOG_PANIC: writeln('SET LEVEL: AV_LOG_PANIC');
      AV_LOG_FATAL: writeln('SET LEVEL: AV_LOG_FATAL');
      AV_LOG_ERROR: writeln('SET LEVEL: AV_LOG_ERROR');
      AV_LOG_WARNING: writeln('SET LEVEL: AV_LOG_WARNING');
      AV_LOG_INFO: writeln('SET LEVEL: AV_LOG_INFO');
      AV_LOG_VERBOSE: writeln('SET LEVEL: AV_LOG_VERBOSE');
      AV_LOG_DEBUG: writeln('SET LEVEL: AV_LOG_DEBUG');
    end;


    read:
      begin
        readln(msg);
        av_vlog(nil, AV_LOG_ERROR, PAnsiChar(msg), []);
        goto read;
      end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
