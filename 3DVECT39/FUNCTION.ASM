;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : move.asm
; Included from: Main Assembley Module
; Description  : Automatic object movement routines/functions
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

code32   segment para public use32
         assume cs:code32, ds:code32

         include pmode.ext                  ; protected mode externals by TRAN
         include irq.ext                    ; irq timing externals
         include 3d.ext
         include macros.inc
         include equ.inc

         public _updvectors                 ; update vector positions/angles
         public _calc_angles                ; calculate angles between objects di,si
         public _calc_middle                ; calculate angles of ebx,ecx,ebp into x,y
         public _get_displacement           ; calculate difference between object si and di
         public _put_object                 ; put object si at ebx,ecx,ebp
         public _get_location               ; get location of object esi
         public _set_angle                  ; set object si to angle bx,cx,bp
         public _get_angle                  ; get object si's angle
         public _set_shape                  ; set shape of object si to ax
         public _set_object_on              ; set main object si to on
         public _set_object_off
         public _set_sub_object_on          ; set sub-object on or off
         public _set_sub_object_off
         public _use_full_rotations         ; set rotation style of object
         public _use_no_rotations
         public _set_to_hi_bitmap           ; set object to be a static bitmap
         public _set_to_lo_bitmap
         public _set_bitmap_scaling         ; set bitmap base scaling for this object
         public _search_next_available_object ; find next available object for use
         public _init_object                ; initialize/clear object for use
         public _move_si                    ; move object si to ebx,ecx,ebp in di
         public _twist_si                   ; rotate object si to ebx,ecx,ebp in di
         public _twist_xonly                ; rotate object si's x angle until = ebx, di = time
         public _twist_yonly                ; rotate object si's y angle until = ecx, di = time
         public _twist_zonly                ; rotate object si's z angle until = ebp, di = time
         public _where_si                   ; where will object si be in di frames?
         public _point_it                   ; point object si at object di
         public _point_dir                  ; point object si in direction it is moving instantly
         public _point_dir_time             ; point object si in direction it is moving in di frames
         public _point_to                   ; point object si at location ebx,ecx,ebp
         public _set_speed                  ; calculate velocity based on angles
         public _set_xyzadds                ; set object world velocity values for location
         public _set_xyzvadds               ; set object world velocity values for angle
         public _point_time                 ; point obj di to bx,cx,bp in di frames
         public _time_to_point              ; pre-cal point obj di to bx,cx,bp in di frames
         public _nullpalette                ; only a null cross reference palette
         public _set_xref_palette           ; set cross reference pal for object si to ebx
         public _fix_xangle                 ; test/correct camera x angle wrap-around
         public _fix_xangleq                ; test/correct camera x angle wrap-around - when using joystick
         public _subtract_camera            ; subtract camera location from x,y,z
         public _relative_velocity          ; calc relative velocity of objects si and di
         public _add_xyzadds                ; add velocity of object esi to ebx,ecx,ebp
         public _get_xyzadds                ; get xyzadds of object esi

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _updvectors: Update vector locations/angles (also does camera)
;
; In:
;    null
; Out:
;    null
;
; Notes:
; Routine is now called by irq, so animation/game continues in background. Much
; better method than using _irq_traces_past
;
; IRQ maintains a universal speed from 486dx66 machine to 386sx25 machine.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_updvectors:
         align 4

         xor ebx,ebx

         i=0
         rept maxobjects+1    ; generate unrolled update loop
         local nuploc, nodecx, nodecy, nodecz

         cmp _acountx+i*2,bx
         je s nodecx
         dec _acountx+i*2
         mov ax,_vxadds+i*2 ; update angles
         add _vxs+i*2,ax
nodecx:
         cmp _acounty+i*2,bx
         je s nodecy
         dec _acounty+i*2
         mov ax,_vyadds+i*2
         add _vys+i*2,ax
nodecy:
         cmp _acountz+i*2,bx
         je s nodecz
         dec _acountz+i*2
         mov ax,_vzadds+i*2
         add _vzs+i*2,ax
