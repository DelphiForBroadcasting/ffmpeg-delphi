(*
 * Copyright (C) 2001-2003 Michael Niedermayer (michaelni@gmx.at)
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 *)

(**
 * Conversion to Pascal Copyright 2014 (c) Oleksandr Nazaruk <mail@freehand.com.ua>
 *
 *)


unit postprocess;


{$MINENUMSIZE 4}

{$IFDEF DARWIN}
  {$linklib postprocess}
{$ENDIF}

interface


uses
  avutil;

{$INCLUDE version.pas}


(**
 * Return the LIBPOSTPROC_VERSION_INT constant.
 *)
function postproc_version(): cardinal;
  cdecl; external LIB_POSTPROC;

(**
 * Return the libpostproc build-time configuration.
 *)
function postproc_configuration(): PAnsiChar;
  cdecl; external LIB_POSTPROC;


(**
 * Return the libpostproc license.
 *)
function postproc_license(): PAnsiChar;
  cdecl; external LIB_POSTPROC;


type
  QP_STORE_T = shortint;
  PQP_STORE_T = ^QP_STORE_T;
  TByteQuadArray = array[0..3] of byte;
  PByteQuadArray = ^TByteQuadArray;
  TIntegerQuadArray = array[0..3] of integer;


const
  PP_QUALITY_MAX  = 6 ;

type
  pp_context  = pointer;
  pp_mode     = pointer;

{$IF LIBPOSTPROC_VERSION_INT < (52 shl 16)}
  pp_context_t = record
    {internal structure}
  end;
  pp_context = ^pp_context_t;
  pp_mode_t = record
    {internal structure}
  end;
  pp_mode = ^pp_mode_t;
  pp_help: PAnsiChar;
{$ELSE}
  pp_help = array of AnsiChar;
{$ENDIF}

procedure pp_postprocess(src: PByteQuadArray; const srcStride: TIntegerQuadArray;
                     dst: PByteQuadArray; const dstStride: TIntegerQuadArray;
                     horizontalSize: integer; verticalSize: integer;
                     QP_store: PQP_STORE_T;  QP_stride: integer;
                     mode: pp_mode; Context: pp_context; pict_type: integer);
   cdecl; external LIB_POSTPROC;


(**
 * Return a pp_mode or NULL if an error occurred.
 *
 * @param name    the string after "-pp" on the command line
 * @param quality a number from 0 to PP_QUALITY_MAX
 *)
function pp_get_mode_by_name_and_quality(name: PAnsiChar; quality: integer): pp_mode;
  cdecl; external LIB_POSTPROC;

procedure pp_free_mode(mode: pp_mode);
  cdecl; external LIB_POSTPROC;

function pp_get_context(width: integer; height: integer; flags: integer): pp_context;
  cdecl; external LIB_POSTPROC;

procedure pp_free_context(Context: pp_context);
  cdecl; external LIB_POSTPROC;

const
  PP_CPU_CAPS_MMX   = $80000000;
  PP_CPU_CAPS_MMX2  = $20000000;
  PP_CPU_CAPS_3DNOW = $40000000;
  PP_CPU_CAPS_ALTIVEC = $10000000;
  PP_CPU_CAPS_AUTO  = $00080000;

  PP_FORMAT         = $00000008;
  PP_FORMAT_420     = ($00000011 or PP_FORMAT);
  PP_FORMAT_422     = ($00000001 or PP_FORMAT);
  PP_FORMAT_411     = ($00000002 or PP_FORMAT);
  PP_FORMAT_444     = ($00000000 or PP_FORMAT);

  PP_PICT_TYPE_QP2  = $00000010; ///< MPEG2 style QScale




implementation

end.

