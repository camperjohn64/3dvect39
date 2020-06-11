;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;
; Sound support - GUS & SB
;
; Labels begining with:
;  _sfx - generic sound commands, both cards
;  _gs  - GUS labels
;  _sb  - Sound Blaster labels
;
; Notes and Examples:
;
;  call _sfx_find              ; for both soundcards
;  jc no sound card installed
;
;  mov edx,_lomembase          ; DMA buffer        * ALL this data is ignored *
;  mov ebx, 1024               ; DMA buffer size   *  if the user has a GUS   *
;  mov ecx, 22000              ; sample rate
;  mov eax,_lomembase
;  add eax, ebx                ; samples are right after DMA buffer
;  call _sfx_init              ; call this for both soundcards (SB and GUS)
;  mul ebx,200000              ; 200000 bytes of sample memory required (0 if GUS)
;  add _lomembase,eax          ; bump up low memory because of DMA (0 if GUS)
;  add _lomembase,ebx          ; bump up low memory because of samples required (0 if GUS)
;
;  call _sfx_uninit            ; done, clear soundcard
;
; Notes: Original GUS code (now modified) from GS.ASM by Thomas Pytel, aka TRAN
;        Sound Blaster code (Gravis Emulation) by John McCarthy, aka FLYNN.
;
; Send me a postcard!
;
;        John McCarthy
;        1316 Redwood Lane
;        Pickering, Ontario.
;        Canada, Earth, Milky Way (for those out-of-towners)
;        L1X 1C5
;
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         .386p
code32   segment para public use32
         assume cs:code32, ds:code32

         include pmode.ext
         include irq.ext
         include file.ext

         public _sfx_find                   ; find if sound device available
         public _sfx_init                   ; intialize sound device
         public _sfx_uninit                 ; unintialize sound device
         public _sfx_putram                 ; put to ram
         public _sfx_getram                 ; get from ram
         public _sfx_shutup                 ; turn single voice off
         public _sfx_relvolume              ; relative volume control
         public _sfx_setvolume              ; set volume of channel
         public _sfx_getfreq

         public _freqtbl                    ; precalculated frequencies for c0 to b4

         public _sfxnumvoices               ; number of voices to mix
         public _sfxmem                     ; next available location in sample memory
         public _sfxram                     ; amount of RAM on card
         public _sfxsign                    ; sign for XOR'ing of samples (only during
                                            ; initial transfer to card)
         public _sfxtype                    ; card installed, 0 = none, 1 = GUS, 2 = SB

         public _vccmnd, _vccntrl, _vcsbeg, _vclbeg, _vclend, _vcfreq, _vcpan, _vcvol
         public _mix_volume

         align 4

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Generic voice handling stuff
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sfx_init   dd offset _return_null          ; jump vectors to appropriate code
_sfx_uninit dd offset _return_null
_sfx_putram dd offset _return_null
_sfx_getram dd offset _return_null
_sfx_shutup dd offset _return_null
_sfx_getfreq dd offset _return_null

_sfxsign db 0                               ; signed data not, 0 = SB, 80h = GUS
_sfxmem  dd 0                               ; next free location in GUS or SB virtual memory
_sfxram  dd 0                               ; amount of available GUS or SB virtual memory
_sfxnumvoices db 16                         ; number of voices (up to 32)
_sfxmiddlec dw 8664                         ; Hz assigned to middle C
_sfxtype db 0                               ; card installed, 0 = none, 1 = GUS, 2 = SB
                                            ; bit 1, 1 = virtual ram or 0 = GUS ram/no ram

_vccmnd  db 32 dup(?)                       ; virtual channel command bits
                                            ;  bit 0: volume change
                                            ;  bit 1: balance change
                                            ;  bit 2: frequency change
                                            ;  bit 3: sample note-on
                                            ;  bit 4: sample continues into next chunk (SB only)
_vccntrl db 32 dup(?)                       ; virtual channel voice control
                                            ;  bit 3: enable loop
                                            ;  bit 4: bi-directional loop
                                            ;  bit 6: 0=forward, 1=reverse
_vcsbeg  dd 32 dup(?)                       ; virtual channel sample begin
_vclbeg  dd 32 dup(?)                       ; virtual channel loop begin
_vclend  dd 32 dup(?)                       ; virtual channel loop end
_vcfreq  dw 32 dup(?)                       ; virtual channel frequency value
_vcpan   db 32 dup(?)                       ; virtual channel pan position
_vcvol   db 32 dup(?)                       ; virtual channel volume (high byte)

_mix_volume db 32 dup(15)                   ; mixing volume (each channel)

aclbeg   dd 32 dup(?)                       ; actual channel loop begin
aclend   dd 32 dup(?)                       ; actual channel loop end
acfreq   dw 32 dup(?)                       ; actual channel frequency value
acpan    db 32 dup(?)                       ; actual channel pan position
acvol    db 32 dup(?)                       ; actual channel volume (high byte)
acpos    dd 32 dup(?)                       ; actual channel position           (SB only)
acstep   db 32 dup(?)                       ; actual channel last step position (SB only)
accntrl  db 32 dup(?)                       ; actual channel voice control      (SB only)
accmnd   db 32 dup(?)                       ; actual channel command            (SB only)

_freqtbl dw 60 dup (0)

