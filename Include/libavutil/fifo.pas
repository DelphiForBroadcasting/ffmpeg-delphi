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

(**
 * @file
 * a very simple circular buffer FIFO implementation
 *)

{$ifndef AVUTIL_FIFO_H}
  {$define AVUTIL_FIFO_H}
	
type
  PPAVFifoBuffer = ^PAVFifoBuffer;
  PAVFifoBuffer = ^TAVFifoBuffer;
  TAVFifoBuffer = record
    buffer 			      : PByte;
    rptr, wptr, end_  : PByte;
    rndx, wndx		    : longword;
  end;

  //callbacks used in the functions av_fifo_generic_read and av_fifo_generic_write
  TFifo_read_func  = function(ptr1: Pointer; ptr2: Pointer; int: integer): Pointer;
  TFifo_write_func = function(ptr1: Pointer; ptr2: Pointer; int: integer): integer;
  TFifo_generic_peek_func = procedure(ptr1: Pointer; ptr2: Pointer; int : integer);

(**
 * Initialize an AVFifoBuffer.
 * @param size of FIFO
 * @return AVFifoBuffer or NULL in case of memory allocation failure
 *)
function av_fifo_alloc(size: cardinal): PAVFifoBuffer;
  cdecl; external LIB_AVUTIL;

(**
 * Initialize an AVFifoBuffer.
 * @param nmemb number of elements
 * @param size  size of the single element
 * @return AVFifoBuffer or NULL in case of memory allocation failure
 *)
function av_fifo_alloc_array(nmemb: cardinal; size: cardinal): PAVFifoBuffer;
  cdecl; external LIB_AVUTIL;

(**
 * Free an AVFifoBuffer.
 * @param *f AVFifoBuffer to free
 *)
procedure av_fifo_free(f: PAVFifoBuffer);
  cdecl; external LIB_AVUTIL;

(**
 * Free an AVFifoBuffer and reset pointer to NULL.
 * @param f AVFifoBuffer to free
 *)
procedure av_fifo_freep(f: PPAVFifoBuffer);
  cdecl; external LIB_AVUTIL;

(**
 * Reset the AVFifoBuffer to the state right after av_fifo_alloc, in particular it is emptied.
 * @param *f AVFifoBuffer to reset
 *)
procedure av_fifo_reset(f: PAVFifoBuffer);
  cdecl; external LIB_AVUTIL;

(**
 * Return the amount of data in bytes in the AVFifoBuffer, that is the
 * amount of data you can read from it.
 * @param *f AVFifoBuffer to read from
 * @return size
 *)
function av_fifo_size(f: PAVFifoBuffer): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Return the amount of space in bytes in the AVFifoBuffer, that is the
 * amount of data you can write into it.
 * @param *f AVFifoBuffer to write into
 * @return size
 *)
function av_fifo_space(f: PAVFifoBuffer): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Feed data from an AVFifoBuffer to a user-supplied callback.
 * Similar as av_fifo_gereric_read but without discarding data.
 * @param f AVFifoBuffer to read from
 * @param buf_size number of bytes to read
 * @param func generic read function
 * @param dest data destination
 *)

function av_fifo_generic_peek(f: PAVFifoBuffer; dest: Pointer; buf_size: integer; func : TFifo_generic_peek_func): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Feed data from an AVFifoBuffer to a user-supplied callback.
 * @param *f AVFifoBuffer to read from
 * @param buf_size number of bytes to read
 * @param *func generic read function
 * @param *dest data destination
 *)
 //void (*func)(void*, void*, int
function av_fifo_generic_read(f: PAVFifoBuffer; dest: Pointer; buf_size: integer; func: TFifo_read_func): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Feed data from a user-supplied callback to an AVFifoBuffer.
 * @param *f AVFifoBuffer to write to
 * @param *src data source; non-const since it may be used as a
 * modifiable context by the function defined in func
 * @param size number of bytes to write
 * @param *func generic write function; the first parameter is src,
 * the second is dest_buf, the third is dest_buf_size.
 * func must return the number of bytes written to dest_buf, or <= 0 to
 * indicate no more data available to write.
 * If func is NULL, src is interpreted as a simple byte array for source data.
 * @return the number of bytes written to the FIFO
 *)
 //int (*func)(void*, void*, int)
function av_fifo_generic_write(f: PAVFifoBuffer; src: Pointer; size: integer; func: TFifo_write_func): integer;
  cdecl; external LIB_AVUTIL;


(**
 * Resize an AVFifoBuffer.
 * @param *f AVFifoBuffer to resize
 * @param size new AVFifoBuffer size in bytes
 * @return <0 for failure, >=0 otherwise
 *)
function av_fifo_realloc2(f: PAVFifoBuffer; size: cardinal): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Enlarge an AVFifoBuffer.
 * In case of reallocation failure, the old FIFO is kept unchanged.
 * The new fifo size may be larger than the requested size.
 *
 * @param f AVFifoBuffer to resize
 * @param additional_space the amount of space in bytes to allocate in addition to av_fifo_size()
 * @return <0 for failure, >=0 otherwise
 *)
function av_fifo_grow(f : PAVFifoBuffer; additional_space : cardinal): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Read and discard the specified amount of data from an AVFifoBuffer.
 * @param *f AVFifoBuffer to read from
 * @param size amount of data to read in bytes
 *)
procedure av_fifo_drain(f: PAVFifoBuffer; size: cint);
  cdecl; external LIB_AVUTIL;



{$endif} (* AVUTIL_FIFO_H *)

