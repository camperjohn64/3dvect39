;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
;        Filename     : Math.inc
;        Included from: 3D1.ASM, 3D2.ASM, 3D3.ASM
;        Description  : General math functions.
;
;        Written by: John McCarthy
;                    1316 Redwood Lane
;                    Pickering, Ontario.
;                    Canada, Earth, Milky Way (for those out-of-towners)
;                    L1X 1C5
;
;        Internet/Usenet:  BRIAN.MCCARTHY@CANREM.COM
;                Fidonet:  Brian McCarthy 1:229/15
;          RIME/Relaynet: ->CRS
;
;        Home phone, (905) 831-1944, don't call at 2 am eh!
;
; Send me your protected mode source code!
; Send me your Objects!
; But most of all, Send me a postcard!!!!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         public _rotate_point               ; _rotate_point using _vmatrix
         public _user3d                     ; calculate 3d ?actual*?/z (both x and y)
         public _user3dx                    ; xactual*x/z
         public _user3dy                    ; yactual*y/z
         public _rotate_by_camera           ; 32 bit _rotate_point using _ematrix
         public _zsolve                     ; solve single equation variable
         public _ysolve
         public _xsolve
         public _cosine
         public _sine
         public _arctan
         public _compound                   ; generate rotation matrix (includes camera)
         public _setsincose                 ; set camera matrix
         public _temp_matrix                ; set user defined/temporary matrix
         public _temp_rotate_point          ; rotate point by temp matrix (tmatrix)
         public _matrix_multiply            ; multiply _tmatrix by _vmatrix
         public _null_y_matrix
         public _inverse_rotate
         public _rotate_x
         public _rotate_y
         public _rotate_z
         public _point_z                    ; align z angle to point EBX,ECX and EBP
         public _sqrt                       ; eax=sqr(eax), thanks to TRAN!

         public _pre_cal_lambert            ; scan object si and calculate surface normals
         public _calc_normal                ; guess...from 3 points, returns vector ebx,ecx,ebp
         public _calc_d                     ; calculate D from plane equation
         public _lambert                    ; calculate surface normal rotation matrix for object si
         public _set_up_all_lambert         ; scans objects from si to di and calls _pre_cal_lambert
         public _l_rotate_point             ; given normal for surface, figures out intensity

         public _lx1                        ; points to load up before calling _calc_normal
         public _ly1
         public _lz1
         public _lx2
         public _ly2
         public _lz2
         public _lx3
         public _ly3
         public _lz3

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _rotate_point - 32 bit _rotate_point point using _vmatrix
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;     _vmatrix - 32 bit rotation matrix - set up by "_compound" routine
; Out:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;
; Notes:
;
; All rotations (_rotate_by_camera,_rotate_point,_temp_rotate_point) are 32 bit.
; _f_rotate_point uses rotation along a plane and uses _ematrix with _precal147
;
; point rotation
; ebx = x   ecx = y   ebp = z    32 bit rotation!
; clobbers edx,esi,eax
;
; remember , matrix offsets are:
;
;  0 1 2     multiply those by 4 for the word address of the matrix
;  3 4 5
;  6 7 8
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_rotate_point:
         mov eax,_vmatrix+8                 ; solve x = bx(0)+cx(1)+bp(2)
         imul ebp
         shrd eax,edx,14
         mov edi,eax
         mov eax,_vmatrix+4
         imul ecx
         shrd eax,edx,14
         add edi,eax
         mov eax,_vmatrix+0
         imul ebx
         shrd eax,edx,14
         add edi,eax                        ; di = new x

         mov eax,_vmatrix+20                ; solve y = bx(3)+cx(4)+bp(5)
         imul ebp
         shrd eax,edx,14
         mov esi,eax
         mov eax,_vmatrix+16
         imul ecx
         shrd eax,edx,14
         add esi,eax
         mov eax,_vmatrix+12
         imul ebx
         shrd eax,edx,14
         add esi,eax                        ; si = new y

         mov eax,_vmatrix+32                ; solve z = bx(6)+cx(7)+bp(8)
         imul ebp
         shrd eax,edx,14
         mov ebp,eax
         mov eax,_vmatrix+28
         imul ecx
         shrd eax,edx,14
         add ebp,eax
         mov eax,_vmatrix+24
         imul ebx
         shrd eax,edx,14
         add ebp,eax                        ; bp = new z

         mov ecx,esi
         mov ebx,edi

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _user3d - scale 3d point into 2d point
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
; Out:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;
; Notes:
;
; fast ratios found in macros.inc since
; multiplication has been substituted with fast lea
;
; trashes eax,edx,edi
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_user3d:                                    ; bp must always be non-zero
         cmul eax,ebx,ratiox                ; use fast constant multiply

         idiv ebp
         mov ebx,eax

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _user3dy - scale 3d point into 2d point on x axis only
; In:
;    ECX - y point
;    EBP - z point
; Out:
;    ECX - y point
;    EBP - z point
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_user3dy:
         cmul eax,ecx,ratioy

         idiv ebp
         mov ecx,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _user3dx - scale 3d point into 2d point on y axis only
; In:
;    EDI - x point
;    ESI - z point
; Out:
;    EDI - x point
;    ESI - z point
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_user3dx:                                   ; bp must always be non-zero
         cmul eax,edi,ratiox

         idiv esi
         mov edi,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Checkfront: checks if a side is visible. (counter-clockwise)
;
; In:
;   (EDI,EBP) - xy of point 1
;   (ESI,ECX) - xy of point 2
;   (EDX,EBX) - xy of point 3
; Out:
;   ECX < 0 if side counter-clockwise
;
; Notes: routine courtesy of "RAZOR"
; eg:
;          call checkfront
;          cmp ecx,0
;          jng dontdraw
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같


         align 4

checkfront:
         cmp edi,esi
         jng s cfc
         mov eax,edi
         mov edi,esi
         mov esi,edx
         mov edx,eax
         mov eax,ebp
         mov ebp,ecx
         mov ecx,ebx
         mov ebx,eax
cfc:
         mov eax,edx                        ; ax = x3
         sub eax,edi                        ; ax = x3 - _x1
         sub ecx,ebp                        ; cx = _y2 - _y1
         imul ecx                           ; ax = (x3-_x1)*(_y2-_y1)
         mov ecx,eax                        ; save it...
         mov eax,esi                        ; ax = _x2
         sub eax,edi                        ; ax = _x2 - _x1
         sub ebx,ebp                        ; bx = y3 - _y1
         imul ebx                           ; ax = (_x2-_x1)*(y3-_y1)
         sub ecx,eax                        ; cx = (x3-_x1)*(_y2-_y1)-(_x2-_x1)*(y3-_y1)
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _rotate_by_camera - 32 bit _rotate_point point using _ematrix
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;     _ematrix - 32 bit rotation matrix - set up by "_setsincose" routine
; Out:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;
; Notes:
;
; point rotation for eye - solves all x,y,z parameters
; camera rotation is 32 bit and uses _ematrix
;
; remember , matrix offsets are:
;
;  0 1 2     multiply those by 4 for the doubleword address of the matrix
;  3 4 5
;  6 7 8
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_rotate_by_camera:
         mov eax,_ematrix+8
         imul ebp
         shrd eax,edx,14
         mov edi,eax
         if usez eq yes
         mov eax,_ematrix+4
         imul ecx
         shrd eax,edx,14
         add edi,eax
         endif
         mov eax,_ematrix+0
         imul ebx
         shrd eax,edx,14
         add edi,eax                        ; di = new x

         mov eax,_ematrix+20
         imul ebp
         shrd eax,edx,14
         mov esi,eax
         mov eax,_ematrix+16
         imul ecx
         shrd eax,edx,14
         add esi,eax
         mov eax,_ematrix+12
         imul ebx
         shrd eax,edx,14
         add esi,eax                        ; si = new y

         mov eax,_ematrix+32
         imul ebp
         shrd eax,edx,14
         mov ebp,eax
         mov eax,_ematrix+28
         imul ecx
         shrd eax,edx,14
         add ebp,eax
         mov eax,_ematrix+24
         imul ebx
         shrd eax,edx,14
         add ebp,eax                        ; bp = new z

         mov ecx,esi
         mov ebx,edi

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _zsolve - 32 bit rotate point using _ematrix - solve one variable only
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;    _ematrix - 32 bit rotation matrix - set up by "_setsincose" routine
;
; Out:
;    EBX - x point (same as entry)
;    ECX - y point (same as entry)
;    EBP - z point (same as entry)
;    ESI - new z point/location
;
; Notes:
;
; solve z from _ematrix - same as above _rotate_by_camera but only solves z for fast
; test of where object is - result is in esi
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_zsolve:
         mov eax,_ematrix+32
         imul ebp
         shrd eax,edx,14
         mov esi,eax
         mov eax,_ematrix+28
         imul ecx
         shrd eax,edx,14
         add esi,eax
         mov eax,_ematrix+24
         imul ebx
         shrd eax,edx,14
         add esi,eax                        ; si = new z
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _xsolve - 32 bit rotate point using _ematrix - solve one variable only
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;    _ematrix - 32 bit rotation matrix - set up by "_setsincose" routine
;
; Out:
;    EBX - x point (same as entry)
;    ECX - y point (same as entry)
;    EBP - z point (same as entry)
;    EDI - new x point/location
;
; Notes:
; If object z test from above routine is positive, this routine will solve
; the rest of the rotation matrix.  this is so we don't waste time solving
; for x and y locations if the object is behind the camera anyway.
; Saves imuls.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4
_xsolve:
         mov eax,_ematrix+8
         imul ebp
         shrd eax,edx,14
         mov edi,eax
         if usez eq yes
         mov eax,_ematrix+4
         imul ecx
         shrd eax,edx,14
         add edi,eax
         endif
         mov eax,_ematrix+0
         imul ebx
         shrd eax,edx,14
         add edi,eax                        ; di = new x
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _ysolve - 32 bit rotate point using _ematrix - solve one variable only
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;    ESI - new z point
;    EDI - new x point
;    _ematrix - 32 bit rotation matrix - set up by "_setsincose" routine
;
; Out:
;    EBX - x new point from EDI
;    ECX - y new point
;    EBP - z new point from ESI
;
; Notes:
;
; Solve y from _ematrix - same as above _xsolve but solves y for fast
; test of where object is.  Final variables are then cleaned up to
; immitate the _rotate_by_camera function in parts.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4
_ysolve:
         mov eax,_ematrix+16
         imul ecx
         shrd eax,edx,14
         mov ecx,eax
         mov eax,_ematrix+12
         imul ebx
         shrd eax,edx,14
         add ecx,eax
         mov eax,_ematrix+20
         imul ebp
         shrd eax,edx,14
         add ecx,eax                        ; cx = new y

         mov ebx,edi                        ; final test, move into appropriate regs
         mov ebp,esi

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
;   _sine - 16 bit theta to 32bit sin(@)
; In:
;     AX - theta  0 - 65536 (0-360)
; Out:
;    EAX - sin (@)   (-4000h to 4000h)
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _cosine - 16 bit theta to 32bit cos(@)
; In:
;     AX - theta  0 - 65536 (0-360)
; Out:
;    EAX - cos (@)   (-4000h to 4000h)
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Notes:
; calculate sin into eax, from ax, smashes bx
; after imul by sin, shr eax,14 to compensate for decimal factor!
;  eg:
;    mov eax,sin(@)
;    mov ebx,32bitnumber
;    imul ebx
;    shrd eax,edx,14
;    eax = ebx*sin(@)
;
;    mov ax,sin(@)
;    mov bx,16bitnumber
;    imul bx
;    shrd ax,dx,14
;    eax = bx*sin(@)
;
; eax is only a sign extended ax and will contain either ffffxxxx or 0000xxxx
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_cosine:
         add ax,4000h
