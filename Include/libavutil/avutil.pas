(*
 * copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
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

(**
 * Conversion to Pascal Copyright 2014 (c) Oleksandr Nazaruk <mail@freehand.com.ua>
 *
 *)

unit avutil;


{$MINENUMSIZE 4}

{$IFDEF DARWIN}
  {$linklib libavutil}
{$ENDIF}

interface

uses
  System.SysUtils;

{$INCLUDE version.pas}

{$INCLUDE rational.pas}

{$INCLUDE common.pas}

(**
 * @file
 * external API header
 *)

(**
 * @mainpage
 *
 * @section ffmpeg_intro Introduction
 *
 * This document describes the usage of the different libraries
 * provided by FFmpeg.
 *
 * @li @ref libavc "libavcodec" encoding/decoding library
 * @li @ref lavfi "libavfilter" graph-based frame editing library
 * @li @ref libavf "libavformat" I/O and muxing/demuxing library
 * @li @ref lavd "libavdevice" special devices muxing/demuxing library
 * @li @ref lavu "libavutil" common utility library
 * @li @ref lswr "libswresample" audio resampling, format conversion and mixing
 * @li @ref lpp  "libpostproc" post processing library
 * @li @ref libsws "libswscale" color conversion and scaling library
 *
 * @section ffmpeg_versioning Versioning and compatibility
 *
 * Each of the FFmpeg libraries contains a version.h header, which defines a
 * major, minor and micro version number with the
 * <em>LIBRARYNAME_VERSION_{MAJOR,MINOR,MICRO}</em> macros. The major version
 * number is incremented with backward incompatible changes - e.g. removing
 * parts of the public API, reordering public struct members, etc. The minor
 * version number is incremented for backward compatible API changes or major
 * new features - e.g. adding a new public function or a new decoder. The micro
 * version number is incremented for smaller changes that a calling program
 * might still want to check for - e.g. changing behavior in a previously
 * unspecified situation.
 *
 * FFmpeg guarantees backward API and ABI compatibility for each library as long
 * as its major version number is unchanged. This means that no public symbols
 * will be removed or renamed. Types and names of the public struct members and
 * values of public macros and enums will remain the same (unless they were
 * explicitly declared as not part of the public API). Documented behavior will
 * not change.
 *
 * In other words, any correct program that works with a given FFmpeg snapshot
 * should work just as well without any changes with any later snapshot with the
 * same major versions. This applies to both rebuilding the program against new
 * FFmpeg versions or to replacing the dynamic FFmpeg libraries that a program
 * links against.
 *
 * However, new public symbols may be added and new members may be appended to
 * public structs whose size is not part of public ABI (most public structs in
 * FFmpeg). New macros and enum values may be added. Behavior in undocumented
 * situations may change slightly (and be documented). All those are accompanied
 * by an entry in doc/APIchanges and incrementing either the minor or micro
 * version number.
 *)

(**
 * @defgroup lavu Common utility functions
 *
 * @brief
 * libavutil contains the code shared across all the other FFmpeg
 * libraries
 *
 * @note In order to use the functions provided by avutil you must include
 * the specific header.
 *
 * @{
 *
 * @defgroup lavu_crypto Crypto and Hashing
 *
 * @{
 * @}
 *
 * @defgroup lavu_math Maths
 * @{
 *
 * @}
 *
 * @defgroup lavu_string String Manipulation
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_mem Memory Management
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_data Data Structures
 * @{
 *
 * @}
 *
 * @defgroup lavu_audio Audio related
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_error Error Codes
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_log Logging Facility
 *
 * @{
 *
 * @}
 *
 * @defgroup lavu_misc Other
 *
 * @{
 *
 * @defgroup lavu_internal Internal
 *
 * Not exported functions, for internal usage only
 *
 * @{
 *
 * @}
 *
 * @defgroup preproc_misc Preprocessor String Macros
 *
 * @{
 *
 * @}
 *
 * @defgroup version_utils Library Version Macros
 *
 * @{
 *
 * @}
 *)


(**
 * @addtogroup lavu_ver
 * @{
 *)

(**
 * Return the LIBAVUTIL_VERSION_INT constant.
 *)
function avutil_version(): cardinal;
  cdecl; external LIB_AVUTIL;

(**
 * Return the libavutil build-time configuration.
 *)
function avutil_configuration(): PAnsiChar;
  cdecl; external LIB_AVUTIL;

(**
 * Return the libavutil license.
 *)
function avutil_license(): PAnsiChar;
  cdecl; external LIB_AVUTIL;

(**
 * @addtogroup lavu_media Media Type
 * @brief Media Type
 *)

type
  TAVMediaType = (
    AVMEDIA_TYPE_UNKNOWN = -1,  ///< Usually treated as AVMEDIA_TYPE_DATA
    AVMEDIA_TYPE_VIDEO,
    AVMEDIA_TYPE_AUDIO,
    AVMEDIA_TYPE_DATA,          ///< Opaque data information usually continuous
    AVMEDIA_TYPE_SUBTITLE,
    AVMEDIA_TYPE_ATTACHMENT,    ///< Opaque data information usually sparse
    AVMEDIA_TYPE_NB
  );

(**
 * Return a string describing the media_type enum, NULL if media_type
 * is unknown.
 *)
function av_get_media_type_string(media_type: TAVMediaType): PAnsiChar;
  cdecl; external LIB_AVUTIL;

const
  FF_LAMBDA_SHIFT = 7;
  FF_LAMBDA_SCALE = (1 shl FF_LAMBDA_SHIFT);
  FF_QP2LAMBDA    = 118; ///< factor to convert from H.263 QP to lambda
  FF_LAMBDA_MAX   = (256*128-1);
 
  FF_QUALITY_SCALE = FF_LAMBDA_SCALE; //FIXME maybe remove
 
(**
 * @brief Undefined timestamp value
 *
 * Usually reported by demuxer that work on containers that do not provide
 * either pts or dts.
 *)

  AV_NOPTS_VALUE   = $8000000000000000;

(**
 * Internal time base represented as integer
 *)

  AV_TIME_BASE     = 1000000;
  
(**
 * Internal time base represented as fractional value
 *)

  AV_TIME_BASE_Q   : TAVRational = (num: 1; den: AV_TIME_BASE);

(**
 * @}
 * @}
 * @defgroup lavu_picture Image related
 *
 * AVPicture types, pixel formats and basic image planes manipulation.
 *
 * @
 *)

type
  TAVPictureType = (
    AV_PICTURE_TYPE_NONE = 0, ///< Undefined
    AV_PICTURE_TYPE_I,     ///< Intra
    AV_PICTURE_TYPE_P,     ///< Predicted
    AV_PICTURE_TYPE_B,     ///< Bi-dir predicted
    AV_PICTURE_TYPE_S,     ///< S(GMC)-VOP MPEG4
    AV_PICTURE_TYPE_SI,    ///< Switching Intra
    AV_PICTURE_TYPE_SP,    ///< Switching Predicted
    AV_PICTURE_TYPE_BI     ///< BI type
  );

(**
 * Return a single letter to describe the given picture type
 * pict_type.
 *
 * @param[in] pict_type the picture type @return a single character
 * representing the picture type, '?' if pict_type is unknown
 *)
function av_get_picture_type_char(pict_type: TAVPictureType): PAnsiChar;
  cdecl; external LIB_AVUTIL;


{$INCLUDE pixfmt.pas}

{$INCLUDE crc.pas}

{$INCLUDE cpu.pas}

{$INCLUDE dict.pas}

{$INCLUDE error.pas}

{$INCLUDE file.pas}

{$INCLUDE mathematics.pas}

{$INCLUDE mem.pas}

{$INCLUDE samplefmt.pas}

{$INCLUDE channel_layout.pas}

{$INCLUDE opt.pas}

{$INCLUDE buffer.pas}

{$INCLUDE imgutils.pas}

{$INCLUDE timestamp.pas}

{$INCLUDE time.pas}

{$INCLUDE timecode.pas}

(**
 * Return x default pointer in case p is NULL.
 *)
function av_x_if_null(p:  pointer; x: pointer): pointer; inline;

(**
 * Compute the length of an integer list.
 *
 * @param elsize  size in bytes of each list element (only 1, 2, 4 or 8)
 * @param term    list terminator (usually 0 or -1)
 * @param list    pointer to the list
 * @return  length of the list, in elements, not counting the terminator
 *)
function av_int_list_length_for_size(elsize: cardinal;
                                     list: pointer; term: int64): cardinal;
  cdecl; external LIB_AVUTIL;

(**
 * Compute the length of an integer list.
 *
 * @param term  list terminator (usually 0 or -1)
 * @param list  pointer to the list
 * @return  length of the list, in elements, not counting the terminator
 *)
function av_int_list_length(list: pointer; term: int64): cardinal;


(**
 * Open a file using a UTF-8 filename.
 * The API of this function matches POSIX fopen(), errors are returned through
 * errno.
 *)
function av_fopen_utf8(const path: PAnsiChar; const mode: PAnsiChar): Pointer;
  cdecl; external LIB_AVUTIL;

(**
 * Return the fractional representation of the internal time base.
 *)
function av_get_time_base_q(): TAVRational;
  cdecl; external LIB_AVUTIL;

(**
 * @}
 * @}
 *)


