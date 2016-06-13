(*
 * Copyright (C) 2011-2013 Michael Niedermayer (michaelni@gmx.at)
 *
 * This file is part of libswresample
 *
 * libswresample is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * libswresample is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with libswresample; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)


{$ifndef SWR_INTERNAL_H}
  {$define SWR_INTERNAL_H}

const
  SWR_CH_MAX  = 64;
  SQRT3_2     = 1.22474487139158904909;  (* sqrt(3/2) *)
  NS_TAPS     = 20;

{$IFDEF CPUX64}
type
  integer_ = int64;
{$ELSE}
type
  integer_ = integer; //longint
{$ENDIF}

type
  TMix_1_1_func_type = procedure(out_ : Pointer; in_ : Pointer; coeffp : Pointer; index : LongInt; len : LongInt) of object;
  TMix_2_1_func_type = procedure(out_ : Pointer; in1_ : Pointer;  in2 : Pointer; coeffp: Pointer; index1: LongInt; index2: LongInt; len: LongInt) of object;
  TMix_any_func_type = procedure(var out_ : PByte; in1 : PByte; coeffp: Pointer; len: integer) of object;

Type
  PAudioData = ^TAudioData;
  TAudioData = record
    ch : array[0..SWR_CH_MAX - 1] of PByte;      ///< samples buffer per channel
    data  : PByte;                ///< samples buffer
    ch_count  : integer;          ///< number of channels
    bps : integer;                ///< bytes per sample
    count : integer;              ///< number of samples
    planar : integer;             ///< 1 if planar audio, 0 otherwise
    fmt    : TAVSampleFormat;     ///< sample format
  end;



  {$INCLUDE audioconvert.pas}
  {$INCLUDE resample.pas}

type
  PDitherContext = ^TDitherContext;
  TDitherContext = record
    method : integer;
    noise_pos : integer;
    scale : Single;
    noise_scale : Single;                                     ///< Noise scale
    ns_taps : integer;                                        ///< Noise shaping dither taps
    ns_scale: Single;                                         ///< Noise shaping dither scale
    ns_scale_1: Single;                                       ///< Noise shaping dither scale^-1
    ns_pos : integer;                                         ///< Noise shaping dither position
    ns_coeffs: array[0..NS_TAPS-1] of Single;                 ///< Noise shaping filter coefficients
    ns_errors : array[0..SWR_CH_MAX-1, 0..(2*NS_TAPS)-1] of Single;
    noise : TAudioData;                                       ///< noise used for dithering
    temp : TAudioData;                                        ///< temporary storage when writing into the input buffer isn't possible
    output_sample_bits : integer;                             ///< the number of used output bits, needed to scale dither correctly
  end;


