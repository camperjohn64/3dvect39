; this code belongs to TRAN

         OPENFILE   = 1
         READFILE   = 1
         WRITEFILE  = 1
         LSEEKFILE  = 1
         CREATEFILE = 1
         FILESIZE   = 1
;        FILECOPY   = 1
;        DELETEFILE = 1
;        FINDFILE   = 1
         ENVIRONMENT = 1
         FINDMARKER  = 1

         .386p
         jumps
code32   segment para public use32
         assume cs:code32, ds:code32

include  pmode.ext
include  macros.inc

public   _filebufloc, _filebuflen
public   _closefile

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
_filebufloc dd 0                            ; location must be in low mem
_filebuflen dw 4000h

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

ifdef    CREATEFILE
public   _createfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Create file
; In:
;   EDX -> ASCIIZ filename
; Out:
;   CF=1 - Error creating file
;   CF=0 - File created succesfully
;     V86R_BX - file handle
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_createfile:
         push ax
         push edx
         add edx,_code32a
         mov ax,dx
         shr edx,4
         and ax,0fh
         mov v86r_dx,ax
         mov v86r_ds,dx
         mov v86r_ax,3c00h
         mov v86r_cx,20h
         mov al,21h
         int 33h
         mov ax,v86r_ax
         mov v86r_bx,ax
         pop edx
         pop ax
         ret
endif

ifdef    OPENFILE
public   _openfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Open file
; In:
;   EDX -> ASCIIZ filename
; Out:
;   CF=1 - Error opening file
;   CF=0 - File opened succesfully
;     V86R_BX - file handle
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_openfile:
         push ax
         push edx
         add edx,_code32a
         mov ax,dx
         shr edx,4
         and ax,0fh
         mov v86r_dx,ax
         mov v86r_ds,dx
         mov v86r_ax,3d02h
         mov al,21h
         int 33h
         mov ax,v86r_ax
         mov v86r_bx,ax
         pop edx
         pop ax
         ret
endif

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Close a file
; In:
;   V86R_BX - file handle
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_closefile:
         push ax
         mov v86r_ax,3e00h
         mov al,21h
         int 33h
         pop ax
         ret

ifdef    DELETEFILE
public   _deletefile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Delete a file
; In:
;   EDX -> ASCIIZ filename
; Out:
;   CF=1 - Error opening file
;   CF=0 - File opened succesfully
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_deletefile:
         push ax
         push edx
         add edx,_code32a
         mov ax,dx
         shr edx,4
         and ax,0fh
         mov v86r_dx,ax
         mov v86r_ds,dx
         mov v86r_ah,41h
         mov al,21h
         int 33h
         pop edx
         pop ax
         ret
endif

ifdef    LSEEKFILE
public   _lseekfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Seek position in file
; In:
;   V86R_BX - file handle
;   EAX - _sineed offset to move to
;   BL - from: 0-beginning of file, 1-current location, 2-end of file
; Out:
;   CF=1  - Error seeking in file
;     EAX - ?
;   CF=0  - Seek fine
;     EAX - new offset from beginning of file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_lseekfile:
         mov v86r_ah,42h
         mov v86r_al,bl
         mov v86r_dx,ax
         shr eax,16
         mov v86r_cx,ax
         mov al,21h
         int 33h
         pushf
         mov ax,v86r_dx
         shl eax,16
         mov ax,v86r_ax
         popf
         ret
endif

ifdef    FILESIZE
public   _filesize
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get size of file
; In:
;   V86R_BX - file handle
; Out:
;   CF=1  - Error checking file
;     EAX - ?
;   CF=0  - chek fine
;     EAX - size of file
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_filesize:
         mov v86r_ax,4201h
         xor eax,eax
         mov v86r_cx,ax
         mov v86r_dx,ax
         mov al,21h
         int 33h
         push v86r_dx
         push v86r_ax
         mov v86r_ax,4202h
         xor eax,eax
         mov v86r_cx,ax
         mov v86r_dx,ax
         mov al,21h
         int 33h
         mov ax,v86r_dx
         shl eax,16
         mov ax,v86r_ax
         pop v86r_dx
         pop v86r_cx
         mov v86r_ax,4200h
         push eax
         mov al,21h
         int 33h
         pop eax
         ret
endif

