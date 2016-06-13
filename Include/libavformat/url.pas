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

(**
 * @file
 * unbuffered private I/O API
 *)

{$ifndef AVFORMAT_URL_H}
{$define AVFORMAT_URL_H}

const
  URL_PROTOCOL_FLAG_NESTED_SCHEME = 1; (*< The protocol name can be the first part of a nested protocol scheme *)
  URL_PROTOCOL_FLAG_NETWORK       = 2; (*< The protocol uses network *)

//extern const AVClass ffurl_context_class;

type
  PURLProtocol = ^TURLProtocol;
  PPURLContext = ^PURLContext;
  PURLContext = ^TURLContext;
  TURLContext = record
    av_class : PAVClass;    (**< information for av_log(). Set by url_open(). *)
    prot : PURLProtocol;
    priv_data : Pointer;
    filename : PAnsiChar;             (**< specified URL *)
    flags : integer;
    max_packet_size : integer;        (**< if non zero, the stream is packetized with this max packet size *)
    is_streamed : integer;            (**< true if streamed (no seek possible), default = false *)
    is_connected : integer;
    interrupt_callback: TAVIOInterruptCB;
    rw_timeout: int64;         (**< maximum time to wait for (network) read/write operation completion, in mcs *)
  end;

  TURLProtocol = record
    name : PAnsiChar;
    url_open : function(h :PURLContext; const url: PAnsiChar; flags: integer): integer; cdecl;
    (**
     * This callback is to be used by protocols which open further nested
     * protocols. options are then to be passed to ffurl_open()/ffurl_connect()
     * for those nested protocols.
     *)
    url_open2 : function(h :PURLContext; const url: PAnsiChar; flags: integer; var options: PAVDictionary): integer; cdecl;
    url_accept : function(h :PURLContext; var c :PURLContext): integer; cdecl;
    url_handshake : function(c :PURLContext): integer; cdecl;

    (**
     * Read data from the protocol.
     * If data is immediately available (even less than size), EOF is
     * reached or an error occurs (including EINTR), return immediately.
     * Otherwise:
     * In non-blocking mode, return AVERROR(EAGAIN) immediately.
     * In blocking mode, wait for data/EOF/error with a short timeout (0.1s),
     * and return AVERROR(EAGAIN) on timeout.
     * Checking interrupt_callback, looping on EINTR and EAGAIN and until
     * enough data has been read is left to the calling function; see
     * retry_transfer_wrapper in avio.c.
     *)
    url_read : function(h :PURLContext; buf: PAnsiChar; size: integer): integer; cdecl;
    url_write : function(h :PURLContext; buf: PAnsiChar; size: integer): integer; cdecl;
    url_seek : function(h :PURLContext; pos: int64; whence: integer): int64; cdecl;
    url_close : function(h :PURLContext): integer; cdecl;
    next : PURLProtocol;

    url_read_pause : function(h :PURLContext; pause: integer): integer; cdecl;
    url_read_seek : function(h :PURLContext; stream_index: integer;
                              timestamp: int64; flags: integer) : int64; cdecl;
    url_get_file_handle : function(h :PURLContext): integer; cdecl;
    url_get_multi_file_handle : function(h :PURLContext; var handles: PInteger;
                                        numhandles: PInteger): integer; cdecl;
    url_shutdown : function(h :PURLContext; flags: integer): integer; cdecl;
    priv_data_size: integer;
    priv_data_class: PAVClass;
    flags: integer;
    url_check : function(h :PURLContext; mask: integer): integer; cdecl;
    url_open_dir : function(h :PURLContext): integer; cdecl;
    url_read_dir : function(h :PURLContext; var next: PAVIODirEntry): integer; cdecl;
    url_close_dir : function(h :PURLContext): integer; cdecl;
    url_delete : function(h :PURLContext): integer; cdecl;
    url_move : function(h_src :PURLContext; h_dst: PURLContext): integer; cdecl;
  end;