nodecz:

         cmp _lcount+i*2,bx
         je s nuploc
         dec _lcount+i*2

         mov eax,_xadds+i*4 ; update position
         add _xs+i*4,eax
         mov eax,_yadds+i*4
         add _ys+i*4,eax
         mov eax,_zadds+i*4
         add _zs+i*4,eax
nuploc:
         i=i+1
         endm

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;_put_object: Set object location
;In:
;   EBX - x point
;   ECX - y point
;   EBP - z point
;    SI - object #
;Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_put_object:
         movzx esi,si
         mov _xs[esi*4],ebx
         mov _ys[esi*4],ecx
         mov _zs[esi*4],ebp
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;_get_location: Get object location
;In:
;   ESI - object #
;Out:
;   EBX - x point
;   ECX - y point
;   EBP - z point
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_get_location:
         movzx esi,si
         mov ebx,_xs[esi*4]
         mov ecx,_ys[esi*4]
         mov ebp,_zs[esi*4]
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;_set_angle: Set object angle
;In:
;    BX - x angle (0-65536)
;    CX - y angle
;    BP - z angle
;    SI - object #
;Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_angle:
         movzx esi,si
         mov _vxs[esi*2],bx
         mov _vys[esi*2],cx
         mov _vzs[esi*2],bp
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;_get_angle: Get object angle
;In:
;    SI - object #
;Out:
;    BX - x angle (0-65536)
;    CX - y angle
;    BP - z angle
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_get_angle:
         movzx esi,si
         mov bx,_vxs[esi*2]
         mov cx,_vys[esi*2]
         mov bp,_vzs[esi*2]
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_shape: Set object shape
; In:
;     AX - shape of object (this later is used as an indexer in the _objbase table)
;     SI - object #
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_shape:
         movzx esi,si
         mov _whatshape[esi*2],ax
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_object_on: Turn object on
; In:
;     SI - object # to make visible
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_object_on:
         movzx esi,si
         or _onoff[esi],mainobject_on
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_object_off: Turn object off
; In:
;     SI - object # to stop drawing
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_object_off:
         movzx esi,si
         and _onoff[esi],-1-mainobject_on
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_sub_object_on: Make angles and location refer to a sub object (arm, leg)
; In:
;     SI - object # to de_sineate as a sub-object
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_sub_object_on:
         movzx esi,si
         or _onoff[esi],sub_object_on
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_sub_object_off: Make angles/locations/velicities refer to a sub object (arm, leg)
; In:
;     SI - object # to un-de_sineate as a sub-object
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_sub_object_off:
         movzx esi,si
         and _onoff[esi],-1-sub_object_on
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; use_full_rotations: Make object free to rotate along any axis
; In:
;     SI - object #
; Out=In
;
;Notes:
;         This also clears the bitmap options below
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_use_full_rotations:
         movzx esi,si
         mov _userotate[esi],full_rotations
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; use_no_rotations: Make object rigid along rotation axis (faster)
; In:
;     SI - object #
; Out=In
;
; Notes:
;   This also clears the bitmap options below
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_use_no_rotations:
         movzx esi,si
         mov _userotate[esi],no_rotation
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_to_hi_bitmap: Make object a hi-res bitmap (like an explosion or something)
; In:
;     SI - object #
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_to_hi_bitmap:
         movzx esi,si
         mov _userotate[esi],s_himap
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_to_lo_bitmap: Make object a lo-res _bitmap (like an explosion or something)
; In:
;     SI - object #
; Out=In
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_to_lo_bitmap:
         movzx esi,si
         mov _userotate[esi],s_lomap
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set_bitmap_scaling: Set scaling factors for bitmaps (explosions)
; In:
;     SI - object #
;     BX - x scaling factor for bitmap
;     CX - y scaling factor for bitmap
; Out=In
;
;Notes: This determines the bitmaps "Size" in the virtual world.
;       You do not have to make this smaller as the bitmap gets farther away,
;       as this is done automatically.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_set_bitmap_scaling:
         movzx esi,si
         mov _bitobjx[esi*2],bx             ; bitmap scaling (gets added to _bitx and _bity)
         mov _bitobjy[esi*2],cx
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; search_next_available_object: Find an object which is not in use
; In:
;   null
; Out:
;  CF = 1 - no free objects
;   ESI - ?
;  CF = 0 - free object found
;   ESI - # of free object to be defined as you please
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_search_next_available_object:
         xor esi,esi