rawfreq  dw 2166,2294,2431,2573,2728,2891,3063,3245,3438,3642,3859,4088
         dw 4332,4589,4862,5147,5457,5782,6126,6490,6876,7285,7718,8177
         dw 8664,9179,9725,10294,10915,11565,12252,12981,13752,14571,15437,16355
         dw 17328,18358,19450,20589,21831,23130,24505,25962,27505,29142,30874,32710
         dw 34656,36716,38900,41179,43663,46260,49011,51925,55010,58284,61749,65421

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Null soundcard (default)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_return_null:
         xor eax,eax
         xor ebx,ebx
         xor ecx,ecx
         xor edx,edx
         xor esi,esi
         xor edi,edi
         xor ebp,ebp
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Macros
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         vol = 1                            ; alter volume
         pan = 2                            ; alter pan position
         freq = 4                           ; alter frequency
         play = 8                           ; start/re-start sample
         cont = 16                          ; continue with SB sample (for next chunk, SB only)
         shutup = 32                        ; turn channel completly off

         loop_on = 8                        ; looping enable
         loop_bi = 16                       ; bi-directional loop
         loop_rev = 64                      ; loop direction, 1 = backwards

gusoutb  macro index,value
         mov al,&index
         out dx,al
         add dl,2
         mov al,&value
         out dx,al
         sub dl,2
endm

gusoutw  macro index,value
         mov al,&index
         out dx,al
         inc edx
         mov ax,&value
         out dx,ax
         dec edx
endm

gusinb   macro reg,index
         mov al,&index
         out dx,al
         add dl,2
         in al,dx
         sub dl,2
         ifnb <reg>
         mov reg,al
         endif
endm

gusinw   macro reg,index
         mov al,&index
         out dx,al
         inc edx
         in ax,dx
         dec edx
         ifnb <reg>
         mov reg,ax
         endif
endm

sbout    macro data
         local wait
wait:    in al,dx
         or al,al
         js wait
         mov al,data
         out dx,al
         endm

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Perform Initial test for card:  Set jump vectors for card found
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sfx_find:
         mov _sfxtype,0

         call _gus_find
         jc fd_looksb

         mov _sfx_init ,offset _gus_init
         mov _sfx_uninit,offset _gus_uninit
         mov _sfx_putram,offset _gus_putram
         mov _sfx_getram,offset _gus_getram
         mov _sfx_shutup,offset _gus_shutup
         mov _sfx_getfreq,offset _gus_getfreq
         mov _sfxtype,1
         mov _sfxsign,0
         ret

fd_looksb:
         call _sb_find
         jc _ret
         mov _sfx_init ,offset _sb_init
         mov _sfx_uninit,offset _sb_uninit
         mov _sfx_putram,offset _sb_putram
         mov _sfx_getram,offset _sb_getram
         mov _sfx_shutup,offset _sb_shutup
         mov _sfx_getfreq,offset _sb_getfreq
         mov _sfxtype,2
         mov _sfxsign,0
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set mixing volume of channel EBX
; In:
;  EBX - voice channel #
;  AL  - volume level
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sfx_setvolume:
         cmp al,0
         jge sv_1
         mov al,0
sv_1:
         cmp al,15
         jle sv_2
         mov al,15
sv_2:
         mov _mix_volume[ebx],al
         or _vccmnd[ebx],vol
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Change volume of channels (relative)
; In:
;   BL - channel to start at
;   CL - channel to end at
;   DL - 1 = inc, -1 = dec
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sfx_relvolume:
         sub cl,bl
         inc cl
         movzx ebx,bl
         movzx ecx,cl
av_1:
         mov al,_mix_volume[ebx]
         add al,dl
         call _sfx_setvolume
         inc ebx
         loop av_1

         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; GUS lowlevel interface. Part II - modified from TRAN's original gs.asm
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         public _gus_handler
         public _gus_shutup
         public _gus_init
         public _gus_uninit
         public _gus_putram
         public _gus_getram
         public _gus_find
         public _gus_getfreq

         public _gusport
         public _gusirq

ormgusirqvect dd ?                          ; old real mode GF1 IRQ vector
rmgusirqbuf db 21 dup(?)                    ; buffer for rm GF1 IRQ callback code

gusport102 dw ?                             ; GUS port + 102h
gusport103 dw ?                             ; GUS port + 103h
gusport104 dw ?                             ; GUS port + 104h
gusport107 dw ?                             ; GUS port + 107h

_gusport dw 220h
_gusirq  db 11

whichguscontrol dd -1                       ; irq timing control number

port103val   db 43h                         ; value to set on exit from IRQ
irqm0tbl     dw 0c089h,0a0e6h
gusirqvaltbl db 0,0,41h,43h,0,42h,0,44h,0,0,0,45h,46h,0,0,47h

voltbl   db 004h,0a0h,0b0h,0c0h,0c8h,0d0h,0d8h,0e0h
         db 0e4h,0e8h,0ech,0f0h,0f2h,0f4h,0f6h,0f8h

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Gus IRQ - useless, never called
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

gus_irq:
         push eax
         mov al,20h
         out 20h,al
irqm0    dw ?                               ; out 0a0h,al | mov eax,eax
         sti
         cld
         push ebx ecx edx esi edi ebp ds
         mov ds, [cs:_seldata]



         pop ds ebp edi esi edx ecx ebx eax
         iretd

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Gus voice handler
; Update GUS from virtual values/commands
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_gus_handler:
         mov dx,gusport103
         movzx ebp,_sfxnumvoices
         dec ebp