type
  PPSwrContext= ^PSwrContext;
  PSwrContext = ^TSwrContext;

  TResample_init_func = function(c: PResampleContext; out_rate: integer; in_rate: integer; filter_size: integer; phase_shift: integer; linear: integer;
                                     cutoff: double; format: TAVSampleFormat; filter_type : TSwrFilterType; kaiser_beta: integer; precision: double; cheby: integer):PResampleContext;
  TResample_free_func = procedure(var c: PResampleContext);
  TMultiple_resample_func = function(c: PResampleContext; dst: PAudioData; dst_size: integer; src: TAudioData; src_size: integer; var consumed: integer): integer;
  TResample_flush_func = function(c: PSwrContext): integer;
  TSet_compensation_func = function(c : PResampleContext; sample_delta: integer; compensation_distance: integer): integer;
  TGet_delay_func = function(s : PSwrContext; base: int64): int64;
  TInvert_initial_buffer_func = function(c: PResampleContext; dst: PAudioData; src: PAudioData; src_size: integer; var dst_idx: integer; var dst_count: integer): integer;
  TGet_out_samples_func = function(s: PSwrContext;  in_samples: integer): int64;

  PResampler = ^TResampler;
  TResampler = record
    init  : TResample_init_func;
    free  : TResample_free_func;
    multiple_resample : TMultiple_resample_func;
    flush : TResample_flush_func;
    set_compensation : TSet_compensation_func;
    get_delay : TGet_delay_func;
    invert_initial_buffer : TInvert_initial_buffer_func;
    get_out_samples : TGet_out_samples_func;
  end;


  TSwrContext = record
    av_class : PAVClass;                        ///< AVClass used for AVOption and av_log()
    log_level_offset : integer;                           ///< logging level offset
    log_ctx : Pointer;                                  ///< parent logging context
    in_sample_fmt : TAVSampleFormat;             ///< input sample format
    int_sample_fmt : TAVSampleFormat;             ///< internal sample format (AV_SAMPLE_FMT_FLTP or AV_SAMPLE_FMT_S16P)
    out_sample_fmt : TAVSampleFormat;             ///< output sample format
    in_ch_layout : int64;                          ///< input channel layout
    out_ch_layout : int64;                          ///< output channel layout
    in_sample_rate : integer;                        ///< input sample rate
    out_sample_rate : integer;                        ///< output sample rate
    flags : integer;                                      ///< miscellaneous flags such as SWR_FLAG_RESAMPLE
    slev : Single;                                     ///< surround mixing level
    clev : Single;                                     ///< center mixing level
    lfe_mix_level : Single;                            ///< LFE mixing level
    rematrix_volume : Single;                          ///< rematrixing volume coefficient
    rematrix_maxval : Single;                          ///< maximum value for rematrixing output
    matrix_encoding : integer;          (**< matrixed stereo encoding *)
    channel_map : PInteger;                         ///< channel index (or -1 if muted channel) map
    used_ch_count : Integer;                              ///< number of used input channels (mapped channel count if channel_map, otherwise in.ch_count)
    engine : integer;


    user_in_ch_count : integer;                           ///< User set input channel count
    user_out_ch_count : integer;                          ///< User set output channel count
    user_used_ch_count : integer;                         ///< User set used channel count
    user_in_ch_layout : int64;                      ///< User set input channel layout
    user_out_ch_layout : int64;                     ///< User set output channel layout
    user_int_sample_fmt : TAVSampleFormat;        ///< User set internal sample format
	
    dither : TDitherContext;

    filter_size : integer;                                (**< length of each FIR filter in the resampling filterbank relative to the cutoff frequency *)
    phase_shift : integer;                                (**< log2 of the number of entries in the resampling polyphase filterbank *)
    linear_interp : integer;                              (**< if 1 then the resampling FIR filter will be linearly interpolated *)
    cutoff : double;                                  (**< resampling cutoff frequency (swr: 6dB point; soxr: 0dB point). 1.0 corresponds to half the output sample rate *)
    filter_type : integer;                 (**< swr resampling filter type *)
    kaiser_beta : integer;                              (**< swr beta value for Kaiser window (only applicable if filter_type == AV_FILTER_TYPE_KAISER) *)
    precision : double;                               (**< soxr resampling precision (in bits) *)
    cheby : integer;                                      (**< soxr: if 1 then passband rolloff will be none (Chebyshev) & irrational ratio approximation precision will be higher *)

    min_compensation : Single;                         ///< swr minimum below which no compensation will happen
    min_hard_compensation : Single;                    ///< swr minimum below which no silence inject / sample drop will happen
    soft_compensation_duration : Single;               ///< swr duration over which soft compensation is applied
    max_soft_compensation : Single;                    ///< swr maximum soft compensation in seconds over soft_compensation_duration
    async : Single;                                    ///< swr simple 1 parameter async, similar to ffmpegs -async
    firstpts_in_samples : int64;                    ///< swr first pts in samples

    resample_first : integer;                             ///< 1 if resampling must come first, 0 if rematrixing
    rematrix : integer;                                   ///< flag to indicate if rematrixing is needed (basically if input and output layouts mismatch)
    rematrix_custom : integer;                            ///< flag to indicate that a custom matrix has been defined

    in_ : TAudioData;                                   ///< input audio data
    postin : TAudioData;                               ///< post-input audio data: used for rematrix/resample
    midbuf : TAudioData;                               ///< intermediate audio data (postin/preout)
    preout : TAudioData;                               ///< pre-output audio data: used for rematrix/resample
    out_ : TAudioData;                                  ///< converted output audio data
    in_buffer : TAudioData;                            ///< cached audio data (convert and resample purpose)
    silence : TAudioData;                              ///< temporary with silence
    drop_temp : TAudioData;                            ///< temporary used to discard output
    in_buffer_index : integer;                            ///< cached buffer position
    in_buffer_count : integer;                            ///< cached buffer length
    resample_in_constraint : integer;                     ///< 1 if the input end was reach before the output end, 0 otherwise
    flushed : integer;                                    ///< 1 if data is to be flushed and no further input is expected
    outpts : int64;                                 ///< output PTS
    firstpts : int64;                               ///< first PTS
    drop_output : integer;                                ///< number of output samples to drop
    delayed_samples_fixup : double;                   ///< soxr 0.1.1: needed to fixup delayed_samples after flush has been called.

    in_convert : PAudioConvert;                ///< input conversion context
    out_convert : PAudioConvert;               ///< output conversion context
    full_convert : PAudioConvert;              ///< full conversion context (single conversion for input and output)
    resample  : TResampleContext;               ///< resampling context
    resampler : TResampler;              ///< resampler virtual function table

    matrix : array[0..(SWR_CH_MAX-1), 0..(SWR_CH_MAX-1)] of Single;           ///< floating point rematrixing coefficients
    native_matrix : PByte;
    native_one : PByte;
    native_simd_one : PByte;
    native_simd_matrix : PByte;
    matrix32 : array[0..SWR_CH_MAX-1, 0..SWR_CH_MAX-1] of integer;       ///< 17.15 fixed point rematrixing coefficients
    matrix_ch : array[0..SWR_CH_MAX-1, 0..SWR_CH_MAX] of byte;    ///< Lists of input channels per output channel that have non zero rematrixing coefficients
    mix_1_1_f : TMix_1_1_func_type;
    mix_1_1_simd : TMix_1_1_func_type;

    mix_2_1_f : TMix_2_1_func_type;
    mix_2_1_simd : TMix_2_1_func_type;

    mix_any_f : TMix_any_func_type;

    (* TODO: callbacks for ASM optimizations *)
  end;


