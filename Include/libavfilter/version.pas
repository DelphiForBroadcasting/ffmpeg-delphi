(*
 * Version macros.
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

{$ifndef AVFILTER_VERSION_H}
  {$define AVFILTER_VERSION_H}

(**
 * @file
 * @ingroup lavfi
 * Libavfilter version macros
 *)

const

	LIB_AVFILTER = 'avfilter-5';
	LIBAVFILTER_VERSION_MAJOR   = 5;
	LLIBAVFILTER_VERSION_MINOR   = 40;
	LIBAVFILTER_VERSION_MICRO   = 101;
  //LIBAVFILTER_VERSION       = AV_VERSION(LIBAVFILTER_VERSION_MAJOR, LLIBAVFILTER_VERSION_MINOR, LIBAVFILTER_VERSION_MICRO);
	LIBAVFILTER_VERSION_INT     = ((LIBAVFILTER_VERSION_MAJOR shl 16) or (LLIBAVFILTER_VERSION_MINOR shl 8) or LIBAVFILTER_VERSION_MICRO);
  LIBAVFILTER_BUILD           = LIBAVFILTER_VERSION_INT;
	LIBAVFILTER_IDENT		       = 'Lavfi';

(**
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *)

{$ifndef FF_API_AVFILTERPAD_PUBLIC}
  FF_API_AVFILTERPAD_PUBLIC           = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_FOO_COUNT}
  FF_API_FOO_COUNT                    = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_AVFILTERBUFFER}
  FF_API_AVFILTERBUFFER               = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_OLD_FILTER_OPTS}
  FF_API_OLD_FILTER_OPTS              = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_OLD_FILTER_OPTS_ERROR}
  FF_API_OLD_FILTER_OPTS_ERROR        = (LIBAVFILTER_VERSION_MAJOR < 7);
{$endif}
{$ifndef FF_API_AVFILTER_OPEN}
  FF_API_AVFILTER_OPEN                = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_AVFILTER_INIT_FILTER}
  FF_API_AVFILTER_INIT_FILTER         = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_OLD_FILTER_REGISTER}
  FF_API_OLD_FILTER_REGISTER          = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}
{$ifndef FF_API_OLD_GRAPH_PARSE}
  FF_API_OLD_GRAPH_PARSE              = (LIBAVFILTER_VERSION_MAJOR < 5);
{$endif}
{$ifndef FF_API_NOCONST_GET_NAME}
  FF_API_NOCONST_GET_NAME             = (LIBAVFILTER_VERSION_MAJOR < 6);
{$endif}


{$endif} (* AVFILTER_VERSION_H *)
	