irql0:
         xor cl,cl
         xchg cl,_vccmnd[ebp]
         or cl,cl
         jz irql0c

         test cl,shutup
         jz short irql0f9
         mov edi,ebp
         call _gus_shutup
         jmp irql0c
irql0f9:
         test cl,play
         jz short irql0f0
         or cl,vol+pan+freq
irql0f0:

         mov eax,ebp
         dec edx
         out dx,al
         inc edx

         cmp _mix_volume[ebp],0
         jne irql0g1
         gusoutb 0,1
         jmp irql0c

irql0g1:
         test cl,freq
         jz short irql0f1
         mov bx,_vcfreq[ebp*2]
         cmp bx,acfreq[ebp*2]
         je short irql0f1
         mov acfreq[ebp*2],bx
         gusoutw 1,bx
irql0f1:

         test cl,pan
         jz short irql0f2
         mov bl,_vcpan[ebp]
         cmp bl,acpan[ebp]
         je short irql0f2
         mov acpan[ebp],bl
         gusoutb 0ch,bl
irql0f2:

         test cl,play
         jz irql0f3
         mov esi,_vclbeg[ebp*4]
         cmp esi,aclbeg[ebp*4]
         je short irql0f2f0
         mov aclbeg[ebp*4],esi
         shrd bx,si,7
         shr esi,7
         gusoutw 2,si
         gusoutb 3,bh
irql0f2f0:
         mov esi,_vclend[ebp*4]
         cmp esi,aclend[ebp*4]
         je short irql0f2f1
         mov aclend[ebp*4],esi
         shrd bx,si,7
         shr esi,7
         gusoutw 4,si
         gusoutb 5,bh
irql0f2f1:
         mov esi,_vcsbeg[ebp*4]
         shrd bx,si,7
         shr esi,7
         gusoutw 0ah,si
         gusoutb 0bh,bh
         gusoutb 0,_vccntrl[ebp]
irql0f3:

         test cl,vol
         jz short irql0f4
         movzx ebx,_vcvol[ebp]
         mov bl,voltbl[ebx]
         cmp bl,4
         jbe irql0f3f4
         mov bh,_mix_volume[ebp]
         shl bh,3
         sub bh,_mix_volume[ebp]            ; *7
         add bl,bh
         sub bl,105                         ; 7*15
irql0f3f4:
         mov bh,acvol[ebp]
         mov ah,bh
         cmp bh,bl
         je short irql0f4
         mov ch,40h
         ja short irql0f3f0
         xchg bl,bh
         xor ch,ch
irql0f3f0:
         gusoutb 7,bl
         gusoutb 8,bh
         gusoutb 9,ah
         gusoutb 0dh,ch
irql0f4:

         mov dx,300h
         db 7 dup(0ech)                     ; in al,dx
         mov dx,gusport103

         test cl,vol
         jz short irql0f5
         movzx ebx,_vcvol[ebp]
         mov al,voltbl[ebx]
         cmp al,4
         jbe irql0f5f4
         mov bh,_mix_volume[ebp]
         shl bh,3
         sub bh,_mix_volume[ebp]            ; *7
         add al,bh
         sub al,105                         ; 7*15
irql0f5f4:
         cmp al,ah
         je short irql0f5
         mov acvol[ebp],al
         gusoutb 9,ah
         gusoutb 0dh,ch
irql0f5:

         test cl,play
         jz short irql0c
         mov esi,_vcsbeg[ebp*4]
         shrd bx,si,7
         shr esi,7
         gusoutw 0ah,si
         gusoutb 0bh,bh
         gusoutb 0,_vccntrl[ebp]

irql0c:
         sub ebp,1
         jnc irql0

         outb port103val
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; A small delay, In: ECX - number of times to do delay
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

gusdelay:
         push ax dx
         mov dx,300h
gusdelayl0:
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         loop gusdelayl0
         pop dx ax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Shove some crap into GUS ram
; In:
;   EBX - addx in GUS ram to shove into
;   ECX - amount of crap to shove
;   EDX -> actual crap to shove
; Notes:
;  All incoming data will be XOR'ed with _sfxsign  !!!
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gus_putram:
         push eax ebx ecx edx esi
         push ecx
         mov al,_sfxsign
         xor al,80h
gsputramlx:
         xor byte ptr [edx],al
         inc edx
         loop gsputramlx
         pop ecx
         sub edx,ecx
         mov esi,edx
         mov dx,gusport104
gsputraml0:
         dec edx
         mov al,44h
         mov port103val,al
         out dx,al
         add dl,2
         shld eax,ebx,16
         out dx,al
         sub dl,2
         mov al,43h
         mov port103val,al
         out dx,al
         inc edx
gsputraml1:
         mov ax,bx
         out dx,ax
         add dl,3
         outsb
         sub dl,3
         inc bx
         loopnz gsputraml1
         jecxz short gsputramd
         add ebx,10000h
         jmp gsputraml0
gsputramd:
         pop esi edx ecx ebx eax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Rip some crap outta GUS ram
; In:
;   EBX - addx in GUS ram to rip from
;   ECX - amount of crap to rip
;   EDX -> buffer for ripped crap
; Notes:
;  All outgoing data will be XOR'ed with _sfxsign  !!!
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gus_getram:
         push eax ebx ecx dx edi
         push ecx
         mov al,_sfxsign
         xor al,80h