function swri_realloc_audio(a: PAudioData; count: integer): integer;
  cdecl; external LIB_SWRESAMPLE;

procedure swri_noise_shaping_int16(s: PSwrContext; dsts: PAudioData; const srcs: PAudioData; const noises: PAudioData; count: integer);
  cdecl; external LIB_SWRESAMPLE;
procedure swri_noise_shaping_int32(s: PSwrContext; dsts: PAudioData; const srcs: PAudioData; const noises: PAudioData; count: integer);
  cdecl; external LIB_SWRESAMPLE;
procedure swri_noise_shaping_float(s: PSwrContext; dsts: PAudioData; const srcs: PAudioData; const noises: PAudioData; count: integer);
  cdecl; external LIB_SWRESAMPLE;
procedure swri_noise_shaping_double(s: PSwrContext; dsts: PAudioData; const srcs: PAudioData; const noises: PAudioData; count: integer);
  cdecl; external LIB_SWRESAMPLE;

function swri_rematrix_init(s: PSwrContext): integer;
  cdecl; external LIB_SWRESAMPLE;
procedure swri_rematrix_free(s: PSwrContext);
  cdecl; external LIB_SWRESAMPLE;
function swri_rematrix(s: PSwrContext; _out: PAudioData; _in: PAudioData; len: integer; mustcopy: integer): integer;
  cdecl; external LIB_SWRESAMPLE;
function swri_rematrix_init_x86(s: PSwrContext): integer;
  cdecl; external LIB_SWRESAMPLE;

function swri_get_dither(s: PSwrContext; dst: Pointer; len: Integer; seed: Cardinal; noise_fmt: TAVSampleFormat): integer;
  cdecl; external LIB_SWRESAMPLE;

function swri_dither_init(s: PSwrContext; var out_fmt: TAVSampleFormat; in_fmt: TAVSampleFormat): integer;
  cdecl; external LIB_SWRESAMPLE;

procedure swri_audio_convert_init_aarch64(ac: PAudioConvert;
                                 var out_fmt: TAVSampleFormat;
                                 in_fmt: TAVSampleFormat;
                                 channels: integer);
  cdecl; external LIB_SWRESAMPLE;
procedure swri_audio_convert_init_arm(ac: PAudioConvert;
                                 var out_fmt: TAVSampleFormat;
                                 in_fmt: TAVSampleFormat;
                                 channels: integer);
  cdecl; external LIB_SWRESAMPLE;
procedure swri_audio_convert_init_x86(ac: PAudioConvert;
                                 var out_fmt: TAVSampleFormat;
                                 in_fmt: TAVSampleFormat;
                                 channels: integer);
  cdecl; external LIB_SWRESAMPLE;
{$endif} (* SWR_INTERNAL_H *)

