;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : macros.inc
; Included from: Your Program
; Description  : Macros used throughout
;
; Written by: John McCarthy
;             1316 Redwood Lane
;             Pickering, Ontario.
;             Canada, Earth, Milky Way (for those out-of-towners)
;             L1X 1C5
;
; Internet/Usenet:  BRIAN.MCCARTHY@CANREM.COM
;         Fidonet:  Brian McCarthy 1:229/15
;   RIME/Relaynet: ->CRS
;
; Home phone, (905) 831-1944, don't call at 2 am eh!
;
; John Mccarthy would really love to work for a company programming Robots
; or doing some high intensive CPU work.  Hint. Hint.
;
; Send me your protected mode source code!
; Send me your Objects!
; But most of all, Send me a postcard!!!!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

pushw    macro ww                           ; push word, used for pushing constants
         mov ax,ww
         push ax
         endm

; macro to out a 16 bit value to an i/o port

out_16   macro register, value
         ifdifi <register>, <dx>            ; if dx not setup
         mov dx, register                   ; then select register
         endif
         ifdifi <value>, <ax>               ; if ax not setup
         mov ax, value                      ; then get data value
         endif
         out dx, ax                         ; set i/o register(s)
endm

; macro to out a 8 bit value to an i/o port

out_8    macro register, value
         ifdifi <register>, <dx>            ; if dx not setup
         mov dx, register                   ; then select register
         endif
         ifdifi <value>, <al>               ; if al not setup
         mov al, value                      ; then get data value
         endif
         out dx, al                         ; set i/o register
endm

; macro to multiply by a constant - this can be done because of protected
; mode's lea function.
;
; use: cmul eax,ecx,12   eax=ecx*12
; as opposed to using imul

cmul     macro result,value,constant        ; constant multiply, use fast lea

         if constant eq 7
         lea result,[value*4+value]         ; 7 = %0111
         shl value,1
         add result,value
         cdq

         elseif constant eq 8
         lea result,[value*8]               ; 8 = %1000
         cdq

         elseif constant eq 9
         lea result,[value*8+value]         ; 9 = %1001
         cdq

         elseif constant eq 10
         shl value,1
         lea result,[value*4+value]         ; 10 = %1010
         cdq

         elseif constant eq 11
         lea result,[value*2+value]         ; 11 = %1011
         shl value,3
         add result,value
         cdq

         elseif constant eq 12
         lea result,[value*2+value]         ; 12 = %1100
         shl result,2
         cdq

         elseif constant eq 13
         lea result,[value*2+value]         ; 13 = %1101
         shl result,2
         add result,value
         cdq

         elseif constant eq 14
         lea result,[value*8]               ; 14 = %1110
         lea result,[result*2]
         sub result,value
         sub result,value
         cdq

         elseif constant eq 15
         lea result,[value*8]               ; 15 = %1111
         lea result,[result*2]
         sub result,value
         cdq

         elseif constant eq 31
         lea result,[value*8]               ; 31 = %1 1111
         lea result,[result*4]
         sub result,value
         cdq

         elseif constant eq 63
         lea result,[value*8]               ; 63 = %11 1111
         lea result,[result*8]
         sub result,value
         cdq

         elseif constant eq 80
         lea result,[value*4+value]         ; 80 = %0101 0000
         shl result,4
         cdq

         elseif constant eq 240
         shl value,4
         lea result,[value*4+value]         ; 240 = %0 1111 0000
         shl value,1
         lea value,[value*4+value]
         add result,value
         cdq

         elseif constant eq 260
         lea result,[value*4]               ; 260 = %1 0000 0100
         shl value,8
         add result,value
         cdq

         elseif constant eq 280
         shl value,3
         lea result,[value*2+value]         ; 240 = %1 0001 1000
         shl value,5
         add result,value
         cdq

         elseif constant eq 300
         shl value,2
         lea result,[value*2+value]         ; 300 = %1 0010 1100
         shl value,3
         lea value,[value*8+value]
         add result,value
         cdq

         elseif constant eq 320
         lea result,[value*4+value]         ; 320 = %1 0100 0000
         shl result,6
         cdq

         elseif constant eq 360
         shl value,3
         lea result,[value*4+value]         ; 360 = %1 0110 1000
         shl value,3
         lea value,[value*4+value]
         add result,value
         cdq

         elseif constant eq 416
         shl value,5
         lea result,[value*4+value]         ; 416 = %1 1010 0000
         shl value,3
         add result,value
         cdq

         elseif constant eq 448
         lea result,[value*8]               ; 464 = %1 1100 0000
         shl value,2
         lea value,[value*4+value]
         add result,value
         shl result,4
         cdq

         elseif constant eq 464
         lea result,[value*8+value]         ; 464 = %1 1101 0000
         shl value,2
         lea value,[value*4+value]
         add result,value
         shl result,4
         cdq

         elseif constant eq 480
         shl value,5
         lea result,[value*4+value]         ; 480 = %1 1110 0000
         shl value,1
         lea value,[value*4+value]
         add result,value
         cdq

         elseif constant eq 1440
         shl value,5
         lea result,[value*4+value]         ; 1440 = 480 * 3
         shl value,1
         lea value,[value*4+value]
         add result,value
         lea result,[result*2+result]
         cdq

         elseif constant eq 2980h
         shl value,7
         lea result,[value*2+value]         ; 2980 = %10 1001 1000 0000
         shl value,4
         lea value,[value*4+value]
         add result,value
         cdq

         elseif constant eq 2d00h
         shl value,8                        ; 2d41/4000h = cos(45degrees) = sin(45)
         lea result,[value*4+value]         ; 2d00h = %0010 1101 0000 0000
         shl value,3                        ; 2d41/2d00 = 99.2% correct!
         lea value,[value*4+value]
         add result,value
         cdq

         else
         mov result,constant
         imul value
         display "Note: Slow multiplication used in constant multiply"
         display " See cmul macro in file macros.inc"
         endif

endm

; convert 16-bit segment, 16-bit offset to 32-bit flat pointer
; ( segment, offset in 32-bit registers OR immediate values )

segoff2ptr macro ptr32, seg16, off16
         mov &ptr32, &seg16
         shl &ptr32, 4
         add &ptr32, &off16
         sub &ptr32, _code32a
         endm

; convert 32-bit flat pointer to 16-bit segment, 16-bit offset
; ( segment, offset in 32-bit registers )

ptr2segoff macro ptr32, seg16, off16
         add &ptr32, _code32a
         mov &off16, &ptr32
         and &off16, 0ffffh
         mov &seg16, &ptr32
         shr &seg16, 4
         and &seg16, 0f000h
         endm

; wait for escape key

waitesc  macro
         local lab1, lab2
lab1:    in al, 60h
         cmp al, 1
         jne lab1
lab2:    in al, 60h
         cmp al, 1
         je lab2
         endm

         b equ byte ptr
         w equ word ptr
         d equ dword ptr
         o equ offset
         s equ short