implementation


function av_x_if_null(p:  pointer; x: pointer): pointer; inline;
begin
  if p = nil then
    Result := x
  else
    Result := p;
end;

function av_int_list_length(list: pointer; term: int64): cardinal;
begin
  Result := av_int_list_length_for_size(sizeof(pointer), list, term);
end;

(* libavutil/version.h *)

function AV_VERSION_INT(a, b, c: integer): integer;
begin
 result:=((a shl 16) or (b shl 8) or c);
end;

function AV_VERSION_DOT(a, b, c: integer): PAnsiChar;
begin
  result:=PAnsiChar(AnsiString(Format('%d.%02.2d.%02.2d',[a, b, c])));
end;

function AV_VERSION(a, b, c: integer): PansiChar;
begin
  result:=AV_VERSION_DOT(a, b, c);
end;

(* libavutil/common.h *)

function MKTAG(a, b, c, d: AnsiChar): integer; inline;
begin
  Result := (ord(a) or (ord(b) shl 8) or (ord(c) shl 16) or (ord(d) shl 24));
end;

function MKBETAG(a, b, c, d: AnsiChar): integer; inline;
begin
  Result := (ord(d) or (ord(c) shl 8) or (ord(b) shl 16) or (ord(a) shl 24));
end;

function av_make_q(num: integer; den: integer): TAVRational; inline;
begin
  result.num:=num;
  result.den:=den;
