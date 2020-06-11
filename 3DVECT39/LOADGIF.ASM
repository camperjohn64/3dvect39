;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : Loadgif.asm
; Included from: Main Assembley Module
; Description  : Gif and LZW decoding routines.  Written based on Rich
;                Geldreich's QBasic version.
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

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

; define externals

         include pmode.ext              ; protected mode externals
         include file.ext
         include macros.inc

         public _loadgif
         public _loadgif_lzw
         public _loadgif_getdword
         public _loadgif_getword
         public _loadgif_getbyte
         public _loadgif_input

_loadgif_input dd 0
gifmem         dd 0
palettemem     dd 0
prefixmem      dd 0
numcolours     dw 0                         ; number of colours in GIF
nopalette      db 0                         ; global or local colour map
_background    db 0                         ; _background indexer in GIF
xlength        dw 0                         ; x and y size of GIF
ylength        dw 0

buflen   = 128
bufleft  dd 0                               ; number of bytes left in byte buffer
bufptr   dd 0                               ; current buffer pointer
bytebuffer db buflen dup (0)                ; buffers for load (speeds disk loading alot)

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Loadgif - simple GIF decoder
; In:
;    EDX - location of free memory to put palette and decoded GIF string
;    EAX - stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
;    ECX - temp storage for LZW prefixs (4096*2*3=24576 length)
; Out:
;   CF=1 - Error decoding file
;   CF=0 - File decoded succesfully
;    EBX - location of palette - if EBX = EDX, then there is no palette in GIF
;    ECX - length of decoded GIF   - might not equal x*y (should, but might not)
;    EDX - location of decoded GIF - first two words are x and y size
;     AX - number of colours in GIF
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_loadgif:
         mov _loadgif_input,eax
         mov gifmem,edx
         mov palettemem,edx
         mov prefixmem,ecx
kkjj:
         call _loadgif_getdword
         jc error_in_gif

         cmp eax,"8FIG"                     ; check GIF8
         jne error_in_gif

         call _loadgif_getword              ; skip "7a" part of GIF
         jc error_in_gif

         call _loadgif_getword              ; skip totalx
         jc error_in_gif

         call _loadgif_getword              ; skip totaly
         jc error_in_gif

         call _loadgif_getbyte              ; numcolours
         jc error_in_gif

         push ax

         and al,7
         mov cl,al
         inc cl
         mov ax,1
         shl ax,cl
         mov numcolours,ax

         pop ax
         and al,128
         xor al,128
         mov nopalette,al

         call _loadgif_getbyte
         jc error_in_gif
         mov _background,al

         call _loadgif_getbyte
         jc error_in_gif
         cmp al,0                           ; ? "Bad screen descriptor in GIF":end
         jne error_in_gif

         cmp nopalette,0
         jne do05

         mov cx,numcolours
         mov ax,3
         mul cx                             ; ax = numcolours*3
         movzx ecx,ax
         mov edx,gifmem
         add gifmem,ecx
         push ecx
         push edx
morepal:
         call _loadgif_getbyte
         mov [edx],al
         inc edx
         loop morepal
         pop esi
         pop ecx
         jc error_in_gif
divloop:
         shr byte ptr [esi],2               ; adjust palette from 8 bit to 6 bit
         inc esi
         loop divloop
do05:
         call _loadgif_getbyte
         jc error_in_gif
         cmp al,44
         je exitdo
         cmp al,33
         jne error_in_gif                   ; ? "Unknown extension type":end

         call _loadgif_getbyte
         jc error_in_gif
do10:
         call _loadgif_getbyte
         jc error_in_gif
         movzx ecx,al
         jcxz do05
do20:
         push ecx
         call _loadgif_getbyte
         pop ecx
         jc error_in_gif
         loop do20

         jmp do10
exitdo:
         call _loadgif_getword              ; skip image left and top
         jc error_in_gif
         call _loadgif_getword
         jc error_in_gif

         call _loadgif_getword
         jc error_in_gif
         mov xlength,ax
         call _loadgif_getword
         jc error_in_gif
         mov ylength,ax

         call _loadgif_getbyte
         jc error_in_gif
         test al,128+64
         jnz error_in_gif                   ; ? "Can't handle local colormaps or interlaced GIFs":end

         mov edx,gifmem
         mov ax,xlength                     ; set x and y size as first two words in decoded file
         mov [edx],ax
         mov ax,ylength
         mov [edx+2],ax

         add edx,4
         mov eax,_loadgif_input
         mov ecx,prefixmem
         call _loadgif_lzw

         mov edx,gifmem
         mov ebx,palettemem
         mov ax,numcolours
         ret