search_loop:
         inc esi
         cmp esi,maxobjects
         je abort_srch
         test _onoff[esi],mainobject_on+sub_object_on+hold_object
         jnz short search_loop

         clc
         ret

abort_srch:
         stc                                ; carry set if no new object available (all are already used)
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; init_object: reset all parameters of an object.
; In:
;    SI - # of object to reset
; Out:
;   null
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_init_object:
         movzx esi,si
         xor eax,eax
         mov _userotate[esi],al
         mov _onoff[esi],al
         mov _xs[esi*4],eax
         mov _ys[esi*4],eax
         mov _zs[esi*4],eax
         mov _xadds[esi*4],eax
         mov _yadds[esi*4],eax
         mov _zadds[esi*4],eax
         mov _vxs[esi*2],ax
         mov _vys[esi*2],ax
         mov _vzs[esi*2],ax
         mov _vxadds[esi*2],ax
         mov _vyadds[esi*2],ax
         mov _vzadds[esi*2],ax
         mov _lcount[esi*2],ax
         mov _acountx[esi*2],ax
         mov _acounty[esi*2],ax
         mov _acountz[esi*2],ax
         mov _palxref[esi],al
         mov _whatshape[esi*2],ax
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _move_si: Calculate velocity for moving object SI from wherever it is
;           now to EBX,ECX,EBP in DI frames
; In:
;    EBX - x location
;    ECX - y location
;    EBP - z location
;     SI - # of object to move
;     DI - # of frames to get there
; Out:
;    EBX - x velocity
;    ECX - y velocity
;    EBP - z velocity
;     SI - # of object to move
;     DI - # of frames to get there
;
; Notes:
;  move is 32 bit, make sure high words of registers are set!
;  time to get there is 16 bit. (if you need more, think! 65535 frames at
;  70 frames a sec is 15 minutes!)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_move_si:
         movzx esi,si

         sub ebx,_xs[esi*4]
         sub ecx,_ys[esi*4]
         sub ebp,_zs[esi*4]

         movzx edi,di

         mov eax,ebx                        ; 32 bit moves
         cdq
         idiv edi
         mov ebx,eax

         mov eax,ecx
         cdq
         idiv edi
         mov ecx,eax

         mov eax,ebp
         cdq
         idiv edi
         mov ebp,eax

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _twist_si: calculate rotation velocities for object si from wherever
;            it is now to ebx,ecx,ebp in di frames
; In:
;    EBX - x angle
;    ECX - y angle
;    EBP - z angle
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
; Out:
;     BX - x anglular velocity
;     CX - y anglular velocity
;     BP - z anglular velocity
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
;
; Notes:
;   Rotate is  32 bit, make   sure   high  words  of  registers  are  set!
;   Time to get there is 16 bit.  Note: Although resulting angle  will  be
;   16 bit, input angle is 32 bit!.  This allows you to rotate many  times
;   before coming to rest at a specified angle  and  also  allows  you  to
;   specify the direction of rotation.    di  specifies  time  to  arrive.
;   Final location is absolute, not relative to current angle.
;
; eg 00000100 is "rotate forwards until 100 degrees"
;    00078000 is "rotate 7 full rotations and come to rest at 32768 degrees"
;    fffd9000 is "rotate backwards 2 rotations and come to rest at 9000h degrees"
;    fffffff0 is "rotate backwards until 65520 degrees (-16)"
;
; Therefore, to reverse the direction of rotation (but maintain  the  final
; position) xor ebx,0ffff0000h  (or ecx or ebp).  bx is final position, but
; top word of ebx determines direction and number of turns to get there.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_twist_si:
         movzx esi,si

         sub bx,_vxs[esi*2]
         sub cx,_vys[esi*2]
         sub bp,_vzs[esi*2]

         movzx edi,di

         mov eax,ebx                        ; 32 bit rotate
         cdq
         idiv edi
         mov ebx,eax

         mov eax,ecx
         cdq
         idiv edi
         mov ecx,eax

         mov eax,ebp
         cdq
         idiv edi
         mov ebp,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _twist_xonly:_rotate_point object si along single axis