gsgetramlx:
         xor byte ptr [edx],al
         inc edx
         loop gsgetramlx
         pop ecx
         sub edx,ecx
         mov edi,edx
         mov dx,gusport104
gsgetraml0:
         dec edx
         mov al,44h
         mov port103val,al
         out dx,al
         add dl,2
         shld eax,ebx,16
         out dx,al
         sub dl,2
         mov al,43h
         mov port103val,al
         out dx,al
         inc edx
gsgetraml1:
         mov ax,bx
         out dx,ax
         add dl,3
         insb
         sub dl,3
         inc bx
         loopnz gsgetraml1
         jecxz short gsgetramd
         add ebx,10000h
         jmp gsgetraml0
gsgetramd:
         pop edi dx ecx ebx eax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize GUS
; In: none
; Out:
;   EAX = 0
;   EBX = 0 (can be used for determining if memory requuired on cpu, SB returns 1)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gus_init:
         pushad
         mov ax,900h
         int 31h
         push ax

         mov dx,_gusport                    ; set up all port vars
         outb 0bh
         add dx,102h
         mov gusport102,dx
         inc edx
         mov gusport103,dx
         inc edx
         mov gusport104,dx
         add dl,3
         mov gusport107,dx

         sub dl,4                           ; initialize GUS
         outb 4ch
         add dl,2
         outb 0
         mov ecx,10h
         call gusdelay
         outb 1
         sub dl,2
         mov ecx,10h
         call gusdelay
         gusoutb 41h,0
         gusoutb 45h,0
         gusoutb 49h,0
         outb 0eh
         add dl,2
         mov al,_sfxnumvoices
         dec al
         or al,0c0h
         outb al
         sub dl,3

         mov bl,1fh                         ; set up all voices
gsinitl0:
         mov al,bl
         and al,7fh
         out dx,al
         inc edx
         gusoutw 9,0
         gusoutb 0,0
         gusoutb 0dh,3
         gusoutb 6,16
         outb 0ch
         add dl,2
         outb 7
         sub dl,3
         mov ecx,1
         call gusdelay
         xor bl,80h
         js gsinitl0
         sub bl,1
         jnc gsinitl0

         sub dx,0f3h                        ; damn, another undocumented port
         outb 5
         sub dl,0fh
         outb 8
         add dl,0bh
         xor al,al
         out dx,al
         add dl,4
         out dx,al
         sub dl,0fh

         movzx ebx,_gusirq                  ; set IRQ channels
         outb 4bh
         add dl,0bh
         mov al,gusirqvaltbl[ebx]
         out dx,al
         sub dl,0bh
         outb 9
         add dx,103h

         outb 43h                           ; how much RAM on the card
         inc edx
         outw 0ffffh
         dec edx
         outb 44h
         add dl,2
         mov cl,3
gsinitl1:
         outb cl
         add dl,2
         in al,dx
         inc eax
         mov ah,al
         out dx,al
         in al,dx
         sub dl,2
         cmp al,ah
         jne short gsinitl1d
         inc _sfxram
         add cl,4
         test cl,10h
         jz gsinitl1
gsinitl1d:
         sub dl,2
         shl _sfxram,18

         gusoutb 4ch,7                      ; enable GUS normal operation

         cmp bl,2                           ; set and enable GF1 IRQ (BL=IRQ num)
         jne short $+4
         mov bl,9
         cmp bl,7
         seta al
         movzx eax,al
         mov ax,irqm0tbl[eax*2]
         mov irqm0,ax
         mov edx,offset gus_irq
         call _setirqvect
         xor al,al
         call _setirqmask
         mov edi,offset rmgusirqbuf
         call _rmpmirqset
         mov ormgusirqvect,eax

         mov whichguscontrol,-1
         call _irq_findcontrol
         jc gusnogus
         mov _irqcontrol[ecx*4],offset _gus_handler
         mov whichguscontrol,ecx
gusnogus:
         mov ecx,60                         ; calculate frequency tables
         mov bl,_sfxnumvoices
         dec bl
         and ebx,1fh
         add bl,1
         mov si,16
gusfreqcalc:
         mov ax,rawfreq[ecx*2-2]
         call _gus_getfreq
         mov _freqtbl[ecx*2-2],ax
         loop gusfreqcalc

         pop ax
         int 31h
         popad
         xor ebx,ebx                        ; memory flag, 0 = all samples on GUS
         xor eax,eax                        ; DMA memory flag. 0 = sound blaster DMA not used
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Uninitialize GUS
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_gus_uninit:
         push ax bx edx
         mov ax,900h
         int 31h
         push ax

         mov bl,_gusirq                     ; Kill GUS IRQ handler
         cmp bl,2
         jne short $+4
         mov bl,9
         mov eax,ormgusirqvect
         call _rmpmirqfree
         mov al,1
         call _setirqmask

         mov dx,gusport103                  ; Shut down GUS
         outb 4ch
         add dl,2
         outb 0
         sub dx,105h
         outb 0bh

         mov ecx,whichguscontrol
         or ecx,ecx
         jl gusnovoice
         mov _irqcontrol[ecx*4],offset _ret
gusnovoice:

         pop ax
         int 31h
         pop edx bx ax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Find a GUS (environment variable)
; Out:
;   EAX,ECX,ESI,EDI - ?
;   CF=0 - found GUS
;   CF=1 - no GUS found
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
pspultrastr db 'ULTRASND'

