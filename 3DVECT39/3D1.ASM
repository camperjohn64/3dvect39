;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : 3d1.asm
; Included from: Main Assembley Module
; Description  : 3d vector routines - fast sort method
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
; - objects cannot enter inside one another
; - maxsurfs and maxpoints can be kept low - set to largest object requirement
;
; To use:
;
;          call _land_draw          ; draw _background landscape
;          call _clearfill          ; clear video memory (last screen)
;          call _look_at_it         ; make camera look at selected object
;          call _setsincose         ; set rotation multipliers for eye
;          call _star_plot          ; plot _background stars (if you want)
;          call _makeobjs           ; plot all objects on current screen
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

         include vars1.inc                  ; labels and such
         align 4
         include tables.inc
         include math.inc                   ; rotate,cos,sin,arctan...
         include xscale.inc
         include poly.inc                   ; common ploygon stuff

         public _makeobjs
         public _make1obj
         public _flush_surfaces
         public _init_tables

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Loadpoints:  Begin loading of points from object definition data into array
; In:
;  ESI -> object #
; Out:
;  ESI -> offset of connection data
; Given ESI as object number.  _rotate_point, translate and convert to 3d the points
; of that object.  returns edi as pointer to sides.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

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

         lodsd
         mov w numpoints,ax
         or ax,ax
         jz no_points_anyway                ; object is made totally out of iterations...
         shr eax,16
         mov numsides,eax
         add esi,50                         ; skip extra data

         mov edi,4                          ; reset xp pointer
middle_load_points:
         test bl,no_rotation
         jnz s np13                         ; use different loop if no rotation
np12:
         movsx ebx,w [esi]                  ; x
         movsx ecx,w [esi+2]                ; y
         movsx ebp,w [esi+4]                ; z

         push edi esi
         call _rotate_point                 ; _rotate_point
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

         mov pointindex,edi                 ; save in case of iteration surfaces

         ret                                ; edi exits with pointer to sides
ntrt:
         mov ebp,ztruncate
         jmp s ntrunct

no_points_anyway:
         mov pointindex,4                   ; side is all iteration surfaces
         shr eax,16
         mov numsides,eax
         add esi,25*2                       ; skip extra data
         ret
np13:
         movsx ebx,w [esi]                  ; x
         movsx ecx,w [esi+2]                ; y
         movsx ebp,w [esi+4]                ; z

         push edi esi
         call _rotate_by_camera             ; rotation matrix already set up! (camera)
         add ebp,zad

         cmp ebp,ztruncate
         jl s ntrt2
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

         mov pointindex,edi                 ; save in case of iteration surfaces

         ret
ntrt2:
         mov ebp,ztruncate
         jmp s ntrunct2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Special surface types/options - make your own
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

special_commands dd offset dobitmap         ; 0
         dd offset dobitmap                 ; 1
         dd offset pushmatrix               ; 2
         dd offset popmatrix                ; 3
         dd offset pushlocation             ; 4
         dd offset poplocation              ; 5
         dd offset newobject                ; 6
         dd offset no_new_matrix            ; 7
         dd offset gosub_function           ; 8
         dd offset return_function          ; 9
         dd offset goto_function            ; 10

number_ofb dw 5*2                           ; hibitmap
         dw 5*2                             ; lobitmap
         dw 1*2                             ; pushmatrix
         dw 1*2                             ; popmatrix
         dw 1*2                             ; pushlocation
         dw 1*2                             ; poplocation
         dw 1*2                             ; newobject
         dw 1*2                             ; no_new_matrix
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
         mov ecx,eax
         and ecx,special-1                  ; maximum 127 "special" commands
         jmp [special_commands+ecx*4]

         align 4

; handle loading of bitmap from object list
;
; eg dw himap,8,5,50,60 ;command is 32,point 8, bitmap 5, x&y scaling of 50,60

dobitmap:
         lodsw                              ; get from si, first is point
         shl eax,2
         stosw                              ; put in sides table

         mov edx,ebp                        ; save indexer
         movzx ebp,ax                       ; get point indexers
         mov eax,zp[ebp]
         mov zeds[ebx*2],eax                ; set zed for sort.
         mov ebp,edx

         movsw                              ; get bitmap type
         movsd                              ; get x then y scaling

         mov edx,command                    ; get command (for iteration bits)
         mov textures[ebx],dx               ; command is now texture

         jmp ln3

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Loadsides: Load connection data from object data definition
; In:
;  ESI -> offset of connection data
; Out: null
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4
loadsides:
         mov _showing,0                     ; reset counter/indexer
         mov lamflag,no

         xor ebp,ebp                        ; indexer to first point
         mov edi,offset sides               ; get ready for lodsw and stosw
         xor ebx,ebx
