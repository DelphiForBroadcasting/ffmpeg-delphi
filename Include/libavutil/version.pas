(*
 * copyright (c) 2003 Fabrice Bellard
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

{$ifndef AVUTIL_VERSION_H}
  {$define AVUTIL_VERSION_H}

(**
 * @addtogroup version_utils
 *
 * Useful to check and match library version in order to maintain
 * backward compatibility.
 *
 * @{
 *)

function AV_VERSION_INT(a, b, c: integer): integer; // Note: see in avutil.pas

function AV_VERSION_DOT(a, b, c: integer): PAnsiChar; // Note: see in avutil.pas

function AV_VERSION(a, b, c: integer): PAnsiChar; // Note: see in avutil.pas


(**
 * @
 *)

(**
 * @file
 * @ingroup lavu
 * Libavutil version macros
 *)

(**
 * @defgroup lavu_ver Version and Build diagnostics
 *
 * Macros and function useful to check at compiletime and at runtime
 * which version of libavutil is in use.
 *
 * @
 *)

const

	LIB_AVUTIL                = 'avutil-54';
	LIBAVUTIL_VERSION_MAJOR   = 54;
	LIBAVUTIL_VERSION_MINOR   = 0;
	LIBAVUTIL_VERSION_MICRO   = 100;
  //LIBAVUTIL_VERSION         = AV_VERSION(LIBAVUTIL_VERSION_MAJOR, LIBAVUTIL_VERSION_MINOR, LIBAVUTIL_VERSION_MICRO);
	LIBAVUTIL_VERSION_INT     = ((LIBAVUTIL_VERSION_MAJOR shl 16) or (LIBAVUTIL_VERSION_MINOR shl 8) or LIBAVUTIL_VERSION_MICRO);
  LIBAVUTIL_BUILD           = LIBAVUTIL_VERSION_INT;
	LIBAVUTIL_IDENT		        = 'Lavu';

(**
 * @}
 *
 * @defgroup depr_guards Deprecation guards
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *
 * @{
 *)

{$IFNDEF FF_API_GET_BITS_PER_SAMPLE_FMT}
  FF_API_GET_BITS_PER_SAMPLE_FMT  = (LIBAVUTIL_VERSION_MAJOR < 54);
{$ENDIF}
{$IFNDEF FF_API_FIND_OPT}
 FF_API_FIND_OPT                 = (LIBAVUTIL_VERSION_MAJOR < 54);
{$ENDIF}
{$IFNDEF FF_API_OLD_AVOPTIONS}
  FF_API_OLD_AVOPTIONS            = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_PIX_FMT}
  FF_API_PIX_FMT                  = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_CONTEXT_SIZE}
  FF_API_CONTEXT_SIZE             = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_PIX_FMT_DESC}
  FF_API_PIX_FMT_DESC             = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_AV_REVERSE}
  FF_API_AV_REVERSE               = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_AUDIOCONVERT}
  FF_API_AUDIOCONVERT             = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_CPU_FLAG_MMX2}
  FF_API_CPU_FLAG_MMX2            = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_SAMPLES_UTILS_RETURN_ZERO}
  FF_API_SAMPLES_UTILS_RETURN_ZERO = (LIBAVUTIL_VERSION_MAJOR < 54);
{$ENDIF}
{$IFNDEF FF_API_LLS_PRIVATE}
  FF_API_LLS_PRIVATE              = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_LLS1}
  FF_API_LLS1                     = (LIBAVUTIL_VERSION_MAJOR < 54);
{$ENDIF}
{$IFNDEF FF_API_AVFRAME_LAVC}
  FF_API_AVFRAME_LAVC             = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_VDPAU}
  FF_API_VDPAU                    = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_GET_CHANNEL_LAYOUT_COMPAT}
  FF_API_GET_CHANNEL_LAYOUT_COMPAT = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_OLD_OPENCL}
  FF_API_OLD_OPENCL               = (LIBAVUTIL_VERSION_MAJOR < 54);
{$ENDIF}
{$IFNDEF FF_API_XVMC}
  FF_API_XVMC                     = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}
{$IFNDEF FF_API_INTFLOAT}
  FF_API_INTFLOAT                 = (LIBAVUTIL_VERSION_MAJOR < 54);
{$ENDIF}
{$IFNDEF FF_API_OPT_TYPE_METADATA}
  FF_API_OPT_TYPE_METADATA        = (LIBAVUTIL_VERSION_MAJOR < 55);
{$ENDIF}



(**
 * @
 *)

{$ENDIF} (* AVUTIL_VERSION_H *)

