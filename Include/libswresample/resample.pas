(*
 * audio resampling
 * Copyright (c) 2004-2012 Michael Niedermayer <michaelni@gmx.at>
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

{$ifndef SWRESAMPLE_RESAMPLE_H}
  {$define SWRESAMPLE_RESAMPLE_H}


type
  PResampleContext = ^TResampleContext;
  TResampleContext = record
    av_class : PAVClass;
    filter_bank : pByte;
    filter_length : integer;
    filter_alloc : integer;
    ideal_dst_incr : integer;
    dst_incr : integer;
    dst_incr_div : integer;
    dst_incr_mod : integer;
    index : integer;
    frac : integer;
    src_incr : integer;
    compensation_distance : integer;
    phase_shift : integer;
    phase_mask : integer;
    linear : integer;
    filter_type : TSwrFilterType;
    kaiser_beta : integer;
    factor : double;
    format : TAVSampleFormat;
    felem_size : integer;
    filter_shift : integer;
    dsp : record
      resample_one : procedure(dst: Pointer; src : Pointer; n : integer; index : int64; incr : int64); cdecl;
      resample : function(c : PResampleContext; dst: Pointer; src: Pointer; n: integer; update_ctx: integer): integer; cdecl;
    end;
  end;


procedure swri_resample_dsp_init(c : PResampleContext);
  cdecl; external LIB_SWRESAMPLE;

procedure swri_resample_dsp_x86_init(c : PResampleContext);
  cdecl; external LIB_SWRESAMPLE;

{$endif} (* SWRESAMPLE_RESAMPLE_H *)