; In:
;    EBX - x angle
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
; Out:
;     BX - x anglular velocity
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
;
; Notes:
;   Same as above...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_twist_xonly:
         movzx esi,si

         sub bx,_vxs[esi*2]

         movzx edi,di

         mov eax,ebx                        ; 32 bit rotate
         cdq
         idiv edi
         mov ebx,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _twist_yonly:_rotate_point object si along single axis
; In:
;    ECX - y angle
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
; Out:
;     CX - x anglular velocity
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
;
; Notes:
;   Same as above...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_twist_yonly:
         movzx esi,si

         sub cx,_vys[esi*2]

         movzx edi,di

         mov eax,ecx                        ; 32 bit rotate
         cdq
         idiv edi
         mov ecx,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _twist_zonly:_rotate_point object si along single axis
; In:
;    EBP - z angle
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
; Out:
;     BP - x anglular velocity
;     SI - # of object to spin/twist/roll...
;     DI - # of frames to get there
;
; Notes:
;   Same as above...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
         align 4
_twist_zonly:
         movzx esi,si

         sub bp,_vzs[esi*2]

         movzx edi,di

         mov eax,ebp                        ; 32 bit _rotate_point
         cdq
         idiv edi
         mov ebp,eax

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _calc_angles: Calculate angles between objects esi and edi.
; In:
;    SI - # of object to look at
;    DI - # of object to look from
; Out:
;    AX - x angle
;    BX - y angle
;
; Notes:
;   Angles are from point of view of DI.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

temp1    dd 0
temp2    dd 0

_calc_angles:
         call _get_displacement
         mov di,_vzs[edi*2]

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _calc_middle: Calculate angles to static point
; In:
;    EBX - x location
;    ECX - y location
;    EBP - z location
; Out:
;    AX - x angle
;    BX - y angle
;
; Notes:
;   Booga Boo
;
;   Y = arctan (x/z)
;   X = arctan ((x*sin(Y) + Z cos(Y)))/y)
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_calc_middle:
         push ecx ebx ebp

         mov ecx,ebx                        ; first get z,x plane, (y angle)
         mov eax,ebp

         call _arctan

         mov temp2,eax                      ; save y angle
         call _cosine                       ; set up 32bit sin/cos multipliers
         mov temp1,eax
         mov eax,temp2
         call _sine

         pop ebp ebx                        ; now compute sqr(z^2+x^2) through y rotation

         imul ebx                           ; use angle from calculation above
         shrd eax,edx,14
         mov edi,eax
         mov eax,temp1
         imul ebp
         shrd eax,edx,14
         add eax,edi                        ; di = new z = run

         pop ecx

         call _arctan                       ; get ax=arctan(y/sqr(z^2+x^2))

         mov ebx,temp2                      ; bx = y angle , ax = x angle
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _get_displacement: figure out displacement between two objects
; In:
;     SI - # of object to look at
;     DI - # of object to look from
; Out:
;    EBX - x distance (signed)
;    ECX - y distance
;    EBP - z distance
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_get_displacement:
         and edi,0000ffffh                  ; faster than movzx (but dont quote me on it)
         and esi,0000ffffh

         mov ebx,_xs[esi*4]                 ; get displacement of esi to edi
         sub ebx,_xs[edi*4]
         mov ecx,_ys[esi*4]
         sub ecx,_ys[edi*4]
         mov ebp,_zs[esi*4]
         sub ebp,_zs[edi*4]
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _where_si: Figure out approximatly where object SI will be in DI frames.
; In:
;     SI - # of object to follow
;     DI - time
; Out:
;    EBX - x location
;    ECX - y location
;    EBP - z location
;     SI - zSI
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_where_si:
         and esi,0000ffffh

         mov ax,_lcount[esi*2]
         or ax,ax
         jne s nx

         mov ebx,_xs[esi*4]                 ; if object has no velocity, xs is position
         mov ecx,_ys[esi*4]
         mov ebp,_zs[esi*4]
         ret
nx:
         cmp ax,di                          ; if di>_lcount, shorten to _lcount
         ja s nxq
         mov di,ax