error_in_gif:
         mov bufleft,0
         mov bufptr,0
         stc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Decode_LZW - simple LZW decoder
; In:
;    ECX - temp storage for LZW prefixs (4096*2*3=24576 length)
;    EDX - memory location for decoded file
;    EAX - stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
; Out:
;   CF=1 - Error decoding file
;   CF=0 - File decoded succesfully
;    ECX - length of decoded file
;    EDX - memory location of decoded file
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

clearcode     dd 0
eoscode       dd 0
firstcode     dd 0
nextcode      dd 0
startmaxcode  dd 0
maxcode       dd 0
startcodesize dd 0
codesize      dd 0
curcode       dd 0
lastcode      dd 0
lastpixel     dd 0
lastchar      dd 0
stackpointer  dd 0
codex         dd 0

bitsin        dd 0
blocksize     dd 0
blockpointer  dd 0
decodemem     dd 0
decodememsav  dd 0

prefix   dd 0
suffix   dd 0
outstack dd 0
ybase    dd 0
workcode dd 0
spaces   db 256 dup (0)

_loadgif_lzw:
         mov _loadgif_input,eax
         mov decodemem,edx
         mov decodememsav,edx               ; save starting code location

         mov prefix,ecx
         add ecx,4096*2
         mov suffix,ecx
         add ecx,4096*2
         mov outstack,ecx

         call init_decode
         jc error_in_decode

         call decode0
         jc error_in_decode

         mov edx,decodememsav
         mov ecx,decodemem
         sub ecx,edx
         clc
         mov bufleft,0
         mov bufptr,0
         ret

error_in_decode:
         mov bufleft,0
         mov bufptr,0
         stc
         ret

shiftout dd 128
         dd 64
         dd 32
         dd 16
         dd 8
         dd 4
         dd 2
         dd 1

powersof2 dd 1
         dd 2
         dd 4
         dd 8
         dd 16
         dd 32
         dd 64
         dd 128
         dd 256
         dd 512
         dd 1024
         dd 2048

init_decode:
         call _loadgif_getbyte
         jc error_in_decode
         mov edx,eax
         mov eax,powersof2[eax*4]
         mov clearcode,eax
         mov eoscode,eax
         add eoscode,1
         mov firstcode,eax
         add firstcode,2
         mov nextcode,eax
         add nextcode,2
         mov startcodesize,edx
         inc startcodesize
         mov codesize,edx
         inc codesize
         mov ebx,powersof2[edx*4+4]
         dec ebx
         mov startmaxcode,ebx
         mov maxcode,ebx

         mov bitsin,0
         mov blocksize,0
         mov blockpointer,1

         ret
decode0:
         call getcode
         jc error_in_decode

         mov eax,codex
         cmp eax,eoscode
         je end_of_decode

         mov eax,codex
         cmp eax,clearcode
         jne else0

         mov ebx,firstcode
         mov nextcode,ebx
         mov ebx,startcodesize
         mov codesize,ebx
         mov ebx,startmaxcode
         mov maxcode,ebx
         call getcode
         jc error_in_decode
         mov eax,codex
         mov curcode,eax
         mov lastcode,eax
         mov lastpixel,eax

         mov edx,decodemem
         mov [edx],al
         inc decodemem

         jmp level0

else0:
         mov curcode,eax
         mov stackpointer,0

         cmp eax,nextcode
         ja error_in_decode
         jne dowhile1

         mov ebx,lastcode
         mov curcode,ebx

         mov ecx,stackpointer
         mov ebx,lastpixel
         mov edi,outstack
         mov [edi+ecx*2],bx                 ; outstack(stackpointer)=lastpixel

         inc stackpointer

dowhile1:
         mov ebx,curcode
         cmp ebx,firstcode
         jl doneloop1

         mov ebp,curcode
         mov edi,suffix
         mov bx,[ebp*2+edi]
         mov ebp,stackpointer
         mov edi,outstack
         mov [edi+ebp*2],bx

         inc stackpointer

         mov ebp,curcode
         mov edi,prefix
         xor ebx,ebx
         mov bx,[ebp*2+edi]
         mov curcode,ebx

         jmp dowhile1

