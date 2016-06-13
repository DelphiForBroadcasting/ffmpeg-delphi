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

{$ifndef AVDEVICE_VERSION_H}
  {$define AVDEVICE_VERSION_H}

const

	LIB_AVDEVICE = 'avdevice-56';
	LIBAVDEVICE_VERSION_MAJOR   = 56;
	LIBAVDEVICE_VERSION_MINOR   = 4;
	LIBAVDEVICE_VERSION_MICRO   = 100;
  //LIBAVDEVICE_VERSION       = AV_VERSION(LIBAVDEVICE_VERSION_MAJOR, LIBSWSCALE_VERSION_MINOR, LIBSWSCALE_VERSION_MICRO);
	LIBAVDEVICE_VERSION_INT     = ((LIBAVDEVICE_VERSION_MAJOR shl 16) or (LIBAVDEVICE_VERSION_MINOR shl 8) or LIBAVDEVICE_VERSION_MICRO);
  LIBAVDEVICE_BUILD           = LIBAVDEVICE_VERSION_INT;
	LIBAVDEVICE_IDENT		        = 'Lavd';

(**
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *)

{$endif} (* AVDEVICE_VERSION_H *)
	

