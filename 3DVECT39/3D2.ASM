;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : 3d2.asm
; Included from: Main Assembley Module
; Description  : 3d vector routines full sorting method (slower)
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
; Send me your protected mode source code!
; Send me your Objects!
; But most of all, Send me a postcard!!!!
;
; - objects can pass through one another and still be sorted correctly
; - maxsurfs and maxpoints must be large - set to TOTAL points/surfs on screen
;
; To use:
;
;          call _land_draw          ; draw _background landscape
;          call _clearfill          ; clear video memory (last screen)
;          call _look_at_it         ; make camera look at selected object
;          call _setsincose         ; set rotation multipliers for eye
;          call _star_plot          ; plot _background stars (if you want)
;          call _makeobjs           ; plot all objects in sides table
;          call _instant_mouse      ; plot mouse on screen
;          call _flip_page          ; flip video pages
;          call _updvectors         ; move objects around, _rotate_point them
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

; define externals

         include pmode.ext                  ; protected mode externals
         include xmode.ext                  ; xmode externals by matt pritchard
         include irq.ext

         extrn _nullpalette:dword

         include macros.inc
         include equ.inc

         include vars2.inc                  ; labels and such
         align 4
         include tables.inc
         include math.inc                   ; _rotate_point, cos,sin,arctan...
         include xscale.inc
         include poly.inc                   ; common ploygon stuff

         public _makeobjs
         public _make1obj
         public _flush_surfaces
         public _init_tables

         strip_bytes equ 4

         align 4

abort_all:
         add esp,strip_bytes                ; abort from loadpoints and _make1obj
         ret                                ; returning now from _makeobjs call

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Loadpoints:  Begin loading of points from object definition data into array
; In:
;  ESI -> object #
; Out:
;  ESI -> offset of connection data
; Given ESI as object number.  _rotate_point, translate and convert to 3d the points
; of that object.  returns edi as pointer to sides.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

loadpoints:
         mov bl,v_userotate[esi]             ; rotation type

         mov si,v_whatshape[esi*2]           ; get shape
         mov esi,_objbase[esi*4]

view_is_not_ok:
         mov eax,[esi]
         add esi,8

         cmp eax,zad                        ; check if too far to see detail anyway
         jb s view_is_not_ok

         mov eax,[esi-4]
         add esi,eax
llkk:
         movzx eax,w [esi]
         mov numpoints,eax

         or eax,eax
         jz no_points_anyway

         mov edi,pointindex                 ; set xp,yp,zp pointer

         shl eax,2
         add eax,pointindex                 ; pointindex = word indexer to last point
         cmp eax,maxpoints*4-4              ; test for overflow in points tables
         jae abort_all

         mov ax,[esi+2]
         mov numsides,eax

         add eax,_showing
         cmp eax,maxsurfaces-1              ; check for overflow in "sides" tables
         jae abort_all

         add esi,4+25*2                     ; skip point and side totals, skip future data
         mov lindex,edi                     ; set last index to points (this one)

         add edi,4                          ; compensate for center of gravity point
middle_load_points:
         test bl,no_rotation                ; check v_userotate command
         jnz np13                           ; use different loop if no rotation
np12:
         movsx ebx,w [esi]                  ; x
         movsx ecx,w [esi+2]                ; y
         movsx ebp,w [esi+4]                ; z

         push edi esi
         call _rotate_point                 ; _rotate_point based on object matrix
         add ebp,zad

         cmp ebp,ztruncate
         jl s ntrt
ntrunct:
         add ebx,xad
         add ecx,yad
         call _make3d
         pop esi edi
         mov xp[edi],ebx
         mov yp[edi],ecx
         mov zp[edi],ebp
         add edi,4                          ; inc xp indexer
         add esi,6                          ; inc input pointer
         dec numpoints
         jne s np12

         mov pointindex,edi                 ; save for next call of loadpoints

         ret                                ; esi exits with pointer to sides
ntrt:
         mov ebp,ztruncate
         jmp s ntrunct

no_points_anyway:
         mov ax,[esi+2]
         mov numsides,eax

         add eax,_showing
         cmp eax,maxsurfaces-1              ; check for overflow in "sides" tables
         jae abort_all

         add esi,4+25*2                     ; skip point and side totals, skip future data

         mov edi,pointindex                 ; set xp,yp,zp pointer
         add pointindex,4
         mov lindex,edi                     ; set last index to points (this one)
         ret
