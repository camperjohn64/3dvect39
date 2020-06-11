;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : font.asm
; Included from: Main assembley module
; Description  : Font and cosmetic screen handling routines.
;                This basically draws backgound screens/opening menus.
;                Have you played Red Baron or Aces of the Pacific?  It's
;                kind of like that.
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
; Send me your protected mode source code!
; Send me your Objects!
; But most of all, Send me a postcard!!!!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32, ss:code32

         include pmode.ext                  ; include externals for other modules
         include xmode.ext                  ; just in case we ever want to use them...
         include macros.inc
         include 3d.ext
         include equ.inc

         public _fnt_tstring
         public _fnt_string
         public _initfont

         public _put_at_top
         public _number_eax

newtext   equ -1
border    equ -2
fillarea  equ -3
hole      equ -4
lowercase equ -5
uppercase equ -6
steelbox  equ -7
repeatbit equ -8
textend   equ 0

wcase    db 0                               ; upper/lower case add
colt     dw 0
linecol  dw 0
tw1      dw 0
tq2      dw 0
sinewave dw 0                               ; sine wave for colour
ltflag   dw 0
brflag   dw 0
q1       dw 0
w1       dw 0
q2       dw 0
w2       dw 0
fontlen  dd 0                               ; offset to font length table

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _fnt_tstring: Display _fnt_string of font from [esi] to zero byte on both video pages
; In:
;    ESI - offset of _fnt_string to display
; Out:
;    ?
;
; eg db -1
;    dw x,y
;    db colour,"Hello",0
;
; commands:  -1 start new x,y,colour and text
;            -2 draw full border starting at x,y to x,y colour offset col
;            -3 fill within limits x,y  to x,y  colour offset col
;            -4 draw inside border from x,y to x,y colour offset col
;            -5 set lower case
;            -6 set upper case
;            -7 steel textured box
;            -8 repeated _bitmap box
;
; Fill inside full borders 3 smaller than border
; Fill inside full borders 2 smaller than border to make a "lump"
; Fill inside "hole" border 2 smaller than hole
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_fnt_tstring:
         push esi                           ; same as _fnt_string, but does
         call _fnt_string                   ; it to both sides
         call _flip_page
         pop esi
         call _fnt_string
         call _flip_page
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _fnt_string: Display _fnt_string of font from [esi] to zero byte on current video page
; In:
;    ESI - offset of _fnt_string to display
; Out:
;    ?
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_fnt_string:
         mov wcase,0                        ; default to upper case

         cld
         lodsb
         jmp testcommand
freshtext:
         lodsw
         mov bx,ax                          ; x
         lodsw
         mov cx,ax                          ; y
         mov ah,0
         lodsb
         mov dx,ax                          ; colour
textloop:
         lodsb                              ; get character/command
testcommand:
         cmp al,0
         je txnon

         cmp al,newtext                     ; -1 = 255 = set new x,y,col
         je freshtext

         cmp al,border                      ; -2 = outside border
         jne n254
         call outside
         jmp textloop                       ; ok, i should've used indirect jumps
n254:
         cmp al,fillarea                    ; fine, give me a hassle, like i need it!
         jne n253                           ; the code is done, i don't want to
         call dofill                        ; change it all now so there!
         jmp textloop
n253:
         cmp al,hole
         jne n252
         call inside
         jmp textloop
n252:
         cmp al,lowercase
         jne n251
         mov wcase,128
         jmp textloop
n251:
         cmp al,uppercase
         jne n250
         mov wcase,0
         jmp textloop
n250:
         cmp al,steelbox
         jne n249
         call steeltext
         jmp textloop
n249:
         cmp al,repeatbit
         jne n248
         call do_bitmapthingy
         jmp textloop
n248:
         add al,wcase                       ; include which case
         pusha
         char ax,bx,cx,dx
         popa
         movzx edi,ax
         add di,di
         add edi,fontlen
         add bx,[edi]                       ; inc to next position

         jmp textloop
txnon:
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _initfont: Initilize upper and lower case fonts to be used with xmode font stuff
; In:
;   ESI -> lowercase font
;   EDI -> uppercase font
;   EBP -> font length tables
; Out:
;   ?
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_initfont:
         mov fontlen,ebp

         push esi
         push edi
         pushw 0                            ; initialize _font0 block
         call _set_display_font

         pushw 1                            ; initialize _font1 block
         call _set_display_font

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Here is the implementation of some of those cheap font "commands"
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

borderd  equ 2
borderm  equ 9
borderl  equ 15

outside:
         lodsw                              ; draw outside box, get q1,w1  q2,w2
         mov q1,ax                          ; q1,w1 is top left, q2,w2 is bot right
         lodsw
         mov w1,ax
         lodsw
         mov q2,ax
         lodsw
         mov w2,ax
         lodsw
         mov colt,ax

         push esi

         mov ax,colt
         add ax,borderd+1
         mov linecol,ax
         drawline q1,w1,q1,w2,linecol       ; now draw lines, use macros
         mov ax,colt
         add ax,borderm-1
         mov linecol,ax
         drawline q1,w1,q2,w1,linecol
         mov ax,colt
         add ax,borderm+1
         mov linecol,ax
         drawline q2,w1,q2,w2,linecol
         mov ax,colt
         add ax,borderd+0
         mov linecol,ax
         drawline q1,w2,q2,w2,linecol

         inc w1                             ; bump for middle lines
         dec w2
         inc q1
         dec q2

         mov ax,colt                        ; draw middle lines
         add ax,borderl-1
         mov linecol,ax
         drawline q1,w1,q1,w2,linecol
         mov ax,colt
         add ax,borderl-2
         mov linecol,ax
         drawline q1,w1,q2,w1,linecol
         mov ax,colt
         add ax,borderl-2
         mov linecol,ax
         drawline q2,w1,q2,w2,linecol
         mov ax,colt
         add ax,borderm-1
         mov linecol,ax
         drawline q1,w2,q2,w2,linecol

         inc w1                             ; bump for inside lines
         dec w2
         inc q1
         dec q2

         mov ax,colt
         add ax,borderd+2
         mov linecol,ax
         drawline q1,w1,q1,w2,linecol       ; draw inner lines
         mov ax,colt
         add ax,borderd+1
         mov linecol,ax
         drawline q1,w1,q2,w1,linecol
         mov ax,colt
         add ax,borderd+0
         mov linecol,ax
         drawline q2,w1,q2,w2,linecol
         mov ax,colt
         add ax,borderl-2
         mov linecol,ax
         drawline q1,w2,q2,w2,linecol

         pop esi
         ret

