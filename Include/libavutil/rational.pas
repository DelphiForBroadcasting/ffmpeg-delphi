(*
 * rational numbers
 * Copyright (c) 2003 Michael Niedermayer <michaelni@gmx.at>
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

(**
 * @file
 * rational numbers
 * @author Michael Niedermayer <michaelni@gmx.at>
 *)

{$ifndef AVUTIL_RATIONAL_H}
  {$define AVUTIL_RATIONAL_H}

type
(**
 * rational number numerator/denominator
 *)
  PAVRational = ^TAVRational;
  TAVRational = record
    num: integer; ///< numerator
    den: integer; ///< denominator
  end; (* size: x64:8, x86:8; verified: mail@freehand.com.ua; 2014-08-26: + *)

(**
 * Create a rational.
 * Useful for compilers that do not support compound literals.
 * @note  The return value is not reduced.
 *)
function av_make_q(num: integer; den: integer): TAVRational; inline;

(**
 * Compare two rationals.
 * @param a first rational
 * @param b second rational
 * @return 0 if a==b, 1 if a>b, -1 if a<b, and INT_MIN if one of the
 * values is of the form 0/0
 *)
function av_cmp_q(a: TAVRational; b: TAVRational): integer; inline;

(**
 * Convert rational to double.
 * @param a rational to convert
 * @return (double) a
 *)
function av_q2d(a: TAVRational): double; inline; (* verified: mail@freehand.com.ua, 2014-08-29: + *)

(**
 * Reduce a fraction.
 * This is useful for framerate calculations.
 * @param dst_num destination numerator
 * @param dst_den destination denominator
 * @param num source numerator
 * @param den source denominator
 * @param max the maximum allowed for dst_num & dst_den
 * @return 1 if exact, 0 otherwise
 *)
function av_reduce(dst_num: PInteger; dst_den: PInteger; num: int64; den: int64; max: int64): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Multiply two rationals.
 * @param b first rational
 * @param c second rational
 * @return b*c
 *)
function av_mul_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external LIB_AVUTIL;

(**
 * Divide one rational by another.
 * @param b first rational
 * @param c second rational
 * @return b/c
 *)
function av_div_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external LIB_AVUTIL;

(**
 * Add two rationals.
 * @param b first rational
 * @param c second rational
 * @return b+c
 *)
function av_add_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external LIB_AVUTIL;

(**
 * Subtract one rational from another.
 * @param b first rational
 * @param c second rational
 * @return b-c
 *)
function av_sub_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external LIB_AVUTIL;

(**
 * Invert a rational.
 * @param q value
 * @return 1 / q
 *)
function av_inv_q(q: TAVRational): TAVRational; inline;

(**
 * Convert a double precision floating point number to a rational.
 * inf is expressed as {1,0} or {-1,0} depending on the sign.
 *
 * @param d double to convert
 * @param max the maximum allowed numerator and denominator
 * @return (AVRational) d
 *)
function av_d2q(d: double; max: integer): TAVRational;
  cdecl; external LIB_AVUTIL;

(**
 * @return 1 if q1 is nearer to q than q2, -1 if q2 is nearer
 * than q1, 0 if they have the same distance.
 *)
function av_nearer_q(q: TAVRational; q1: TAVRational; q2: TAVRational): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Find the nearest value in q_list to q.
 * @param q_list an array of rationals terminated by {0, 0}
 * @return the index of the nearest value found in the array
 *)
function av_find_nearest_q_idx(q: TAVRational; q_list: PAVRational): integer;
  cdecl; external LIB_AVUTIL;

{$endif} (* AVUTIL_RATIONAL_H *)


