;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
; Filename     : More.inc
; Included from: Main assembley module
; Description  : Irq palette fading routines
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
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

; define externals

         include pmode.ext                  ; protected mode externals
         include irq.ext
         include macros.inc
         include equ.inc

         public _slidebytes                 ; TRAN's slide byte routine
         public _slidewords                 ; slide word routine
         public _fade_all                   ; fade palette to a common colour
         public _fade_palette               ; fade from esi to edi
         public _palette1                   ; temp storage palettes (768 bytes each)
         public _palette2
         public _sourcepal
         public _destpal
         public _fadestep
         public _fadestatus
         public _fade_palette_read          ; fade from current palette to pal at ESI
         public _wait_for_fade              ; wait for irq fade to complete
         public _get_palette                ; get palette from video card
         public _put_palette                ; put palette to video card
         public _default_palette            ; palette for DOS
         public _stop_fade

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Slide a block of bytes closer to another block in value
; In:
;   BL - max value to slide by (usually 1)
;   ECX - number of bytes to slide
;   ESI - block to slide towards
;   EDI - block to slide
; Out:
;   CF=1 - no changes made
;   CF=0 - at least one change made
; Notes: Routine courtesy of TRAN from HELL.EXE
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_slidebytes:
         pushad
         xor bh,bh
slidebytesml:
         mov al,[edi]
         mov ah,[esi]
         cmp al,ah
         je short slidebytesmlc
         mov bh,1
         jb short slidebytesmlf0
         sub ah,al
         neg ah
         cmp ah,bl
         jbe short slidebytesmlf2
         mov ah,bl
slidebytesmlf2:
         neg ah
         jmp short slidebytesmlf1
slidebytesmlf0:
         sub ah,al
         cmp ah,bl
         jbe short slidebytesmlf1
         mov ah,bl
slidebytesmlf1:
         add al,ah
         mov [edi],al
slidebytesmlc:
         inc edi
         inc esi
         loop slidebytesml
         sub bh,1
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Slide a block of words closer to another block in value
; In:
;   BX - max value to slide by (1 = really slow slide)
;   ECX - number of words to slide
;   ESI - block to slide towards
;   EDI - block to slide
; Out:
;   CF=1 - no changes made
;   CF=0 - at least one change made
; Notes: Idea courtesy of TRAN from _slidebytes
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_slidewords:
         pushad
         xor dh,dh
slidewordsml:
         mov ax,[edi]
         mov bp,[esi]
         cmp ax,bp
         je short slidewordsmlc
         mov dh,1
         jb short slidewordsmlf0
         sub bp,ax
         neg bp
         cmp bp,bx
         jbe short slidewordsmlf2
         mov bp,bx
slidewordsmlf2:
         neg bp
         jmp short slidewordsmlf1
slidewordsmlf0:
         sub bp,ax
         cmp bp,bx
         jbe short slidewordsmlf1
         mov bp,bx
slidewordsmlf1:
         add ax,bp
         mov [edi],ax
slidewordsmlc:
         add edi,2
         add esi,2
         loop slidewordsml
         sub dh,1
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Data for IRQ controlled palette fading routines
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

number_of_colours equ 256

_palette1 db number_of_colours*3 dup (0)
_palette2 db number_of_colours*3 dup (0)
_sourcepal  dd 0
_destpal    dd 0
_fadestep   dd 0
_fadestatus db 0
fadecount   db 0
irqnum      dd -1

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; _Fade_palette_read: IRQ Fade from current palette to new palette at ESI
; In:
;  ESI = palette to fade to
;   BH - how much to fade each pel        (usually 1)
;   BL - how often should fade be applied (255 = every IRQ)
; Out: null
; Notes: takes control of _irqcontrol2
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_fade_palette_read:
         call _stop_fade
         mov _fadestep,ebx

         mov edi,offset _palette2           ; get current palette from card (yeah, i know its slow)
         mov ecx,number_of_colours*3
         xor al,al
         call _get_palette

         mov edi,offset _palette2
         jmp _fade_palette

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; _Fade_all: IRQ Fade palette to a common single colour
; In:
;  EAX = colour to fade to (xx,rd,gr,bl)
;   BH - how much to fade each pel
;   BL - how often should fade be applied (1 = very slow)
; Out: null
; Notes: takes control of _irqcontrol2
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_fade_all:
         call _stop_fade
         mov _fadestep,ebx
         mov ecx,number_of_colours
         mov edi,offset _palette1
         mov bl,al
         shr eax,8