(**
 * Create a URLContext for accessing to the resource indicated by
 * url, but do not initiate the connection yet.
 *
 * @param puc pointer to the location where, in case of success, the
 * function puts the pointer to the created URLContext
 * @param flags flags which control how the resource indicated by url
 * is to be opened
 * @param int_cb interrupt callback to use for the URLContext, may be
 * NULL
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR code in case of failure
 *)
function ffurl_alloc(var puc: PURLContext; const filename: PAnsiChar; flags: integer;
                int_cb: PAVIOInterruptCB): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Connect an URLContext that has been allocated by ffurl_alloc
 *
 * @param options  A dictionary filled with options for nested protocols,
 * i.e. it will be passed to url_open2() for protocols implementing it.
 * This parameter will be destroyed and replaced with a dict containing options
 * that were not found. May be NULL.
 *)
function ffurl_connect(uc: PURLContext; var options: PAVDictionary): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Create an URLContext for accessing to the resource indicated by
 * url, and open it.
 *
 * @param puc pointer to the location where, in case of success, the
 * function puts the pointer to the created URLContext
 * @param flags flags which control how the resource indicated by url
 * is to be opened
 * @param int_cb interrupt callback to use for the URLContext, may be
 * NULL
 * @param options  A dictionary filled with protocol-private options. On return
 * this parameter will be destroyed and replaced with a dict containing options
 * that were not found. May be NULL.
 * @return >= 0 in case of success, a negative value corresponding to an
 * AVERROR code in case of failure
 *)
function ffurl_open(var puc: PURLContext; filename: PAnsiChar; flags: integer;
               int_cb: PAVIOInterruptCB; var options: PAVDictionary): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Accept an URLContext c on an URLContext s
 *
 * @param  s server context
 * @param  c client context, must be unallocated.
 * @return >= 0 on success, ff_neterrno() on failure.
 *)
function ffurl_accept(s: PURLContext; var c: PURLContext): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Perform one step of the protocol handshake to accept a new client.
 * See avio_handshake() for details.
 * Implementations should try to return decreasing values.
 * If the protocol uses an underlying protocol, the underlying handshake is
 * usually the first step, and the return value can be:
 * (largest value for this protocol) + (return value from other protocol)
 *
 * @param  c the client context
 * @return >= 0 on success or a negative value corresponding
 *         to an AVERROR code on failure
 *)
function ffurl_handshake(c: PURLContext): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Read up to size bytes from the resource accessed by h, and store
 * the read bytes in buf.
 *
 * @return The number of bytes actually read, or a negative value
 * corresponding to an AVERROR code in case of error. A value of zero
 * indicates that it is not possible to read more from the accessed
 * resource (except if the value of the size argument is also zero).
 *)
function ffurl_read(h: PURLContext; buf: PAnsiChar; size: integer): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Read as many bytes as possible (up to size), calling the
 * read function multiple times if necessary.
 * This makes special short-read handling in applications
 * unnecessary, if the return value is < size then it is
 * certain there was either an error or the end of file was reached.
 *)
function ffurl_read_complete(h: PURLContext; buf: PAnsiChar; size: integer): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Write size bytes from buf to the resource accessed by h.
 *
 * @return the number of bytes actually written, or a negative value
 * corresponding to an AVERROR code in case of failure
 *)
function ffurl_write(h: PURLContext; buf: PAnsiChar; size: integer): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Change the position that will be used by the next read/write
 * operation on the resource accessed by h.
 *
 * @param pos specifies the new position to set
 * @param whence specifies how pos should be interpreted, it must be
 * one of SEEK_SET (seek from the beginning), SEEK_CUR (seek from the
 * current position), SEEK_END (seek from the end), or AVSEEK_SIZE
 * (return the filesize of the requested resource, pos is ignored).
 * @return a negative value corresponding to an AVERROR code in case
 * of failure, or the resulting file position, measured in bytes from
 * the beginning of the file. You can use this feature together with
 * SEEK_CUR to read the current file position.
 *)
function ffurl_seek(h: PURLContext; pos: int64; whence: integer): int64;
  cdecl; external LIB_AVFORMAT;