doneloop1:
         mov ebx,curcode
         mov lastpixel,ebx

         mov ebx,lastpixel
         mov edi,decodemem
         mov [edi],bl
         inc decodemem

         mov ecx,stackpointer
         dec ecx
         cmp ecx,-1
         je outfornext

fornextloop:
         mov esi,outstack
         mov bx,[esi+ecx*2]
         mov edi,decodemem
         mov [edi],bl
         inc decodemem

         dec ecx
         cmp ecx,-1
         jne fornextloop

outfornext:
         cmp nextcode,4096
         jae endif2

         mov ebx,lastcode
         mov ecx,nextcode
         mov edi,prefix
         mov [edi+ecx*2],bx
         mov ebx,lastpixel
         mov edi,suffix
         mov [edi+ecx*2],bx

         inc nextcode

         cmp codesize,12
         jae endif2

         mov ecx,nextcode
         cmp ecx,maxcode
         jbe endif2

         inc codesize
         shl maxcode,1
         inc maxcode
endif2:

         mov ebx,codex
         mov lastcode,ebx

level0:
         mov eax,codex
         cmp eax,eoscode
         jne decode0

end_of_decode:
         clc
         ret

getcode:
         cmp bitsin,0
         jne nogetbuf

         call getbufferedbyte
         jc error_in_decode

         mov lastchar,eax
         mov bitsin,8
nogetbuf:
         mov edx,bitsin
         mov ecx,shiftout[edx*4-4]
         mov eax,lastchar
         cdq
         div ecx
         mov workcode,eax
dowhile3:
         mov eax,codesize
         cmp eax,bitsin
         jle exitdo2

         call getbufferedbyte
         jc error_in_decode

         mov lastchar,eax

         mov ecx,bitsin
         mov ebx,powersof2[ecx*4]
         mul ebx
         or workcode,eax

         add bitsin,8
         jmp dowhile3

exitdo2:
         mov eax,codesize
         sub bitsin,eax

         mov eax,maxcode
         and eax,workcode
         mov codex,eax

         clc
         ret

getbufferedbyte:
         mov eax,blockpointer
         cmp eax,blocksize
         jle endif3

         call _loadgif_getbyte
         jc error_in_decode

         mov blocksize,eax

         mov ecx,eax
         mov edx,offset spaces
getmorepal:
         call _loadgif_getbyte
         mov [edx],al
         inc edx
         loop getmorepal

         mov blockpointer,1
endif3:
         xor eax,eax
         mov ecx,blockpointer
         mov al,spaces[ecx-1]
         inc blockpointer
         clc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Getdword - get dword from open file (self buffered)
; Getword  - get  word from open file (self buffered)
; Getbyte  - get  byte from open file (self buffered)
;
; In:
;    _loadgif_input - stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
; Out:
;   CF=1 - Error reading file
;     EAX - ?
;   CF=0 - Read went fine
;     EAX - dword from file
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_loadgif_getdword:
         push ecx
         xor ecx,ecx
         call _loadgif_getbyte
         jc retpopx
         mov cl,al
         call _loadgif_getbyte
         jc retpopx
         mov ch,al
         call _loadgif_getbyte
         jc retpopx
         shl eax,16
         or ecx,eax
         call _loadgif_getbyte
         jc retpopx
         shl eax,24
         or eax,ecx
         pop ecx
         ret

_loadgif_getword:
         push ecx
         xor ecx,ecx
         call _loadgif_getbyte
         jc retpopx
         mov cl,al
         call _loadgif_getbyte
         jc retpopx
         mov ch,al
         mov ax,cx
retpopx:
         pop ecx
         ret

_loadgif_getbyte:
         dec bufleft
         cmp bufleft,0
         jg gb_ok
         push ecx edx
         mov edx,offset bytebuffer
         mov ecx,buflen
         mov bufptr,0
         call [_loadgif_input]
         mov bufleft,ecx
         pop edx ecx
gb_ok:
         mov eax,bufptr
         movzx eax,byte ptr bytebuffer[eax]
         inc bufptr
         clc
         ret

code32   ends
         end