ld_lp:
         lodsw                              ; get command word
         mov command,eax
         mov edx,eax                        ; save for later test

         mov order[ebx*2],ebx               ; set order to 0,2,4,6,8...

         test eax,special                   ; if bitmap, do special load, or previous
         jnz ld_special                     ; colour (avoids pre-fetch instruction flush)

         mov eax,[esi]                      ; get texture data/type
         mov texture12,eax

         mov eax,[esi+4]                    ; get colour, high byte is other side
         add esi,8
         mov colors12,eax

         push ebp
         push ebx

         movzx eax,w [esi]                  ; get from esi, first is unconditinal
         add esi,2
         shl eax,2
         mov [edi],ax                       ; put in edi
         mov [edi+4],ax
         mov ecx,eax

         lodsw                              ; get from esi
         shl eax,2
         mov [edi+2],ax                     ; put in edi
         mov [edi+6],ax
         cmp eax,ecx                        ; check all after first point
         je s ld_exitloop
         add edi,4
ld_loop:
         lodsw
         shl eax,2
         mov [edi+0],ax
         cmp eax,ecx
         je s ld_exitloop

         lodsw
         shl eax,2
         mov [edi+2],ax
         cmp eax,ecx
         je s ld_exitloop

         lodsw
         shl eax,2
         mov [edi+4],ax
         add edi,6
         cmp eax,ecx
         jne s ld_loop

ld_exitloop:
         push esi
         mov edi,ebp                        ; adjust bp into appropriate indexer
         mov bp,[sides+edi+6]
         mov ecx,[zp+ebp]
         mov bp,[sides+edi+4]
         add ecx,[zp+ebp]
         mov bp,[sides+edi+2]               ; get point indexers
         add ecx,[zp+ebp]                   ; take average of 4 z values, should be
         mov bp,[sides+edi+0]               ; average of all but two is ok.
         add ecx,[zp+ebp]
         mov zeds[ebx*2],ecx                ; but any will do.

         test edx,onscr                     ; find if test is for on screen pixels
         jnz test_if_on_screen
         test dl,both                       ; check if always visible (or point, or line)
         jnz its_line

return_screen:
         mov edx,[xp+ebp]                   ; first point
         mov ebx,[yp+ebp]

         mov bp,[sides+edi+2]
         mov esi,[xp+ebp]                   ; second point
         mov ecx,[yp+ebp]

         mov bp,[sides+edi+4]
         mov edi,[xp+ebp]                   ; third point
         mov ebp,[yp+ebp]

         call checkfront                    ; check if side is visible using p1,2,3

         pop esi ebx ebp

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
         inc _showing
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
         add edi,offset sides

         dec numsides                       ; count for next side
         jne ld_lp

         ret

         align 4
its_line:
         pop esi ebx ebp
         test w texture12,shade+last
         jz ln2

; handle gourad/_lambert shading

         align 4
handle_shading:
         test w texture12,last              ; test to use previous colour or bitmap call
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
         test w texture12,inverse           ; have the sides flipped?
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
         sub zad,1                          ; prevent huge object from becoming 0
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
         ret                                ; out of room for surfaces, return and plot

; perform test for option "onscr" - test if polygon points on screen.
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
         mov al,2
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

; handle failure of iteration option

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

         test v_userotate[esi],s_himap+s_point ; check if bitmap or point
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
         jl noa2
         movsx eax,_ymaxs
         add eax,btolr
         cmp ecx,eax
         jge noa2

         mov zad,ebp
         mov zedthis,ebp                    ; store z for next sort

         mov xp,ebx                         ; save center of gravity as point 0
         mov yp,ecx
         mov zp,ebp

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
         call loadsides                     ; now load sides, starting at di
         call _sortlist                     ; sort surfaces
         jmp _drawvect                      ; draw surfaces and exit
noa:
         ret

; if v_userotate = "bitmap" then draw bitmap at location x,y,z

         align 4

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
         jl noa2

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
         mov zedthis,ebp                    ; store z for next sort
         mov esi,currobj                    ; pop original object number

         mov al,v_userotate[esi]
         test al,s_point                    ; check if point
         jnz mo_ispoint

         push eax ebx ecx                   ; save actual center of bitmap and command

         mov ebx,xad                        ; calc size of bitmap
         mov ecx,yad

         shl esi,1                          ; si = word
         movzx edx,v_bitobjx[esi]           ; get addition for bitmap size
         sub ebx,edx
         movzx edx,v_bitobjy[esi]           ; get addition for bitmap size
         sub ecx,edx

         mov si,v_whatshape[esi]
         shl esi,2                          ; si = dword
         sub ebx,_bitx[esi]
         sub ecx,_bity[esi]                 ; ebx,ecx = top corner of bitmap in 3d

         mov eax,_bitbase[esi]
         mov _bitmap,eax

         call _make3d                       ; ebx,ecx = top corner of bitmap in 2d

         pop ebp eax                        ; bp = y, ax = x center
         sub bp,cx                          ; bp = y height/2
         sub ax,bx                          ; ax = x width/2
         mov _scale_destheight,bp
         mov _scale_destwidth,ax

         movsx ebp,bp
         movsx eax,ax
         shr eax,1
         shr ebp,1
         add cx,bp
         add bx,ax

         add bx,_xcent
         add cx,_ycent
         mov _scale_destx,bx
         mov _scale_desty,cx

         pop eax
         test al,lomap-himap                ; test to use 1/4 scale bitmap or full scale
         jz _xscale2
         jmp _xscale4
