;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Simple Sound FX routines - uses GUS.ASM routines, works on GUS and crappy SB
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

        include pmode.ext
        include gus.ext
        include irq.ext
        include file.ext

        public _vcstarts
        public _load_sams
        public _play_sample
        public _load_lib

_vcstarts dd 40 dup (0) ; sample start locations (next is end) no maxmimum # of samples

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Play sample
; In:
;   AX = sample # to play
;   DL = channel (0-31)
;   BL = volume  (0-15)
;   BH = pan     (0-8)
;   CL = voice control (loop and stuff, usually 0)
;   CH = precalculated frequency (0-59)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_play_sample:
        movzx eax,ax
        movzx edx,dl

        mov edi,[_vcstarts+eax*4]
        mov ebp,[_vcstarts+4+eax*4]
        sub ebp,2

        mov _vcsbeg[edx*4],edi
        mov _vclbeg[edx*4],edi
        mov _vclend[edx*4],ebp

        mov _vcpan+[edx],bh
        mov _vcvol+[edx],bl
        movzx eax,ch
        mov ax,_freqtbl[eax*2]
        mov _vcfreq[edx*2],ax
        mov _vccntrl[edx],cl
        mov _vccmnd[edx],play  ; command comes last
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Load samples from DOS (8bit, unsigned)
; In:
;  EDI => ASCIIZ list of samples to load
;  EDX => Buffer (must be able to contain largest sample)
; Out:
;  EBP = number of samples loaded
;   CF = 1 files not found/failed
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_load_sams:
        xor ebp,ebp
        mov eax,_sfxmem
        mov _vcstarts,eax
lsloop:
        push edx
        mov edx,edi
        call _openfile
        pop edx
        jc lserr

        call _filesize
        mov ecx,eax
        add eax,_sfxmem
        mov _vcstarts[ebp*4+4],eax
        call _readfile

        mov ebx,_sfxmem
        call _sfx_putram
        add _sfxmem,ecx

        call _closefile
        inc ebp
        xor al,al
        mov ecx,64
        repnz scasb
        jcxz lserr
        cmp byte ptr [edi],0
        jne lsloop

        clc
        ret
lserr:
        stc
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Load samples from WAD (8bit, unsigned)
; In:
;  EDI => LSEEKFILE Offset and Length of samples to load
;  EDX => Buffer (must be able to contain largest sample)
;  ECX => number of samples to load
; Out:
;  EBP = number of samples loaded
;   CF = 1 files not found/failed
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_load_lib:
        xor ebp,ebp
        mov eax,_sfxmem
        mov _vcstarts,eax
        xchg ecx,edi
libloop:
        xor bl,bl
        mov eax,[ecx]
        call _lseekfile
        jc qerex
        mov ebx,[ecx+4]
        add ecx,8
        mov esi,_sfxmem
        mov _vcstarts[ebp*4+4],esi
        add _vcstarts[ebp*4+4],ebx
        xchg ecx,ebx
        call _readfile                      ; edx = loc, ecx = len, ebx = build
        xchg esi,ebx
        call _sfx_putram
        add _sfxmem,ecx
        xchg esi,ecx
        inc ebp
        dec edi
        jnz libloop

        clc
qerex:
        call _closefile
        ret

code32  ends
        end