dofill:
         lodsw                              ; fill box, get q1,w1  q2,w2
         mov q1,ax                          ; q1,w1 is top left, q2,w2 is bot right
         lodsw
         mov w1,ax
         lodsw
         mov q2,ax
         lodsw
         mov w2,ax
         lodsw
         mov colt,ax

         push esi
         block q1,w1,q2,w2,colt
         pop esi

         ret

inside:
         lodsw                              ; draw inside box, get q1,w1  q2,w2
         mov q1,ax                          ; q1,w1 is top left, q2,w2 is bot right
         lodsw
         mov w1,ax
         lodsw
         mov q2,ax
         lodsw
         mov w2,ax
         lodsw
         mov colt,ax

         push esi

         mov ax,colt
         add ax,borderm+1
         mov linecol,ax
         drawline q1,w1,q1,w2,linecol       ; now draw lines, use macros
         mov ax,colt
         add ax,borderd-1
         mov linecol,ax
         drawline q1,w1,q2,w1,linecol
         mov ax,colt
         add ax,borderd+1
         mov linecol,ax
         drawline q2,w1,q2,w2,linecol
         mov ax,colt
         add ax,borderm+2
         mov linecol,ax
         drawline q1,w2,q2,w2,linecol

         inc w1                             ; bump for inside lines
         dec w2
         inc q1
         dec q2

         mov ax,colt
         add ax,borderm+3
         mov linecol,ax
         drawline q1,w1,q1,w2,linecol       ; now draw lines, use macros
         mov ax,colt
         add ax,borderd+1
         mov linecol,ax
         drawline q1,w1,q2,w1,linecol
         mov ax,colt
         add ax,borderd+2
         mov linecol,ax
         drawline q2,w1,q2,w2,linecol
         mov ax,colt
         add ax,borderl
         mov linecol,ax
         drawline q1,w2,q2,w2,linecol

         pop esi
         ret

simplesine dw 9,10,11,12,13,14,15,15
         dw 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0,1,2,3,4,5,6,7,8

steeltext:
         mov ltflag,0                       ; make steel textured box (sin wave)
         mov brflag,0
         mov sinewave,0

         lodsw
         mov q1,ax
         mov q2,ax
         lodsw
         mov tw1,ax
         lodsw
         mov tq2,ax
         lodsw
         mov w1,ax
         mov w2,ax
         lodsw
         mov linecol,ax
         lodsw
         mov colt,ax
steel_loop:
         mov cx,colt
         add sinewave,cx
         movzx edi,sinewave
         shr di,8
         and di,32*2-2
         mov ax,simplesine[edi]
         add ax,linecol
         mov di,ax

         drawline q1,w1,q2,w2,di

         mov ax,ltflag
         cmp ax,0
         jne st_doside

         dec w1
         mov ax,w1
         cmp ax,tw1
         jne st_dopt2

         mov ltflag,1
         jmp st_dopt2
st_doside:
         inc q1
st_dopt2:
         mov ax,brflag
         cmp ax,1
         je st_doup

         inc q2
         mov ax,q2
         cmp ax,tq2
         jne st_chkout

         mov brflag,1
st_chkout:
         mov ax,q1
         cmp ax,tq2
         jna steel_loop

         ret
st_doup:
         dec w2
         jmp st_chkout

do_bitmapthingy:
         push esi
         lodsd                              ; do repeat _bitmap
         push eax                           ; push _bitmap offset (location of _bitmap)
         lodsw                              ; get _x1,_y1,_x2,_y2
         push ax
         lodsw
         push ax
         lodsw
         push ax
         lodsw
         push ax
         call _repeat_bitmap

         pop esi
         add esi,2+2+2+2+4                  ; add for next text instruction

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _put_at_top: Debugging Tool
;  In:
;    Regs - null
;    _number_eax - number to plot at top of screen
;  Out = In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_number_eax dd 0

hexs     db "0123456789ABCDEF"

top_number db -3
         dw 100,12,220,32,3
         db -1
         dw 107,20
         db 13
         db "EAX="
number   db "00000000",0

_put_at_top:
         pushad
         mov eax,_number_eax
         mov esi,7
         call set_hex
         call set_hex
         call set_hex
         call set_hex
         call set_hex
         call set_hex
         call set_hex
         call set_hex
         mov esi, o top_number
         call _fnt_string
         popad
         ret
set_hex:
         mov di,ax
         and edi,0fh
         mov bl,hexs[edi]
         mov number[esi],bl
         shr eax,4
         dec si
         ret

code32   ends
         end