np13:
         movsx ebx,w [esi]                  ; x
         movsx ecx,w [esi+2]                ; y
         movsx ebp,w [esi+4]                ; z

         push edi esi
         call _rotate_by_camera             ; rotation matrix already set up! (camera)
         add ebp,zad

         cmp ebp,ztruncate
         jge s ntrt2
ntrunct2:
         add ebx,xad
         add ecx,yad
         call _make3d
         pop esi edi
         mov xp[edi],ebx
         mov yp[edi],ecx
         mov zp[edi],ebp
         add edi,4                          ; inc xp indexer
         add esi,6
         dec numpoints
         jne s np13

         mov pointindex,edi                 ; save for next call of loadpoints

         ret
ntrt2:
         mov ebp,ztruncate
         jmp s ntrunct2

         align 4

special_commands dd offset do_bitmap
         dd offset do_bitmap
         dd offset pushmatrix
         dd offset popmatrix
         dd offset pushlocation
         dd offset poplocation
         dd offset newobject
         dd offset no_new_matrix
         dd offset gosub_function           ; 8
         dd offset return_function          ; 9
         dd offset goto_function            ; 10

number_ofb dw 5*2
         dw 5*2
         dw 1*2
         dw 1*2
         dw 1*2
         dw 1*2
         dw 1*2
         dw 1*2
         dw ?                               ; gosub_function
         dw ?                               ; return_function
         dw ?                               ; goto_function

         align 4
gosub_function:
         push esi
         movsx eax,w [esi]
         add esi,eax
         jmp return_iteration

         align 4
return_function:
         pop esi
         add esi,2
         jmp return_iteration

         align 4
goto_function:
         movsx eax,w [esi]
         add esi,eax
         jmp return_iteration

         align 4
pushmatrix:
         push _vmatrix+0
         push _vmatrix+4
         push _vmatrix+8
         push _vmatrix+12
         push _vmatrix+16
         push _vmatrix+20
         push _vmatrix+24
         push _vmatrix+28
         push _vmatrix+32
         jmp return_iteration

         align 4
popmatrix:
         pop _vmatrix+32
         pop _vmatrix+28
         pop _vmatrix+24
         pop _vmatrix+20
         pop _vmatrix+16
         pop _vmatrix+12
         pop _vmatrix+8
         pop _vmatrix+4
         pop _vmatrix+0
         jmp return_iteration

         align 4
pushlocation:
         push xad
         push yad
         push zad
         jmp return_iteration

         align 4
poplocation:
         pop zad
         pop yad
         pop xad
         jmp return_iteration

         align 4
ld_special:
         mov cx,ax
         and ecx,special-1                  ; max 127 commands
         jmp [special_commands+ecx*4]

         align 4

; handle loading of _bitmap from object list
;
; eg dw himap,8,5,50,60 ;command is 32,point 8, _bitmap 5, x&y scaling of 50,60

do_bitmap:
         align 4

         lodsw                              ; get from si, first is point
         shl eax,2
         add eax,lindex                     ; add to include offset in list
         stosw                              ; put in sides table

         mov edx,ebp                        ; save indexer
         movzx ebp,ax                       ; get point indexers
         mov eax,zp[ebp]
         mov zeds[ebx*2],eax                ; set zed for sort.
         mov ebp,edx

         movsw                              ; get _bitmap type
         movsd                              ; get x then y scaling

         mov edx,command                    ; get command (for iteration bits)
         mov textures[ebx],dx

         cmp zad,64000                      ; _bitmaps farther than 65536 screw up
         jge no_norml                       ; you can't see them anyway. prevent overflow
         jmp ln3

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Loadsides: Load connection data from object data definition
; In:
;  ESI -> offset of connection data
; Out: null
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

loadsides:
         mov lamflag,no
         mov edi,offsides                   ; get ready for lodsw and stosw
         mov ebp,edi                        ; ebp = offset to first point in side
         mov ebx,_showing                   ; bx = word indexer for surfaces
         shl ebx,1
