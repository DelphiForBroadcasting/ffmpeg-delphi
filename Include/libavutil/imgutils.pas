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

 
{$ifndef AVUTIL_IMGUTILS_H}
  {$define AVUTIL_IMGUTILS_H}


  
(**
 * @file
 * misc image utilities
 *
 * @addtogroup lavu_picture
 * @{
 *)

{$INCLUDE pixdesc.pas}


(**
 * Compute the max pixel step for each plane of an image with a
 * format described by pixdesc.
 *
 * The pixel step is the distance in bytes between the first byte of
 * the group of bytes which describe a pixel component and the first
 * byte of the successive group in the same plane for the same
 * component.
 *
 * @param max_pixsteps an array which is filled with the max pixel step
 * for each plane. Since a plane may contain different pixel
 * components, the computed max_pixsteps[plane] is relative to the
 * component in the plane with the max pixel step.
 * @param max_pixstep_comps an array which is filled with the component
 * for each plane which has the max pixel step. May be NULL.
 *)


Procedure av_image_fill_max_pixsteps(max_pixsteps: TArray4Integer; max_pixstep_comps: TArray4Integer;
                                const pixdesc: PAVPixFmtDescriptor);
  cdecl; external LIB_AVUTIL;

(**
 * Compute the size of an image line with format pix_fmt and width
 * width for the plane plane.
 *
 * @return the computed size in bytes
 *)
Function av_image_get_linesize(pix_fmt: TAVPixelFormat; width, plane : integer) : integer;
  cdecl; external LIB_AVUTIL;
(**
 * Fill plane linesizes for an image with pixel format pix_fmt and
 * width width.
 *
 * @param linesizes array to be filled with the linesize for each plane
 * @return >= 0 in case of success, a negative error code otherwise
 *)
Function av_image_fill_linesizes(linesizes: TArray4Integer; pix_fmt: TAVPixelFormat; width : integer): integer;
  cdecl; external LIB_AVUTIL;
(**
 * Fill plane data pointers for an image with pixel format pix_fmt and
 * height height.
 *
 * @param data pointers array to be filled with the pointer for each image plane
 * @param ptr the pointer to a buffer which will contain the image
 * @param linesizes the array containing the linesize for each
 * plane, should be filled by av_image_fill_linesizes()
 * @return the size in bytes required for the image buffer, a negative
 * error code in case of failure
 *)
Function av_image_fill_pointers(data: PArray4PByte; pix_fmt: TAVPixelFormat; height: integer;
                           ptr : PByte; const linesizes: TArray4Integer): integer;
  cdecl; external LIB_AVUTIL;
(**
 * Allocate an image with size w and h and pixel format pix_fmt, and
 * fill pointers and linesizes accordingly.
 * The allocated image buffer has to be freed by using
 * av_freep(&pointers[0]).
 *
 * @param align the value to use for buffer size alignment
 * @return the size in bytes required for the image buffer, a negative
 * error code in case of failure
 *)
Function av_image_alloc(pointers: PArray4PByte; linesizes: PInteger {TArray4Integer};
                   w, h : integer; pix_fmt : TAVPixelFormat; align : integer): integer;
  cdecl; external LIB_AVUTIL;
(**
 * Copy image plane from src to dst.
 * That is, copy "height" number of lines of "bytewidth" bytes each.
 * The first byte of each successive line is separated by *_linesize
 * bytes.
 *
 * bytewidth must be contained by both absolute values of dst_linesize
 * and src_linesize, otherwise the function behavior is undefined.
 *
 * @param dst_linesize linesize for the image plane in dst
 * @param src_linesize linesize for the image plane in src
 *)
Procedure av_image_copy_plane(var dst: PByte; dst_linesize : integer;
                         const src : PByte; const src_linesize : integer;
                         bytewidth: integer; height: integer);
  cdecl; external LIB_AVUTIL;
(**
 * Copy image in src_data to dst_data.
 *
 * @param dst_linesizes linesizes for the image in dst_data
 * @param src_linesizes linesizes for the image in src_data
 *)
Procedure av_image_copy(dst_data: PArray4PByte; dst_linesizes: PInteger;
                   const src_data: PArray4PByte; src_linesizes: PInteger;
                   pix_fmt: TAVPixelFormat; width, height : integer);
  cdecl; external LIB_AVUTIL;


(**
 * Setup the data pointers and linesizes based on the specified image
 * parameters and the provided array.
 *
 * The fields of the given image are filled in by using the src
 * address which points to the image data buffer. Depending on the
 * specified pixel format, one or multiple image data pointers and
 * line sizes will be set.  If a planar format is specified, several
 * pointers will be set pointing to the different picture planes and
 * the line sizes of the different planes will be stored in the
 * lines_sizes array. Call with src == NULL to get the required
 * size for the src buffer.
 *
 * To allocate the buffer and fill in the dst_data and dst_linesize in
 * one call, use av_image_alloc().
 *
 * @param dst_data      data pointers to be filled in
 * @param dst_linesizes linesizes for the image in dst_data to be filled in
 * @param src           buffer which will contain or contains the actual image data, can be NULL
 * @param pix_fmt       the pixel format of the image
 * @param width         the width of the image in pixels
 * @param height        the height of the image in pixels
 * @param align         the value used in src for linesize alignment
 * @return the size in bytes required for src, a negative error code
 * in case of failure
 *)
function av_image_fill_arrays(var dst_data : PArray4PByte; dst_linesize : TArray4Integer;
                         const src: PByte;
                         pix_fmt : TAVPixelFormat; width : integer; height : integer; align : integer): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Return the size in bytes of the amount of data required to store an
 * image with the given parameters.
 *
 * @param[in] align the assumed linesize alignment
 *)