_sine:
         shr ax,2
         cmp ax,2000h
         jge s q3o4                         ; quadrant 3 or 4

         cmp ax,1000h
         jl s q0                            ; quad 1

         mov ebx,1fffh
         sub bx,ax
         jmp s half_sine                    ; quad 2
q0:
         movzx ebx,ax
         jmp s half_sine
q3o4:
         cmp ax,3000h
         jl s q3
         mov ebx,3fffh
         sub bx,ax
         call half_sine                     ; quad 4
         neg eax
         ret
q3:
         and ax,0fffh
         movzx ebx,ax                       ; quad 3
         call half_sine
         neg eax
         ret
half_sine:
         xor eax,eax
         mov ax,w sinus[ebx*2]
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Arctan - 32 bit rise/run to 16bit arctan(rise/run)
; In:
;    EAX - Run
;    ECX - Rise
; Out:
;     AX - arctan(ECX/EAX)
;
; Notes:
; smashes cx,ax,dx,si
; arctan(ecx/0) is valid and tested for
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_arctan:
         or eax,eax
         jl s qd2or3
         je findmax
         or ecx,ecx
         jge s halftax                      ; quadrant 1
         neg ecx                            ; quadrant 4, ax=-ax
         call halftan
         neg ax
         shl eax,2
         ret
qd2or3:
         neg eax
         or ecx,ecx
         jge s qd2
         neg ecx                            ; quad 3, ax=ax+8192
         call halftan
         add ax,8192
         shl eax,2
         ret
qd2:
         call halftan
         neg ax
         add ax,8192
         shl eax,2
         ret
halftax:
         call halftan
         shl eax,2
         ret

         align 4

halftan:
         xor edx,edx

; cx=rise  positive
; ax=run   positive

         cmp eax,ecx
         jl s opptan                        ; greater than 45 degrees, other side...

         xchg ecx,eax                       ; ax<cx
         shld edx,eax,11                    ; *2048 edx = high dword for divide
         shl eax,11                         ; *2048
         div ecx
         movzx esi,ax
         mov ax,w negtan[esi*2]             ; resulting angle (0-512 is 0-45) in ax
         ret

         align 4

opptan:
         shld edx,eax,11                    ; *2048 edx = high dword for divide
         shl eax,11                         ; *2048

         div ecx
         movzx esi,ax                       ; ax remainder
         mov cx,w negtan[esi*2]
         mov eax,1000h
         sub ax,cx                          ; resulting angle (2048-4096 is 45-90) in ax
         ret