fd_lp:
         mov [edi+0],ah
         mov [edi+1],al
         mov [edi+2],bl
         add edi,3
         loop fd_lp

         mov edi,offset _palette2           ; get current palette from card (yeah, i know its slow)
         mov ecx,number_of_colours*3
         xor al,al
         call _get_palette

         mov esi,offset _palette1
         mov edi,offset _palette2
         mov ebx,_fadestep

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; _Fade_palette: Fade palette from palette ESI to palette EDI
; In:
;  ESI - palette to fade to
;  EDI - palette to fade from
;   BH - how much to fade each pel
;   BL - how often should fade be applied (255 = every IRQ)
; Out: null
; Notes: takes control of _irqcontrol2
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_fade_palette:
         pushad
         call _stop_fade

         mov _destpal,edi
         mov edi,offset _palette1           ; copy palette to modify into buffer
         mov _sourcepal,edi
         mov _fadestep,ebx

         mov ecx,number_of_colours*3
         rep movsb

         mov fadecount,0
         mov _fadestatus,-1
         call _irq_findcontrol
         mov irqnum,ecx
         mov _irqcontrol[ecx*4],offset irqfade
         popad
         ret

irqfade:
         mov al,b _fadestep
         add fadecount,al
         jnc no_changeyet

         mov esi,_sourcepal
         mov edi,_destpal
         mov bl,b _fadestep+1
         mov ecx,number_of_colours*3
         call _slidebytes
         jc no_more_fade

         cld
         mov edx,dac_write_addr
         xor al,al
         out dx,al
         mov esi,_destpal
         inc edx
         mov ecx,number_of_colours*3
         rep outsb
         ret

no_more_fade:
         call _stop_fade
         mov _fadestatus,0
no_changeyet:
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Wait for fade to complete
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_wait_for_fade:
         test _fadestatus,-1                ; wait until fade is complete
         jnz _wait_for_fade
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; _GetPal - get current palette from video card
; In:
;   EDI - destination location
;    AL - start pel
;   ECX - number of pels to get (max 768)
; Out: ?
; Notes: Listen, I know this routine is duplicated in xmode.asm but I hate
;        stack frames.
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_get_palette:
         pushad
         mov edx, dac_read_addr             ; read block of pals
         out dx, al
         mov edx, pel_data_reg

         rep insb                           ; block read dac registers
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; _PutPal - put new palette to video card
; In:
;   ESI - destination location
;    AL - start pel
;   ECX - number of pels to write (max 768)
; Out: ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_put_palette:
         pushad
         mov edx, dac_write_addr
         out dx, al
         mov edx, pel_data_reg
         rep outsb
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Stop fading
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_stop_fade:
         cmp irqnum,-1
         je _ret
         push ecx
         mov ecx,irqnum
         mov _irqcontrol[ecx*4],offset _ret
         mov irqnum,-1
         pop ecx
         ret