end;

function FFMIN(a,b : integer): integer;
begin
  if (a > b) then result := b
  else result := a;
end;

(* libavutil/rational.h *)

function av_cmp_q (a: TAVRational; b: TAVRational): integer; inline;
var
  tmp: int64;
begin
  tmp := a.num * int64(b.den) - b.num * int64(a.den);

  if tmp <> 0 then
    Result := ((tmp xor a.den xor b.den) shr 63) or 1
  else if (b.den and a.den) <> 0 then
    Result := 0
  else if (a.num and b.num) <> 0 then
    Result := (a.num shr 31) - (b.num shr 31)
  else
    Result := low(integer);
end;

function av_q2d(a: TAVRational): double; inline;
begin
  Result := a.num / a.den;
end;

function av_inv_q(q: TAVRational): TAVRational; inline;
begin
  Result.num := q.den;
  Result.den := q.num;
end;


(* libavutil/log.h *)

function AV_LOG_C(x : integer): integer;
begin
  result:= x shl 8;
end;

(* libavutil/error.h *)
function AVERROR(err: integer): integer; // Note: see avutil.pas
begin
{$IF EDOM > 0}
  result := -err;
{$ELSE}
  result := -err;
{$IFEND}
end;

function AVUNERROR(err: integer): integer; // Note: see avutil.pas
begin
{$IF EDOM > 0}
  result := -err;
{$ELSE}
  result := -err;
{$IFEND}
end;