findmax:
         mov eax,16384
         or ecx,ecx
         jge _ret
         neg eax
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _compound - generate object matrix, 12 imul's first
; In:
;    ESI - Object # to get angles from
;    v_vxs[esi*2] - object x angle (0-65536)
;    v_vys[esi*2] - object y angle (0-65536)
;    v_vzs[esi*2] - object z angle (0-65536)
; Out:
;    _vmatrix - resulting rotation matrix including camera matrix
;    ESI = ESI
;
; Notes:
;              x                         y                      z
;
;x=  cz * cy - sx * sy * sz   - sz * cy - sx * sy * cz     - cx * sy
;
;y=         sz * cx                   cx * cz                - sx
;
;z=  cz * sy + sx * sz * cy   - sy * sz + sx * cy * cz       cx * cy
;
;then perform matrix multiply by negative x and z matricies
;
; -x matrix                             -z matrix
;     x       y       z                   x       y       z
;
;x    1       0       0                cz     sz       0
;
;y    0      cx       sx              -sz     cz       0
;
;z    0     -sx       cx                0      0       1
;
; Notice original object matrix takes 12 imuls, camera modify takes 24, can
; you do this faster? (less imuls)
;
; A call to _setsincose MUST have taken place for this routine to calculate
; the camera matrix correctly.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_compound:
         push esi

         mov ax,v_vxs[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosx,eax
         pop eax
         call _sine
         mov vsinx,eax
         mov ebp,eax                        ; bp = sx
         neg eax
         mov [_vmatrix+20],eax

         mov ax,v_vzs[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosz,eax
         mov edi,eax                        ; di = cz
         pop eax
         call _sine
         mov vsinz,eax
         mov edx,eax                        ; dx = sz

         mov ax,v_vys[esi*2]
         neg ax
         add ax,eyeay
         push eax
         call _cosine
         mov vcosy,eax
         pop eax
         call _sine
         mov vsiny,eax                      ; ax = sy

         mov ebx,edx                        ; save sz

         mov ecx,eax                        ; save sy

         imul ebx                           ; bx = - sy * sz
         shrd eax,edx,14
         mov ebx,eax
         neg ebx
         mov [_vmatrix+28],ebx

         mov eax,ecx                        ; si = cz * sy
         imul edi
         shrd eax,edx,14
         mov esi,eax
         mov [_vmatrix+24],esi

         mov eax,vcosy

         imul edi                           ; di = cy * cz
         shrd eax,edx,14
         mov edi,eax
         mov [_vmatrix+0],edi

         mov eax,vsinz
         mov ecx,vcosy

         imul ecx                           ; cx = - sz * cy
         shrd eax,edx,14
         mov ecx,eax
         neg ecx
         mov [_vmatrix+4],ecx

         mov eax,ebp
         imul esi
         shrd eax,edx,14
         mov esi,eax
         neg esi
         add [_vmatrix+4],esi

         mov eax,ebp
         imul edi
         shrd eax,edx,14
         mov edi,eax
         add [_vmatrix+28],edi

         mov eax,ebp
         imul ebx
         shrd eax,edx,14
         mov ebx,eax
         add [_vmatrix+0],ebx

         mov eax,ebp
         imul ecx
         shrd eax,edx,14
         mov ecx,eax
         neg ecx
         add [_vmatrix+24],ecx

         mov esi,vcosx

         mov eax,vcosy
         imul esi                           ; cx * cy
         shrd eax,edx,14
         mov [_vmatrix+32],eax

         mov eax,vsiny
         imul esi                           ;-cx * sy
         shrd eax,edx,14
         neg eax
         mov [_vmatrix+8],eax

         mov eax,vsinz
         imul esi                           ; cx * sz
         shrd eax,edx,14
         mov [_vmatrix+12],eax

         mov eax,vcosz
         imul esi                           ; cx * cz
         shrd eax,edx,14
         mov [_vmatrix+16],eax

         mov edi,_ecosx                      ; now perform camera x rotation,12 imuls
         mov esi,_esinx
         mov ebp,esi
         neg ebp

         mov eax,[_vmatrix+12]
         imul edi
         shrd eax,edx,14
         mov ecx,eax

         mov eax,[_vmatrix+24]
         imul esi
         shrd eax,edx,14

         add ecx,eax                        ; ecx = new _vmatrix+12

         mov eax,[_vmatrix+12]
         imul ebp
         shrd eax,edx,14
         mov ebx,eax

         mov eax,[_vmatrix+24]
         imul edi
         shrd eax,edx,14

         add ebx,eax                        ; ebx = new _vmatrix+24

         mov [_vmatrix+12],ecx
         mov [_vmatrix+24],ebx

         mov eax,[_vmatrix+16]
         imul edi
         shrd eax,edx,14
         mov ecx,eax

         mov eax,[_vmatrix+28]
         imul esi
         shrd eax,edx,14

         add ecx,eax                        ; ecx = new _vmatrix+16

         mov eax,[_vmatrix+16]
         imul ebp
         shrd eax,edx,14
         mov ebx,eax

         mov eax,[_vmatrix+28]
         imul edi
         shrd eax,edx,14

         add ebx,eax                        ; ebx = new _vmatrix+28

         mov [_vmatrix+16],ecx
         mov [_vmatrix+28],ebx

         mov eax,[_vmatrix+20]
         imul edi
         shrd eax,edx,14
         mov ecx,eax

         mov eax,[_vmatrix+32]
         imul esi
         shrd eax,edx,14

         add ecx,eax                        ; ecx = new _vmatrix+20

         mov eax,[_vmatrix+20]
         imul ebp
         shrd eax,edx,14
         mov ebx,eax

         mov eax,[_vmatrix+32]
         imul edi
         shrd eax,edx,14

         add ebx,eax                        ; ebx = new _vmatrix+32

         mov [_vmatrix+20],ecx
         mov [_vmatrix+32],ebx

         if usez eq yes
         cmp eyeaz,0
         je cp_noz

         mov edi,_ecosz                      ; now perform camera z rotation,12 imuls
         mov esi,_esinz
         mov ebp,esi
         neg esi

         mov eax,[_vmatrix+0]
         imul edi
         shrd eax,edx,14
         mov ecx,eax

         mov eax,[_vmatrix+12]
         imul esi
         shrd eax,edx,14

         add ecx,eax

         mov eax,[_vmatrix+0]
         imul ebp
         shrd eax,edx,14
         mov ebx,eax

         mov eax,[_vmatrix+12]
         imul edi
         shrd eax,edx,14

         add ebx,eax

         mov [_vmatrix+0],ecx
         mov [_vmatrix+12],ebx

         mov eax,[_vmatrix+4]
         imul edi
         shrd eax,edx,14
         mov ecx,eax

         mov eax,[_vmatrix+16]
         imul esi
         shr eax,14
         movsx eax,ax

         add ecx,eax

         mov eax,[_vmatrix+4]
         imul ebp
         shrd eax,edx,14
         mov ebx,eax

         mov eax,[_vmatrix+16]
         imul edi
         shrd eax,edx,14

         add ebx,eax

         mov [_vmatrix+4],ecx
         mov [_vmatrix+16],ebx

         mov eax,[_vmatrix+8]
         imul edi
         shrd eax,edx,14
         mov ecx,eax

         mov eax,[_vmatrix+20]
         imul esi
         shrd eax,edx,14

         add ecx,eax

         mov eax,[_vmatrix+8]
         imul ebp
         shrd eax,edx,14
         mov ebx,eax

         mov eax,[_vmatrix+20]
         imul edi
         shrd eax,edx,14

         add ebx,eax

         mov [_vmatrix+8],ecx
         mov [_vmatrix+20],ebx

         endif
cp_noz:
         pop esi
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _setsincose - generate rotation matrix for  y,x,z  camera rotation
;
; In:
;    eyeax - camera x angle (0-65536)
;    eyeay - camera y angle (0-65536)
;    eyeaz - camera z angle (0-65536)
; Out:
;    _vmatrix - resulting rotation matrix including camera matrix
;
; Notes:
; called only once every frame.  completed in 12 multiplys
; matrix is also used for objects with no rotation (always angle 0,0,0)
;
; where is my postcard! see readme.doc for info.
;
;              x                    y                    z
;
; x=  cz * cy + sx * sy * sz     -cx * sz     - sy * cz + sx * cy * sz
;
; y=  sz * cy - sx * sy * cz      cx * cz     - sy * sz - sx * cy * cz
;
; z=         cx * sy                 sx                cx * cy
;
;
;  matrix offsets: (doublewords)
;
;     x  y  z
;
; x    0  4  8
; y   12 16 20
; z   24 28 32
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_setsincose:
         mov ax,eyeax
         call _cosine
         mov _ecosx,eax                     ; _ecosx and such are used by object rotation
         mov ax,eyeax                      ; _ematrix is used to find where object is
         call _sine
         mov _esinx,eax
         mov [_ematrix+28],eax
         mov ebp,eax                        ; bp = sx

         if usez eq yes
         mov ax,eyeaz
         call _cosine
         mov _ecosz,eax
         mov edi,eax                        ; di = cz
         mov ax,eyeaz
         call _sine
         mov _esinz,eax
         mov edx,eax                        ; dx = sz
         endif

         if usez eq no
         mov edi,4000h                      ; di = cos 0
         mov _ecosz,4000h
         xor edx,edx                        ; dx = sin 0
         mov _esinz,0
         endif

         mov ax,eyeay
         call _cosine
         mov _ecosy,eax
         mov ax,eyeay
         call _sine
         mov _esiny,eax                      ; ax = sy

         mov ebx,edx                        ; save sz

         mov ecx,eax                        ; save sy

         imul ebx                           ; bx = sy * sz
         shrd eax,edx,14
         mov ebx,eax
         neg ebx
         mov [_ematrix+20],ebx
         neg ebx

         mov eax,ecx                        ; si = - (cz * sy)
         imul edi
         shrd eax,edx,14
         mov esi,eax
         neg esi
         mov [_ematrix+8],esi

         mov eax,_ecosy

         imul edi                           ; di = cy * cz
         shrd eax,edx,14
         mov edi,eax
         mov [_ematrix+0],edi

         mov eax,_esinz
         mov ecx,_ecosy

         imul ecx                           ; cx = sz * cy
         shrd eax,edx,14
         mov ecx,eax
         mov [_ematrix+12],ecx

         mov eax,ebp
         imul esi
         shrd eax,edx,14
         mov esi,eax
         add [_ematrix+12],esi

         mov eax,ebp
         imul edi
         shrd eax,edx,14
         mov edi,eax
         neg edi
         add [_ematrix+20],edi

         mov eax,ebp
         imul ebx
         shrd eax,edx,14
         mov ebx,eax
         add [_ematrix+0],ebx

         mov eax,ebp
         imul ecx
         shrd eax,edx,14
         mov ecx,eax
         add [_ematrix+8],ecx

         mov esi,_ecosx

         mov eax,_ecosy
         imul esi                           ; cx * cy
         shrd eax,edx,14
         mov [_ematrix+32],eax

         mov eax,_esiny
         imul esi                           ; cx * sy
         shrd eax,edx,14
         mov [_ematrix+24],eax

         mov eax,_esinz
         imul esi                           ;-cx * sz
         shrd eax,edx,14
         neg eax
         mov [_ematrix+4],eax

         mov eax,_ecosz
         imul esi                           ; cx * cz
         shrd eax,edx,14
         mov [_ematrix+16],eax

         neg _esinx                         ; reverse angles for object rotation
         neg _esiny

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _temp_matrix: generate temp matrix, 12 imul's, from object esi
;
; In:
;    ESI - Object # to get angles from
;    v_vxs[esi*2] - object x angle (0-65536)
;    v_vys[esi*2] - object y angle (0-65536)
;    v_vzs[esi*2] - object z angle (0-65536)
; Out:
;    _tmatrix - resulting rotation matrix (excluding camera matrix)
;    ESI = ESI
;
; Notes:
;              x                         y                      z
;
;x=  cz * cy - sx * sy * sz   - sz * cy - sx * sy * cz     - cx * sy
;
;y=         sz * cx                   cx * cz                - sx
;
;z=  cz * sy + sx * sz * cy   - sy * sz + sx * cy * cz       cx * cy
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_temp_matrix:
         push esi

         mov ax,v_vxs[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosx,eax
         pop eax
         call _sine
         mov vsinx,eax
         mov ebp,eax                        ; bp = sx
         neg eax
         mov [_tmatrix+20],eax

         mov ax,v_vzs[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosz,eax
         mov edi,eax                        ; di = cz
         pop eax
         call _sine
         mov vsinz,eax
         mov edx,eax                        ; dx = sz

         mov ax,v_vys[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosy,eax
         pop eax
         call _sine
         mov vsiny,eax                      ; ax = sy

         mov ebx,edx                        ; save sz

         mov ecx,eax                        ; save sy

         imul ebx                           ; bx = - sy * sz
         shr eax,14
         movsx ebx,ax
         neg ebx
         mov [_tmatrix+28],ebx

         mov eax,ecx                        ; si = cz * sy
         imul edi
         shr eax,14
         movsx esi,ax
         mov [_tmatrix+24],esi

         mov eax,vcosy

         imul edi                           ; di = cy * cz
         shr eax,14
         movsx edi,ax
         mov [_tmatrix+0],edi

         mov eax,vsinz
         mov ecx,vcosy

         imul ecx                           ; cx = - sz * cy
         shr eax,14
         movsx ecx,ax
         neg ecx
         mov [_tmatrix+4],ecx

         mov eax,ebp
         imul esi
         shr eax,14
         movsx esi,ax
         neg esi
         add [_tmatrix+4],esi

         mov eax,ebp
         imul edi
         shr eax,14
         movsx edi,ax
         add [_tmatrix+28],edi

         mov eax,ebp
         imul ebx
         shr eax,14
         movsx ebx,ax
         add [_tmatrix+0],ebx

         mov eax,ebp
         imul ecx
         shr eax,14
         movsx ecx,ax
         neg ecx
         add [_tmatrix+24],ecx

         mov esi,vcosx

         mov eax,vcosy
         imul esi                           ; cx * cy
         shr eax,14
         movsx eax,ax
         mov [_tmatrix+32],eax

         mov eax,vsiny
         imul esi                           ;-cx * sy
         shr eax,14
         movsx eax,ax
         neg eax
         mov [_tmatrix+8],eax

         mov eax,vsinz
         imul esi                           ; cx * sz
         shr eax,14
         movsx eax,ax
         mov [_tmatrix+12],eax

         mov eax,vcosz
         imul esi                           ; cx * cz
         shr eax,14
         movsx eax,ax
         mov [_tmatrix+16],eax

         pop esi
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _temp_rotate_point - 32 bit _rotate_point point using _tmatrix
; In:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;     _tmatrix - 32 bit rotation matrix - set up by "_temp_matrix" routine
; Out:
;    EBX - x point
;    ECX - y point
;    EBP - z point
;
; Notes:
;  Same as _rotate_point and _rotate_by_camera
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_temp_rotate_point:
         mov eax,_tmatrix+8                 ; solve x = bx(0)+cx(1)+bp(2)
         imul ebp
         shrd eax,edx,14
         mov edi,eax
         mov eax,_tmatrix+4
         imul ecx
         shrd eax,edx,14
         add edi,eax
         mov eax,_tmatrix+0
         imul ebx
         shrd eax,edx,14
         add edi,eax                        ; di = new x

         mov eax,_tmatrix+20                ; solve y = bx(3)+cx(4)+bp(5)
         imul ebp
         shrd eax,edx,14
         mov esi,eax
         mov eax,_tmatrix+16
         imul ecx
         shrd eax,edx,14
         add esi,eax
         mov eax,_tmatrix+12
         imul ebx
         shrd eax,edx,14
         add esi,eax                        ; si = new y

         mov eax,_tmatrix+32                ; solve z = bx(6)+cx(7)+bp(8)
         imul ebp
         shrd eax,edx,14
         mov ebp,eax
         mov eax,_tmatrix+28
         imul ecx
         shrd eax,edx,14
         add ebp,eax
         mov eax,_tmatrix+24
         imul ebx
         shrd eax,edx,14
         add ebp,eax                        ; bp = new z

         mov ecx,esi
         mov ebx,edi

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _matrix_multiply: multiply _tmatrix by _vmatrix, [_vmatrix]=[_tmatrix][_vmatrix]
;
; In:
;    _vmatrix - rotation matrix
;    _tmatrix - rotation matrix
; Out:
;    _vmatrix - resulting rotation matrix
;
; Notes:
;
; [ _tmatrix+ 0 _tmatrix+ 2 _tmatrix+ 4 ] [ _vmatrix+ 0 _vmatrix+ 2 _vmatrix+ 4 ]
; [                                  ] [                                  ]
; [ _tmatrix+ 6 _tmatrix+ 8 _tmatrix+10 ] [ _vmatrix+ 6 _vmatrix+ 8 _vmatrix+10 ]
; [                                  ] [                                  ]
; [ _tmatrix+12 _tmatrix+14 _tmatrix+16 ] [ _vmatrix+12 _vmatrix+14 _vmatrix+16 ]
;
; Think of it this way, this routine will generate a resulting matrix as  if
; you _rotate_pointd an  object by _tmatrix, then _rotate_pointd  the  object  by  _vmatrix.
; Instead, call this routine then you will only have to _rotate_point the object by
; _vmatrix!.
;
; Notice _tmatrix is done before _vmatrix!!  This is used for calculating the
; positions of arms on bodies, hands on arms, fingers on hands...etc...
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_matrix_multiply:

         mov ebx,[_vmatrix+0]
         mov ecx,[_vmatrix+4]
         mov ebp,[_vmatrix+8]

         mov eax,[_tmatrix+0]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+12]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+24]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+0

         mov eax,[_tmatrix+4]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+16]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+28]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+4

         mov eax,[_tmatrix+8]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+20]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+32]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+8

         mov ebx,[_vmatrix+12]
         mov ecx,[_vmatrix+16]
         mov ebp,[_vmatrix+20]

         mov eax,[_tmatrix+0]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+12]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+24]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+12

         mov eax,[_tmatrix+4]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+16]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+28]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+16

         mov eax,[_tmatrix+8]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+20]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+32]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+20

         mov ebx,[_vmatrix+24]
         mov ecx,[_vmatrix+28]
         mov ebp,[_vmatrix+32]

         mov eax,[_tmatrix+0]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+12]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+24]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+24

         mov eax,[_tmatrix+4]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+16]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+28]
         imul ebp
         shrd eax,edx,14
         add esi,eax

         push esi                           ; _tmatrix+28

         mov eax,[_tmatrix+8]
         imul ebx
         shrd eax,edx,14
         mov esi,eax

         mov eax,[_tmatrix+20]
         imul ecx
         shrd eax,edx,14
         add esi,eax

         mov eax,[_tmatrix+32]
         imul ebp
         shrd eax,edx,14
         add esi,eax

