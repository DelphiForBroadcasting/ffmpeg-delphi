(*
 * copyright (c) 2005 Michael Niedermayer <michaelni@gmx.at>
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)
 
{$ifndef AVUTIL_INTFLOAT_READWRITE_H}
	{$define AVUTIL_INTFLOAT_READWRITE_H}


{$if FF_API_INTFLOAT}

type
(* IEEE 80 bits extended float *)
  PAVExtFloat = ^TAVExtFloat;
  TAVExtFloat = record	
	  exponent : array[0..2] of PByte;
	m antissa : array[0..8] of PByte;
  end;


function av_int2dbl(v: int64): double;
  cdecl; external LIB_AVUTIL; deprecated;
function av_int2flt(v: cint32): single;
  cdecl; external LIB_AVUTIL; deprecated;
function av_ext2dbl(const ext: TAVExtFloat): double;
  cdecl; external LIB_AVUTIL;  deprecated;
function av_dbl2int(d: double): int64;
  cdecl; external LIB_AVUTIL;  deprecated;
function av_flt2int(d: single): integer;
  cdecl; external LIB_AVUTIL;  deprecated;
function av_dbl2ext(d: double): TAVExtFloat;
  cdecl; external LIB_AVUTIL; deprecated;
{$ENDIF}

{$EndIf} (* AVUTIL_INTFLOAT_READWRITE_H *)
