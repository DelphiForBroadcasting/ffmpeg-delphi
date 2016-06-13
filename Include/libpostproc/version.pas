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

{$ifndef POSTPROC_POSTPROCESS_VERSION_H}
  {$define POSTPROC_POSTPROCESS_VERSION_H}

const
	LIB_POSTPROC                = 'postproc-53';
	LIBPOSTPROC_VERSION_MAJOR   = 53;
	LIBPOSTPROC_VERSION_MINOR   = 3;
	LIBPOSTPROC_VERSION_MICRO   = 100;
  //LIBPOSTPROC_VERSION         = AV_VERSION(LIBPOSTPROC_VERSION_MAJOR, LIBPOSTPROC_VERSION_MINOR, LIBPOSTPROC_VERSION_MICRO);
  LIBPOSTPROC_VERSION_INT     = ((LIBPOSTPROC_VERSION_MAJOR shl 16) or (LIBPOSTPROC_VERSION_MINOR shl 8) or LIBPOSTPROC_VERSION_MICRO);
  LIBPOSTPROC_BUILD           = LIBPOSTPROC_VERSION_INT;

	LIBPOSTPROC_IDENT		        = 'postproc';

{$ifndef FF_API_QP_TYPE}
  FF_API_QP_TYPE = LIBPOSTPROC_VERSION_MAJOR < 55;
{$endif}

{$endif} (* POSTPROC_POSTPROCESS_VERSION_H *)