nxq:
         and edi,0000ffffh

         mov eax,_xadds[esi*4]              ; figure out where object will be di*frames
         imul edi
         add eax,_xs[esi*4]
         mov ebx,eax

         mov eax,_yadds[esi*4]
         imul edi
         add eax,_ys[esi*4]
         mov ecx,eax

         mov eax,_zadds[esi*4]
         imul edi
         add eax,_zs[esi*4]
         mov ebp,eax

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _point_it: Point object SI at object DI
; In:
;    SI = object # to point
;    DI = target object
; Out:
;   _vxs[esi*2]=AX= x angle (in case you need it)
;   _vys[esi*2]=BX= y angle
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_point_it:
         push esi edi
         xchg si,di                         ; xchange so user doesn't get confused
         push edi
         call _calc_angles
         pop edi
         movzx edi,di
         mov _vxs[edi*2],ax
         mov _vys[edi*2],bx
         pop edi esi

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _point_dir: Point object SI in direction it is moving
; In:
;    SI = object # to point
;  _xadds[esi*4] = direction object is moving
;  _yadds[esi*4] =    "           "
;  _zadds[esi*4] =    "           "
; Out:
;   _vxs[esi*2]=AX= x angle (in case you need it)
;   _vys[esi*2]=BX= y angle
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_point_dir:
         movzx esi,si

         mov ebx,_xadds[esi*4]
         mov ecx,_yadds[esi*4]
         mov ebp,_zadds[esi*4]

         shl ebx,4                          ; * whatever to get some decimal accuracy
         shl ecx,4
         shl ebp,4

         mov edi,esi                        ; xchange so user doesn't get confused
         push edi

         call _calc_middle

         pop esi
         mov _vxs[esi*2],ax
         mov _vys[esi*2],bx

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _point_dir_time: Point object SI in direction it is moving in DI frames
; In:
;    SI = object # to point
;    DI = time to arrive at angle
;  _xadds[esi*4] = direction object is moving
;  _yadds[esi*4] =    "           "
;  _zadds[esi*4] =    "           "
; Out:
;   _vxadds[esi*2]= x angle counter
;   _vyadds[esi*2]= y angle counter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_point_dir_time:
         movzx edi,di
         push edi

         movzx esi,si

         mov ebx,_xadds[esi*4]
         mov ecx,_yadds[esi*4]
         mov ebp,_zadds[esi*4]

         shl ebx,4                          ; * whatever to get some decimal accuracy
         shl ecx,4
         shl ebp,4

         mov edi,esi                        ; xchange so user doesn't get confused
         push edi

         call _calc_middle

         pop esi
         pop edi

         sub ax,_vxs[esi*2]

         cwd
         idiv di
         mov _vxadds[esi*2],ax

         sub bx,_vys[esi*2]

         mov ax,bx
         cwd
         idiv di
         mov _vyadds[esi*2],ax

         mov _acountx[esi*2],di
         mov _acounty[esi*2],di
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _point_to: Point object SI at location EBX,ECX,EBP.
; In:
;    SI = object # to point
;   EBX = x location
;   ECX = y location
;   EBP = z location
; Out:
;   _vxs[esi*2]=AX= x angle (in case you need it)
;   _vys[esi*2]=BX= y angle
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_point_to:
         mov di,si                          ; xchange so user doesn't get confused
         movzx edi,di
         push edi

         sub ebx,_xs[edi*4]                 ; get displacement of esi to edi
         sub ecx,_ys[edi*4]
         sub ebp,_zs[edi*4]

         call _calc_middle

         pop esi
         mov _vxs[esi*2],ax
         mov _vys[esi*2],bx

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _set_speed: "Move object in direction it is pointing"
;              Set speed of object si to ebp*angle, then set _lcount to di
;
; In:
;    SI = object # to set speed of
;   EBP = signed speed (10000 is good, 1 is dead slow, 10000000 is light speed, fffff000 = 4096 reverse)
; Out:
;    EBX = x velocity
;    ECX = x velocity
;    EBP = x velocity
;     DI = 65535 (for counter if you want it)
;
; Notes:
;    EBX= (- cosx * siny) * ebp
;    ECX=        (- sinx) * ebp
;    EBP=   (cosx * cosy) * ebp
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_speed:
         movzx esi,si

         mov ax,_vxs[esi*2]
         neg ax
         push eax
         call _cosine
         mov ecx,eax                        ; cx = cos x
         pop eax
         call _sine

         neg eax
         imul ebp                           ; set y speed
         shrd eax,edx,14
         push eax

         mov ax,_vys[esi*2]
         neg ax
         push eax
         call _cosine
         mov edx,eax                        ; dx = cos y
         pop eax
         call _sine

         mov ebx,edx                        ; save because imul trashes dx

         imul ecx                           ; ax = sy * cx
         shrd eax,edx,14                    ; shr eax,14 compensates for cos decimals
         imul ebp
         shrd eax,edx,14
         neg eax
         push eax

         mov eax,ebx
         imul ecx
         shrd eax,edx,14
         imul ebp
         shrd eax,edx,14

         mov ebp,eax
         pop ebx
         pop ecx

         mov edi,65535

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _set_xyzadds:  Set velocity of object SI in world co-ordinates
; In:
;  EBX - x velocity
;  ECX - y velocity
;  EBP - z velocity
;   DI - time for travel (_lcount)
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_xyzadds:
         movzx esi,si
         mov _xadds[esi*4],ebx
         mov _yadds[esi*4],ecx
         mov _zadds[esi*4],ebp
         mov _lcount[esi*2],di
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _set_xyzvadds:  Set angular velocity of object SI in world co-ordinates
; In:
;   BX - x angular velocity
;   CX - y angular velocity
;   BP - z angular velocity
;   DI - time for travel (_acountxyz)
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_xyzvadds:
         movzx esi,si
         mov _vxadds[esi*2],bx
         mov _vyadds[esi*2],cx
         mov _vzadds[esi*2],bp
         mov _acountx[esi*2],di
         mov _acounty[esi*2],di
         mov _acountz[esi*2],di
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _point_time: Point object SI at location EBX,ECX,EBP, in DI frames (DI = time)
; In:
;   EBX = x location
;   ECX = y location
;   EBP = z location
;    SI - # of object to spin/twist/roll...
;    DI - # of frames to get there
; Out:
;    BX - x anglular velocity
;    CX - y anglular velocity
;    BP - z anglular velocity
;    SI - # of object to spin/twist/roll...
;    DI - # of frames to get there
;
; Notes:
;  This could also be used for the camera, but if you are  going  to
;  point the camera at an object, call _cam_newfollow instead.  _cam_newfollow
;  allows for when the object is moving - _cam_newfollow will  track  the
;  object as it moves and even  if  it   accelerates!    The  camera
;  movement/turning must have high  resolution or  the  viewer  will
;  notice a "glitch" or "jump".
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_point_time:
         call _time_to_point

