(*
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


{$ifndef AVFILTER_INTERNAL_H}
{$define AVFILTER_INTERNAL_H}

(**
 * @file
 * internal API functions
 *)


{$IF FF_API_AVFILTERBUFFER}
const	
	POOL_SIZE = 32;
{$ENDIF}


(**
 * Send a frame of data to the next filter.
 *
 * @param link   the output link over which the data is being sent
 * @param frame a reference to the buffer of data being sent. The
 *              receiving filter will free this reference when it no longer
 *              needs it or pass it on to the next filter.
 *
 * @return >= 0 on success, a negative AVERROR on error. The receiving filter
 * is responsible for unreferencing frame in case of error.
 *)
//function ff_filter_frame(link: PAVFilterLink; frame: PAVFrame): integer;
//    cdecl; external LIB_AVFILTER;


{$endif} (* AVFILTER_INTERNAL_H *)