_default_palette label byte
         db 000h,000h,000h,000h,000h,02Ah,000h,02Ah
         db 000h,000h,02Ah,02Ah,02Ah,000h,000h,02Ah
         db 000h,02Ah,02Ah,02Ah,000h,02Ah,02Ah,02Ah
         db 000h,000h,015h,000h,000h,03Fh,000h,02Ah
         db 015h,000h,02Ah,03Fh,02Ah,000h,015h,02Ah
         db 000h,03Fh,02Ah,02Ah,015h,02Ah,02Ah,03Fh
         db 000h,015h,000h,000h,015h,02Ah,000h,03Fh
         db 000h,000h,03Fh,02Ah,02Ah,015h,000h,02Ah
         db 015h,02Ah,02Ah,03Fh,000h,02Ah,03Fh,02Ah
         db 000h,015h,015h,000h,015h,03Fh,000h,03Fh
         db 015h,000h,03Fh,03Fh,02Ah,015h,015h,02Ah
         db 015h,03Fh,02Ah,03Fh,015h,02Ah,03Fh,03Fh
         db 015h,000h,000h,015h,000h,02Ah,015h,02Ah
         db 000h,015h,02Ah,02Ah,03Fh,000h,000h,03Fh
         db 000h,02Ah,03Fh,02Ah,000h,03Fh,02Ah,02Ah
         db 015h,000h,015h,015h,000h,03Fh,015h,02Ah
         db 015h,015h,02Ah,03Fh,03Fh,000h,015h,03Fh
         db 000h,03Fh,03Fh,02Ah,015h,03Fh,02Ah,03Fh
         db 015h,015h,000h,015h,015h,02Ah,015h,03Fh
         db 000h,015h,03Fh,02Ah,03Fh,015h,000h,03Fh
         db 015h,02Ah,03Fh,03Fh,000h,03Fh,03Fh,02Ah
         db 015h,015h,015h,015h,015h,03Fh,015h,03Fh
         db 015h,015h,03Fh,03Fh,03Fh,015h,015h,03Fh
         db 015h,03Fh,03Fh,03Fh,015h,03Fh,03Fh,03Fh
         db 000h,026h,010h,012h,003h,015h,018h,000h
         db 000h,000h,00Ah,002h,026h,025h,00Fh,000h
         db 001h,02Ah,004h,026h,009h,015h,030h,000h
         db 000h,000h,026h,023h,020h,000h,000h,000h
         db 006h,005h,029h,000h,000h,000h,009h,030h
         db 021h,00Dh,033h,01Ah,026h,018h,003h,030h
         db 031h,032h,033h,034h,035h,036h,037h,038h
         db 039h,001h,002h,003h,004h,005h,006h,010h
         db 013h,011h,012h,017h,03Bh,001h,028h,001h
         db 000h,00Bh,010h,039h,008h,000h,000h,000h
         db 034h,00Fh,001h,002h,004h,00Ah,002h,024h
         db 00Fh,017h,026h,02Bh,022h,034h,01Fh,01Ah
         db 019h,01Bh,018h,003h,03Fh,000h,000h,00Ah
         db 000h,02Bh,03Dh,018h,000h,000h,000h,039h
         db 000h,00Eh,000h,000h,033h,000h,033h,02Bh
         db 003h,013h,025h,02Eh,024h,020h,02Dh,025h
         db 020h,021h,020h,030h,02Fh,033h,034h,023h
         db 021h,032h,024h,021h,00Dh,00Ah,00Dh,00Ah
         db 00Ah,02Fh,028h,02Eh,020h,00Dh,023h,003h
         db 021h,032h,034h,028h,039h,020h,034h,032h
         db 029h,025h,033h,020h,034h,02Fh,020h,022h
         db 025h,020h,021h,020h,032h,025h,027h,035h
         db 02Ch,021h,032h,020h,02Fh,02Eh,020h,004h
         db 029h,027h,029h,034h,021h,02Ch,020h,010h
         db 029h,038h,025h,02Ch,03Ah,020h,028h,034h
         db 031h,036h,029h,020h,032h,039h,038h,02Dh
         db 031h,034h,038h,037h,00Dh,00Ah,020h,020h
         db 020h,020h,020h,020h,020h,020h,020h,020h
         db 020h,020h,020h,020h,020h,020h,020h,020h
         db 020h,020h,020h,020h,020h,020h,020h,020h
         db 020h,021h,02Eh,024h,020h,02Fh,02Eh,020h
         db 034h,028h,025h,020h,014h,02Fh,032h,02Fh
         db 02Eh,034h,02Fh,020h,016h,012h,020h,013h
         db 009h,007h,03Ah,020h,028h,034h,031h,036h
         db 029h,020h,036h,033h,031h,02Dh,036h,036h
         db 032h,035h,00Dh,00Ah,00Dh,00Ah,00Fh,032h
         db 020h,037h,032h,029h,034h,025h,020h,034h
         db 02Fh,020h,034h,028h,029h,033h,020h,021h
         db 024h,024h,032h,025h,033h,033h,03Ah,00Dh
         db 00Ah,00Dh,00Ah,020h,020h,020h,020h,00Ah
         db 02Fh,028h,02Eh,020h,00Dh,023h,003h,021h
         db 032h,034h,028h,039h,00Dh,00Ah,020h,020h
         db 020h,020h,031h,033h,031h,036h,020h,012h
         db 025h,024h,037h,02Fh,02Fh,024h,020h,00Ch
         db 021h,02Eh,025h,00Dh,00Ah,020h,020h,020h
         db 020h,010h,029h,023h,02Bh,025h,032h,029h
         db 02Eh,027h,02Ch,020h,00Fh,02Eh,034h,021h
         db 032h,029h,02Fh,02Eh,00Dh,00Ah,020h,020h
         db 020h,020h,003h,021h,02Eh,021h,024h,021h
         db 02Ch,020h,005h,021h,032h,034h,028h,02Ch
         db 020h,00Dh,029h,02Ch,02Bh,039h,020h,017h
         db 021h,039h,02Eh,020h,020h,028h,026h,02Fh
         db 032h,020h,034h,028h,02Fh,033h,025h,020h
         db 02Fh,035h,034h,02Dh,02Fh,026h,02Dh,034h
         db 02Fh,037h,02Eh,025h,032h,033h,029h,00Dh
         db 00Ah,020h,020h,020h,020h,00Ch,031h,018h
         db 020h,031h,003h,035h,00Dh,00Ah,024h,03Eh
         db 000h,000h,000h,000h,03Fh,001h,00Fh,001h
         db 030h,000h,039h,003h,000h,003h,000h,03Ch
         db 001h,00Ch,001h,030h,000h,01Ch,000h,03Ch
         db 00Eh,000h,004h,000h,031h,001h,037h,001h
         db 030h,000h,03Dh,010h,000h,006h,000h,02Fh
         db 001h,035h,001h,000h,000h,000h,03Fh,023h
         db 000h,00Dh,000h,00Eh,033h,004h,020h,016h
         db 025h,023h,034h,02Fh,032h,033h,020h,029h
         db 02Eh,020h,033h,032h,030h,038h,034h,030h
         db 030h,020h,00Dh,02Fh,024h,025h,02Dh,018h
         db 03Bh,03Fh,00Fh,000h,030h,001h,00Eh,016h
         db 025h,023h,034h,02Fh,032h,020h,012h,02Fh
         db 035h,034h,029h,02Eh,025h,033h,020h,022h
         db 039h,020h,00Ah,02Fh,028h,02Eh,020h,00Dh
         db 023h,003h,021h,032h,034h,028h,039h,03Fh

code32   ends
         end
