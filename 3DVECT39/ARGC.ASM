         CCHEKSWITCH = 1
         CCHEKSTR = 1
         CCHEKSSTR = 1
         CCMND = 1
         .386p
code32   segment para public use32
         assume cs:code32, ds:code32, ss:code32

include  pmode.ext

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
setandchek: ; Set up ES, EDI, ECX and chek length
         mov bx,_selzero
         mov es,bx
         mov edi,_pspa
         add edi,81h
         movzx ecx,byte ptr es:[edi-1]
         cmp cl,ah
         jb setandchekf
         ret
setandchekf: ;  command line too short
         add esp,4
         pop es
         popad
         stc
         ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
findswitch: ; Find switch AL on command line
         mov ah,al
         mov ebx,edi
         mov ebp,ecx
findswitchl1:
         mov al,'/'
         repnz scasb
         jecxz findswitch2
         mov al,ah
         dec ecx
         scasb
         jne findswitchl1
         ret
findswitch2:
         mov edi,ebx
         mov ecx,ebp
findswitchl2:
         mov al,'-'
         repnz scasb
         jecxz setandchekf
         mov al,ah
         dec ecx
         scasb
         jne findswitchl2
         ret

ifdef    CCHEKSWITCH
public   _cchekswitchnc, _cchekswitch
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Chek if switch AL entered on command line
; In:
;   AL - switch
; Out:
;   CF=1 - switch does not exist
;   CF=0 - switch exists on command line
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_cchekswitchnc:
         cmp al,'A'
         jb short _cchekswitch
         cmp al,'z'
         ja short _cchekswitch
         cmp al,'a'
         jae short cchekswitchncf0
         cmp al,'Z'
         ja short _cchekswitch
cchekswitchncf0:
         push ax
         and al,0dfh
         call _cchekswitch
         pop ax
         jnc _ret
         push ax
         or al,20h
         call _cchekswitch
         pop ax
         ret
_cchekswitch:
         pushad
         push es
         mov ah,3
         call setandchek
         call findswitch
         pop es
         popad
         clc
         ret
endif

ifdef    CCHEKSTR
public   _cchekstr
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get _fnt_string number AL
; In:
;   AL - _fnt_string number
;   EDX -> buffer for _fnt_string
; Out:
;   CF=1 - _fnt_string not found
;   CF=0 - _fnt_string found
;     EDX - ASCIIZ _fnt_string
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_cchekstr:
         pushad
         push es
         mov ah,2
         call setandchek
         inc al
         mov bl,al
chekstrl1:
         mov al,' '
         repnz scasb
         jecxz chekstrf
         mov al,es:[edi]
         cmp al,'-'
         je chekstrl1
         cmp al,'/'
         je chekstrl1
         dec bl
         jnz chekstrl1
         push ds
         mov ax,es
         mov bx,ds
         mov es,bx
         mov ds,ax
         mov esi,edi
         mov edi,edx
chekstrl2:
         lodsb
         stosb
         cmp al,' '
         loopnz chekstrl2
         jnz chekstrf1
         dec edi
chekstrf1:
         xor al,al
         stosb
         pop ds
         pop es
         popad
         clc
         ret
chekstrf:
         pop es
         popad
         stc
         ret
endif

ifdef    CCHEKSSTR
public   _ccheksstr
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get _fnt_string associated with switch AL
; In:
;   AL - switch
;   EDX -> buffer for _fnt_string
; Out:
;   CF=1 - _fnt_string not found
;   CF=0 - _fnt_string found or switch does not have _fnt_string
;     EDX - ASCIIZ _fnt_string
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_ccheksstr:
         pushad
         push es
         mov ah,4
         call setandchek
         call findswitch
         jecxz chekstrf
         cmp byte ptr es:[edi],' '
         je chekstrf
         push ds
         mov ax,es
         mov bx,ds
         mov es,bx
         mov ds,ax
         mov esi,edi
         mov edi,edx
cheksstrl2:
         lodsb
         stosb
         cmp al,' '
         loopnz cheksstrl2
         jnz cheksstrf1
         dec edi
cheksstrf1:
         xor al,al
         stosb
         pop ds
         pop es
         popad
         clc
         ret
endif


ifdef    CCMND
         public _ccmndsave, _ccmndrestore
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Save command line into buffer (doesnt record EXE name)
; In:
;  EDX -> buffer for command line
; Out:
;  EAX - command line length
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_ccmndsave:
         pushad
         push es
         mov ah,2
         call setandchek

         push ds
         mov ax,es
         mov bx,ds
         mov es,bx
         mov ds,ax
         mov esi,edi
         mov edi,edx
         mov edx,ecx
shekstrl2:
         lodsb
         stosb
         loop shekstrl2

         pop ds
         pop es
         mov [esp+28],edx
         popad
         clc
         ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Save command line into buffer (doesnt record EXE name)
; In:
;  EDX -> original command line buffer
;   AL -  command line length
; Out: null
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_ccmndrestore:
         pushad
         push es
         mov ah,2
         call setandchek

         mov byte ptr es:[edi-1],al
         movzx ecx,al

         push ds
         mov esi,edx
reskstrl2:
         lodsb
         stosb
         loop reskstrl2

         pop ds
         pop es
         popad
         clc
         ret
endif

code32   ends
         end

