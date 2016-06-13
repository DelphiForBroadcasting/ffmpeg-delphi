(*
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

{$IFNDEF AVCODEC_VERSION_H}
  {$define AVCODEC_VERSION_H}

const

	LIB_AVCODEC                 = 'avcodec-56';
	LIBAVCODEC_VERSION_MAJOR    = 56;
	LIBAVCODEC_VERSION_MINOR    = 60;
	LIBAVCODEC_VERSION_MICRO    = 100;

  //LIBAVCODEC_VERSION        = AV_VERSION(LIBAVCODEC_VERSION_MAJOR, LIBAVCODEC_VERSION_MINOR, LIBAVCODEC_VERSION_MICRO);
	LIBAVCODEC_VERSION_INT      =((LIBAVCODEC_VERSION_MAJOR shl 16) or (LIBAVCODEC_VERSION_MINOR shl 8) or LIBAVCODEC_VERSION_MICRO);
  LIBAVCODEC_BUILD            = LIBAVCODEC_VERSION_INT;

	LIBAVCODEC_IDENT		        = 'Lavc';

(**
 * FF_API_* defines may be placed below to indicate public API that will be
 * dropped at a future version bump. The defines themselves are not part of
 * the public API and may change, break or disappear at any time.
 *
 * @note, when bumping the major version it is recommended to manually
 * disable each FF_API_* in its own commit instead of disabling them all
 * at once through the bump. This improves the git bisect-ability of the change.
 *)

{$ifndef FF_API_VIMA_DECODER}
  FF_API_VIMA_DECODER    = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_REQUEST_CHANNELS}
  FF_API_REQUEST_CHANNELS = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_OLD_DECODE_AUDIO}
  FF_API_OLD_DECODE_AUDIO = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_OLD_ENCODE_AUDIO}
  FF_API_OLD_ENCODE_AUDIO = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_OLD_ENCODE_VIDEO}
  FF_API_OLD_ENCODE_VIDEO = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_CODEC_ID}
  FF_API_CODEC_ID          = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_AUDIO_CONVERT}
  FF_API_AUDIO_CONVERT     = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_AVCODEC_RESAMPLE}
  FF_API_AVCODEC_RESAMPLE  = FF_API_AUDIO_CONVERT;
{$endif}

{$ifndef FF_API_DEINTERLACE}
  FF_API_DEINTERLACE       = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_DESTRUCT_PACKET}
  FF_API_DESTRUCT_PACKET   = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_GET_BUFFER}
  FF_API_GET_BUFFER        = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_MISSING_SAMPLE}
  FF_API_MISSING_SAMPLE    = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}
{$ifndef FF_API_LOWRES}
  FF_API_LOWRES            = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_CAP_VDPAU}
  FF_API_CAP_VDPAU         = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_BUFS_VDPAU}
  FF_API_BUFS_VDPAU        = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_VOXWARE}
  FF_API_VOXWARE           = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_SET_DIMENSIONS}
  FF_API_SET_DIMENSIONS    = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_DEBUG_MV}
  FF_API_DEBUG_MV          = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_AC_VLC}
  FF_API_AC_VLC            = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_OLD_MSMPEG4}
  FF_API_OLD_MSMPEG4       = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_ASPECT_EXTENDED}
  FF_API_ASPECT_EXTENDED   = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_THREAD_OPAQUE}
  FF_API_THREAD_OPAQUE     = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_CODEC_PKT}
  FF_API_CODEC_PKT         = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_ARCH_ALPHA}
  FF_API_ARCH_ALPHA        = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_XVMC}
  FF_API_XVMC              = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_ERROR_RATE}
  FF_API_ERROR_RATE        = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_QSCALE_TYPE}
  FF_API_QSCALE_TYPE       = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_MB_TYPE}
  FF_API_MB_TYPE           = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_MAX_BFRAMES}
  FF_API_MAX_BFRAMES       = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_NEG_LINESIZES}
  FF_API_NEG_LINESIZES     = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_EMU_EDGE}
  FF_API_EMU_EDGE          = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_ARCH_SH4}
  FF_API_ARCH_SH4          = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_ARCH_SPARC}
  FF_API_ARCH_SPARC        = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_UNUSED_MEMBERS}
FF_API_UNUSED_MEMBERS    = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_IDCT_XVIDMMX}
  FF_API_IDCT_XVIDMMX      = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_INPUT_PRESERVED}
  FF_API_INPUT_PRESERVED   = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_NORMALIZE_AQP}
  FF_API_NORMALIZE_AQP     = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_GMC}
  FF_API_GMC               = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_MV0}
  FF_API_MV0               = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_CODEC_NAME}
  FF_API_CODEC_NAME        = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$ifndef FF_API_AFD}
  FF_API_AFD               = (LIBAVCODEC_VERSION_MAJOR < 57);
{$endif}

{$IFNDEF FF_API_VISMV}
(* XXX: don't forget to drop the -vismv documentation *)
  FF_API_VISMV             = (LIBAVCODEC_VERSION_MAJOR < 57);
{$ENDIF}
{$IFNDEF FF_API_DV_FRAME_PROFILE}
  FF_API_DV_FRAME_PROFILE  = (LIBAVCODEC_VERSION_MAJOR < 57);
{$ENDIF}
{$IFNDEF FF_API_AUDIOENC_DELAY}
  FF_API_AUDIOENC_DELAY    = (LIBAVCODEC_VERSION_MAJOR < 58);
{$ENDIF}
{$IFNDEF FF_API_VAAPI_CONTEXT}
  FF_API_VAAPI_CONTEXT     = (LIBAVCODEC_VERSION_MAJOR < 58);
{$ENDIF}
{$IFNDEF FF_API_AVCTX_TIMEBASE}
  FF_API_AVCTX_TIMEBASE    = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_MPV_OPT}
  FF_API_MPV_OPT           = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_STREAM_CODEC_TAG}
  FF_API_STREAM_CODEC_TAG  = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_QUANT_BIAS}
  FF_API_QUANT_BIAS        = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_RC_STRATEGY}
  FF_API_RC_STRATEGY       = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_CODED_FRAME}
  FF_API_CODED_FRAME       = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_MOTION_EST}
  FF_API_MOTION_EST        = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}
{$IFNDEF FF_API_WITHOUT_PREFIX}
  FF_API_WITHOUT_PREFIX    = (LIBAVCODEC_VERSION_MAJOR < 59);
{$ENDIF}


{$ENDIF} (* AVCODEC_VERSION_H *)
