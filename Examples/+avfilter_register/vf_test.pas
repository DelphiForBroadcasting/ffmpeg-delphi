unit vf_test;

interface

uses
  System.SysUtils,
  avutil,
  avcodec,
  avfilter;

{$MINENUMSIZE 4}

type
  PTestFilterContext = ^TTestFilterContext;
  TTestFilterContext = record
    class_  : PAVClass;
    opt1    : PAnsiChar;
    opt2    : PAnsiChar;
  end;

function vf_test_register: integer;
function config_props_input(link: PAVFilterLink): Integer; cdecl;
function filter_frame_input(inlink: PAVFilterLink; in_ : PAVFrame): Integer; cdecl;

var
  FTestInputs         : array of TAVFilterPad;
  FTestOutputs        : array of TAVFilterPad;
  FTestFilter         : TAVFilter;
  FTestFilterClass    : TAVClass;
  LTestFilterOptions  : array of TAVOption;

implementation



function filter_frame_input(inlink: PAVFilterLink; in_ : PAVFrame): Integer; cdecl;
var
  LTestFilterContext : PTestFilterContext;
begin
  LTestFilterContext := PTestFilterContext(inlink^.dst^.priv);
  result := 0;
end;

function config_props_input(link: PAVFilterLink): Integer; cdecl;
var
  LTestFilterContext : PTestFilterContext;
begin
  LTestFilterContext := PTestFilterContext(link^.dst^.priv);
  writeln('config_props_input');
  result := 0;
end;



function vf_test_register: integer;
var
  LTestFilterContext : TTestFilterContext;
begin

  setLength(LTestFilterOptions, 2);
  fillchar(LTestFilterOptions[0], sizeof(TAVOption), #0);
  LTestFilterOptions[0].name       := PAnsiChar('opt1');
  LTestFilterOptions[0].help       := PAnsiChar('Options1 description');
  LTestFilterOptions[0].offset     := Integer(@LTestFilterContext.opt1) - Integer(@LTestFilterContext);
  LTestFilterOptions[0].type_      := AV_OPT_TYPE_STRING;
  LTestFilterOptions[0].default_val.str := PAnsiChar('test');
  LTestFilterOptions[0].min        := 0;
  LTestFilterOptions[0].max        := 0;
  LTestFilterOptions[0].flags      := AV_OPT_FLAG_FILTERING_PARAM;

  fillchar(LTestFilterOptions[1], sizeof(TAVOption), #0);
  LTestFilterOptions[1].name       := PAnsiChar('opt2');
  LTestFilterOptions[1].help       := PAnsiChar('Options2 description');
  LTestFilterOptions[1].offset     := Integer(@LTestFilterContext.opt2) - Integer(@LTestFilterContext);
  LTestFilterOptions[1].type_      := AV_OPT_TYPE_STRING;
  LTestFilterOptions[1].default_val.str := PAnsiChar('test');
  LTestFilterOptions[1].min        := 0;
  LTestFilterOptions[1].max        := 0;
  LTestFilterOptions[1].flags      := AV_OPT_FLAG_FILTERING_PARAM;


  fillchar(FTestFilterClass, sizeof(TAVClass), #0);
  FTestFilterClass.class_name := PAnsiChar('TestFilterClass');
  FTestFilterClass.item_name  := av_default_item_name;
  FTestFilterClass.option     := @LTestFilterOptions[0];
  FTestFilterClass.version    := LIBAVUTIL_VERSION_INT;

  setLength(FTestInputs, 1);
  fillchar(FTestInputs[0], sizeof(TAVFilterPad), #0);
  FTestInputs[0].name          := PAnsiChar('default');
  FTestInputs[0].type_         := AVMEDIA_TYPE_VIDEO;
  FTestInputs[0].filter_frame  := filter_frame_input;
  FTestInputs[0].config_props  := config_props_input;

  setLength(FTestOutputs, 1);
  fillchar(FTestOutputs[0], sizeof(TAVFilterPad), #0);
  FTestOutputs[0].name         := PAnsiChar('default');
  FTestOutputs[0].type_        := AVMEDIA_TYPE_VIDEO;

  fillchar(FTestFilter, sizeof(TAVFilter), #0);
  FTestFilter.name        := PAnsiChar('fh-test');
  FTestFilter.description := PAnsiChar('Test filter descrition');
  FTestFilter.priv_size   := sizeof(TTestFilterContext);
  FTestFilter.priv_class  := @FTestFilterClass;
  FTestFilter.inputs      := @FTestInputs[0];
  FTestFilter.outputs     := @FTestOutputs[0];

  result := avfilter_register(@FTestFilter);
end;

end.