ld_lp:
         mov ax,[esi]                       ; get command word
         add esi,2
         mov command,eax

         test eax,special                   ; if _bitmap, do special load,
         jnz ld_special                     ; or test previous color

         mov eax,[esi]                      ; get texture data/type
         mov texture12,eax

         mov eax,[esi+4]                    ; get colour, high byte is other side
         add esi,8
         mov colors12,eax

         mov ecx,lindex                     ; quick add for loop

         push ebp
         push ebx

         movzx eax,w [esi]                  ; get from esi, first is unconditinal
         add esi,2
         shl eax,2
         add eax,ecx                        ; add to include offset in list
         mov [edi],ax                       ; put in edi
         mov [edi+4],ax
         mov edx,eax

         lodsw                              ; get from esi
         shl eax,2
         add eax,ecx
         mov [edi+2],ax                     ; put in edi
         mov [edi+6],ax
         cmp eax,edx                        ; check all after first point
         je s ld_exitloop
         add edi,4
ld_loop:
         lodsw
         shl eax,2
         add eax,ecx
         mov [edi+0],ax
         cmp eax,edx
         je s ld_exitloop

         lodsw
         shl eax,2
         add eax,ecx
         mov [edi+2],ax
         cmp eax,edx
         je s ld_exitloop

         lodsw
         shl eax,2
         add eax,ecx
         mov [edi+4],ax
         add edi,6
         cmp eax,edx
         jne s ld_loop

ld_exitloop:
         push esi

         mov edi,ebp                        ; adjust bp into appropriate indexer

         movzx ebp,w [edi+6]
         mov ecx,[zp+ebp]
         mov bp,[edi+4]
         add ecx,[zp+ebp]
         mov bp,[edi+2]
         add ecx,[zp+ebp]
         mov ebp,edx                        ; get point indexers
         add ecx,[zp+ebp]                   ; take average of two z points for sort
         mov zeds[ebx*2],ecx

         mov edx,command

         test edx,onscr                     ; find if test is for on screen pixels
         jnz test_if_on_screen
         test dl,both                       ; check if always visible
         jnz its_line

return_screen:
         mov edx,[xp+ebp]                   ; first point
         mov ebx,[yp+ebp]

         mov bp,[edi+2]
         mov esi,[xp+ebp]                   ; second point
         mov ecx,[yp+ebp]

         mov bp,[edi+4]
         mov edi,[xp+ebp]                   ; third point
         mov ebp,[yp+ebp]

         call checkfront                    ; check if side is visable using p1,2,3

         pop esi ebx ebp                    ; return object data pointer

         mov edx,command
         or ecx,ecx
         jle s test_shading                 ; cx>-1 if side visible, skip if not
         test edx,double                    ; test to use other colour
         jz s skipit                        ; miss this side...
         shr texture12,16
         shr colors12,16
         xor w texture12,inverse            ; do inverse shading
test_shading:
         test texture12,shade+last
         jnz handle_shading                 ; shading bit set, do it...
ln2:
         test edx,check                     ; find out if side is only a test side
         jnz s no_show

         mov eax,texture12                  ; another side added...
         mov textures[ebx],ax
         movzx eax,w colors12
         add eax,palxrefx                  ; get offset of palette cross reference table for this object
         mov ax,[eax]
         mov surfcolors[ebx],ax
ln3:
         inc _showing                       ; another side added...
         add ebx,2
         add ebp,maxpolys*2                 ; bump ebp to next block
no_show:
         test edx,iterate
         jnz handle_surface_iteration
skipit:
         test edx,normal                    ; do we skip surface normal data
         jz s no_norml
         add esi,6
no_norml:
         test edx,iterate
         jnz failed_iteration               ; skip iteration data if surface failure

return_iteration:
         mov edi,ebp                        ; set di for next stosw

         dec numsides                       ; count for next side
         jne ld_lp

         mov offsides,edi                   ; save for next call

         ret

         align 4
its_line:
         pop esi ebx ebp
         test w texture12,shade+last
         jz ln2

; handle gourad/_lambert shading

         align 4
handle_shading:
         test w texture12,last              ; test to use previous colour or _bitmap call
         jnz ld_do_previous

         test w texture12,wavey
         jnz ln2

         push ebx esi ebp edx

         cmp lamflag,no                     ; is _lambert matrix set up?
         je s setitup                       ; jump to less likely route
returnq:
         mov bx,word ptr [esi]              ; get surface normal
         mov cx,word ptr [esi+2]
         mov bp,word ptr [esi+4]
         add esi,6
         call _l_rotate_point               ; _rotate_point surface normal by _lambert matrix

         pop edx
         test w texture12,inverse           ; have the sides flipped? test dx,256
         jnz s invert_colour                ; jump to least likely route