_gus_find:
         pushad
         mov esi,_pspa
         movzx esi,word ptr gs:[esi+2ch]
         shl esi,4
gsfindl3:
         mov edi,offset pspultrastr
         mov ecx,8
         repe cmps byte ptr gs:[esi],byte ptr es:[edi]
         jne short gsfindf0
         mov edi,10h
         call gsfindr0
         mov _gusport,cx
         call gsfindr0
         call gsfindr0
         mov edi,10
         call gsfindr0
         mov _gusirq,cl
         popad
         clc
         ret
gsfindf0:
         lea esi,[esi+ecx-8]
gsfindl0:
         inc esi
         cmp byte ptr gs:[esi-1],0
         jne gsfindl0
         cmp byte ptr gs:[esi],0
         jne gsfindl3
         popad
         stc
         ret

gsfindr0:
         movzx eax,byte ptr gs:[esi]
         inc esi
         sub al,'0'
         jc gsfindr0
         cmp al,9
         ja gsfindr0
         mov ecx,eax
gsfindr0l0:
         mov al,gs:[esi]
         inc esi
         sub al,'0'
         jc gsfindr0d
         cmp al,9
         ja gsfindr0d
         imul ecx,edi
         add ecx,eax
         jmp gsfindr0l0
gsfindr0d:
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Shut voice EDI up on GUS
; In:
;   EDI - voice to kill
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gus_shutup:
         push edx eax ebx
         mov _vccmnd[edi],0
         mov dx,gusport103
         mov eax,edi
         dec edx                            ; 3X2
         out dx,al
         inc edx                            ; 3X3
         gusinb bl,89h
         gusoutb 6,64+48
         gusoutb 7,4
         gusoutb 8,bl
         gusoutb 0dh,40h
         pop ebx eax edx
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Convert actual frequency to GUS frequency number
; In:
;   EAX - frequency
; Out:
;   AX - GUS frequency number
;   EAX high word - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gus_getfreq:
         push edx ebx ebp
         xor ebp,ebp
         mov bp,_sfxmiddlec
         mul ebp
         mov ebp,8664
         div ebp
         xor edx,edx
         shl eax,10
         xor ebx,ebx
         mov bl,_sfxnumvoices
         cmp bl,14
         jae short $+4
         mov bl,14
         mov bx,freqact[ebx*2-14*2]
         div ebx
         pop ebp ebx edx
         ret

freqact  dw 44100,41160,38587,36317,34300,32494,30870,29400,28063
         dw 26843,25725,24696,23746,22866,22050,21289,20580,19916,19293

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; SB lowlevel interface. - Everyone knows that the SB is OUTDATED and that
; anyone whose anybody has a GUS!  These routines are for those losers...
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

         public _sb_find
         public _sb_init
         public _sb_uninit
         public _sb_putram
         public _sb_getram
         public _sb_get_dmacount
         public _sb_getfreq

         public _sbport
         public _sbirq
         public _sbdmabuffer
         public _sbdmasize
         public _sbmixspeed
         public _sbvoltables
         public _sbsamples
         public _sbvolume

_sbport  dw 0
_sbirq   db 0

_sbdmabuffer dd 0                           ; DMA buffer
_sbdmasize   dd 0                           ; DMA buffer size
_sbmixspeed  dw 0                           ; mixing speed, (11000,22000...)
_sbvoltables dd 0                           ; pointer to volume tables
_sbsamples   dd 0                           ; sample tables
_sbvolume    db 50                          ; overall volume diminishing for samples (256=full) init only
sbebp    dd 0                               ; temp ebp 2
dmaxor   dd 0                               ; xor value to flip between dma half buffers
dmachunk dd 0                               ; current dma chunk location (front/back)
dmahalf  dd 0                               ; _sbdmasize /2
samend   dd 0                               ; current sample end location
saveebp  dd 0                               ; temp save of ebp

ormsbirqvect dd ?                           ; old real mode SB IRQ vector
rmsbirqbuf db 21 dup(?)                     ; buffer for rm SB IRQ callback code

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Find a SB (environment variable)
; Out:
;   EAX,ECX,ESI,EDI - ?
;   CF=0 - found GUS
;   CF=1 - no SB found
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

pspsbstr db 'BLASTER'

_sb_find:
         pushad
         mov esi,_pspa
         movzx esi,word ptr gs:[esi+2ch]
         shl esi,4
sbfindl3:
         mov edi,offset pspsbstr
         mov ecx,7
         repe cmps byte ptr gs:[esi],byte ptr es:[edi]
         jne short sbfindf0

         mov ebx,esi
         mov ecx,10h
         mov al,"A"
         mov ah,"a"
         dec esi
sbf_loop1:
         inc esi
         cmp byte ptr gs:[esi],ah
         je sbf_it1
         cmp byte ptr gs:[esi],al
         loopne sbf_loop1
sbf_it1:
         mov edi,10h
         call sbfindr0
         mov _sbport,cx

         mov ecx,10h
         mov al,"I"
         mov ah,"i"
         dec ebx
sbf_loop2:
         inc ebx
         cmp byte ptr gs:[ebx],ah
         je sbf_it2
         cmp byte ptr gs:[ebx],al
         loopne sbf_loop2
sbf_it2:
         mov esi,ebx

         mov edi,10
         call sbfindr0
         mov _sbirq,cl
         popad
         clc
         ret
sbfindf0:
         lea esi,[esi+ecx-7]