;        push esi             ; _tmatrix+32

;        pop esi
         mov [_vmatrix+32],esi
         pop esi
         mov [_vmatrix+28],esi
         pop esi
         mov [_vmatrix+24],esi
         pop esi
         mov [_vmatrix+20],esi
         pop esi
         mov [_vmatrix+16],esi
         pop esi
         mov [_vmatrix+12],esi
         pop esi
         mov [_vmatrix+ 8],esi
         pop esi
         mov [_vmatrix+ 4],esi
         pop esi
         mov [_vmatrix+ 0],esi
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _sqrt: Routine courtesy TRAN
;
; In:
;   EAX - number to take root of
; Out:
;   EAX - root
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_sqrtbasetbl db 0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225

         align 4
_sqrt:
         pushad
         mov ebp,eax
         bsr ebx,eax
         jnz short _sqrtf0
         xor ebx,ebx
_sqrtf0:
         shr ebx,3
         lea eax,[ebx*8]
         mov cl,32
         sub cl,al
         rol ebp,cl
         mov eax,ebp
         movzx eax,al
         mov edi,offset _sqrtbasetbl
         mov ecx,10h
_sqrtl0:
         scasb
         je short _sqrtl0d
         jb short _sqrtl0d2
         loop _sqrtl0
         inc edi
_sqrtl0d2:
         dec edi
         inc cl
_sqrtl0d:
         movzx edx,byte ptr [edi-1]
         dec cl
         xor cl,0fh
         mov edi,ecx
         mov ecx,ebx
         jecxz short _sqrtdone
         sub eax,edx
_sqrtml:
         shld eax,ebp,8
         rol ebp,8
         mov ebx,edi
         shl ebx,5
         xor edx,edx
         mov esi,eax
         div ebx
         rol edi,4
         add edi,eax
         add ebx,eax
_sqrtf2:
         imul eax,ebx
         mov edx,eax
         mov eax,esi
         sub eax,edx
         jc short _sqrtf1
         loop _sqrtml
_sqrtdone:
         mov [esp+28],edi
         popad
         ret
_sqrtf1:
         dec ebx
         dec edi
         movzx eax,bl
         and al,1fh
         jmp _sqrtf2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _lambert: generate _lambert shading 1x3 matrix, completed in 6 imuls