noa7:
         ret
mo_ispoint:
         cmp bx,_xmins                      ; draw single point/bullet
         jl s noa7
         cmp bx,_xmaxs
         jge s noa7
         cmp cx,_ymins
         jl s noa7
         cmp cx,_ymaxs                      ; _ymaxs1 if larger pixel
         jge s noa7

         mov edi, _current_page             ; point to active vga page
         add bx,_xcent
         add cx,_ycent

         mov si,cx
         mov eax,[esi*4+_fastimultable]     ; get offset to start of line

         mov cx, bx                         ; copy to extract plane # from
         shr bx, 2                          ; x offset (bytes) = xpos/4
         add bx, ax                         ; offset = width*ypos + xpos/4

         mov ax, map_mask_plane1            ; map mask & plane select register
         and cl, plane_bits                 ; get plane bits
         shl ah, cl                         ; get plane select value
         out_16 sc_index, ax                ; select plane

         movzx ebx,bx
         mov [edi+ebx],b bulletcolour       ; draw pixel, red or yellow is good
;        add edi,xactual/4
;        mov [edi+ebx],b bulletcolour2      ; draw larger bullet/pixel

; if drawing larger pixel, change above code to this!
;        cmp cx,_ymaxs1
;        jge s noa7

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Setmakeorder: Initialize original order for plotting objects
;  In=Out=null
; Notes:  This is called by _init_tables so there is no need for you to do it.
; This  must  be  called  once  at  the  beginging of the program  to  define
; in what order the objects must be plotted (back to front).   The  order  is
; constantly being re-arranged as objects move in front an behind one another
; If you want to do windowing, save the makeorder table for each window.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

setmakeorder:

         i=0
         rept maxobjects                    ; macro to produce unrolled loop
         mov makeorder+i*4,i+1              ; set makeorder to 0,1,2,3,4
         i=i+1
         endm

         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _makeobjs: Make/plot all objects on _current_page
;  In=Out=null
; Notes: Called from your mainline animation routine, falls through to sort
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_makeobjs:                                  ; make all objects, unrolled loop
         xor esi,esi
         i=0

         rept maxobjects
         local itsoff

         mov eax,7fffffffh                  ; in case of abort
         mov esi,makeorder+i*4
         test v_onoff[esi],mainobject_on    ; check on/off
         jz s itsoff

         call _make1obj
         mov eax,zedthis                    ; get z and save for re_sort
         xor esi,esi
itsoff:
         mov finalzed+i*4,eax

         i=i+1
         endm

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Re_sort:Bubble sort for entire objects, fastest when already sorted (assumed)
;  In=Out=null
; Notes: No need to ever call this routine as _makeobjs falls through to here.
; This routine sorts the objects make order by the previous Z distance.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         basedif equ makeorder-finalzed
re_sort:
         mov edi,maxobjects*4+offset finalzed
         mov esi,maxobjects
         mov ecx,maxobjects+2
         mov edx,offset finalzed-4-4
rs_loop1:
         dec esi
         sub edi,4
         mov eax,makeorder[esi*4]
         test v_onoff[eax],mainobject_on
         loopz s rs_loop1
         jcxz _ret

         mov esi,-1
rs_loop2:
         inc esi
         add edx,4
         mov eax,makeorder[esi*4]
         test v_onoff[eax],mainobject_on
         loopz s rs_loop2
         jcxz _ret

         xor ebx,ebx                        ; sort flag
nextccx:
         mov esi,edx
         add edx,4
nextddx:
         add esi,4

         mov eax,[esi+4]
         cmp eax,[esi]
         jle s donotng
         xchg eax,[esi]                     ; don't flip entire object, just indexers
         xchg eax,[esi+4]
         mov eax,basedif[esi+4]
         xchg eax,basedif[esi]
         xchg eax,basedif[esi+4]
         inc ebx                            ; flag that one sorted
donotng:
         cmp esi,edi
         jb s nextddx

         or ebx,ebx                         ; re-sort until no more sorts
         loopne s nextccx
quickex:
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _init_tables: Initialize ordering before beginning 3d animation
;  In=Out=null
; Notes: Called by YOU. Different routines between 3d1,3d2 and 3d3
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_init_tables:
         call setmakeorder
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _flush_surfaces: Sort and flush all surfaces from polygon buffer to screen
;  In=Out=null
; Notes: called by _make1obj
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_flush_surfaces:
         call _sortlist                     ; sort sides according to z distance
         call _drawvect                     ; draw 'em on da screen
         ret

code32   ends
         end
