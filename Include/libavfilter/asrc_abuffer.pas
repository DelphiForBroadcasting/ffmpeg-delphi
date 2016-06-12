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

{$ifndef AVFILTER_ASRC_ABUFFER_H}
  {$define AVFILTER_ASRC_ABUFFER_H}


(**
 * @file
 * memory buffer source for audio
 *
 * @deprecated use buffersrc.h instead.
 *)

(**
 * Queue an audio buffer to the audio buffer source.
 *
 * @param abuffersrc audio source buffer context
 * @param data pointers to the samples planes
 * @param linesize linesizes of each audio buffer plane
 * @param nb_samples number of samples per channel
 * @param sample_fmt sample format of the audio data
 * @param ch_layout channel layout of the audio data
 * @param planar flag to indicate if audio data is planar or packed
 * @param pts presentation timestamp of the audio buffer
 * @param flags unused
 *
 * @deprecated use av_buffersrc_add_ref() instead.
 *)
function av_asrc_buffer_add_samples(abuffersrc: PAVFilterContext;
                               data: P8PByteArray; linesize : T8IntegerArray;
                               nb_samples: integer; sample_rate: integer;
                               sample_fmt: integer; ch_layout: int64; planar: integer;
                               pts : int64; flags: integer = 0): integer; deprecated 'use av_buffersrc_add_ref() instead';
    cdecl; external LIB_AVFILTER;

(**
 * Queue an audio buffer to the audio buffer source.
 *
 * This is similar to av_asrc_buffer_add_samples(), but the samples
 * are stored in a buffer with known size.
 *
 * @param abuffersrc audio source buffer context
 * @param buf pointer to the samples data, packed is assumed
 * @param size the size in bytes of the buffer, it must contain an
 * integer number of samples
 * @param sample_fmt sample format of the audio data
 * @param ch_layout channel layout of the audio data
 * @param pts presentation timestamp of the audio buffer
 * @param flags unused
 *
 * @deprecated use av_buffersrc_add_ref() instead.
 *)
function av_asrc_buffer_add_buffer(abuffersrc: PAVFilterContext;
                              buf: PByte; buf_size: integer;
                              sample_rate: integer;
                              sample_fmt: integer; ch_layout: int64; planar: integer;
                              pts : int64; flags: integer = 0): integer; deprecated 'use av_buffersrc_add_ref() instead'
    cdecl; external LIB_AVFILTER;

(**
 * Queue an audio buffer to the audio buffer source.
 *
 * @param abuffersrc audio source buffer context
 * @param samplesref buffer ref to queue
 * @param flags unused
 *
 * @deprecated use av_buffersrc_add_ref() instead.
 *)
function av_asrc_buffer_add_audio_buffer_ref(abuffersrc: PAVFilterContext;
                                        samplesref: PAVFilterBufferRef;
                                         flags: integer = 0): integer; deprecated 'use av_buffersrc_add_ref() instead';
     cdecl; external LIB_AVFILTER;

{$endif} (* AVFILTER_ASRC_ABUFFER_H *)