;        add ebx,000010000h                 ; do this if you want more than one rotation
;        add ecx,000020000h                 ; along a selected axis.
;        add ebp,0fffc0000h

         jmp _twist_si                      ; twist object to this location in di frames!

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _time_to_point: Calculate timed angles in preparation for roll.
; In:
;   EBX = x location
;   ECX = y location
;   EBP = z location
;    SI - # of object to spin/twist/roll...
;    DI - # of frames to get there
; Out:
;   EBX - x angle  (_sine extended for direction of roll)
;   ECX - y angle
;    SI - # of object to spin/twist/roll...
;    DI - # of frames to get there
;
; Notes:
;  Output is ready for _twist_si routine.  But you can add high words  to  the
;  output in order to get it to roll more than 1 rotation.  See example above
;  The direction for rotation is defined by the closest angle.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_time_to_point:
         push edi esi edi esi ebp ecx ebx
         call _where_si                     ; find out where object will be in di frames

         pop eax                            ; get x location to look at
         sub ebx,eax                        ; get displacement of where it will be to where
         neg ebx                            ; it should point

         pop eax                            ; get y location to look at
         sub ecx,eax
         neg ecx

         pop eax                            ; get z location to look at
         sub ebp,eax
         neg ebp

         pop edi esi                        ; notice reverse order for _calc_middle!

         call _calc_middle
         pop esi                            ; pop object number
         pop edi                            ; pop time
         movzx esi,si

         push ax bx                         ; save x angle,yangle
         sub ax,_vxs[esi*2]
         sub bx,_vys[esi*2]
         movsx ecx,bx                       ; set _sine for rotations
         movsx ebx,ax

         pop cx bx                          ; cx = y angle, bx = x angle
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Default/Null cross referencing palette: eg 1=1, 7=7, 221=221...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_nullpalette:
         i=0
         rept 256
         db i
         i=i+1
         endm

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _set_xref_palette: Set cross referencing palette for object si
; In:
;  ESI = object #
;   BL = selected cross referencing palette number (eg 0,1,2,3,4)
;
; Notes:
;  Each object can have its own colour scheme by setting the cross  reference
;  palette to re-direct the actual colours to a new set of colours.  The xref
;  palette doesn't have to be 256 bytes long,  it only needs to re-direct the
;  colours that your selected object has.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_xref_palette:
         movzx esi,si
         mov _palxref[esi],bl
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _fix_xangle: Force x angle of object to remain within range +- 16384
;  In: ESI = object to modify
;
; Notes: This routine can be called once every frame.   The  purpose  of  this
; routine is to prevent  an objects x   angle  from  making  the  object  turn
; upsidedown.  All the routine will do is, when the x angle goes out-of-range,
; this will turn the y angle 180degrees and also turn the x angle  180degrees.
; The objects x angular velocity will also be negated.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_fix_xangle:
         mov ax,_vxs[esi*2]
         add ax,16384
         cmp ax,0
         je fixxzero
         cmp ax,32768
         je fixxzero
         ja fixxangle
         ret