(**
 * Close the resource accessed by the URLContext h, and free the
 * memory used by it. Also set the URLContext pointer to NULL.
 *
 * @return a negative value if an error condition occurred, 0
 * otherwise
 *)
function ffurl_closep(h: PPURLContext): integer;
  cdecl; external LIB_AVFORMAT;
function ffurl_close(h: PURLContext): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Return the filesize of the resource accessed by h, AVERROR(ENOSYS)
 * if the operation is not supported by h, or another negative value
 * corresponding to an AVERROR error code in case of failure.
 *)
function ffurl_size(h: PURLContext): int64;
  cdecl; external LIB_AVFORMAT;

(**
 * Return the file descriptor associated with this URL. For RTP, this
 * will return only the RTP file descriptor, not the RTCP file descriptor.
 *
 * @return the file descriptor associated with this URL, or <0 on error.
 *)
function ffurl_get_file_handle(h: PURLContext): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Return the file descriptors associated with this URL.
 *
 * @return 0 on success or <0 on error.
 *)
function ffurl_get_multi_file_handle(h: PURLContext; var handles: PInteger; numhandles: PInteger): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Signal the URLContext that we are done reading or writing the stream.
 *
 * @param h pointer to the resource
 * @param flags flags which control how the resource indicated by url
 * is to be shutdown
 *
 * @return a negative value if an error condition occurred, 0
 * otherwise
 *)
function ffurl_shutdown(h: PURLContext; flags: integer): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Register the URLProtocol protocol.
 *)
function ffurl_register_protocol(protocol: PURLProtocol): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Check if the user has requested to interrup a blocking function
 * associated with cb.
 *)
function ff_check_interrupt(cb: PAVIOInterruptCB): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Iterate over all available protocols.
 *
 * @param prev result of the previous call to this functions or NULL.
 *)
function ffurl_protocol_next(prev: PURLProtocol): PURLProtocol;
  cdecl; external LIB_AVFORMAT;

(* udp.c *)
function ff_udp_set_remote_url(h: PURLContext; uri: PAnsiChar): integer;
  cdecl; external LIB_AVFORMAT;
function ff_udp_get_local_port(h: PURLContext): integer;
  cdecl; external LIB_AVFORMAT;

(**
 * Assemble a URL string from components. This is the reverse operation
 * of av_url_split.
 *
 * Note, this requires networking to be initialized, so the caller must
 * ensure ff_network_init has been called.
 *
 * @see av_url_split
 *
 * @param str the buffer to fill with the url
 * @param size the size of the str buffer
 * @param proto the protocol identifier, if null, the separator
 *              after the identifier is left out, too
 * @param authorization an optional authorization string, may be null.
 *                      An empty string is treated the same as a null string.
 * @param hostname the host name string
 * @param port the port number, left out from the string if negative
 * @param fmt a generic format string for everything to add after the
 *            host/port, may be null
 * @return the number of characters written to the destination buffer
 *)
function ff_url_join(str: PAnsiChar; size: Integer; const proto: PAnsiChar;
                const authorization: PAnsiChar; const hostname: PAnsiChar;
                port: Integer; const fmt: PAnsiChar): Integer; varargs;
  cdecl; external LIB_AVFORMAT;

(**
 * Convert a relative url into an absolute url, given a base url.
 *
 * @param buf the buffer where output absolute url is written
 * @param size the size of buf
 * @param base the base url, may be equal to buf.
 * @param rel the new url, which is interpreted relative to base
 *)
procedure ff_make_absolute_url(buf: PAnsiChar; size: integer; const base: PAnsiChar;
                          const rel: PAnsiChar);
  cdecl; external LIB_AVFORMAT;

(**
 * Allocate directory entry with default values.
 *
 * @return entry or NULL on error
 *)
function ff_alloc_dir_entry(): PAVIODirEntry;
  cdecl; external LIB_AVFORMAT;

{$endif} (* AVFORMAT_URL_H *)