ifdef    READFILE
public   _readfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Read from file
; In:
;   V86R_BX - file handle
;   EDX -> buffer to read to
;   ECX - number of bytes to read
; Out:
;   CF=1 - Error reading file
;     EAX - ?
;   CF=0 - Read went fine
;     EAX - number of bytes read
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_readfile:
         pushad
         xor ebp,ebp
         add edx,_code32a
         lea ebx,[ecx+edx]
         cmp ebx,100000h
         ja readlong
         mov eax,edx
         shr eax,4
         and dx,0fh
         mov v86r_ds,ax
         mov v86r_dx,dx
readl:
         mov eax,0fff0h
         cmp eax,ecx
         jbe readlf1
         mov eax,ecx
readlf1:
         mov v86r_cx,ax
         mov v86r_ax,3f00h
         mov al,21h
         int 33h
         jc readdone2
         movzx ebx,v86r_ax
         add ebp,ebx
         sub ecx,ebx
         jbe readdone
         or ebx,ebx
         jz readdone
         add v86r_ds,0fffh
         jmp readl
readlong:
         mov edi,edx
         sub edi,_code32a
         mov edx,ecx
         mov eax,_filebufloc
         add eax,_code32a
         mov ebx,eax
         shr eax,4
         and bx,0fh
         mov v86r_ds,ax
         mov v86r_dx,bx
         movzx ebx,_filebuflen
readlongl:
         mov eax,ebx
         cmp eax,edx
         jbe readlonglf1
         mov eax,edx
readlonglf1:
         mov v86r_cx,ax
         mov v86r_ax,3f00h
         mov al,21h
         int 33h
         jc short readdone2
         movzx ecx,v86r_ax
         add ebp,ecx
         mov eax,ecx
         or eax,eax
         jz readdone
         mov esi,_filebufloc
         rep movsb
         sub edx,eax
         ja readlongl
readdone:
         clc
readdone2:
         mov [esp+28],ebp
         popad
         ret
endif

ifdef    WRITEFILE
public   _writefile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Write to file
; In:
;   V86R_BX - file handle
;   EDX -> buffer to write from
;   ECX - number of bytes to write
; Out:
;   CF=1 - Error writing file
;     EAX - ?
;   CF=0 - Write went fine
;     EAX - number of bytes read
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_writefile:
         pushad
         xor ebp,ebp
         add edx,_code32a
         lea ebx,[ecx+edx]
         cmp ebx,100000h
         ja writelong
         mov eax,edx
         shr edx,4
         and ax,0fh
         mov v86r_ds,dx
         mov v86r_dx,ax
writel:
         mov eax,0fff0h
         cmp eax,ecx
         jbe writelf1
         mov eax,ecx
writelf1:
         mov v86r_cx,ax
         mov v86r_ax,4000h
         mov al,21h
         int 33h
         jc writedone2
         movzx ebx,v86r_ax
         add ebp,ebx
         sub ecx,ebx
         jbe writedone
         add v86r_ds,0fffh
         jmp writel
writelong:
         mov esi,edx
         sub esi,_code32a
         mov edx,ecx
         mov eax,_filebufloc
         add eax,_code32a
         mov ebx,eax
         shr eax,4
         and bx,0fh
         mov v86r_ds,ax
         mov v86r_dx,bx
         movzx ebx,_filebuflen
writelongl:
         mov eax,ebx
         cmp eax,edx
         jbe writelonglf1
         mov eax,edx
writelonglf1:
         mov ecx,eax
         mov edi,_filebufloc
         rep movsb
         mov v86r_cx,ax
         mov v86r_ax,4000h
         mov al,21h
         int 33h
         jc writedone2
         movzx ecx,v86r_ax
         add ebp,ecx
         sub edx,ecx
         ja writelongl
writedone:
         clc
writedone2:
         mov [esp+28],ebp
         popad
         ret
endif

ifdef    FILECOPY
public   _filecopy
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Copy some bytes from one file to another
; In:
;   V86R_SI - source file handle
;   V86R_DI - destination file handle
;   ECX - number of bytes to copy
; Out:
;   CF=1  - Error copying file
;     EAX - ?
;   CF=0  - copied fine
;     EAX - number of bytes copied
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_filecopy:
         pushad
         xor ebp,ebp
         mov edx,_filebufloc
         add edx,_code32a
         mov al,dl
         and ax,0fh
         shr edx,4
         mov v86r_ds,dx
         mov v86r_dx,ax
         movzx ebx,_filebuflen
copylongl:
         mov eax,ebx
         cmp eax,ecx
         jbe copylonglf1
         mov eax,ecx