sbfindl0:
         inc esi
         cmp byte ptr gs:[esi-1],0
         jne sbfindl0
         cmp byte ptr gs:[esi],0
         jne sbfindl3
         popad
         stc
         ret

sbfindr0:
         movzx eax,byte ptr gs:[esi]
         inc esi
         sub al,'0'
         jc sbfindr0
         cmp al,9
         ja sbfindr0
         mov ecx,eax
sbfindr0l0:
         mov al,gs:[esi]
         inc esi
         sub al,'0'
         jc sbfindr0d
         cmp al,9
         ja sbfindr0d
         imul ecx,edi
         add ecx,eax
         jmp sbfindr0l0
sbfindr0d:
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Shut voice EDI up on SB
; In:
;   EDI - voice to kill
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_sb_shutup:
         mov _vccmnd[edi],0
         mov accmnd[edi],0
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Sound Blaster IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

sb_irq:
         push eax
         mov al,20h                         ; re-enable irq
         out 20h,al
irqm00   dw ?                               ; out 0a0h,al | mov eax,eax
         sti
         cld
         push ebx ecx edx esi edi ebp ds
         mov ds, [cs:_seldata]

         mov dx,_sbport                     ; acknowlege sound blaster
         add dx,0eh
         in al,dx

         mov eax,dmaxor                     ; we are now transferring other section...
         xor dmachunk,eax                   ; flip to other dma chunk

         call wipe_dmachunk
         call _sb_handler

         pop ds ebp edi esi edx ecx ebx eax
         iretd

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Wipe current dma chunk
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

wipe_dmachunk:
         push edi ecx eax
         mov ecx,dmahalf
         shr ecx,2
         mov edi,dmachunk
         mov eax,80808080h
         rep stosd
         pop eax ecx edi
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get current DMA location
; Out:
;  ECX = > DMA load location
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_get_dmacount:
         push eax
         xor ecx,ecx
         in al,03h                          ; get from dma controller
         mov cl,al
         in al,03h
         mov ch,al
         neg ecx
         add ecx,_sbdmasize
         add ecx,_sbdmabuffer
         dec ecx
         pop eax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize SB
;  In:
;   EDX = > free memory for DMA buffer (must be in low memory!)
;   EAX = > free memory for volume tables, samples (MUST BE HIGHER THAN EDX!!)
;   EBX = > DMA buffer size (dword aligned)
;    CX = mixing speed (11000, 22000...)
; Out:
;  CF - 1 error initalizing sound blaster
;  CF - 0 ok!
;   EAX = amount EDX was adjusted because of DMA page overlap. eg: add _lomembase,ebx
;         this includes the original DMA size (0 if GUS)
;   EBX = 1 (can be used for determining if memory required on cpu, GUS returns 0,eg: imul ebx,200000)
;
; Notes:
;  If EAX < or = EDX, samples AND volume tables will follow DMA memory.
;  Volume tables use 16*256 bytes of memory - make sure you remember this
;  when allocating memory for samples.  200000 bytes of sample memory req'd
;  means to allocate 204096 bytes of memory.
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_init:
         pushad
         mov ax,900h
         int 31h
         push ax

         mov [esp+28+2],ebx                 ; mov eax,ebx after final popad
         mov _sbvoltables,eax
         mov _sbdmabuffer,edx
         mov _sbdmasize,ebx
         mov _sbmixspeed,cx
         add edx,_code32a

         mov eax,edx                        ; make sure actual DMA address+size does not
         add eax,ebx                        ; cross a 64k page boundary
         cmp ax,dx
         ja sb_dmatalk
         dec edx
         xor dx,dx
         add edx,00010000h
         sub edx,_code32a
         mov eax,_sbdmabuffer
         sub eax,edx
         neg eax
         add eax,ebx
         mov [esp+28+2],eax
         mov _sbdmabuffer,edx
         add edx,_code32a

sb_dmatalk:
         mov ecx,ebx
         dec ecx

         mov al,05h                         ; program DMA controller
         out 0ah,al

         xor al,al
         out 0ch,al

         mov al,dl                          ; edx = location for DMA
         out 02h,al
         shr edx,8
         mov al,dl
         out 02h,al
         shr edx,8
         mov al,dl
         out 83h,al

         mov al,cl                          ; cx = length
         out 03h,al
         mov al,ch
         out 03h,al
         mov al,01h                         ; high length
         out 0ah,al

         mov al,59h
         out 0bh,al

         mov bl,_sbirq                      ; get protected mode IRQ going
         cmp bl,2
         jne short $+4
         mov bl,9
         cmp bl,7
         seta al
         movzx eax,al
         mov ax,irqm0tbl[eax*2]
         mov irqm00,ax
         mov edx,offset sb_irq
         call _setirqvect
         xor al,al
         call _setirqmask
         mov edi,offset rmsbirqbuf
         call _rmpmirqset
         mov ormsbirqvect,eax

         mov edi,_sbdmabuffer               ; clear DMA buffer
         mov al,80h
         mov ecx,_sbdmasize
         cld
         rep stosb

sb_resetdsp:
         mov dx,_sbport                     ; make sure SB is awake and listening
         add dx,06h
         mov al,1
         out dx,al
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         in al,dx
         xor al,al
         out dx,al
         mov cx,100
sb_waitid:
         mov dx,_sbport
         add dx,0eh
         in al,dx
         or al,al
         js sb_getid
         loop sb_waitid

         stc
         jmp sb_error