function FFERRTAG(a, b, c, d: AnsiChar): integer; inline;
begin
  result:=-Integer(MKTAG(a, b, c, d));
end;

function av_make_error_string(errbuf: PAnsiChar; errbuf_size: cardinal; errnum: integer): PAnsiChar; inline;
begin
  av_strerror(errnum, errbuf, errbuf_size);
  result := errbuf;
end;

function av_err2str(errnum: integer): PAnsiChar; inline;
var
  errbuf: PAnsiChar;
begin
  errbuf := AnsiStrAlloc(AV_ERROR_MAX_STRING_SIZE);
  result:=av_make_error_string(errbuf, AV_ERROR_MAX_STRING_SIZE, errnum);
end;

(* libavutil/mem.h *)

function av_malloc_array(nmemb: cardinal; size: cardinal): pointer; inline;
begin
  if (size <= 0 ) or (nmemb >= maxint / size) then
    av_malloc_array := NIL
  else
    av_malloc_array := av_malloc(nmemb * size);
end;

function av_mallocz_array(nmemb: cardinal; size: cardinal): pointer; inline;
begin
  if (size <= 0 ) or (nmemb >= maxint / size) then
    av_mallocz_array := NIL
  else
    av_mallocz_array := av_mallocz(nmemb * size);
end;

(* libavutil/timestamp.pas *)

(**
 * Fill the provided buffer with a string containing a timestamp
 * representation.
 *
 * @param buf a buffer with size in bytes of at least AV_TS_MAX_STRING_SIZE
 * @param ts the timestamp to represent
 * @return the buffer in input
 *)

Function av_ts_make_string(buf : PAnsiChar; ts: int64): PAnsiChar; Inline;
begin
  if (ts = AV_NOPTS_VALUE) then
    StrLCopy(buf, 'NOPTS', AV_TS_MAX_STRING_SIZE)
  else
    StrLCopy(buf, PAnsiChar(ansistring(format('%d', [ts]))), AV_TS_MAX_STRING_SIZE);
  result := buf;
end;

{**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 *}
Function av_ts2str(ts: int64): PAnsiChar;
var
	param : array[0..AV_TS_MAX_STRING_SIZE-1] of ansichar;
begin
  result := av_ts_make_string(param, ts);
end;

(**
 * Fill the provided buffer with a string containing a timestamp time
 * representation.
 *
 * @param buf a buffer with size in bytes of at least AV_TS_MAX_STRING_SIZE
 * @param ts the timestamp to represent
 * @param tb the timebase of the timestamp
 * @return the buffer in input
 *)
Function av_ts_make_time_string(buf : PAnsiChar; ts : int64; tb: PAVRational): PAnsiChar; Inline;
begin
  if (ts = AV_NOPTS_VALUE) then
    StrLCopy(buf, 'NOPTS'+#0, AV_TS_MAX_STRING_SIZE)
  else
    StrLCopy(buf, PAnsiChar(ansistring(format('%.6g', [av_q2d(tb^) * ts]))), AV_TS_MAX_STRING_SIZE);
  result := buf;
end;

(**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 *)

Function av_ts2timestr(ts: int64; tb: PAVRational): PAnsiChar;
var
	param : array[0..AV_TS_MAX_STRING_SIZE-1] of ansichar;
begin
 result := av_ts_make_time_string(param, ts, tb);
end;


end.