lp_contin:
         add edi,256
         shr edi,1                          ; result -256 to +256, turn into 0-256
         mov al,b shading_tables[edi]       ; now into 0-15
         xor ah,ah
         mov lastshade,al

         pop ebp esi ebx

         add w colors12,ax                  ; user can have offset color in object!

         jmp ln2

         align 4
invert_colour: ; inversion occures with other side option,
         neg edi                            ; always visible option, and shading option
         jmp lp_contin                      ; all combined!

         align 4
setitup:
         push esi
         mov esi,currobj                    ; this is object # from _make1obj
         call _lambert                      ; set up _lambert maxtrix
         mov lamflag,yes
         pop esi
         jmp s returnq

         align 4

ld_do_previous:
         mov al,lastshade                   ; use colour from previous calculation
         add b colors12,al
         jmp ln2

; handle iteration option

         align 4

handle_surface_iteration:
         test edx,normal
         jz s no_norml2
         add esi,6                          ; skip if shading normal present
no_norml2:
         test edx,matrix                    ; test to derive new matrix
         jz no_new_matrix
newobject:
         mov edi,currobj                    ; new matrix, get offset object number
         add di,[esi+16]
         test v_onoff[edi],sub_object_on     ; test if sub-object has been turned on...
         jz failed_iteration

         mov eax,[esi+24]
         mov minzc,eax
         mov eax,[esi+28]
         mov btolr,eax
         push ebx esi ebp edx               ; save stuff before iteration handle

         mov bx,w v_xs[edi*4]                ; get rotation location
         mov cx,w v_ys[edi*4]
         mov bp,w v_zs[edi*4]
         add bx,[esi+10]
         add cx,[esi+12]
         add bp,[esi+14]
         movsx ebx,bx
         movsx ecx,cx
         movsx ebp,bp

         push edi
         call _rotate_point                 ; z<>0, find rotation location

         add xad,ebx
         add yad,ecx
         add zad,ebp

         pop esi                            ; return object number+offset
         test v_userotate[esi],no_rotation   ; test to use new matrix or add to old
         jnz do_compound_thingy
         call _temp_matrix                  ; add to old
         call _matrix_multiply
         mov eax,minzc
         cmp zad,eax                        ; check if new object will be behind camera
         jg done_alterq
         jmp failed_iterationq

do_compound_thingy:
         call _compound                     ; _compound new matrix
         mov eax,minzc
         cmp zad,eax                        ; check if new object will be behind camera
         jg done_alterq
         jmp failed_iterationq

no_new_matrix:
         test b [esi+8],centroid            ; is there a centroid offset?
         jz done_alter
         mov eax,[esi+28]
         mov btolr,eax

         push ebx esi ebp edx               ; save stuff before centroid handle
         movsx ebx,w [esi+10]               ; no new matrix command, find point
         movsx ecx,w [esi+12]               ; offset (addition)
         movsx ebp,w [esi+14]

         call _rotate_point                 ; if found, add _rotate_pointd point to xad,yad,zad

         add xad,ebx
         add yad,ecx
         add zad,ebp

done_alterq:
         sub zad,1
         adc zad,1

         mov ebx,xad                        ; test if new xad,yad,zad are within screen boundaries
         mov ecx,yad
         mov ebp,zad

         cmul eax,ebx,ratiox                ; use fast constant multiply fo 3d conversion
         idiv ebp

         movsx edx,_xmins
         sub edx,btolr
         cmp eax,edx                        ; tolerance is max object size/ratio
         jl failed_iterationq
         movsx edx,_xmaxs
         add edx,btolr
         cmp eax,edx
         jge failed_iterationq

         mov ebx,eax

         cmul eax,ecx,ratioy
         idiv ebp

         movsx edx,_ymins
         sub edx,btolr
         cmp eax,edx
         jl failed_iterationq
         movsx edx,_ymaxs
         add edx,btolr
         cmp eax,edx
         jge failed_iterationq

         mov edi,pointindex
         mov xp[edi],ebx
         mov yp[edi],eax
         mov zp[edi],ebp
         add pointindex,4

         pop edx ebp esi ebx