sb_getid:
         mov dx,_sbport
         add dx,0ah
         in al,dx
         cmp al,0aah
         je sb_sbok
         loop sb_waitid

         stc
         jmp sb_error

sb_sbok:
         mov dx,_sbport
         add dx,0ch
         mov ax,1000
         mul ax
         div _sbmixspeed
         neg al
         mov ah,al
         mov dx,_sbport
         add dx,0ch
         sbout 40h                         ; 40h = set digitized transfer time constant
         sbout ah

sb_startdma:
         mov ebx,_sbdmasize
         shr ebx,1
         dec ebx
         sbout 48h                          ; 48h = set DSP block transfer size
         sbout bl
         sbout bh
         sbout 1ch                          ; 1Ch = start auto-initialize mode
         sbout 0d1h                         ; D1h = turn sound blaster digitized sounds on

         mov ebx,_sbdmasize                 ; set pre-calculated DMA/2 size
         shr ebx,1
         mov dmahalf,ebx

         mov eax,_sbdmabuffer               ; set xor for chunk flipping
         add ebx,eax
         xor ebx,eax
         mov dmaxor,ebx
         mov dmachunk,eax
         xor dmachunk,ebx                   ; point active dma chunk to second half (while first half plays)

         cmp eax,_sbvoltables
         jb sb_oklocation

         add eax,_sbdmasize                 ; set volume table location
         mov _sbvoltables,eax
sb_oklocation:
         mov eax,_sbvoltables
         mov esi,eax

         add eax,16*256+256                 ; set location for virtual ram
         mov _sbsamples,eax

         mov ecx,16*256-1                   ; generate volume tables
         movzx ebx,_sbvolume                ; percentile volume diminishing so sample addition doesn't carry

sb_volloop:
         movzx eax,cl
         sub eax,80h
         movzx edi,ch
         imul edi
         shr eax,4                          ; shr eax,4 = full volume
         imul bx
         mov [esi+ecx],ah                   ; ah rather than shr eax,8
         dec ecx
         jnl sb_volloop

         mov ecx,256-1                      ; make master volume lookup tables
sb_mastertables:
         mov ebx,ecx
         mov eax,ecx
         and bl,0fh
         shr al,4
         imul ebx
         imul eax,17
         mov ebx,15*15
         idiv ebx
         cmp al,17
         jne sb_special
         mov al,0fh
sb_special:
         mov [esi+16*256+ecx],al
         dec ecx
         jnl sb_mastertables

         mov ecx,60
         xor ebx,ebx
sbpitchloop:
         movzx eax,rawfreq[ebx*2]
         call _sb_getfreq
         mov _freqtbl[ebx*2],ax

         inc ebx
         loop sbpitchloop

         pop ax
         int 31h
         popad
         mov ebx,1
         clc
         ret

sb_error:
         pop ax
         int 31h
         popad
         xor ebx,ebx
         xor eax,eax
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Unintialize SB
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_uninit:
         pushad
         mov ax,900h
         int 31h
         push ax
         mov dx,_sbport
         add dx,0ch
         sbout 0d3h                         ; D3h = turn sound blaster digitized sounds off
         sbout 0dah                         ; DAh = exit auto-initialize mode

         mov bl,_sbirq                      ; restore original IRQ
         cmp bl,2
         jne short $+4
         mov bl,9
         mov eax,ormsbirqvect
         call _rmpmirqfree
         mov al,1
         call _setirqmask
         pop ax
         int 31h
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Shove some crap into SB virtual ram
; In:
;   EBX - addx in SB virtual ram to shove into
;   ECX - amount of crap to shove
;   EDX -> actual crap to shove
; Notes:
;  All incomming data will be XOR'ed with _sfxsign  !!!
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_putram:
         pushad
         add ebx,_sbsamples
pr_loop:
         mov al,[edx]
         xor al,_sfxsign
         mov [ebx],al
         inc edx
         inc ebx
         loop pr_loop
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Rip some crap outta SB virtual ram
; In:
;   EBX - addx in SB virtual ram to rip from
;   ECX - amount of crap to rip
;   EDX -> buffer for ripped crap
; Notes:
;  All outgoing data will be XOR'ed with _sfxsign  !!!
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_getram:
         pushad
         add ebx,_sbsamples
gr_loop:
         mov al,[ebx]
         xor al,_sfxsign
         mov [edx],al
         inc edx
         inc ebx
         loop gr_loop
         popad
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Main loop - Handle sound blaster mixing/voices/looping/bidirectional/volume
;
; This routine simply emulates a GUS on crappy Sound Blaster.
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_handler:
         movzx ebp,_sfxnumvoices
         dec ebp

_sb_moreloop:
         mov sbebp,ebp

         test _vccmnd[ebp],shutup
         jz short sbh_0f9
         mov edi,ebp
         call _sb_shutup
         jmp sbh_next
sbh_0f9:

         test _vccmnd[ebp],vol
         jz sbh_more3
         mov al,_vcvol[ebp]
         mov acvol[ebp],al
sbh_more3:

         test _vccmnd[ebp],freq
         jz sbh_more0
         mov ax,_vcfreq[ebp]
         mov acfreq[ebp*2],ax