;
; In:
;    ESI - Object # to get angles from
;    v_vxs[esi*2] - object x angle (0-65536)
;    v_vys[esi*2] - object y angle (0-65536)
;    v_vzs[esi*2] - object z angle (0-65536)
;    _y_angle_of_sun - (0-65536)
;
; Out:
;    _lmatrix  - shading matrix
;    ESI - ?
;
; Notes:
;
;z= ( sz ( cx + ( sx * cy )) + cz * sy ) * 45degrees  [x]
;   ( cz ( cx + ( sx * cy )) - sz * sy ) * 45degrees  [y]
;   ( cx * cy - sx ) * 45 degrees                     [z]
;
;note cos45=sin45=2d41h, but we will use 2d00h (99.2% accurate)
; you can change the y angle of the sun/light but not the x angle.
; changing the x angle would require a new formula.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_lambert:
         mov ax,v_vxs[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosx,eax
         pop eax
         call _sine
         mov vsinx,eax
         mov ebp,eax                        ; ebp = sx

         mov ax,v_vzs[esi*2]
         neg ax
         push eax
         call _cosine
         mov vcosz,eax
         mov edi,eax                        ; edi = cz
         pop eax
         call _sine
         mov vsinz,eax
         mov edx,eax                        ; edx = sz

         mov ax,v_vys[esi*2]
         neg ax
         add eax,_y_angle_of_sun            ; 2000h = 45 degrees y angle for light source
         push eax
         call _cosine
         mov vcosy,eax
         mov esi,eax                        ; esi = cy
         pop eax
         call _sine
         mov vsiny,eax                      ; eax = sy

         mov ebx,edx                        ; ebx = sz

         mov ecx,eax                        ; ecx = sy

         mov eax,ebp                        ; get sx

         imul esi                           ; eax = sx * cy
         shrd eax,edx,14
         sub eax,vcosx                      ; eax = cx + ( sx * cy)

         push eax

         imul ebx                           ; cx + ( sx * cy) * sz
         shrd eax,edx,14
         mov _lmatrix+0,eax

         pop eax

         imul edi                           ; di = cz
         shrd eax,edx,14
         mov _lmatrix+4,eax                 ; cx + ( sx * cy) * cz

         mov eax,ebx
         imul ecx                           ; - sz * sy
         shrd eax,edx,14
         sub _lmatrix+4,eax

         mov eax,edi
         imul ecx                           ; cz * sy
         shrd eax,edx,14
         add _lmatrix+0,eax

         mov eax,vcosx                      ; (cx * cy - sx) * 45deg
         imul esi
         shrd eax,edx,14
         mov ebx,eax
         add ebx,ebp

         cmul eax,ebx,2d00h                 ; * 45degrees
         shrd eax,edx,14
         movsx eax,ax
         mov _lmatrix+8,eax

         mov ebx,_lmatrix+4
         cmul eax,ebx,2d00h
         shrd eax,edx,14
         mov _lmatrix+4,eax

         mov ebx,_lmatrix+0
         cmul eax,ebx,2d00h
         shrd eax,edx,14
         mov _lmatrix+0,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _pre_cal_lambert: Pre-calculate all neccessary stuff for object DI
;
; In:
;    EDI - Object # to pre-calculate normals for
;    _objbase[esi*4] -> offset of object data
; Out:
;    ESI -> minimum address of object data
;    EDI -> maximum address of object data
;    EBP -> points to header for object
;
; Notes:
;
; Precalculate surface normals for object di.  This  is  so  you  don't
; have to type them in when de_sineing new objects. Imagine, 400 points,
; with 350 surfaces, calculating them all manually?  This routine  also
; figures out the iteration skip offset (if you have surfaces dependant
; on other surfaces) and also sets bit 1 if it is a line (two  points),
; and sets bit 4 if 1 point.This routine also sets the number of points
; to skip if an iteration is found. It  counts  the  number  of  points
; within iterations (even iterations within iterations)  and  sets  the
; skip value so any iterations skipped will have a pre-calculated point
; offset.  Did that make sense?
;
; Things done here:
;
; set point command if only 1 connection
; set line  command if only 2 connections
; set normal bit in commands if shading used in texture
; calculate and set shading normals
; calculate offsets for iteration jumps (in case surface not visible)
; calculate number of points to skip for iterations (in case surface not visible)
; set offset flag if iteration uses a point offset (4'th future use word)
; calculate and set auto-intensity of color if auto_s bit set
;
; Most of the above is done so the user (you) wont have to calculate this stuff
; yourself - makes object modification much easier.
;
; If you find the routine to be sloppy remember it is only used
; for object initialization.
;
; This routine  will probably crash if your object is not set up correctly
; The entire 3dvect source will crash if this routine  isn't run  and  the
; chances of you knowing how to do all that  this  routine  does  manually
; are pretty slim since most of you out there are doughheads.
;
; The minimum and maximum addresses are returned in ESI and EDI so you can
; output the resulting object to a binary file. EBP points to the starting
; header of the object (usually, but not neccessaraly, the minimum address)
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_lx1     dd 0
_ly1     dd 0
_lz1     dd 0

_lx2     dd 0
_ly2     dd 0
_lz2     dd 0

_lx3     dd 0
_ly3     dd 0
_lz3     dd 0

finx     dd 0
finy     dd 0
finz     dd 0

temp1    dw 0
temp2    dw 0                               ; number of points
temp3    dw 0                               ; number of sides
temp4    dw 0
temp5    dd 0                               ; minimum address
temp6    dd 0                               ; maximum address

_pre_cal_lambert:
         movzx edi,di                       ; in case user is lazy
         mov esi,_objbase[edi*4]
         mov temp5,esi
         mov temp6,esi
         push esi                           ; save for exit
more_reses:
         push esi                           ; save header offset
         add esi,4
         lodsd
         add esi,eax                        ; handle first resolution

         lodsw
         mov temp2,ax
         lodsw
         mov temp3,ax

         mov xad,0
         mov yad,0
         mov zad,0
         mov temp1,-1
         mov ax,[esi+14]
         mov temp4,ax

         mov eax,[esi+8*2]
         or eax,[esi+8*2+4]
         jnz lam_hhgg
         mov dword ptr [esi+8*2],maxz       ; if no max/min found, force one
         mov dword ptr [esi+8*2+4],minz
lam_hhgg:
         mov eax,[esi+12*2]
         jnz lam_hhgc
         mov dword ptr [esi+12*2],tolerance
lam_hhgc:
         add esi,25*2                       ; skip future use bytes
         mov edi,4                          ; edi=4 to skip center of gravity
         mov xp,0
         mov yp,0
         mov zp,0
         cmp temp2,0
         je no_points_2
lam_ap12:
         mov bx,w [esi]                     ; load all the points into array
         mov cx,w [esi+2]
         mov bp,w [esi+4]
         add bx,w xad
         add cx,w yad
         add bp,w zad
         movsx ebx,bx
         movsx ecx,cx
         movsx ebp,bp
         mov xp[edi],ebx
         mov yp[edi],ecx
         mov zp[edi],ebp
         add esi,6
         add edi,4
         dec temp2
         jne s lam_ap12                     ; esi = address of sides now...
no_points_2:
         mov pointindex,edi

lam_loadsides:
         call checkesi                      ; check minimum and maximum addresses

         mov edi,esi                        ; save in case of line adjust
         mov ax,[esi]                       ; get command

         mov bx,ax                          ; save command
         test ax,special                    ; test if special command
         jz s lam_notmap                    ; no, skip through loop
         mov di,ax
         and edi,special-1

         cmp ax,gosub                       ; check for jump commands, yeah,yeah, I should have made a table, who cares...
         jne ffgg1
         add esi,2
         lodsw
         push esi
         movsx eax,ax
         sub esi,2
         add esi,eax
         jmp lam_next
ffgg1:
         cmp ax,return
         jne ffgg2
         pop esi
         jmp lam_next
ffgg2:
         cmp ax,goto_offset
         jne ffgg3
         add esi,2
         lodsw
         movsx eax,ax
         sub esi,2
         add esi,eax
         jmp lam_next
ffgg3:
         mov di,number_ofb[edi*2]           ; yes, skip special command length
         add esi,edi
         xor bx,bx
         cmp ax,sub_object
         je lam_do_it
         cmp ax,static_sub_object
         je lam_do_it
         jmp lam_next                       ; go to next side
lam_notmap:
         call pcl_testashade

         mov ax,[esi+2]                     ; get texture for both sides
         or ax,[esi+4]

         test ax,shade                      ; test shading bit
         jnz lam_calcit                     ; yes, calculate shading normal

         push edi                           ; save command location

         add esi,4+4+2                      ; skip 2 colour & 2 texture words & command
         mov edi,esi

         lodsw                              ; get first point indexer
         add ax,temp4
         stosw

         mov cx,ax
         xor dx,dx
lam_ldlp:
         lodsw                              ; count number of connection points
         add ax,temp4
         stosw

         inc dx
         cmp ax,cx
         jne lam_ldlp

         call checkesi                      ; check minimum and maximum addresses

         pop edi                            ; pop command location

         cmp dx,1                           ; only 1 point?, set point command
         jne lam_test_line
         or w [edi+0],both
         or w [edi+2],point
         or w [edi+4],point
         jmp lam_test_iteration

lam_test_line:
         cmp dx,2                           ; only 2 points?, set line command
         jne lam_test_iteration
         or w [edi+0],both
         or w [edi+2],line
         or w [edi+4],line

lam_test_iteration:
         xor ax,ax
         test bx,iterate                    ; test if iteration command used
         jnz lam_do_it                      ; yes,solve internal iteration
lam_next:
         dec temp1
         jnz lam_nopop
         pop ax
         mov temp4,ax
         pop ax
         mov temp1,ax
         jmp lam_next
lam_nopop:
         dec temp3
         jnz lam_loadsides

         pop esi
         lodsd
         add esi,4
         cmp eax,-1                         ; last resolution?
         jne more_reses

         call checkesi                      ; check minimum and maximum addresses
         pop ebp                            ; pop header offset
         mov esi,temp5                      ; load up start and end offsets of object
         mov edi,temp6

         ret

lam_calcit:
         push esi                           ; save command location
         add esi,4+4+2                      ; skip colour and 2 future use words

         lodsw                              ; first point
         add ax,temp4
         mov [esi-2],ax
         push ax
         movzx edi,ax

         mov ebx,[xp+edi*4]
         mov ecx,[yp+edi*4]
         mov ebp,[zp+edi*4]

         mov _lx1,ebx
         mov _ly1,ecx
         mov _lz1,ebp

         lodsw                              ; second point
         add ax,temp4
         mov [esi-2],ax
         movzx edi,ax

         mov ebx,[xp+edi*4]
         mov ecx,[yp+edi*4]
         mov ebp,[zp+edi*4]

         mov _lx2,ebx
         mov _ly2,ecx
         mov _lz2,ebp

         lodsw                              ; third point
         add ax,temp4
         mov [esi-2],ax
         movzx edi,ax

         mov ebx,[xp+edi*4]
         mov ecx,[yp+edi*4]
         mov ebp,[zp+edi*4]

         mov _lx3,ebx
         mov _ly3,ecx
         mov _lz3,ebp

         push esi

         call _calc_normal

         pop esi

         pop dx                             ; now find shading normal storage, pop first connector

lam_ldl2:
         lodsw
         add ax,temp4
         mov [esi-2],ax
         cmp ax,dx
         jne lam_ldl2

         mov edi,esi

         mov ax,bx
         stosw
         mov ax,cx
         stosw
         mov ax,bp
         stosw

         add esi,6

         pop edi                            ; get original command location back
         or w [edi],normal
         mov bx,[edi]
         jmp lam_test_iteration

lam_surfc_cnt dw 0

; this finds the total number of points to skip if an iteration fails, dx = #
; remember, this is a pre-calculation routine so it doesn't need to be fast.

lam_do_it:
         xor dx,dx                          ; clear total number of points to skip

         mov ax,[esi+10]                    ; test if there is a center of rotation point
         or ax,[esi+12]
         or ax,[esi+14]
         jz done_alter2
         or w [esi+8],centroid              ; set flag if offset found (center of gravity)

         movsx ebx,w [esi+10]
         movsx ecx,w [esi+12]
         movsx ebp,w [esi+14]
         add xad,ebx
         add yad,ecx
         add zad,ebp
         mov ebx,xad
         mov ecx,yad
         mov ebp,zad
         mov edi,pointindex
         mov xp[edi],ebx
         mov yp[edi],ecx
         mov zp[edi],ebp
         add pointindex,2
         add dx,1                           ; centroid is an extra point to skip
done_alter2:
         mov ax,temp1
         push ax
         mov ax,temp4
         push ax

         mov ax,[esi+18]
         add temp4,ax
         mov w [esi+18],0

         mov lam_surfc_cnt,0
         push esi                           ; this is our return address (continue from here+4)

         lodsw                              ; get number of points.
         add dx,ax                          ; save as TOTAL number of points to skip
         mov temp2,ax

         lodsw                              ; get number of surfaces
         mov temp1,ax
         inc temp1
         add lam_surfc_cnt,ax               ; count until this is zero

         mov eax,[esi+8*2]
         or eax,[esi+10*2]
         jnz lam_hhgg2
         mov dword ptr [esi+8*2],maxz       ; if no max/min found, force one
         mov dword ptr [esi+8*2+4],minz
lam_hhgg2:
         mov eax,[esi+12*2]
         jnz lam_hhgl
         mov dword ptr [esi+12*2],tolerance
lam_hhgl:
         add esi,25*2

         mov edi,pointindex
         cmp temp2,0
         je lam_test_check                  ; only sides added, no additional points
lam_ap13:
         mov bx,w [esi]                     ; load all the points into array
         mov cx,w [esi+2]                   ; for calculation of gourad shadings
         mov bp,w [esi+4]
         add bx,w xad
         add cx,w yad
         add bp,w zad
         movsx ebx,bx
         movsx ecx,cx
         movsx ebp,bp
         mov xp[edi],ebx
         mov yp[edi],ecx
         mov zp[edi],ebp
         add esi,6
         add edi,4
         dec temp2
         jne s lam_ap13                     ; esi = address of sides now...

         mov pointindex,edi

lam_test_check:
         cmp lam_surfc_cnt,0                ; test if user just wants to add points
         je lam_no_surfs                    ; i dont know why anyone would want to do this?

lam_test_until_target:
         lodsw                              ; get command
         mov bx,ax
         test ax,special                    ; test if special command
         jz s lam_notmap_it                 ; no, skip through loop

         mov di,ax
         and edi,special-1

         cmp ax,gosub                       ; check for jump commands, yeah,yeah, I should have made a table, who cares...
         jne ffgg1x
         add esi,2
         lodsw
         push esi
         movsx eax,ax
         sub esi,2
         add esi,eax
         jmp lam_next_it
ffgg1x:
         cmp ax,return
         jne ffgg2x
         pop esi
         jmp lam_next_it
ffgg2x:
         cmp ax,goto_offset
         jne ffgg3x
         add esi,2
         lodsw
         movsx eax,ax
         sub esi,2
         add esi,eax
         jmp lam_next_it
ffgg3x:
         movzx edi,number_ofb[edi*2]        ; yes, skip special command length
         add esi,edi
         sub esi,2
         cmp ax,sub_object
         je lam_re_lam
         cmp ax,static_sub_object
         je lam_re_lam
         jmp s lam_nog

lam_notmap_it:
         lodsw
         mov bp,ax
         lodsw
         or bp,ax                           ; find if shading bit used, add esi,6 if so
         add esi,4                          ; skip 2 colour words

         lodsw                              ; get first point indexer
         mov cx,ax
lam_ldl3:
         lodsw
         cmp ax,cx
         jne lam_ldl3

         test bp,shade                      ; test if gouraud normal present
         jz lam_nog
         add esi,6                          ; skip it if present
lam_nog:
         test bx,iterate                    ; test if iteration command used
         jnz lam_re_lam                     ; solve internal iteration again...
lam_next_it:
         dec lam_surfc_cnt
         jnz lam_test_until_target
lam_no_surfs:
         mov edi,esi                        ; save current location
         pop esi                            ; return original start location
         sub edi,esi                        ; get difference between them
         sub di,8                           ; offset for loadsides routine - constant

         lodsw                              ; get number of points
         mov bx,ax

         lodsw
         add temp3,ax

         mov cx,dx
         mov ax,6
         imul bx
         movzx ebx,ax

         mov ax,di
         mov edi,esi
         stosw                              ; save offset
         mov ax,cx
         stosw                              ; save number of points found in iterations

         mov eax,[esi+8*2]
         or eax,[esi+10*2]
         jnz lam_hhgg3
         mov dword ptr [esi+8*2],maxz       ; if no max/min found, force one
         mov dword ptr [esi+8*2+4],minz
lam_hhgg3:
         mov eax,[esi+12*2]
         jnz lam_hhgq
         mov dword ptr [esi+12*2],tolerance
lam_hhgq:
         add esi,25*2                       ; adjust for next load
         add esi,ebx

         jmp lam_next

lam_re_lam:
         lodsw                              ; get number of points for recursed iteration
         add dx,ax                          ; save as TOTAL number of points to skip
         mov cx,ax

         lodsw                              ; get number of surfaces
         add lam_surfc_cnt,ax               ; count until this is zero

         mov eax,[esi+8*2]
         or eax,[esi+10*2]
         jnz lam_hhgg4
         mov dword ptr [esi+8*2],maxz       ; if no max/min found, force one
         mov dword ptr [esi+8*2+4],minz
lam_hhgg4:
         mov eax,[esi+12*2]
         jnz lam_hhgv
         mov dword ptr [esi+12*2],tolerance
lam_hhgv:
         add esi,25*2

         mov eax,6
         imul cx
         add esi,eax

         jmp lam_next_it

checkesi:
         cmp esi,temp5
         jae noesi1
         mov temp5,esi
noesi1:
         cmp esi,temp6
         jbe noesi2
         mov temp6,esi
noesi2:
         ret

pcl_testashade:
         mov ax,[esi+2]
         or ax,[esi+4]
         test ax,auto_s
         jnz pcl_test2
         ret
pcl_test2:
         pushad
         push esi
         push esi
         mov _vxs,0
         mov _vys,0
         mov _vzs,0
         xor esi,esi
         call _lambert
         pop esi

         movzx ebx,w [esi+10]
         movzx ecx,w [esi+12]
         movzx edx,w [esi+14]

         mov eax,xp[ebx*4]
         mov _lx1,eax
         mov eax,yp[ebx*4]
         mov _ly1,eax
         mov eax,zp[ebx*4]
         mov _lz1,eax
         mov eax,xp[ecx*4]
         mov _lx2,eax
         mov eax,yp[ecx*4]
         mov _ly2,eax
         mov eax,zp[ecx*4]
         mov _lz2,eax
         mov eax,xp[edx*4]
         mov _lx3,eax
         mov eax,yp[edx*4]
         mov _ly3,eax
         mov eax,zp[edx*4]
         mov _lz3,eax
         call _calc_normal

         call _l_rotate_point
         pop esi
         push edi

         test w [esi+2],auto_s
         jz pcl_test4
         test w [esi+2],inverse
         jz pcl_test3
         neg edi
pcl_test3:
         add edi,256
         shr edi,1                          ; result -256 to +256, turn into 0-256
         mov al,b shading_tables[edi]       ; now into 0-15
         xor ah,ah
         add w [esi+6],ax
         mov ax,[esi+2]
         and ax,65535-auto_s
         mov [esi+2],ax
pcl_test4:
         pop edi

         test w [esi+4],auto_s
         jz pcl_test6
         test w [esi+4],inverse
         jz pcl_test5
         neg edi
pcl_test5:
         add edi,256
         shr edi,1                          ; result -256 to +256, turn into 0-256
         mov al,b shading_tables[edi]       ; now into 0-15
         xor ah,ah
         add w [esi+8],ax
         mov ax,[esi+4]
         and ax,65535-auto_s
         mov [esi+4],ax
pcl_test6:
         popad
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _calc_normal: calculate surface normal
;
; In:
;    _lx1 - x of point 1 on triangle
;    _ly1 - y of point 1 on triangle
;    _lz1 - z of point 1 on triangle
;    _lx2 - x of point 2 on triangle
;    _ly2 - y of point 2 on triangle
;    _lz2 - z of point 2 on triangle
;    _lx3 - x of point 3 on triangle
;    _ly3 - y of point 3 on triangle
;    _lz3 - z of point 3 on triangle
;
; Out:
;    EBX = finx = x of surface normal of triangle
;    ECX = finy = y of surface normal of triangle
;    EBP = finz = z of surface normal of triangle
;
; Notes:
; _x2 = _x2 - _x1
; _y2 = _y2 - _y1
; z2 = z2 - z1
;
; x3 = x3 - _x1
; y3 = y3 - _y1
; z3 = z3 - z1
;
; x = _y2 * z3 - z2 * y3
; y = z2 * x3 - _x2 * z3
; z = _x2 * y3 - _y2 * x3
;
; a = SQR(x ^ 2 + y ^ 2 + z ^ 2)
;
; x = INT(x / a * 256 + .5)
; y = INT(y / a * 256 + .5)
; z = INT(z / a * 256 + .5)
;
; This worked for me on the first try!
;
; If you wanted to get the equation of a plane, you could do this after:
;  d = - x * _x1 - y * _y1 - z * z1
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         nshl = 8

_calc_normal:
         mov ebx,_lx1
         mov ecx,_ly1
         mov ebp,_lz1

         sub _lx2,ebx
         sub _ly2,ecx
         sub _lz2,ebp

         sub _lx3,ebx
         sub _ly3,ecx
         sub _lz3,ebp

         mov eax,_ly2
         mov ebx,_lz3
         imul ebx
         mov ecx,eax

         mov eax,_lz2
         mov ebx,_ly3
         imul ebx
         sub ecx,eax

         mov finx,ecx                       ; save x of normal

         mov eax,_lz2
         mov ebx,_lx3
         imul ebx
         mov ecx,eax

         mov eax,_lx2
         mov ebx,_lz3
         imul ebx
         sub ecx,eax

         mov finy,ecx                       ; save y of normal

         mov eax,_lx2
         mov ebx,_ly3
         imul ebx
         mov ecx,eax

         mov eax,_ly2
         mov ebx,_lx3
         imul ebx
         sub ecx,eax

         mov finz,ecx                       ; save z of normal

calc_testloop:
         cmp finx,32768                     ; make sure (normal^2)*2 is < 2^32
         jge calc_shrit
         cmp finy,32768
         jge calc_shrit
         cmp finz,32768
         jge calc_shrit

         cmp finx,-32768
         jle calc_shrit
         cmp finy,-32768
         jle calc_shrit
         cmp finz,-32768
         jg ok_2_bite_dust

calc_shrit:
         shr finx,1                         ; calculations will be too large if squared, div by 2
         test finx,40000000h
         jz no_neg_calc1
         or finx,80000000h
no_neg_calc1:
         shr finy,1
         test finy,40000000h
         jz no_neg_calc2
         or finy,80000000h
no_neg_calc2:
         shr finz,1
         test finz,40000000h
         jz no_neg_calc3
         or finz,80000000h
no_neg_calc3:
         jmp calc_testloop

ok_2_bite_dust:
         mov eax,finx                       ; x^2
         mov edi,eax                        ; objects
         imul edi
         mov edi,eax

         mov eax,finy                       ; y^2
         mov esi,eax
         imul esi
         mov esi,eax

         mov eax,finz                       ; z^2
         mov ebp,eax
         imul ebp

         add eax,esi
         add eax,edi

         call _sqrt                         ; get square root of number

         mov ecx,eax
         or ecx,ecx
         je lam_abort                       ; should never happen!

         mov eax,finx
         cdq
         shl eax,nshl                       ; set unit vector to 2^nshl (256)
         idiv ecx
         mov finx,eax

         mov eax,finy
         cdq
         shl eax,nshl
         idiv ecx
         mov finy,eax

         mov eax,finz
         cdq
         shl eax,nshl
         idiv ecx
         mov finz,eax

         mov ebx,finx
         mov ecx,finy
         mov ebp,finz

lam_abort:
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _calc_d: Calculate D portion of equation of a plane
; In:
;    EBX = x of surface normal of triangle
;    ECX = y of surface normal of triangle
;    EBP = z of surface normal of triangle
;    _lx1 - x of point on triangle (any point)
;    _ly1 - y of point on triangle
;    _lz1 - z of point on triangle
; Out:
;    EAX = D     (Ax+By+Cz=D)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_calc_d:
         mov eax,_lx1
         imul ebx
         mov esi,eax

         mov eax,_ly1
         imul ecx
         add esi,eax

         mov eax,_lz1
         imul ebp
         add eax,esi

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _set_up_all_lambert: set up all _lambert normals from object si to object di
;
; In:
;    ESI - object # to start at
;    EDI - object # to end at
;    _objbase[esi*4 - edi*4] -> offsets to object data
; Out:
;   null
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_up_all_lambert:
         movzx edi,di                       ; in case user is lazy
         movzx esi,si

         xchg edi,esi                       ; so user doesn't get confuzed
set_lop:
         push esi edi
         call _pre_cal_lambert
         pop edi esi
         inc edi
         cmp edi,esi
         jna set_lop

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _l_rotate_point: _rotate_point surface normal through _lambert matrix
;
; In:
;    BX - x of surface normal
;    CX - y of surface normal
;    BP - z of surface normal
;    _lmatrix - 16 bit, 1x3 _lambert shading matrix - set up by "_lambert" routine
; Out:
;    BX - x of surface normal (untouched)
;    CX - y of surface normal (untouched)
;    BP - z of surface normal (untouched)
;   EDI - colour intensity for surface (-255 to +255)
;
; Notes:
;   Your mother is a hamster.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_l_rotate_point:
         mov eax,_lmatrix+8                 ; solve edi = bx(0)+cx(4)+bp(8)
         imul bp
         shrd ax,dx,14
         mov edi,eax
         mov eax,_lmatrix+4
         imul cx
         shrd ax,dx,14
         add edi,eax
         mov eax,_lmatrix+0
         imul bx
         shrd ax,dx,14
         add edi,eax                        ; di = new colour -256 to 255 (not edi, di!)
         movsx edi,di

         add edi,256                        ; make sure result is within range -256 to 256
         and edi,511                        ; sometimes is messes up...
         sub edi,256

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Shading tables used for fake cosin colour intensity - 256 bytes
; Default is 16 colours per _lambert calculation.  But you could have 32, 48
; or whatever you want, even an odd number like 53.  Use the SHADING.BAS
; program to make the table to your custom size.
;
; Shading_bits is the variable for use with the texture command "LAST".  This
; variable tells the routine what bits to  pluck  off  when  determining  the
; shading intensity. Obviosly this cant  be  used  if  your  palette  shading
; length is not a function of 2's complement.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         if shading_colours eq 16

; 16 colour shading table

         align 4
shading_tables:
         db 0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1
         db 1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2
         db 2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3
         db 3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4
         db 4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5
         db 5,5,5,5,5,5,5,5,5,5,5,5,6,6,6,6
         db 6,6,6,6,6,6,6,6,6,6,6,6,6,6,7,7
         db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
         db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
         db 8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9
         db 9,9,9,9,9,10,10,10,10,10,10,10,10,10,10,10
         db 10,10,10,10,10,10,11,11,11,11,11,11,11,11,11,11
         db 11,11,11,11,11,11,11,11,12,12,12,12,12,12,12,12
         db 12,12,12,12,12,12,12,12,12,13,13,13,13,13,13,13
         db 13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14
         db 14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,15

         elseif shading_colours eq 32

; 32 colour shading table

         align 4
shading_tables:
         db 0,0,0,0,0,0,0,1,1,1,1,1,1,1,2,2
         db 2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4
         db 4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6
         db 6,6,6,6,7,7,7,7,7,7,7,7,8,8,8,8
         db 8,8,8,8,9,9,9,9,9,9,9,9,10,10,10,10
         db 10,10,10,10,10,11,11,11,11,11,11,11,11,12,12,12
         db 12,12,12,12,12,12,13,13,13,13,13,13,13,13,14,14
         db 14,14,14,14,14,14,14,15,15,15,15,15,15,15,15,15
         db 16,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17
         db 17,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19
         db 19,19,20,20,20,20,20,20,20,20,20,21,21,21,21,21
         db 21,21,21,22,22,22,22,22,22,22,22,22,23,23,23,23
         db 23,23,23,23,24,24,24,24,24,24,24,24,25,25,25,25
         db 25,25,25,25,26,26,26,26,26,26,26,26,27,27,27,27
         db 27,27,27,28,28,28,28,28,28,28,29,29,29,29,29,29
         db 29,29,30,30,30,30,30,30,30,31,31,31,31,31,31,31
         endif

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Generate null Y matrix (for camera)
;
; In: ECX => matrix for storage
; Out:
;     ECX => 9 doubleword resulting rotation matrix (excluding camera y angle)
;
; Notes:
;      x       y           z
;
; x=  cz   -cx * sz   + sx * sz
;
; y=  sz    cx * cz   - sx * cz
;
; z=   0       sx         cx
;
;
;  Matrix offsets: (doublewords)
;
;     x  y  z
;
; x    0  4  8
; y   12 16 20
; z   24 28 32
;
; Notes: This routine generates the camera matrix without the Y component.
;
;        A call to _setsincose MUST have taken place for this routine to work
;        correctly!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_null_y_matrix:
         mov eax,_ecosz
         mov [ecx+0],eax

         mov ebx,_esinz
         mov [ecx+12],ebx

         mov edi,_esinx
         mov [ecx+28],edi

         mov esi,_ecosx
         mov [ecx+32],esi

         mov d [ecx+24],0

         imul edi
         shrd eax,edx,14
         neg eax
         mov [ecx+20],eax

         mov eax,_ecosz
         imul edi
         shrd eax,edx,14
         mov [ecx+16],eax

         mov eax,ebx
         imul edi
         shrd eax,edx,14
         mov [ecx+8],eax

         mov eax,esi
         imul ebx
         shrd eax,edx,14
         neg eax
         mov [ecx+4],eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Inverse Rotate by Camera
; In:
;  EBX = x
;  ECX = y
;  EBP = z
;  ESI => indexer to angles (object number)
; Out:
;  EBX = x
;  ECX = y
;  EBP = z
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

icosx    dd 0
isinx    dd 0
icosy    dd 0
isiny    dd 0
icosz    dd 0
isinz    dd 0
ix       dd 0
iy       dd 0
iz       dd 0

_inverse_rotate:
         push esi ebx ecx ebp

         mov ax,_vxs[esi*2]
         neg ax
         call _cosine
         mov icosx,eax

         mov ax,_vxs[esi*2]
         neg ax
         call _sine
         mov isinx,eax

         mov ax,_vys[esi*2]
         neg ax
         call _cosine
         mov icosy,eax

         mov ax,_vys[esi*2]
         neg ax
         call _sine
         mov isiny,eax

         mov ax,_vzs[esi*2]
         neg ax
         call _cosine
         mov icosz,eax

         mov ax,_vzs[esi*2]
         neg ax
         call _sine
         mov isinz,eax

         pop ebp ecx ebx

         mov eax,ebx
         imul icosz
         shrd eax,edx,14
         mov esi,eax
         mov eax,ecx
         imul isinz
         shrd eax,edx,14
         sub esi,eax
         mov ix,esi

         mov eax,ebx
         imul isinz
         shrd eax,edx,14
         mov esi,eax
         mov eax,ecx
         imul icosz
         shrd eax,edx,14
         add esi,eax
         mov iy,esi

         mov ebx,ix
         mov ecx,iy

         mov eax,ecx
         imul icosx
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul isinx
         shrd eax,edx,14
         sub esi,eax
         mov iy,esi

         mov eax,ecx
         imul isinx
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul icosx
         shrd eax,edx,14
         add esi,eax
         mov iz,esi

         mov ecx,iy
         mov ebp,iz

         mov eax,ebx
         imul icosy
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul isiny
         shrd eax,edx,14
         sub esi,eax
         mov ix,esi

         mov eax,ebx
         imul isiny
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul icosy
         shrd eax,edx,14
         add esi,eax
         mov iz,esi

         mov ebx,ix
         mov ebp,iz

         pop esi
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Rotate point along X axis
; In:
;  ECX = Y
;  EBP = Z
;   AX = angle to rotate by
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_rotate_x:
         push ebx ecx ebp ax
         call _cosine
         mov icosx,eax

         pop ax
         call _sine
         mov isinx,eax

         pop ebp ecx ebx

         mov eax,ecx
         imul icosx
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul isinx
         shrd eax,edx,14
         sub esi,eax
         mov iy,esi

         mov eax,ecx
         imul isinx
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul icosx
         shrd eax,edx,14
         add esi,eax

         mov ebp,esi
         mov ecx,iy
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Rotate point along Y axis
; In:
;  EBX = X
;  EBP = Z
;   AX = angle to rotate by
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_rotate_y:
         push ebx ecx ebp ax
         call _cosine
         mov icosy,eax

         pop ax
         call _sine
         mov isiny,eax

         pop ebp ecx ebx

         mov eax,ebx
         imul icosy
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul isiny
         shrd eax,edx,14
         sub esi,eax
         mov ix,esi

         mov eax,ebx
         imul isiny
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul icosy
         shrd eax,edx,14
         add esi,eax

         mov ebp,esi
         mov ebx,ix
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Rotate point along Z axis
; In:
;  EBX = X
;  ECX = Y
;   AX = angle to rotate by
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_rotate_z:
         push ebx ecx ebp ax
         call _cosine
         mov icosz,eax

         pop ax
         call _sine
         mov isinz,eax

         pop ebp ecx ebx

         mov eax,ebx
         imul icosz
         shrd eax,edx,14
         mov esi,eax
         mov eax,ecx
         imul isinz
         shrd eax,edx,14
         sub esi,eax
         mov ix,esi

         mov eax,ebx
         imul isinz
         shrd eax,edx,14
         mov esi,eax
         mov eax,ecx
         imul icosz
         shrd eax,edx,14
         add esi,eax

         mov ecx,esi
         mov ebx,ix
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _Point_Z: Calculate Z roll direction to line object up with point
; In:
;  EBX = x point
;  ECX = y point
;  EBP = z point
;   AX = current Y angle of object
;   DI = current X angle of object
; Out:
;   AX = Z angle
; Notes:
;   u = x*cos(Y) - z*sin(Y)
;   v = x*sin(Y) + z*cos(Y)
;   y = y*cos(X) - v*sin(X)
;   Z = arctan (u/y)         = AX
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_point_z:
         push esi edi ebx ax
         call _cosine
         mov icosy,eax
         pop ax
         call _sine
         mov isiny,eax

         pop ebx
         imul ebp
         shrd eax,edx,14
         mov esi,eax
         neg esi
         mov eax,icosy
         imul ebx
         shrd eax,edx,14
         add esi,eax
         mov ix,esi

         mov eax,ebx
         imul isiny
         shrd eax,edx,14
         mov esi,eax
         mov eax,ebp
         imul icosy
         shrd eax,edx,14
         add esi,eax

         mov ax,di
         call _cosine
         mov icosx,eax
         mov ax,di
         call _sine
         mov isinx,eax
         mov eax,ecx
         imul icosx
         shrd eax,edx,14
         mov edi,eax
         mov eax,esi
         imul isinx
         shrd eax,edx,14
         sub edi,eax

         mov eax,edi
         mov ecx,ix
         call _arctan
         pop edi esi
         ret

