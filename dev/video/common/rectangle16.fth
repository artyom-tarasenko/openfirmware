\ See license at end of file
purpose: Drawing functions for 16-bit graphics extension

external

code 565>argb-pixel  ( 565 -- argb )
   ax pop
   ax bx mov  d# 11 # bx shr  d# 19 # bx shl  \ Red
   ax dx mov  d# 27 # dx shl  d# 24 # dx shr  dx bx or  \ Blue
   d# 21 # ax shl  d# 26 # ax shr  d# 10 # ax shl  bx ax or
   h# ff070307 # ax or
   ax push
c;
code 565>argb  ( src dst #pixels -- )
   cx pop
   di  0 [sp]  xchg
   si  4 [sp]  xchg

   begin
      ax ax xor
      op: ax lods
      ax bx mov  d# 11 # bx shr  d# 19 # bx shl  \ Red
      ax dx mov  d# 27 # dx shl  d# 24 # dx shr  dx bx or  \ Blue
      d# 21 # ax shl  d# 26 # ax shr  d# 10 # ax shl  bx ax or
      h# ff070307 # ax or
      ax stos
   loopa

   di pop
   si pop
c;
code argb>565-pixel  ( argb -- 565 )
   ax pop
   ax bx mov  d# 19 # bx shr  d# 11 # bx shl  \ Red
   ax dx mov  d# 24 # dx shl  d# 27 # dx shr  dx bx or  \ Blue
   d# 16 # ax shl  d# 26 # ax shr  d# 5 # ax shl  bx ax or  \ Green
   ax push
c;

code argb>565  ( src dst #pixels -- )
   cx pop
   di  0 [sp]  xchg
   si  4 [sp]  xchg

   begin
      ax lods
      ax bx mov  d# 19 # bx shr  d# 11 # bx shl  \ Red
      ax dx mov  d# 24 # dx shl  d# 27 # dx shr  dx bx or  \ Blue
      d# 16 # ax shl  d# 26 # ax shr  d# 5 # ax shl  bx ax or  \ Green
      op: ax stos
   loopa

   di pop
   si pop
c;

: rectangle-setup  ( x y w h -- wb fbadr h )
   swap depth * 3 rshift swap              ( x y wbytes h )
   2swap  /scanline * frame-buffer-adr +   ( wbytes h x line-adr )
   swap depth * 3 rshift +                 ( wbytes h fbadr )
   swap                                    ( wbytes fbadr h )
;
: 565-rectangle-setup  ( x y w h -- w fbadr h )
   2swap  /scanline * frame-buffer-adr +   ( w h x line-adr )
   swap depth * 3 rshift +                 ( w h fbadr )
   swap                                    ( w fbadr h )
;
: fill-rectangle  ( color x y w h -- )
   depth d# 32 =  if                            ( color x y w h )
      2>r 2>r  565>argb-pixel  2r> 2r>          ( color' x y w h )
   then                                         ( color x y w h )

   rot /scanline *  frame-buffer-adr +          ( color x w h fbadr )
   -rot >r                                      ( color x fbadr w  r: h )
   \ The loop is inside the case for speed
   depth  case                                  ( color x fbadr w  r: h )
      \ The stack before ?do is                 ( color width-bytes fbadr h 0 )
      8     of      -rot         +  r> 0  ?do  3dup swap rot  fill  /scanline +  loop  endof
      d# 16 of  /w* -rot  swap wa+  r> 0  ?do  3dup swap rot wfill  /scanline +  loop  endof
      d# 32 of  /l* -rot  swap la+  r> 0  ?do  3dup swap rot lfill  /scanline +  loop  endof
      ( default )  r> drop nip    ( color x fbadr bytes/pixel )
   endcase                                      ( color width-bytes fbadr )
   3drop
;

: draw-rectangle  ( adr x y w h -- )
   565-rectangle-setup  0  ?do             ( adr w fbadr )
      3dup swap                            ( adr w fbadr  adr fbadr w )
      depth d# 32 =  if                    ( adr w fbadr  adr fbadr w )
         565>argb                          ( adr w fbadr )
      else                                 ( adr w fbadr  adr fbadr w )
         /w* move                          ( adr w fbadr )
      then                                 ( adr w fbadr )
      >r  tuck wa+ swap  r>                ( adr' w fbadr )
      /scanline +                          ( adr' w fbadr' )
   loop                                    ( adr' w fbadr' )
   3drop
;

defer pixel!  ( color fbadr i -- )
: 565-pixel!   ( color fbadr i -- )  wa+ w!  ;
: argb-pixel!  ( color fbadr i -- )  rot 565>argb-pixel -rot  la+ l!  ;

: draw-transparent-rectangle  ( adr x y w h -- )
   depth d# 32 =  if
      ['] argb-pixel! to pixel!
   else
      ['] 565-pixel! to pixel!
   then
   565-rectangle-setup                  ( adr w fbadr h )
   >r  rot  r>                          ( w fbadr adr h )
   0  ?do                               ( w fbadr adr )
      2 pick 0  ?do                     ( w fbadr adr )
         dup i wa+ w@                   ( w fbadr adr color )
         dup h# ffff =  if              ( w fbadr adr color )
            drop                        ( w fbadr adr )
         else                           ( w fbadr adr color )
            2 pick i pixel!             ( w fbadr adr )
         then                           ( w fbadr adr )
      loop                              ( w fbadr adr )
      swap /scanline +   swap           ( w fbadr' adr )
      third wa+                         ( w fbadr adr' )
   loop                                 ( w fbadr' adr' )
   3drop
;

: native-read-rectangle  ( adr x y w h -- )
   rectangle-setup 0  ?do                  ( adr wbytes fbadr )
      3dup -rot move                       ( adr wbytes fbadr )
      >r  tuck + swap  r>                  ( adr' wbytes fbadr )
      /scanline +                          ( adr' wbytes fbadr' )
   loop                                    ( adr' wbytes fbadr' )
   3drop
;
: read-rectangle  ( adr x y w h -- )
   565-rectangle-setup 0  ?do              ( adr w fbadr )
      3dup -rot                            ( adr w fbadr  fbadr adr w )
      depth d# 32 =  if                    ( adr w fbadr  fbadr adr w )
         argb>565                          ( adr w fbadr )
      else                                 ( adr w fbadr  fbadr adr w )
         /w* move                          ( adr w fbadr )
      then                                 ( adr w fbadr )
      >r  tuck wa+ swap  r>                ( adr' w fbadr )
      /scanline +                          ( adr' w fbadr' )
   loop                                    ( adr' w fbadr' )
   3drop
;
: dimensions  ( -- width height )  width height  ;

: replace-color  ( old new -- )
   depth d# 32 =  if
      swap 565>argb-pixel swap 565>argb-pixel  ( old' new' )
      frame-buffer-adr  width height * /l* bounds do
         over i l@ xor h# ffffff and 0=  if  dup i l!  then
      /l +loop
      2drop
   else
      frame-buffer-adr  width height * /w* bounds do
         over i w@ = if  dup i w!  then
      /w +loop
      2drop
   then
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
