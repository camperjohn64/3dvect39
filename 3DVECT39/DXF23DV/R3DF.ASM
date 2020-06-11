;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; DXF "Remove 3DFaces"
;
; Lets say you have a 3d object from some bulletin board, but the 3dfaces
; are all screwed up.  Use this utility to remove any 3dfaces but keep the
; wireframe.  After I wrote this, I realized you can do this from  AUTOCAD
; by just selecting ERASE 3DFACE ALL  ... oh, well...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

; Link this with PMODE, FILE, and ARGC

          .386p
          jumps

code32    segment para public use32
          assume cs:code32, ds:code32, ss:code32

          include pmode.ext
          include file.ext
          include argc.ext

          public  _main

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Macros
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

upper     macro regx  ; make register uppercase
          local strl
          cmp regx,"a"
          jb short strl
          cmp regx,"z"
          ja short strl
          sub regx,"a"-"A"
strl:
          endm

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; DATA
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

inputname       db 60 dup (?)
outputname      db 60 dup (?)

buffer          db 60 dup (?)
fileloc         dd 0

dxfo            dd 0      ; start dxf file location
dxfsize         dd 0      ; dxf filesize

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; CODE
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

include extras.rt

errmsg0         db 10,13,'Missing Filename!',0dh,0ah,"$"
errmsg1         db 10,13,'Not Enough Memory!',0dh,0ah,"$"
errmsg2         db 10,13,'Error Opening File!',0dh,0ah,"$"
okmsg           db 10,13,"Bye!",10,13,"$"

exiterr0:
        mov edx,offset errmsg0
        call _putdosmsg
        jmp okerr0
exiterr1:
        mov edx,offset errmsg1
        call _putdosmsg
        jmp okerr0
exiterr2:
        mov edx,offset errmsg2
        call _putdosmsg
        jmp okerr0
okerr0:
        mov edx,offset okmsg
        call _putdosmsg
        jmp _exit

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Allocate memory
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_main:
        call _setbuf

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Parse and open DXF, allocate memory, load DXF, close file
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        xor al,al
        mov edx,offset inputname
        call _cchekstr
        jc exiterr0
        mov edx,offset inputname
        call _openfile
        jc exiterr2
        call _filesize
        mov dxfsize,eax
        call _getlomem
        jc exiterr1
        mov dxfo,eax
        mov fileloc,eax
        mov edx,eax
        mov ecx,dxfsize
        call _readfile
        jc exiterr2
        call _closefile

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Parse and open output filename
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov al,1                        ; check for filename on commandline
        mov edx,offset outputname
        call _cchekstr
        jc exiterr0
        mov edx,offset outputname
        call _createfile
        jc exiterr0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Write new DXF file without 3dfaces
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov edi,dxfo
        mov ebp,edi
        add ebp,dxfsize
        mov dxfsize,ebp

outloop:
        mov fileloc,edi
        mov edx,offset tag1
        mov ebp,dxfsize
        call search_string
        jc done

        push edi
        mov edx,fileloc
        mov ecx,edi
        sub ecx,edx
        cmp ecx,0
        je end2end
        call _writefile
end2end:
        pop edi

        mov edx,offset tag2
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag3
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag4
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag5
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag6
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag7
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag8
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tag9
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset taga
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tagb
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tagc
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tagd
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tage
        mov ebp,dxfsize
        call search_string
        jc exiterr0

        mov edx,offset tagf ; yeah, it should have been a loop but who gives a shit!
        mov ebp,dxfsize
        call search_string
        jc exiterr0
        call next

        jmp outloop
done:
        mov edx,fileloc
        mov ecx,dxfsize
        sub ecx,edx
        cmp ecx,0
        je outq
        call _writefile
outq:
        call _closefile
        jmp _exit

tag1    db "3DFACE",0
tag2    db " 8",0
tag3    db " 10",0
tag4    db " 20",0
tag5    db " 30",0
tag6    db " 11",0
tag7    db " 21",0
tag8    db " 31",0
tag9    db " 12",0
taga    db " 22",0
tagb    db " 32",0
tagc    db " 13",0
tagd    db " 23",0
tage    db " 33",0
tagf    db " 0",0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Unpad string
; In:  EDI => string eg " , Hello th"
; Out: EDI => string (after spaces, colons, whatever) eg "Hello th"
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
unpad:
        dec edi
upx:
        inc edi
        mov al,[edi]
        cmp al,"A"
        jae upretx
        cmp al,"9"
        ja upx
        cmp al,31
        jb upx
upretx:
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Next string
; In:  EDI => string eg "Hello there mi"
; Out: EDI => next string (after spaces, colons, whatever) eg "there mi"
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
next:
        call unpad
        dec edi
nxc:
        inc edi
        mov al,[edi]
        cmp al,"A"
        jae nxc
        cmp al,"9"
        ja nxretc
        cmp al,31
        jae nxc
nxretc:
        jmp unpad

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search_string: Find string at EDX in DXF file
; In:
;   EDX => ASCIIZ string to search for (DXF)
;   EDI = location to start search
;   EBP = location to end search
; Out:
;  CF = 1 - not found
;  CF = 0 - found
;   EDI = location where found
; Notes: String at EDI must have a space or zero at end for search tp succeed.
;  eg:  EDX => "HELLO",0
;       EDI => "ABCDHELLOEFGI" will FAIL! - but " ABCDHELLO DKJ" will succeed!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

search_string:
        mov esi,edx
        mov ecx,edi
ssloop:
        mov al,[esi]
        mov ah,[ecx]
        upper al
        upper ah
        inc esi
        inc ecx
        cmp al,ah
        je ssloop

        cmp al,0
        jne ssabort

        cmp ah,"."
        jae ssabort

        clc
        ret
ssabort:
        cmp ecx,ebp
        jae ssretx

        inc edi
        jmp search_string
ssretx:
        stc
        ret

code32  ends
        end