copylonglf1:
         mov v86r_cx,ax
         mov v86r_ax,3f00h
         mov ax,v86r_si
         mov v86r_bx,ax
         mov al,21h
         int 33h
         jc copydone2
         mov ax,v86r_ax
         or ax,ax
         jz copydone
         mov v86r_cx,ax
         mov v86r_ax,4000h
         mov ax,v86r_di
         mov v86r_bx,ax
         mov al,21h
         int 33h
         jc copydone2
         movzx edx,v86r_ax
         add ebp,edx
         sub ecx,edx
         ja copylongl
copydone:
         clc
copydone2:
         mov [esp+28],ebp
         popad
         ret
endif

ifdef    FINDFILE
public   _findfile
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Do an AH=4E findfirst
; In:
;   AL - type of search: 4E-first, 4F-next
;   CX - search attributes
;   EDX -> 13 byte buffer for filename found
;   EDI -> search mask
; Out:
;   CF=1 - file not found
;     [EDX] - ?
;   CF=0 - file found
;     [EDX] - filename
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_findfile:
         push eax
         push esi
         push edi
         add edi,_code32a
         mov esi,edi
         and esi,0fh
         shr edi,4
         mov v86r_ds,di
         mov v86r_dx,si
         mov v86r_ah,al
         mov v86r_cx,cx
         mov esi,_code16a
         sub esi,62h
         mov edi,edx
         mov al,21h
         int 33h
         mov ax,gs
         mov ds,ax
         movsd
         movsd
         movsd
         movsb
         mov ax,es
         mov ds,ax
         pop edi
         pop esi
         pop eax
         ret
endif

ifdef    ENVIRONMENT
         public _setup_env
         public _localpath
         public _envirpath
         public _progname

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; _setup_env - get environment path, program name
; In:
;   null
; Out:
;   _localpath
;   _envirpath
;   _progname
; Notes:
; The following routines are by Alan Illeman
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_setup_env:

         push esi edi
         mov edi, _pspa
         sub edi, _code32a
         movzx eax, word ptr [edi]+2Ch
         segoff2ptr edi, eax, 0

         mov ecx, 32768
         mov al, 1
         cld
         repne scasb
         inc edi
         mov esi, edi
         mov edi, offset _envirpath
envir1:
         lodsb
         stosb
         cmp al, '\'
         jne envir2
         mov ebx, esi
envir2:
         or al, al
         jnz envir1
;--------------------------------------
; save program name
;--------------------------------------
         mov esi, ebx
         mov edi, offset _progname
envir3:
         lodsb
         stosb
         or al, al
         jnz envir3

;--------------------------------------
; get local path
;--------------------------------------
         mov edi, offset _localpath

         mov v86r_ah, 19h                   ; get current disk
         mov al, 21h                        ; doscall
         int 33h
         mov al, v86r_al                    ; 0=A, 1=B, 2=C, etc

         mov dl, al
         inc dl
         add al, 'A'                        ; drive letter
         stosb
         mov al, ':'                        ; colon
         stosb
         mov al, '\'                        ; backslash
         stosb

         ptr2segoff edi, ebx, eax
         mov v86r_ds, bx
         mov v86r_si, ax

         mov v86r_ah, 47h                   ; get current directory
         mov v86r_dl, dl                    ; DL = disk
         mov al, 21h                        ; doscall
         int 33h

         cmp byte ptr [edi], 0              ; no directory ?
         je local1                          ; yes, exit

         mov edi, offset _localpath
         mov ecx, 127
         add edi, ecx
         xor al, al
         std
         repe scasb
         cld
         inc edi
         inc edi

         mov al, '\'                        ; final backslash
         stosb
local1:
         xor al, al                         ; null termination
         stosb

         pop edi esi
         ret

; this is what the above routine sets up for you:

