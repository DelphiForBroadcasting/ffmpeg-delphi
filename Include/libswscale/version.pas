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

{$ifndef SWSCALE_VERSION_H}
  {$define SWSCALE_VERSION_H}

const

	LIB_SWSCALE = 'swscale-3';
	LIBSWSCALE_VERSION_MAJOR   = 3;
	LIBSWSCALE_VERSION_MINOR   = 1;
	LIBSWSCALE_VERSION_MICRO   = 101;
  //LIBSWSCALE_VERSION       = AV_VERSION(LIBSWSCALE_VERSION_MAJOR, LIBSWSCALE_VERSION_MINOR, LIBSWSCALE_VERSION_MICRO);
	LIBSWSCALE_VERSION_INT     = ((LIBSWSCALE_VERSION_MAJOR shl 16) or (LIBSWSCALE_VERSION_MINOR shl 8) or LIBSWSCALE_VERSION_MICRO);
  LIBSWSCALE_BUILD           = LIBSWSCALE_VERSION_INT;
	LIBSWSCALE_IDENT		       = 'SwS';

(**
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *)

{$ifndef FF_API_SWS_CPU_CAPS}
  FF_API_SWS_CPU_CAPS = LIBSWSCALE_VERSION_MAJOR < 4;
{$endif}
{$ifndef FF_API_ARCH_BFIN}
  FF_API_ARCH_BFIN = LIBSWSCALE_VERSION_MAJOR < 4;
{$endif}

{$endif} (* SWSCALE_VERSION_H *)
	

