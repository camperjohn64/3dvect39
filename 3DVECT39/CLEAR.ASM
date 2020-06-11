;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : Clear.asm
; Included from: Main Assembley module
; Description  : Screen clearing routines and Bitmap compilation routines
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

         include pmode.ext                  ; protected mode externals by TRAN
         include 3d.ext

         include macros.inc
         include equ.inc

         public _compile_foreground
         public _compile_background_dl
         public _compile_xy
         public _gif_squeeze_y
         public _gif_squeeze_x

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _Compile_background_dl:  Generate clear compiled bitmap, colour=dl
; In:
;  Regs:
;    DL - colour to write for "blank", usually 0
;   EBP => available memory - crashes if not enough.
;  Memory:
;   _cliptp - clipping parameters
;   _clipbt
;   _cliplt
;   _cliprt
;
; Out:
;  EBP => location for "clear" routine
;  EDI => next available location in memory (after ret function, ready for stosb)
;
; Notes:
;  The X clipping parameters must be aligned by 4 pixels. eg: 160,164,168...
;  are valid clipping borders.  This is only neccessary on the X axis.
;
;  When calling the resulting compiled routine, EDI must point to the
;  current video page.  eg mov edi,_current_page   call ebp
;
;  66 BA C5 03 B0 0F EE
;  out_8 sc_data, all_planes   ; write to all planes
;
;  66 BA C5 03 B0 xx EE
;  out_8 sc_data, xx           ; write to selective plane (1,2,4,8)
;
;  66 C7 87 DD CC BB AA 22 11
;  mov word ptr [edi+0aabbccddh],1122h
;
;  C6 87 DD CC BB AA 11
;  mov byte ptr [edi+0aabbccddh],11h
;
;  C7 87 DD CC BB AA 44 33 22 11
;  mov dword ptr [edi+0aabbccddh],11223344h
;
;  C3
;  ret
;
;  89 87 44 33 22 11
;  mov [edi+11223344h],eax
;
;  33 C0
;  xor eax,eax
;
;  D1 E9
;  shr ecx,1
;
;  B8 12 12 12 12
;  mov eax,12121212h
;
;  88 87 44 33 22 11
;  mov [edi+11223344h],al
;
;  66 89 87 44 33 22 11
;  mov [edi+11223344h],ax
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

tempqx   dd 0
tempqy   dd 0
j        dd 0
i        dd 0
trash    dd 0

_compile_background_dl:
         mov trash,0
         mov edi,ebp

         mov esi,offset macro0 ; set out_8 all_planes
         mov ecx, 7
         rep movsb

         mov esi,offset macro9 ; set mov eax,colour
         mov ecx,1
         rep movsb

         mov al,dl             ; set colour
         mov ecx,4
         rep stosb

         xor eax,eax
         mov i,eax
         mov ax,_ymaxs
         sub ax,_ymins
         mov tempqy,eax
cb_bc_loop1:
         xor eax,eax
         mov j,eax
         mov ax,_xmaxs
         sub ax,_xmins
         shr eax,4             ; /4/4
         mov tempqx,eax
cb_bc_loop2:
         cmp tempqx,0
         je cb_nobiglines

         xor eax,eax
         mov ax,_ycent
         add ax,_ymins
         cmul ebx,eax,xactual
         shr ebx,2
         add ebx,j

         mov ax,_xcent
         add ax,_xmins
         shr eax,2
         add ebx,eax

         mov ecx,i
         cmul eax,ecx,xactual
         shr eax,2
         add ebx,eax

         test ebx,1
         jz cb_noalign

         mov esi,offset macroa ; set mov [edi+12345678h],al
         mov ecx,2
         rep movsb

         mov eax,ebx
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb

         mov trash,1

         xor eax,eax
         mov j,eax
         mov ax,_xmaxs
         sub ax,_xmins
         sub eax,4
         shr eax,4             ; /4/4
         mov tempqx,eax
         inc j
         jmp cb_bc_loop2

cb_noalign:
         mov esi,offset macro6 ; set mov [edi+12345678h],eax
         mov ecx,2
         rep movsb

         mov eax,ebx
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb

         add j,4

         dec tempqx
         jnz cb_bc_loop2