_localpath db 160 dup(0)                    ; current directory with "\" and terminating 0, eg c:\dir\@
_envirpath db 160 dup(0)                    ; directory where program is (along with program name) eg c:\dir\prog.exe@
_progname db 16 dup(0)                      ; program name with terminating 0  eg prog.exe@

         endif

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Findmarker - Find "[MARKER]"+text+0 in file:
;
; In:
; ECX -> ASCIIZ marker text to find.  text is null terminated. max findbuflen characters
;
; Out:
;
; EAX = position in file where marker found (=position after marker, ready to load data)
;  CF=1  - Error seeking in file or marker not found
;  CF=0  - Seek fine
; EBX = filesize (well, it's actually the first dword after the name)
;
; eg:dw x,x,x,x,"[MARKER]databeginshere"
;    dw 0,0,0,0  <- eax will point to this position in file if you seek for "databeginshere",0
;
; Note: File search is from current position. Not start of file
;
; I will use this to store all my data (mods, gifs etc...) at the end  of  the
; executable.  when the appropriate data is required, search the program  name
; for the mod or gif required.  This then returns a seek position to load that
; mod   or     gif    from.     After    assembling    the    main    program,
; copy /b yourprog.exe+marker.txt+data.dat  to concatenate the  data   to  the
; executable.  Where marker.txt = "[MARKER]thing" and you search for  "thing".
; eax will then point to where data.dat is in yourprog.exe
;
; Changes since last time you saw this: (if you ever did)
;
; EBX is the first dword after the marker  name.  you no longer need to add 4
; to the seek location as the first dword is always the length of the file.
; (Assuming you put it there, use HEADER.EXE to put it there automatically)
;
; Also, the file must now be open to start.  Findmarker will position the file
; for the next load location.
;
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
ifdef    FINDMARKER

         public _findmarker

findbuflen equ 32                           ; buffer length to define maximum search _fnt_string size (/2)

_findmarker:
         pushad

        ;xor bl,bl                          ; activate this code for search from
        ;xor eax,eax                        ; start of file rather than current position
        ;call _lseekfile
        ;jc ferror

         mov esi,ecx
         mov ecx,findbuflen
         mov edi,offset lookfor
         rep movsb                          ; move text into buffer

         mov edx, offset findbuffer1
         mov ecx, findbuflen*2
         call _readfile
         jc ferror

         xor esi,esi
         xor edi,edi
         xor ebp,ebp

scanloop:
         mov al,search[esi]
         or al,al
         jz foundit
         cmp findbuffer1[edi],al
         je next
         mov esi,-1
next:
         inc esi
         inc edi
         inc ebp
         cmp edi,findbuflen
         jne scanloop

         push esi
         mov ecx,findbuflen
         mov esi,offset findbuffer2
         mov edi,offset findbuffer1
         rep movsb
         pop esi

         mov edx, offset findbuffer2
         mov ecx,findbuflen
         push ebp
         call _readfile
         pop ebp
         jc ferror
         cmp eax,0
         stc
         je ferror

         xor edi,edi
         jmp scanloop

foundit:
         add ebp,4
         mov [esp+28],ebp
         mov ebx,dword ptr findbuffer1[edi]
         mov [esp+16],ebx
         clc
         mov eax,findbuflen*2-4
         sub eax,edi
         neg eax
         mov bl,1
         call _lseekfile
ferror:
         popad
         ret

search   db "[MARKER]"
lookfor  db findbuflen dup (0)
findbuffer1 db findbuflen dup (0)
findbuffer2 db findbuflen dup (0)

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Build marker file offsets
;In: EDX -> offset of filename for load
;    ECX -> offset of marker header (below)
;    EBP -> offset for file starts and lengths
;eg:
;thelist db "AG.SND",0
;        db "B2.SND",0
;        db "B3.SND",0
;        db "B4.SND",0
;        db "B5.SND",0
;        db 0
;
;theoffs dd 0,0  ; <- points to ag.snd within marker file: offset, length
;        dd 0,0  ; <- points to b2.snd
;        dd 0,0
;        dd 0,0
;        dd 0,0
;
; Out:
;   Marker buffer is modified
;   CF = 0  all found
;   Regs Out = Regs In
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

public   _buildlist
_buildlist:
         pushad
         call _openfile
         jc short ferex
         xor esi,esi
bl_1:
         call _findmarker
         jnc short ferexq
         xor bl,bl
         xor eax,eax
         xor esi,esi
         call _lseekfile
         jc ferex
         call _findmarker
         jc ferex
ferexq:
         add eax,esi;bbb
         mov edi,ecx
         push eax
         mov ecx,16
         xor al,al
         repnz scasb
         mov ecx,edi
         pop eax
         mov [ebp],eax
         mov [ebp+4],ebx
         add ebp,8

         mov eax,ebx
         mov bl,1
         call _lseekfile
         mov esi,eax
         cmp byte ptr [ecx],0
         jne bl_1
         clc
ferex:
         pushf
         call _closefile
         popf
         popad
         ret

         endif

code32   ends
         end
