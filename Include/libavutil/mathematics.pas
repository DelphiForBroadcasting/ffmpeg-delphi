(*
 * copyright (c) 2005-2012 Michael Niedermayer <michaelni@gmx.at>
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

{$ifndef AVUTIL_MATHEMATICS_H}
  {$define AVUTIL_MATHEMATICS_H}

const
{$IFNDEF  M_E}
  M_E           = 2.7182818284590452354;   (* e *)
{$ENDIF}
{$IFNDEF  M_LN2}
  M_LN2         = 0.69314718055994530942;  (* log_e 2 *)
{$ENDIF}
{$IFNDEF  M_LN10}
  M_LN10        = 2.30258509299404568402;  (* log_e 10 *)
{$ENDIF}
{$IFNDEF  M_LOG2_10}
  M_LOG2_10     = 3.32192809488736234787;  (* log_2 10 *)
{$ENDIF}
{$IFNDEF  M_PHI}
  M_PHI         = 1.61803398874989484820;   (* phi / golden ratio *)
{$ENDIF}
{$IFNDEF  M_PI}
  M_PI          = 3.14159265358979323846;  (* pi *)
{$ENDIF}
{$IFNDEF  M_PI_2}
  M_PI_2        = 1.57079632679489661923;  (* pi/2 *)
{$ENDIF}
{$IFNDEF  M_SQRT1_2}
  M_SQRT1_2     = 0.70710678118654752440;  (* 1/sqrt(2) *)
{$ENDIF}
{$IFNDEF  M_SQRT2}
  M_SQRT2       = 1.41421356237309504880;  (* sqrt(2) *)
{$ENDIF}
{$IFNDEF  NAN}
  NAN           = $7fc00000;
{$ENDIF}
{$IFNDEF  INFINITY}
  INFINITY      = $7f800000;
{$ENDIF}


(**
 * @addtogroup lavu_math
 * @
 *)

type
  TAVRounding = (
    AV_ROUND_ZERO     = 0, ///< Round toward zero.
    AV_ROUND_INF      = 1, ///< Round away from zero.
    AV_ROUND_DOWN     = 2, ///< Round toward -infinity.
    AV_ROUND_UP       = 3, ///< Round toward +infinity.
    AV_ROUND_NEAR_INF = 5, ///< Round to nearest and halfway cases away from zero.
    AV_ROUND_PASS_MINMAX = 8192  ///< Flag to pass INT64_MIN/MAX through instead of rescaling, this avoids special cases for AV_NOPTS_VALUE
  );

(**
 * Return the greatest common divisor of a and b.
 * If both a or b are 0 or either or both are <0 then behavior is
 * undefined.
 *)
function av_gcd(a: int64; b: int64): int64;
  cdecl; external LIB_AVUTIL;

(**
 * Rescale a 64-bit integer with rounding to nearest.
 * A simple a*b/c isn't possible as it can overflow.
 *)
function av_rescale (a, b, c: int64): int64;
  cdecl; external LIB_AVUTIL; (* verified: mail@freehand.com.ua, 2014-09-05: + *)

(**
 * Rescale a 64-bit integer with specified rounding.
 * A simple a*b/c isn't possible as it can overflow.
 *
 * @return rescaled value a, or if AV_ROUND_PASS_MINMAX is set and a is
 *         INT64_MIN or INT64_MAX then a is passed through unchanged.
 *)
function av_rescale_rnd (a, b, c: int64; enum: TAVRounding): int64;
  cdecl; external LIB_AVUTIL;

(**
 * Rescale a 64-bit integer by 2 rational numbers.
 *)
function av_rescale_q (a: int64; bq, cq: TAVRational): int64;
  cdecl; external LIB_AVUTIL;

(**
 * Rescale a 64-bit integer by 2 rational numbers with specified rounding.
 *
 * @return rescaled value a, or if AV_ROUND_PASS_MINMAX is set and a is
 *         INT64_MIN or INT64_MAX then a is passed through unchanged.
 *)
function av_rescale_q_rnd(a: int64; bq, cq: TAVRational;
                          enum: integer): int64; (* verified: mail@freehand.com.ua, 2014-08-29: + *)
  cdecl; external LIB_AVUTIL;

(**
 * Compare 2 timestamps each in its own timebases.
 * The result of the function is undefined if one of the timestamps
 * is outside the int64_t range when represented in the others timebase.
 * @return -1 if ts_a is before ts_b, 1 if ts_a is after ts_b or 0 if they represent the same position
 *)
function av_compare_ts(ts_a: int64; tb_a: TAVRational; ts_b: int64; tb_b: TAVRational): integer;
  cdecl; external LIB_AVUTIL;
 
(**
 * Compare 2 integers modulo mod.
 * That is we compare integers a and b for which only the least
 * significant log2(mod) bits are known.
 *
 * @param mod must be a power of 2
 * @return a negative value if a is smaller than b
 *         a positiv  value if a is greater than b
 *         0                if a equals          b
 *)
function av_compare_mod(a: int64; b: int64; modVar: int64): int64;
  cdecl; external LIB_AVUTIL;

(**
 * Rescale a timestamp while preserving known durations.
 *
 * @param in_ts Input timestamp
 * @param in_tb Input timesbase
 * @param fs_tb Duration and *last timebase
 * @param duration duration till the next call
 * @param out_tb Output timesbase
 *)
function av_rescale_delta(in_tb: TAVRational; in_ts: int64;  fs_tb: TAVRational; duration: integer; last: PInt64; out_tb: TAVRational): int64;
  cdecl; external LIB_AVUTIL;

(**
 * Add a value to a timestamp.
 *
 * This function guarantees that when the same value is repeatly added that
 * no accumulation of rounding errors occurs.
 *
 * @param ts Input timestamp
 * @param ts_tb Input timestamp timebase
 * @param inc value to add to ts
 * @param inc_tb inc timebase
 *)
function av_add_stable(in_tb: TAVRational; ts: int64; inc_tb: TAVRational; inc: int64): int64;
  cdecl; external LIB_AVUTIL;

{$endif} (* AVUTIL_MATHEMATICS_H *)