cb_nobiglines:
         mov cx,_xmaxs
         sub cx,_xmins
         sub cx,w trash
         test cx,8+4
         jz cb_noextra

         xor eax,eax
         mov ax,_ycent
         add ax,_ymins
         cmul ebx,eax,xactual
         shr ebx,2
         add ebx,j

         mov ax,_xcent
         add ax,_xmins
         shr eax,2
         add ebx,eax

         mov esi,i
         cmul eax,esi,xactual
         shr eax,2
         add eax,ebx
         mov ebx,eax

         test cx,8
         jz cb_no8

         push cx
         mov esi,offset macrob ; set mov word ptr [edi+12345678h],ax
         mov ecx,3
         rep movsb

         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb

         add ebx,2
         pop cx
cb_no8:
         test cx,4
         jz cb_noextra

         mov esi,offset macroa ; set mov [edi+12345678h],eax
         mov ecx,2
         rep movsb

         mov eax,ebx
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb
cb_noextra:

         inc i
         dec tempqy
         jnz cb_bc_loop1

         mov al,macro5
         stosb

         ret

macro0 db 066h,0BAh,0C5h,003h,0B0h,00Fh,0EEh            ; out_8 sc_data, all_planes
macro1 db 066h,0BAh,0C5h,003h,0B0h,000h,0EEh            ; out_8 sc_data, xx - write to selective plane (1,2,4,8)
macro2 db 066h,0C7h,087h,0DDh,0CCh,0BBh,0AAh,022h,011h  ; mov word ptr [edi+0aabbccddh],1122h
macro3 db 0C6h,087h,0DDh,0CCh,0BBh,0AAh,011h            ; mov byte ptr [edi+0aabbccddh],11h
macro4 db 0C7h,087h,0DDh,0CCh,0BBh,0AAh,044h,033h,022h,011h ; mov dword ptr [edi+0aabbccddh],11223344h
macro5 db 0C3h                          ; ret
macro6 db 089h,087h,044h,033h,022h,011h ; mov [edi+11223344h],eax
macro7 db 033h,0C0h                     ; xor eax,eax
macro8 db 0D1h,0E9h                     ; shr ecx,1
macro9 db 0B8h,012h,012h,012h,012h      ; mov eax,12121212h
macroa db 088h,087h,044h,033h,022h,011h ; mov [edi+11223344h],al
macrob db 066h,089h,087h,044h,033h,022h,011h ; mov [edi+11223344h],ax

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _Compile_foreground: Generate compiled bitmap for bitmap pointed to by EDX
; In:
;  Regs:
;   EAX => bitmap offset  (first 2 words are bitmap x,y)
;    BX - x start for bitmap
;    CX - y start for bitmap
;    DL - colour to consider for "blank", usually 0 (anything lower = blank)
;   EBP => available memory - crashes if not enough.
;  Memory:
;   _cliptp - clipping parameters
;   _clipbt
;   _cliplt
;   _cliprt
;
; Out:
;  EBP => location for routine
;  EDI => next free memory location
;
; Notes:
;  When calling the resulting compiled routine, EDI must point to the
;  current video page.  eg mov edi,_current_page   call ebp
;
; Resulting routine needs:
;
;  EDI => screen offset
;  EAX => port mask for starting plane, eg: al = 1,2,4, or 8
;
; eg:
;  mov edi,_current_page
;  mov al,1
;  call [ebp]
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

poctor   dd 0  ; top left of bitmap
pik      dd 0  ; current column of bitmap (offset)
xlen     dw 0  ; xlength, ylength
ylen     dw 0
xtemp    dw 0  ; length counters
ytemp    dw 0
membash  dd 0  ; pointer to start of memory
xtop     dw 0  ; where is bitmap on screen
ytop     dw 0
yreal    dw 0
xreal    dw 0
blank    db 0
count4   db 0
ddr      dd 0
ddn      dd 0

_compile_foreground:
         mov xtop,bx
         mov ytop,cx

         mov blank,dl

         mov poctor,eax
         add poctor,4

         mov bx,[eax]
         mov xlen,bx
         mov bx,[eax+2]
         mov ylen,bx

         mov membash,ebp
         mov edi,ebp

         mov esi,offset macroc
         mov ecx,offset macrod - offset macroc
         rep movsb

         mov count4,4

cf_loop1:
         movzx eax,ytop
         imul eax,xactual
         movzx ebx,xtop
         add eax,ebx
         shr eax,2
         mov ddr,eax

         mov ax,xlen
         mov xtemp,ax

         mov bx,xtop
         mov xreal,bx

         mov ax,xtop
         and al,3
         mov [macroe+2],al

         mov esi,offset macrod
         mov ecx,macrog-macrod
         rep movsb

         mov eax,poctor
         mov pik,eax