sbh_more0:

         test _vccmnd[ebp],play
         jz sbh_more1

         mov al,_vccntrl[ebp]
         mov accntrl[ebp],al
         mov eax,_vclbeg[ebp*4]
         add eax,_sbsamples
         mov aclbeg[ebp*4],eax
         mov edx,_vcsbeg[ebp*4]
         add edx,_sbsamples
         mov eax,_vclend[ebp*4]
         add eax,_sbsamples
         mov aclend[ebp*4],eax
         mov acpos[ebp*4],edx
         mov acstep[ebp],0
         mov bh,_vcvol[ebp]
         mov acvol[ebp],bh
         mov ax,_vcfreq[ebp]
         mov acfreq[ebp*2],ax
         mov accmnd[ebp],cont
         mov _vccmnd[ebp],0
         jmp short sbh_mixit

sbh_more1:
         test accmnd[ebp],cont
         jz sbh_next

sbh_mixit:
         mov edx,acpos[ebp*4]               ; get actual sample position
         xor ebx,ebx                        ; clear top word
         mov bl,acvol[ebp]                  ; get voice volume
         shl bl,4
         or bl,_mix_volume[ebp]             ; get channel volume
         xor eax,eax
         mov ax,acfreq[ebp*2]               ; get voice frequency scaling
         xor ecx,ecx
         test accntrl[ebp],loop_rev         ; set Z flag of looping
         mov cl,ah                          ; transfer high step temporarily
         mov ah,acstep[ebp]                 ; get step from last time through
         mov edi,aclend[ebp*4]              ; get sample end
         mov ebp,ecx                        ; set high step for sample increment
         mov samend,edi                     ; dont have an extra register, must save in memory
         mov ecx,dmahalf                    ; set loop counter
         mov edi,dmachunk                   ; find current DMA chunk (front/back half)
         mov esi,_sbvoltables               ; point to volume tables
         mov bh,byte ptr [esi+16*256+ebx]   ; mix in master volume for channel
         jnz sbh_subloop                    ; use Z flag from looping

sbh_addloop:
         mov bl,[edx]                       ; mixing loop, get from sample
         mov bl,[ebx+esi]                   ; volume cross referance, bh = 0 - 15, bl = byte
         add [edi],bl                       ; mix into DMA
         inc edi                            ; inc DMA location
         add ah,al                          ; increment fractional counter
         adc edx,ebp                        ; increment integer counter
         cmp samend,edx                     ; done sample?
         jbe short sbh_firstshot            ; yes, check for looping else exit
         dec ecx                            ; count, dec ecx is faster than loop
         jnz short sbh_addloop

         mov ebp,sbebp                      ; if cpu gets here, sample continues to next DMA chunk
         mov acpos[ebp*4],edx               ; save data from this transfer to use in next
         mov acstep[ebp],ah
         jmp sbh_next

sbh_firstshot:
         mov saveebp,ebp                    ; in case of looping, all registers must remain same
         mov ebp,sbebp
         test accntrl[ebp],loop_on
         jnz sbh_handlelooping

         mov ebp,sbebp                      ; get voice number
         mov accmnd[ebp],0                  ; voice done, clear command
         mov _vccmnd[ebp],0                 ; clear virtual command
         jmp sbh_next                       ; do next voice

sbh_subloop:
         mov bl,[edx]                       ; backwards mixing loop:
         mov bl,[ebx+esi]                   ; volume cross referance, bh = 0 - 15, bl = byte
         add [edi],bl                       ; mix into DMA
         inc edi                            ; inc DMA location
         add ah,al                          ; increment fractional counter
         sbb edx,ebp                        ; decrement integer counter this time
         cmp edx,samend                     ; done sample?
         jbe short sbh_firstshot            ; yes, check for looping else exit
         dec ecx                            ; count, dec ecx is faster than loop
         jnz short sbh_subloop

         mov ebp,sbebp                      ; if cpu gets here, sample continues to next DMA chunk
         mov acpos[ebp*4],edx               ; save data from this transfer to use in next
         mov acstep[ebp],ah
         jmp sbh_next

sbh_handlelooping:
         test accntrl[ebp],loop_bi
         jz short sbh_nobidir
         xor accntrl[ebp],loop_rev          ; flip direction of loop
         push eax ebx
         mov eax,aclend[ebp*4]
         mov ebx,aclbeg[ebp*4]
         mov aclend[ebp*4],ebx
         mov aclbeg[ebp*4],eax
         mov samend,ebx
         pop ebx eax
sbh_nobidir:
         mov edx,aclbeg[ebp*4]
         test accntrl[ebp],loop_rev
         jnz sbh_subtest
         mov ebp,saveebp
         dec ecx                            ; count, dec ecx is faster than loop
         jnz sbh_addloop

sbh_next:
         mov ebp,sbebp
         dec ebp
         jnl _sb_moreloop

         ret

sbh_subtest:
         mov ebp,saveebp                    ; backwards part of bi-directional loop
         dec ecx
         jnz sbh_subloop
         jmp short sbh_next

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Convert actual frequency to SB frequency number
; In:
;   EAX - frequency
; Out:
;   AX - SB frequency scaling number
;   EAX high word - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_sb_getfreq:
         push ebp ebx
         mov ebp,eax
         mov ax,_sfxmiddlec                 ; make pitch tables
         shl eax,16                         ; step[ebx]="middle c" * rawfreq[ebx] / mixrate / rawfreq[24*2]
         movzx ebx,_sbmixspeed
         cdq
         div ebx
         mul ebp

         mov ebp,8664
         div ebp
         shr eax,8

         pop ebx ebp
         ret

code32   ends
         end