fixxangle:
         add _vys[esi*2],32768
         add _vzs[esi*2],32768
         mov ax,16384
         sub ax,_vxs[esi*2]
         shl ax,1
         add _vxs[esi*2],ax
         neg _vxadds[esi*2]
         ret
fixxzero:
         mov ax,_vzs[esi*2]
         mov _vzs[esi*2],0
         mov _vys[esi*2],ax
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; This fix routine looks great with the joystick, but it is more like a brick
; wall than a correct solution to x angle inversion.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_fix_xangleq:
         mov ax,_eyeax
         add ax,16384
         cmp ax,32768
         ja fixxangleq
         ret
fixxangleq:
         cmp _eyeax,0
         jl fixqqq
         mov _eyeax,16383
         ret
fixqqq:
         mov _eyeax,-16383
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Subtract camera: Make x,y,z relative to camera.
; In:
;   EBX = x location
;   ECX = y location
;   EBP = z location
; Out:
;   EBX = x location
;   ECX = y location
;   EBP = z location
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_subtract_camera:
         sub ebx,_eyex
         sub ecx,_eyey
         sub ebp,_eyez
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _Relative_velocity: Get difference in velocities between object si and di
; In:
;  ESI = object #
;  EDI = object #
; Out:
;  EBX - x speed difference
;  ECX - y speed difference
;  EBP - z speed difference
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_relative_velocity:
         movzx edi,di
         movzx esi,si

         mov ebx,_xadds[esi*4]
         mov ecx,_yadds[esi*4]
         mov ebp,_zadds[esi*4]

         sub ebx,_xadds[edi*4]
         sub ecx,_yadds[edi*4]
         sub ebp,_zadds[edi*4]

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Add velocity EBX,ECX,EBP to object ESI
; In:
;  ESI = object #
;  EBX - x speed
;  ECX - y speed
;  EBP - z speed
; Out:
;  EBX - x new speed
;  ECX - y new speed
;  EBP - z new speed
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_add_xyzadds:
         add ebx,_xadds[esi*4]
         add ecx,_yadds[esi*4]
         add ebp,_zadds[esi*4]

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Get velocity of object ESI
; In:
;  ESI = object #
; Out:
;  EBX - x speed
;  ECX - y speed
;  EBP - z speed
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_get_xyzadds:
         mov ebx,_xadds[esi*4]
         mov ecx,_yadds[esi*4]
         mov ebp,_zadds[esi*4]

         ret

code32   ends
         end