done_alter:
         movzx eax,w [esi]                  ; get number of extra points in iteration
         add esi,2
         mov numpoints,eax                  ; set as counter
         mov ecx,eax                        ; save number of extra points for later use

         shl eax,2
         add eax,pointindex                 ; pointindex = word indexer to last point
         cmp eax,maxpoints*4                ; test for overflow in points tables
         jae abort_all2

         lodsw                              ; get number of sides in iteration
         add numsides,eax

         add eax,_showing
         cmp eax,maxsurfaces-1              ; check for overflow in "sides" tables
         jae abort_all2

         add esi,25*2

         or ecx,ecx                         ; no new points to add? (just surfaces)
         je return_iteration                ; only sides added to iteration, done...

         push ebx ebp edx                   ; save load and store locations

         mov edi,currobj                    ; add more points to xp,yp,zp list
         mov bl,v_userotate[edi]             ; because iteration is visible

         mov edi,pointindex                 ; movzx edi,pointindex

         call middle_load_points
         pop edx ebp ebx

         jmp return_iteration

         align 4

abort_all2:
         add esp,strip_bytes                ; abort from iteration and _make1obj
         ret                                ; returning now from _makeobjs call

; perform test for option "onscr" - generate iteration if points on screen.
; routine also tests if polygon crosses screen - eg no point is on the screen
; but the polygon covers the screen, like the front of a very big building.

         align 4

test_if_on_screen:
         xor bl,bl                          ; bl = quadrant flag
         push edx edi                       ; save command

         mov esi,ebp
tios:
         mov ecx,xp[esi]                    ; cx, dx =(x,y) to test
         mov edx,yp[esi]

         mov ah,32                          ;  32 16  8    determine where point is,
         cmp cx,_xmins                      ;1  x  x  x    then or bl with location
         jl s ytest                         ;2  x  x  x
         mov ah,8                           ;4  x  x  x
         cmp cx,_xmaxs                      ;
         jge s ytest
         mov ah,16
ytest:
         mov al,1
         cmp dx,_ymins
         jl s oritall
         mov al,4
         cmp dx,_ymaxs
         jge s oritall

         cmp ah,16
         je s on_screen                     ; a point is on the screen, generate side...
oritall:
         or bl,ah                           ; point is not on the screen, but it may
         or bl,al                           ; contribute to a polygon which covers the screen.

         add edi,2                          ; get next connection for another test
         mov si,sides[edi]
         cmp si,bp                          ; test if at last connection in iteration test
         jne tios

         xor al,al                          ; count number of bits in y (must be >2)
         ror bl,1
         adc al,0
         ror bl,1
         adc al,0
         ror bl,1
         adc al,0
         cmp al,1
         jbe s skipit2

         xor al,al                          ; now count x (must be >2)
         ror bl,1
         adc al,0
         ror bl,1
         adc al,0
         ror bl,1
         adc al,0
         cmp al,1
         jbe s skipit2
on_screen:
         pop edi edx

         test edx,both                      ; side is on screen
         jz return_screen                   ; test if alway visible

         pop esi ebx ebp                    ; always, pop and test for shading
         test edx,shade
         jz ln2                             ; no shading - do normal return
         jmp handle_shading

skipit2:
         pop edi edx esi ebx ebp
         jmp skipit

; handle failure of option 512

         align 4

failed_iterationq:
         pop edx ebp esi ebx

failed_iteration:
         movzx ecx,w [esi+4]                ; number of bytes to skip in case of failure
         mov ax,[esi+6]                     ; get number of points TOTAL in iteration
         add esi,8
         shl eax,2                          ; in case iteration in iteration in iteration...
         add w pointindex,ax
         add esi,ecx
         jmp return_iteration

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _make1obj: Handle plotting of object ESI
; In:
;   ESI -> object #
; OUT:null
; Notes:
; Routine assumes object is already ON!  note: esi not si!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_make1obj:
         mov currobj,esi

         mov ebx,v_xs[esi*4]                 ; displacement
         sub ebx,eyex
         mov ecx,v_ys[esi*4]
         sub ecx,eyey
         mov ebp,v_zs[esi*4]
         sub ebp,eyez

         test v_userotate[esi],s_himap+s_point ; check if _bitmap or point
         jnz mo_special

         if div_256 eq 8
         shr ebx,8                          ; account for decimal places
         test ebx,00800000h
         jz s pm_1
         or ebx, 0ff000000h