function av_image_get_buffer_size(pix_fmt : TAVPixelFormat; width : integer; height : integer; align : integer): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Copy image data from an image into a buffer.
 *
 * av_image_get_buffer_size() can be used to compute the required size
 * for the buffer to fill.
 *
 * @param dst           a buffer into which picture data will be copied
 * @param dst_size      the size in bytes of dst
 * @param src_data      pointers containing the source image data
 * @param src_linesizes linesizes for the image in src_data
 * @param pix_fmt       the pixel format of the source image
 * @param width         the width of the source image in pixels
 * @param height        the height of the source image in pixels
 * @param align         the assumed linesize alignment for dst
 * @return the number of bytes written to dst, or a negative value
 * (error code) on error
 *)
function av_image_copy_to_buffer(var dst : PByte; dst_size : integer;
                            const src_data : PArray4PByte; const src_linesize : TArray4Integer;
                            pix_fmt : TAVPixelFormat; width : integer; height : integer; align : integer): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Check if the given dimension of an image is valid, meaning that all
 * bytes of the image can be addressed with a signed int.
 *
 * @param w the width of the picture
 * @param h the height of the picture
 * @param log_offset the offset to sum to the log level for logging with log_ctx
 * @param log_ctx the parent logging context, it may be NULL
 * @return >= 0 if valid, a negative error code otherwise
 *)
Function av_image_check_size(w : cardinal; h: cardinal; log_offset : integer; log_ctx : Pointer): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Check if the given sample aspect ratio of an image is valid.
 *
 * It is considered invalid if the denominator is 0 or if applying the ratio
 * to the image size would make the smaller dimension less than 1. If the
 * sar numerator is 0, it is considered unknown and will return as valid.
 *
 * @param w width of the image
 * @param h height of the image
 * @param sar sample aspect ratio of the image
 * @return 0 if valid, a negative AVERROR code otherwise
 *)
function av_image_check_sar(w : cardinal; h : cardinal;  sar : TAVRational): integer;
  cdecl; external LIB_AVUTIL;

(**
 * @}
 *)


{$EndIf} (* AVUTIL_IMGUTILS_H *)




