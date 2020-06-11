;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Modified Simple 669 playback routine using 'gus' lowlevel GUS routines.
;
; The IRQ is expected to call this routine 50 times a second.  Why, Because!
; Anyway, that means that .669's that have a tempo of 4 are played a little
; faster than you would expect.  All other tempos sound fine.
;
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         .386p
code32   segment para public use32
         assume cs:code32, ds:code32

include  pmode.ext
include  gus.ext
include  irq.ext

public   _ord669

public   _muzloc, _muzend, _muzrow, _muzord, _muzloop, _muzeord

public   _gsp669_init, _gsp669_uninit, _gsp669_load, _gsp669_play, _gsp669_stop

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
align    4
ordptr     dd ?                             ; ptr to order list
tempoptr   dd ?                             ; ptr to tempo list
breakptr   dd ?                             ; ptr to break list
patbaseptr dd ?                             ; ptr to base of patterns
instptr    dd ?                             ; ptr to sample data

currowptr dd ?                              ; ptr to next row to play

_muzloc  label word                         ; ord:row
_muzrow  db ?                               ; current row playing
_muzord  db ?                               ; current order playing
_muzend  label word                         ; end:loop
_muzloop db ?                               ; loop point of 669
_muzeord db ?                               ; last+1 order of 669

panloc   db 0                               ; base of ping-pong pan
tempo    db ?                               ; tempo
tempoc   db ?                               ; tempo counter
row      db ?                               ; current row
_ord669  db ?                               ; current order
break    db ?                               ; row of break

which669control dd -1                       ; irq timing control number

pantbl   db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
         db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
         db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
         db 3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
         db 12,12,12,11,11,10,9,8,7,6,5,4

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Main playback routine called by GUS IRQ routine
mr:
         mov al,tempoc
         dec al
         jnz mrd

         mov esi,currowptr
         mov ax,word ptr row
         inc al
         cmp al,break
         jbe short mrf0
         xor al,al
         inc ah
         cmp ah,_muzeord
         jbe short mrf1
         mov ah,_muzloop
mrf1:
         movzx ebp,ah
         mov edi,ordptr
         movzx esi,byte ptr ds:[ebp+edi]
         mov edi,tempoptr
         mov bl,[edi+esi]
         mov tempo,bl
         mov edi,breakptr
         mov bl,[edi+esi]
         mov break,bl
         lea esi,[esi*2+esi]
         shl esi,9
         add esi,patbaseptr
mrf0:
         mov word ptr row,ax
         mov _muzloc,ax

         movzx edx,panloc
         inc dl
         and dl,3fh
         mov panloc,dl
         mov edi,instptr
         mov ebp,7
mrl0:
         mov al,[esi+2]
         mov ah,al
         and al,0f0h
         cmp al,50h
         jne short mrl0f0
         and ah,0fh
         mov tempo,ah
mrl0f0:
         mov bl,pantbl[edx+ebp*4]
         mov _vcpan[ebp],bl
         or _vccmnd[ebp],2
         mov ax,[esi]
         cmp al,0feh
         ja mrl0c
         movzx ebx,ah
         and bl,0fh
         mov _vcvol[ebp],bl
         or _vccmnd[ebp],1
         cmp al,0feh
         je short mrl0c
         xchg al,ah
         shr ax,2
         shr al,2
         movzx ebx,ah
         mov bx,_freqtbl[ebx*2]
         mov _vcfreq[ebp*2],bx
         movzx ebx,al
         lea ebx,[ebx*4+ebx]
         lea ebx,[ebx*4+ebx]
         mov al,[edi+ebx+12]
         mov _vccntrl[ebp],al
         mov eax,[edi+ebx+13]
         mov _vcsbeg[ebp*4],eax
         mov eax,[edi+ebx+17]
         mov _vclbeg[ebp*4],eax
         mov eax,[edi+ebx+21]
         mov _vclend[ebp*4],eax
         mov _vccmnd[ebp],play
mrl0c:
         add esi,3
         sub ebp,1
         jnc mrl0

         mov currowptr,esi
         xor eax,eax
         mov ah,tempo
         mov ecx,eax
         shr ecx,1
         add eax,ecx
         shr ecx,2
         add eax,ecx
         shr ecx,2
         add eax,ecx
         add eax,128
         mov al,ah
mrd:
         mov tempoc,al
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Init 669 player and low level gus crap
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_init:
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset 669 player and low level gus crap
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_uninit:
         call _gsp669_stop
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load a 669, samples go directly into GUS ram
; In:
;   EAX -> stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
;   EDX -> buffer large enough for all music data plus largest sample
; _sfxmem -> location to begin storing on GUS memory
; Out:
;   EAX - number of bytes of buffer to keep
;   EBX - number of bytes used on GUS
; _sfxmem -> next free GUS memory location
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_load:
         pushad
         mov ebp,edx
         mov ecx,1f1h
         call eax
         mov al,[edx+70h]
         mov _muzloop,al
         lea eax,[edx+71h]
         mov ordptr,eax
         add eax,80h
         mov tempoptr,eax
         add eax,80h
         mov breakptr,eax
         add edx,ecx
         mov instptr,edx
         lea esi,[edx+13]
         movzx edi,byte ptr [ebp+6eh]
         imul ecx,edi,25
         call dword ptr [esp+28]
         add edx,ecx
         mov patbaseptr,edx
         movzx ecx,byte ptr [ebp+6fh]
         lea ecx,[ecx*2+ecx]
         shl ecx,9
         call dword ptr [esp+28]
         add edx,ecx
         mov ebx,_sfxmem
gsp669loadl0:
         mov ecx,[esi]
         add esi,25
         jecxz gsp669loadl0c
         call dword ptr [esp+28]
         call _sfx_putram
         add ebx,ecx
gsp669loadl0c:
         dec edi
         jnz gsp669loadl0
         sub edx,[esp+20]
         mov [esp+28],edx
         mov [esp+16],ebx                   ; save amount of GUS ram used for samples
         add _sfxmem,ebx

         mov esi,instptr
         movzx ecx,byte ptr [ebp+6eh]
         xor ebx,ebx
gsp669loadl1:
         mov edx,[esi+13]
         mov [esi+13],ebx
         mov al,8
         cmp edx,[esi+21]
         jae short gsp669loadl1c
         xor al,al
         mov [esi+21],edx
gsp669loadl1c:
         add [esi+17],ebx
         add [esi+21],ebx
         dec dword ptr [esi+21]
         mov [esi+12],al
         add ebx,edx
         add esi,25
         loop gsp669loadl1

         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Play a loaded 669
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_play:
         push ax ecx edi
         call _gsp669_stop
         mov edi,ordptr
         mov ecx,80h
         mov al,0ffh
         repne scasb
         sub cl,7eh
         neg cl
         mov _muzeord,cl
         mov _muzloc,0
         mov panloc,0
         mov dword ptr tempoc,0ff0001h
         mov which669control,-1
         call _irq_findcontrol
         jc gspno669
         mov _irqcontrol[ecx*4],offset mr
         mov which669control,ecx
gspno669:
         pop edi ecx ax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Stop playback
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_stop:
         mov dword ptr _vcvol[0],0000000h
         mov dword ptr _vcvol[4],0000000h
         mov dword ptr _vccmnd[0],20202020h
         mov dword ptr _vccmnd[4],20202020h
         mov ecx,which669control
         or ecx,ecx
         jl _ret
         mov _irqcontrol[ecx*4],offset _ret
         ret

code32   ends
         end