pm_1:
         shr ecx,8
         test ecx,00800000h
         jz s pm_2
         or ecx, 0ff000000h
pm_2:
         shr ebp,8
         test ebp,00800000h
         jz s pm_3
         or ebp, 0ff000000h
pm_3:
         endif

         mov si,v_whatshape[esi*2]           ; get shape
         mov esi,_objbase[esi*4]            ; get header start
         add esi,[esi+4]                    ; get first resolution
         mov edi,[esi+14*2]                 ; get maximum distance seen

         cmp ebx,edi                        ; check if within visible space
         jnl s noa2                         ; if object miles away, don't bother
         cmp ebp,edi
         jnl s noa2
         cmp ecx,edi
         jnl s noa2
         neg edi
         cmp ebp,edi
         jl s noa2
         cmp ebx,edi
         jl s noa2
         cmp ecx,edi
         jg s mo_misout
noa2:
         ret
mo_misout:
         mov edi,dword ptr [esi+16*2]
         mov eax,dword ptr [esi+18*2]
         mov btolr,eax
         call _zsolve                       ; figure out camera displacement

         cmp esi,edi                        ; check if behind camera, miminum dist.
         jl s noa2

         sub esi,1                          ; make z non-zero
         adc esi,1

         call _xsolve
         mov xad,edi                        ; store 3d offsets
         call _make3dx                      ; now make object farther in 3d

         movsx eax,_xmins
         sub eax,btolr
         cmp edi,eax                        ; tolerance is max object size/ratio
         jl s noa2
         movsx eax,_xmaxs
         add eax,btolr
         cmp edi,eax
         jge s noa2

         call _ysolve                       ; solve y and set correct regs
         mov yad,ecx
         call _make3dy                      ; now make object farther in 3d

         movsx eax,_ymins
         sub eax,btolr
         cmp ecx,eax
         jl s noa2
         movsx eax,_ymaxs
         add eax,btolr
         cmp ecx,eax
         jge noa2

         mov zad,ebp
         mov esi,pointindex

         mov xp[esi],ebx                    ; save center of gravity as point 0
         mov yp[esi],ecx
         mov zp[esi],ebp

         mov esi,currobj                    ; pop original object number
         xor ebx,ebx
         mov bl,v_palxref[esi]
         mov ebx,_xreftable[ebx*4]
         mov palxrefx,ebx

         test v_userotate[esi],no_rotation   ; test to call _compound routine
         jnz s mk_skipc                     ; skip if anything other than full rotations
         call _compound                     ; full rotation object, calc. matrix
mk_skipc:
         call loadpoints                    ; load points and _rotate_point, exit di=sides
         jmp loadsides                      ; now load sides, starting at di

         align 4
noa:
         ret

         align 4

; if v_userotate = 32 then draw _bitmap at location x,y,z

mo_special:
         mov edi,maxz*256
         cmp ebx,edi                        ; check if within visible space
         jnl s noa                          ; if object miles away, don't bother
         cmp ebp,edi
         jnl s noa
         cmp ecx,edi
         jnl s noa
         neg edi
         cmp ebp,edi
         jl s noa
         cmp ebx,edi
         jl s noa
         cmp ecx,edi
         jl s noa

         if div_256 eq 8
         shr ebx,8                          ; account for decimal places, /256
         test ebx,00800000h
         jz s pq_1
         or ebx, 0ff000000h
pq_1:
         shr ecx,8
         test ecx,00800000h
         jz s pq_2
         or ecx, 0ff000000h
pq_2:
         shr ebp,8
         test ebp,00800000h
         jz s pq_3
         or ebp, 0ff000000h
