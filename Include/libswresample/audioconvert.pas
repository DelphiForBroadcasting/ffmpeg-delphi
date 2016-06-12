(*
 * audio conversion
 * Copyright (c) 2006 Michael Niedermayer <michaelni@gmx.at>
 * Copyright (c) 2008 Peter Ross
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


{$ifndef SWR_AUDIOCONVERT_H}
  {$define SWR_AUDIOCONVERT_H}

(**
 * @file
 * Audio format conversion routines
 *)


type
  TConv_func_type = procedure(po: PByte; pi: PByte; is_ : integer; os: integer; end_ : PByte) of object;
  TSimd_func_type =  procedure(var dst: PByte; src: PByte; len: integer) of object;


  PAudioConvert = ^TAudioConvert;
  TAudioConvert = record
    channels : integer;
    in_simd_align_mask : integer;
    out_simd_align_mask : integer;
    conv_f : TConv_func_type;
    simd_f : TSimd_func_type;
    ch_map : PInteger;
    silence: array[0..7] of PByte; ///< silence input sample
  end;


(**
 * Create an audio sample format converter context
 * @param out_fmt Output sample format
 * @param in_fmt Input sample format
 * @param channels Number of channels
 * @param flags See AV_CPU_FLAG_xx
 * @param ch_map list of the channels id to pick from the source stream, NULL
 *               if all channels must be selected
 * @return NULL on error
 *)
function swri_audio_convert_alloc(out_fmt: TAVSampleFormat;
                                       in_fmt : TAVSampleFormat;
                                       channels: integer; var ch_map : integer;
                                       flags: integer): PAudioConvert;
  cdecl; external LIB_SWRESAMPLE;

(**
 * Free audio sample format converter context.
 * and set the pointer to NULL
 *)
procedure swri_audio_convert_free(var ctx : PAudioConvert);
  cdecl; external LIB_SWRESAMPLE;

(**
 * Convert between audio sample formats
 * @param[in] out array of output buffers for each channel. set to NULL to ignore processing of the given channel.
 * @param[in] in array of input buffers for each channel
 * @param len length of audio frame size (measured in samples)
 *)
function swri_audio_convert(ctx : PAudioConvert; out_ : PAudioData; in_ : PAudioData; len: integer): integer;
  cdecl; external LIB_SWRESAMPLE;

{$endif} (* AUDIOCONVERT_H *)