cf_loop3:
         mov ax,ylen
         mov ytemp,ax

         mov ax,ytop
         mov yreal,ax

         mov eax,ddr
         mov ddn,eax

         mov ebp,pik

cf_loop2:
         mov ax,yreal

         cmp ax,_cliptp
         jb cf_no
         cmp ax,_clipbt
         ja cf_no

         mov ax,xreal

         cmp ax,_cliplt
         jb cf_no
         cmp ax,_cliprt
         ja cf_no

         mov al,[ebp]
         cmp al,blank
         jbe cf_no

         mov esi,o macro3
         mov ecx,2
         rep movsb

         mov bl,al
         mov eax,ddn
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb
         shr eax,8
         stosb

         mov al,bl
         stosb
cf_no:
         inc yreal
         add ddn,xactual/4
         movzx ebx,xlen
         add ebp,ebx

         dec ytemp
         jnz cf_loop2

         add pik,4
         inc ddr
         add xreal,4
         sub xtemp,4
         cmp xtemp,0
         jg cf_loop3

         inc poctor
         inc xtop
         dec count4
         jnz cf_loop1

         mov al,macro5
         stosb

         mov ebp,membash
         ret

macroc:  mov ebp,edi
         mov bl,al
macrod:  mov edi,ebp
         mov al,bl
macroe   db 0C0h,0E0h,000h           ; shl al,xx
         cmp al,8
         jbe s macrof
         shr al,4
         inc edi
macrof   db 066h,0BAh,0C5h,003h,0EEh ; out_8 sc_data,al
macrog:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Gif squeezer:  Turn a X*Y gif into a X*Y/2 gif. eg 320x400 => 320x200
; In:
;   EDX => offset of bitmap (first two words are x,y size)
; Out:
;   EDX = EDX
;   EDI => new end of bitmap
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_gif_squeeze_y:
         push eax esi ecx
         shr word ptr [edx+2],1
         mov ax,[edx+2]
         movzx ebx,word ptr [edx]

         mov esi,edx
         mov edi,edx
         add esi,4
         add edi,4
gs_loop:
         mov ecx,ebx
         rep movsb

         add esi,ebx
         dec ax
         jnz gs_loop

         pop ecx esi eax
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _compile_xy:  Calculate offset and port mask in preparation for compiled
;               bitmap call
; In:
;   EBX = x relative screen location (both can be negative)
;   ECX = y relative screen location
; Out:
;   ESI = addition for base screen pointer
;    AL = start xmode port mask
;
; Notes:
;   A compiled bitmap can be moved around the screen by selecting an offset
;   and new start port mask.  This routine calculates those things for you.
;
; Example 1:
;
;  Draw bitmap at location it was compiled at:
;
;  mov edi,_current_page
;  mov al,1
;  mov ebp,where_compiled_bitmap_is_in_memory
;  call ebp
;
; Example 2:
;
;  Draw bitmap at new location:
;
;  mov ebx,x_offset
;  mov ecx,y_offset
;  call _compile_xy
;  mov edi,_current_page
;  add edi,esi
;  mov ebp,where_compiled_bitmap_is_in_memory
;  call ebp
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_compile_xy:
         cmul esi,ecx,xactual/4

         mov eax,ebx
         shr eax,2
         test eax,000800000h
         jz short nomin
         or   eax,0ff000000h
nomin:
         add esi,eax

         mov ecx,ebx
         and cl,3
         mov al,1
         shl al,cl
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Gif squeezer:  Turn a X*Y gif into a X/2*Y gif. eg 320x400 => 160x400
; In:
;   EDX => offset of bitmap (first two words are x,y size)
; Out:
;   EDX = EDX
;   EDI => new end of bitmap
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_gif_squeeze_x:
         push eax esi ecx
         shr word ptr [edx],1
         mov ax,[edx+2]
         movzx ebx,word ptr [edx]

         mov esi,edx
         mov edi,edx
         add esi,4
         add edi,4
gs_loop2:
         mov ecx,ebx
gs_loopx:
         movsb
         inc esi
         loop gs_loopx

         dec ax
         jnz gs_loop2

         pop ecx esi eax
         ret

         ends
         end