pq_3:
         endif

         call _zsolve                       ; figure out camera displacement

         cmp esi,minz                       ; check if behind camera, miminum dist.
         jl noa

         call _xsolve
         mov xad,edi                        ; store 3d offsets
         call _make3dx                      ; now make object farther in 3d

         cmp edi,xmit                       ; tolerance is max object size/ratio
         jl noa
         cmp edi,xmat
         jge noa

         call _ysolve                       ; solve y and set correct regs
         mov yad,ecx
         call _make3dy                      ; now make object farther in 3d

         cmp ecx,ymit
         jl noa
         cmp ecx,ymat
         jge noa

         mov zad,ebp
         mov esi,currobj                    ; pop original object number

         cmp pointindex,(maxpoints-1)*2     ; check if there is room in table
         jge noa
         cmp _showing,maxsurfaces-1
         jge noa

         test v_userotate[esi],s_point       ; is point or _bitmap?
         jnz mo_ispoint

         mov edi,pointindex
         mov [xp+edi],ebx                   ; set location of _bitmap
         mov [yp+edi],ecx
         mov [zp+edi],ebp

         mov edi,offsides
         add offsides,maxpolys*2            ; update for next object/_bitmap

         mov ebx,_showing
         shl ebp,2                          ; adjust so it's the same as loadsides
         mov zeds[ebx*4],ebp                ; set z sort indexer

         inc _showing                       ; one more surface...
         xor ah,ah
         mov al,v_userotate[esi]
         mov textures[ebx*2],ax             ; set command for _bitmap

         mov eax,pointindex
         add pointindex,4
         stosw
         mov ax,v_whatshape[esi*2]
         stosw
         mov ax,v_bitobjx[esi*2]             ; set x and y scales (stretching)
         stosw
         mov ax,v_bitobjy[esi*2]
         stosw
noa4:
         ret

         align 4

mo_ispoint:
         cmp bx,_xmins                      ; draw single point/bullet
         jl s noa4
         cmp bx,_xmaxs
         jge s noa4
         cmp cx,_ymins
         jl s noa4
         cmp cx,_ymaxs                      ; _ymaxs1 if larger pixel
         jge s noa4

         mov edi,pointindex
         mov [xp+edi],ebx                   ; set location of point/_bitmap
         mov [yp+edi],ecx
         mov [zp+edi],ebp

         mov edi,offsides
         add offsides,maxpolys*2            ; update for next object/_bitmap

         mov ebx,_showing
         shl ebx,1
         shl ebp,2
         mov zeds[ebx*2],ebp                ; set z sort indexer

         inc _showing                       ; one more surface...

         mov textures[ebx],64               ; set this command as point
         mov surfcolors[ebx],bulletcolour   ; only for variable colours

         mov eax,pointindex
         add pointindex,4

         stosw
         stosw
noa8:
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Set_order: Initialize original order for plotting objects
;  In=Out=null
; Notes:  This is called by _flush_surfaces so no need for you to do it.
; This must be called every frame to re-initalize the order for polygon sorting
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

set_order:
         mov ecx,_showing
         jcxz s non2_do
         dec ecx
         jz s non2_do
         shl ecx,1
         mov esi,ecx
         shl esi,1
         add esi,offset order

         prc equ 8

         cmp ecx,prc*2
         jb s ordrloop
bigsloop:
         i=0
         rept prc
         mov [esi+i],ecx
         i=i-4
         sub ecx,2
         endm
         jz s non2_do
         sub esi,prc*4
         cmp ecx,prc*2
         jae s bigsloop
ordrloop:
         mov [esi],ecx
         sub esi,4
         dec ecx
         loop ordrloop
non2_do:
         mov [order],0                      ; fill last

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _makeobjs: Make/plot all objects on _current_page, unrolled loop
;  In=Out=null
; Notes: Called from _makeobjs
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

makeobjx:
         i=1

         rept maxobjects
         local itsoff

         test v_onoff+i,mainobject_on        ; check on/off
         jz s itsoff

         mov esi,i
         call _make1obj
itsoff:

         i=i+1
         endm

         ret                                ; put no code here! _make1obj may force abort!

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _init_tables: Initialize ordering before beginning 3d animation
;  In=Out=null
; Notes: Called by YOU. Different routines between 3d1,3d2 and 3d3
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_init_tables:
         mov offsides, offset sides         ; clear table indexers for call
         mov pointindex,0
         mov _showing,0
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _makeobjs: Make/plot all objects on _current_page
;  In=Out=null
; Notes: Called from your mainline animation routine, falls through to _flush_surfaces
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_makeobjs:
         call makeobjx                      ; make objects

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _flush_surfaces: Sort and flush all surfaces from polygon buffer to screen
;  In=Out=null
; Notes: called by _makeobjs
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_flush_surfaces:
         call set_order                     ; set ordering of sides
         call _sortlist                     ; sort sides according to z distance
         call _drawvect                     ; draw 'em on da screen

         mov offsides, offset sides         ; clear table indexers for call
         mov pointindex,0

         ret

code32   ends
         end
