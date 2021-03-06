\ See license at end of file
purpose: Common code for NAND FLASH access

h#  0 instance value total-pages   \ Start with 0 and add chips
h#  0 instance value pages/chip
h# 40 instance value pages/eblock

\ This uses byte 4 to work out the plane parameters
\ The Samsung part has this byte, but the Hynix part doesn't
: planes-auto  ( adr -- adr )
   dup 4 + c@   ( adr plane-data )
   h# 1000 over  4 rshift  7 and  lshift  ( adr plane-data pages/plane )
   1  rot 2 rshift 3 and  lshift          ( adr kbytes/plane #planes )
   *  to pages/chip        ( adr )
;

\ This uses byte 3 to work out the page and erase block sizes
: pages-auto  ( adr -- adr )
   dup 3 + c@                                 ( adr size-data )
   h#    400  over            3 and  lshift  to /page    ( adr size-data )
   h# 1.0000  swap  4 rshift  3 and  lshift  to /eblock  ( adr )
   /eblock /page / to pages/eblock
;

\ : configure-address  ( adr -- adr )
\    dup c@  case
\ \     h# 98  of  x   endof  \ Toshiba
\ \     h# 04  of  x   endof  \ Fujitsu
\ \     h# 8f  of  x   endof  \ National
\ \     h# 07  of  x   endof  \ Renesas
\ \     h# 20  of  x   endof  \ ST
\       h# ec  of  5  3  endof  \ Samsung
\       h# ad  of  5  3  endof  \ Hynix
\    endcase
\    to #erase-adr-byte  to #address-bytes
\ ;

: configure-size  ( adr -- adr )
   \ These are all 2K-page devices
   dup 1+ c@   case  ( adr device-code )
      h#  0  of  abort  endof  \ This is the result for nonexistent chips
      h# ff  of  abort  endof  \ Another likely result for nonexistent chips
      h# f2  of  h# 01.0000  endof   \ 128 MB,  1 Gbit,  64K pages
      h# f1  of  h# 02.0000  endof   \ 256 MB,  2 Gbit, 128K pages
      h# dc  of  h# 04.0000  endof   \ 512 MB,  4 Gbit, 256K pages
      h# d3  of  h# 08.0000  endof   \   1 GB,  8 Gbit, 512K pages
      h# d5  of  h# 10.0000  endof   \   2 GB, 16 Gbit,   1M pages
      ( adr device-code)
      ." Unsupported NAND FLASH device code " dup .x cr  abort
   endcase
   to pages/chip  
;  

: configure-capabilities  ( adr -- adr )
   dup 2 + c@                ( adr id3 )
   dup h# 80 and 0<> to cached-write?
   dup h# 40 and 0<> to interleave?
   4 rshift 3 and   1 swap lshift  to #simultaneous-writes
;

: configure-auto  ( adr -- adr )
   configure-capabilities
   pages-auto
   configure-size
;
: configure  ( -- okay? )
   read-id                ( adr )
   ['] configure-auto catch 0= nip
   pages/chip  total-pages +  to total-pages
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
