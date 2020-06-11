;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : xscale.inc
; Included from: 3D1.ASM, 3D2.ASM, 3D3.ASM
; Description  : bitmap Scaling routines - non-cartisian plotting
;
; _xscale1.ASM by John A. Slagel, jas37876@uxa.cso.uiuc.edu
; This is some code to do bitmap scaling in VGA Mode X.  It can scale a
; bitmap of any size down to 2 pixels wide, or up to thousands of pixels
; wide.  It performs complete clipping, with only a small constant amount
; of time to clip, no matter how huge the image is.  It draws column by
; column to reduce the number of plane switches, which are slow. The inner
; column loop has been optimized for no memory accesses, except to read or
; write a pixel.  This uses MASM 5.1 features, and can be compiled in any
; memory model by changing the .MODEL line, but make sure that you always
; pass a far pointer to the bitmap data, regardless of memory model.
; C-callable as:
;   void _xscale1( int X, int Y, int DW, int DY,
;                     int SW, int SH, void far * bitmap );
; X,Y   are the upper left-hand coordinates of where to draw the bitmap.
; DW,DH are the width and height of the SCALEed _bitmap
; SW,SH are the width and height of the source _bitmap.
; _bitmap is a pointer to the _bitmap bits.
;
; Routine has been modified for 32 bit protected mode by John McCarthy.
; John McCarthy thanks John A. Slagel for providing this code, and hopes
; John A. Slagel is not offended by the changes.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         public _draw_scale
         public _tdraw_scale
         public _tdraw_scale4
         public _xscale1
         public _xscale2
         public _xscale4
         public _repeat_bitmap

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _draw_scale - draw scaled _bitmap in modex
; In:
;    ESI - offset of _bitmap to draw, first two words are x,y size
;     AX - x width to scale to
;     BX - y width to scale to
;     CX - x location, non-cartisian
;     DX - y location, non-cartisian
; _current_page - current offset of video memory for page of xmode, see xmode.asm
;
; Out:
;    null
;
; Notes:
;  destructive bitmap - non-cartisian
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_draw_scale:
         mov _bitmap,esi
         mov _scale_destwidth,ax
         mov _scale_destheight,bx
         mov _scale_destx,cx
         mov _scale_desty,dx

_xscale1:
         cmp _scale_destwidth, 2            ; if destination width is less than 2
         jl done                            ;     then don't draw it.

         cmp _scale_destheight, 2           ; if destination height is less than 2
         jl done                            ;     then don't draw it.

         mov ax, _scale_desty               ; if it is completely below the
         cmp ax, _clipbt                    ; lower clip bondry,
         jg done                            ;     then don't draw it.

         add ax, _scale_destheight          ; if it is above clip boundries
         dec ax                             ;     then don't draw it.
         cmp ax, _cliptp
         jl done

         mov ax, _scale_destx               ; if it is to the right of the
         mov cx, _cliprt                    ; right clip boundry
         cmp ax, _cliprt                    ;     then don't draw it.
         jg done

         add ax, _scale_destwidth           ; if it is completely to the left
         dec ax                             ; of the left clip boundry,
         cmp ax, _cliplt                    ;     then don't draw it.
         jl done

         mov esi, _bitmap             ; make esi point to _bitmap data
         lodsw                              ; get source x width
         mov sourcewidth,ax
         lodsw                              ; get source y height
         mov sourceheight,ax

         mov ax, _scale_destwidth           ; clippedwidth is initially set to
         mov clippedwidth, ax               ; the requested dest width.

         add ax,ax                          ; initialize the x decision var
         neg ax                             ; to be -2*_scale_destwidth
         mov decisionx, ax                  ;

         mov ax, _scale_destheight          ; clippedheight is initially set to
         mov clippedheight, ax              ; the requested dest size.

         add ax,ax                          ; initialize the y decision var
         neg ax                             ; to be -2*_scale_destheight
         mov decisiony, ax                  ;

         movsx eax, _cliptp                 ; if y is below the top
         mov edx, eax                       ; clipping boundry, then we don't
         sub dx, _scale_desty               ; need to clip the top, so we can
         js s notopclip                     ; jump over the clipping stuff.

         mov _scale_desty, ax               ; this block performs clipping on the
         sub clippedheight, dx              ; top of the _bitmap.  i have heavily
         movsx ecx, sourceheight            ; optimized this block to use only 4
         imul ecx, edx                      ; 32-bit registers, so i'm not even
         mov eax, ecx                       ; gonna try to explain what it's doing.
         cdq                                ; but i can tell you what results from
         movsx ebx, _scale_destheight       ; this:  the decisiony var is updated
         idiv ebx                           ; to start at the right clipped row.
         movsx edx, sourcewidth             ; y is moved to the top clip
         imul edx, eax                      ; boundry. clippedheight is lowered since
         add esi, edx                       ; we won't be drawing all the requested
         imul eax, ebx                      ; rows. esi is changed to point over
         sub ecx, eax                       ; the _bitmap data that is clipped off.
         sub ecx, ebx                       ;
         add ecx, ecx                       ;
         mov decisiony, cx                  ; <end of top clipping block >

notopclip:
         mov ax, _scale_desty               ; if the _bitmap doesn't extend over the
         add ax, clippedheight              ; bottom clipping boundry, then we
         dec ax                             ; don't need to clip the bottom, so we
         cmp ax, _clipbt                    ; can jump over the bottom clip code.
         jle s nobottomclip                 ;

         mov ax, _clipbt                    ; clip off the bottom by reducing the
         sub ax, _scale_desty               ; clippedheight so that the _bitmap won't
         inc ax                             ; extend over the lower clipping
         mov clippedheight, ax              ; boundry.

nobottomclip:
         movsx eax, _cliplt                 ; if x is to the left of the
         mov edx, eax                       ; top clipping boundry, then we don't
         sub dx, _scale_destx               ; need to clip the left, so we can
         js s noleftclip                    ; jump over the clipping stuff.

         mov _scale_destx, ax               ; this block performs clipping on the
         sub clippedwidth, dx               ; left of the _bitmap.  i have heavily
         movsx ecx, sourcewidth             ; optimized this block to use only 4
         imul ecx, edx                      ; 32-bit registers, so i'm not even
         mov eax, ecx                       ; gonna try to explain what it's doing.
         cdq                                ; but i can tell you what results from
         movsx ebx, _scale_destwidth        ; this:  the decisionx var is updated
         idiv ebx                           ; to start at the right clipped column.
         add esi, eax                       ; x is moved to the left clip
         imul eax, ebx                      ; boundry. clippedwidth is reduced since
         sub ecx, eax                       ; we won't be drawing all the requested
         sub ecx, ebx                       ; cols. esi is changed to point over
         add ecx, ecx                       ; the _bitmap data that is clipped off.
         mov decisionx, cx                  ; <end of left clipping block >

noleftclip:
         mov ax, _scale_destx               ; if the _bitmap doesn't extend over the
         add ax, clippedwidth               ; right clipping boundry, then we
         dec ax                             ; don't need to clip the right, so we
         cmp ax, _cliprt                    ; can jump over the right clip code.
         jle s noclipright                  ;

         mov ax, _cliprt                    ; clip off the right by reducing the
         sub ax, _scale_destx               ; clippedwidth so that the _bitmap won't
         inc ax                             ; extend over the right clipping
         mov clippedwidth, ax               ; boundry.

         ;calculate starting video address
noclipright:
         xor edi,edi
         mov di, _scale_desty               ; we are going to set edi to start point
         imul edi, xactual/4
         xor eax,eax
         mov ax, _scale_destx               ; the offset edi is
         mov cx, ax                         ; calculated by:
         shr ax, 2                          ;     di = y*80+x/2
         add eax, _current_page
         add edi,eax                        ; edi is ready!

         mov dx, sc_index                   ; point the vga sequencer to the map
         mov al, map_mask                   ; mask register, so that we only need
         out dx, al                         ; to send out 1 byte per column.

         inc dx                             ; move to the sequencer's data register.
         and cx, 3                          ; calculate the starting plane. this is
         mov al, 11h                        ; just:
         shl al, cl                         ; plane =  (11h << (x and 3))
         out dx, al                         ; select the first plane.

         xor ecx,ecx
         mov cx, sourcewidth                ; use cx for source width
         mov xad, ecx
         shl sourcewidth,1

         align 4                           ; since this point gets jumped to a lot,
         ; make sure that it is dword aligned.
rowloop:
         push esi                           ; save the starting source index
         push edi                           ; save the starting dest index
         push ax                            ; save the current plane mask
         push bp                            ; save the current base pointer

         mov cx, clippedheight              ; use al for row counter (0-239)
         mov bx, decisiony                  ; use bx for decision variable
         mov dx, sourceheight               ; use dx for source height * 2
         add dx, dx
         mov bp, _scale_destheight          ; use bp for dest height * 2
         add bp, bp
         mov ah, [esi]                      ; get the first source pixel

         align 4                            ; common jump point... align for speed.
columnloop:
         mov [edi], ah                      ; draw a pixel
         dec cx                             ; decrement line counter
         jz s donewithcol                   ; see if we're done with this column
         add edi, xactual/4                 ; go on to the next screen row
         add bx, dx                         ; increment the decision variable
         js s columnloop                    ; draw this source pixel again

incsourcerow:
         add esi, xad                       ; move to the next source pixel
         sub bx, bp                         ; decrement the decision variable
         jns s incsourcerow                 ; see if we need to skip another source pixel
         mov ah, [esi]                      ; get the next source pixel
         jmp s columnloop                   ; start drawing this pixel

donewithcol:
         pop bp                             ; restore bp to access variables
         pop ax                             ; restore al = plane mask
         pop edi                            ; restore di to top row of screen
         pop esi                            ; restore si to top row of source bits

         rol al, 1                          ; move to next plane
         adc edi, 0                         ; go on to next screen column
         mov dx, sc_data                    ; tell the vga what column we're in
         out dx, al                         ; by updating the map mask register

         mov bx, decisionx                  ; use bx for the x decision variable
         add bx, sourcewidth                ; increment the x decision variable
         js s nextcol                       ; jump if we're still in the same source col.
         mov dx, _scale_destwidth           ; dx = w * 2
         add dx, dx
incsourcecol:
         inc esi                            ; move to next source column
         sub bx, dx                         ; decrement x decision variable
         jns s incsourcecol                 ; see if we skip another source column
nextcol:
         mov decisionx, bx                  ; free up bx for colloop
         dec clippedwidth                   ; if we're not at last column
         jnz rowloop                        ;    then do another column
done:
         ret                                ; we're done!

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _tdraw_scale - Draw transparent scaled _bitmap in modex
; In:
;    ESI - offset of _bitmap to draw, first two words are x,y size
;     AX - x width to scale to
;     BX - y width to scale to
;     CX - x location, non-cartisian
;     DX - y location, non-cartisian
; _current_page - current offset of video memory for page of xmode, see xmode.asm
;
; Out:
;    null
;
; Notes:
;  transparent _bitmap.  any bytes that = 0 are skipped,- non-cartisian
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_tdraw_scale:
         mov _bitmap,esi
         mov _scale_destwidth,ax
         mov _scale_destheight,bx
         mov _scale_destx,cx
         mov _scale_desty,dx

_xscale2:
         cmp _scale_destwidth, 2            ; if destination width is less than 2
         jl s done                          ;     then don't draw it.

         cmp _scale_destheight, 2           ; if destination height is less than 2
         jl s done                          ;     then don't draw it.

         mov ax, _scale_desty               ; if it is completely below the
         cmp ax, _clipbt                    ; lower clip bondry,
         jg s done                          ;     then don't draw it.

         add ax, _scale_destheight          ; if it is above clip boundries
         dec ax                             ;     then don't draw it.
         cmp ax, _cliptp
         jl s done

         mov ax, _scale_destx               ; if it is to the right of the
         mov cx, _cliprt                    ; right clip boundry
         cmp ax, _cliprt                    ;     then don't draw it.
         jg s done

         add ax, _scale_destwidth           ; if it is completely to the left
         dec ax                             ; of the left clip boundry,
         cmp ax, _cliplt                    ;     then don't draw it.
         jl s done

         mov esi, _bitmap             ; make esi point to _bitmap data
         lodsw                              ; get source x width
         mov sourcewidth,ax
         lodsw                              ; get source y height
         mov sourceheight,ax

         mov ax, _scale_destwidth           ; clippedwidth is initially set to
         mov clippedwidth, ax               ; the requested dest width.

         add ax,ax                          ; initialize the x decision var
         neg ax                             ; to be -2*_scale_destwidth
         mov decisionx, ax                  ;

         mov ax, _scale_destheight          ; clippedheight is initially set to
         mov clippedheight, ax              ; the requested dest size.

         add ax,ax                          ; initialize the y decision var
         neg ax                             ; to be -2*_scale_destheight
         mov decisiony, ax                  ;

         movsx eax, _cliptp                 ; if y is below the top
         mov edx, eax                       ; clipping boundry, then we don't
         sub dx, _scale_desty               ; need to clip the top, so we can
         js s notopclip2                    ; jump over the clipping stuff.

         mov _scale_desty, ax               ; this block performs clipping on the
         sub clippedheight, dx              ; top of the _bitmap.  i have heavily
         movsx ecx, sourceheight            ; optimized this block to use only 4
         imul ecx, edx                      ; 32-bit registers, so i'm not even
         mov eax, ecx                       ; gonna try to explain what it's doing.
         cdq                                ; but i can tell you what results from
         movsx ebx, _scale_destheight       ; this:  the decisiony var is updated
         idiv ebx                           ; to start at the right clipped row.
         movsx edx, sourcewidth             ; y is moved to the top clip
         imul edx, eax                      ; boundry. clippedheight is lowered since
         add esi, edx                       ; we won't be drawing all the requested
         imul eax, ebx                      ; rows. esi is changed to point over
         sub ecx, eax                       ; the _bitmap data that is clipped off.
         sub ecx, ebx                       ;
         add ecx, ecx                       ;
         mov decisiony, cx                  ; <end of top clipping block >

notopclip2:
         mov ax, _scale_desty               ; if the _bitmap doesn't extend over the
         add ax, clippedheight              ; bottom clipping boundry, then we
         dec ax                             ; don't need to clip the bottom, so we
         cmp ax, _clipbt                    ; can jump over the bottom clip code.
         jle s nobottomclip2

         mov ax, _clipbt                    ; clip off the bottom by reducing the
         sub ax, _scale_desty               ; clippedheight so that the _bitmap won't
         inc ax                             ; extend over the lower clipping
         mov clippedheight, ax              ; boundry.

nobottomclip2:
         movsx eax, _cliplt                 ; if x is to the left of the
         mov edx, eax                       ; top clipping boundry, then we don't
         sub dx, _scale_destx               ; need to clip the left, so we can
         js s noleftclip2                   ; jump over the clipping stuff.

         mov _scale_destx, ax               ; this block performs clipping on the
         sub clippedwidth, dx               ; left of the _bitmap.  i have heavily
         movsx ecx, sourcewidth             ; optimized this block to use only 4
         imul ecx, edx                      ; 32-bit registers, so i'm not even
         mov eax, ecx                       ; gonna try to explain what it's doing.
         cdq                                ; but i can tell you what results from
         movsx ebx, _scale_destwidth        ; this:  the decisionx var is updated
         idiv ebx                           ; to start at the right clipped column.
         add esi, eax                       ; x is moved to the left clip
         imul eax, ebx                      ; boundry. clippedwidth is reduced since
         sub ecx, eax                       ; we won't be drawing all the requested
         sub ecx, ebx                       ; cols. esi is changed to point over
         add ecx, ecx                       ; the _bitmap data that is clipped off.
         mov decisionx, cx                  ; <end of left clipping block >

noleftclip2:
         mov ax, _scale_destx               ; if the _bitmap doesn't extend over the
         add ax, clippedwidth               ; right clipping boundry, then we
         dec ax                             ; don't need to clip the right, so we
         cmp ax, _cliprt                    ; can jump over the right clip code.
         jle s noclipright2

         mov ax, _cliprt                    ; clip off the right by reducing the
         sub ax, _scale_destx               ; clippedwidth so that the _bitmap won't
         inc ax                             ; extend over the right clipping
         mov clippedwidth, ax               ; boundry.

         ;calculate starting video address
noclipright2:
         movsx edi, _scale_desty            ; we are going to set edi to start point
         imul edi, xactual/4
         movsx eax, _scale_destx            ; the offset edi is
         mov cx, ax                         ; calculated by:
         shr eax, 2                         ; edi = y*80+x/2
         add eax, _current_page
         add edi,eax                        ; edi is ready!

         mov dx, sc_index                   ; point the vga sequencer to the map
         mov al, map_mask                   ; mask register, so that we only need
         out dx, al                         ; to send out 1 byte per column.

         inc dx                             ; move to the sequencer's data register.
         and cx, 3                          ; calculate the starting plane. this is
         mov al, 11h                        ; just:
         shl al, cl                         ; plane =  (11h << (x and 3))
         out dx, al                         ; select the first plane.

         xor ecx,ecx
         mov cx, sourcewidth                ; use cx for source width
         mov xad, ecx
         shl sourcewidth,1

         align 4                           ; since this point gets jumped to a lot,
         ; make sure that it is dword aligned.
rowloop2:
         push esi                           ; save the starting source index
         push edi                           ; save the starting dest index
         push ax                            ; save the current plane mask
         push bp                            ; save the current base pointer

         mov cx, clippedheight              ; use al for row counter (0-239)
         mov bx, decisiony                  ; use bx for decision variable
         mov dx, sourceheight               ; use dx for source height * 2
         add dx, dx
         mov bp, _scale_destheight          ; use bp for dest height * 2
         add bp, bp
         mov ah, [esi]                      ; get the first source pixel
         or ah,ah
         jz s null_loop                     ; if zero, perform null loop

         align 4                            ; common jump point... align for speed.
columnloop2:
         mov [edi], ah                      ; draw a pixel
         dec cx                             ; decrement line counter
         jz s donewithcol2                  ; see if we're done with this column
         add edi, xactual/4                 ; go on to the next screen row
         add bx, dx                         ; increment the decision variable
         js s columnloop2                   ; draw this source pixel again

incsourcerow2:
         add esi, xad                       ; move to the next source pixel
         sub bx, bp                         ; decrement the decision variable
         jns s incsourcerow2                ; see if we need to skip another source pixel
         mov ah, [esi]                      ; get the next source pixel
         cmp ah,0
         jz s null_loop
         jmp s columnloop2                  ; start drawing this pixel

donewithcol2:
         pop bp                             ; restore bp to access variables
         pop ax                             ; restore al = plane mask
         pop edi                            ; restore di to top row of screen
         pop esi                            ; restore si to top row of source bits

         rol al, 1                          ; move to next plane
         adc edi, 0                         ; go on to next screen column
         mov dx, sc_data                    ; tell the vga what column we're in
         out dx, al                         ; by updating the map mask register

         mov bx, decisionx                  ; use bx for the x decision variable
         add bx, sourcewidth                ; increment the x decision variable
         js s nextcol2                      ; jump if we're still in the same source col.
         mov dx, _scale_destwidth           ; dx = w * 2
         add dx, dx
incsourcecol2:
         inc esi                            ; move to next source column
         sub bx, dx                         ; decrement x decision variable
         jns s incsourcecol2                ; see if we skip another source column
nextcol2:
         mov decisionx, bx                  ; free up bx for colloop
         dec clippedwidth                   ; if we're not at last column
         jnz rowloop2                       ;    then do another column
done2:
         ret                                ; we're done!

         align 4                           ; common jump point... align for speed.
null_loop:
         dec cx                             ; decrement line counter
         jz s donewithcol2                  ; see if we're done with this column
         add edi, xactual/4                 ; go on to the next screen row
         add bx, dx                         ; increment the decision variable
         js s null_loop                     ; perform more increments
         jmp s incsourcerow2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _repeat_bitmap - Draw repeated bit map.
; In:
;    REGS = none
; Stack frame:
;    DWORD: offset to _bitmap
;     WORD: left   x of window - non-cartisian...
;     WORD: top    y of window
;     WORD: right  x of window
;     WORD: bottom y of window
; MEMORY:
; _current_page - current offset of video memory for page of xmode, see xmode.asm
;
; Out:
;    null
;
; Notes:
;
; Good for _backgrounds in menus and title  screens.
; routine is NOT intended for animation because it is slow. uses scale routine
; because scale routine clips bitmaps.  Sloppy routine just draws all over the
; place and lets the scale clip borders handle the rest.
;
; remember: first two words of bitmap define width and height
;
; From C (Ug...)
; _repeat_bitmap (off bitmap, _x1%, _y1%, _x2%, _y2%)
;
; From assembley (oh, yes)
;
; push offset bitmaptorepeat
; push _x1
; push _y1
; push _x2
; push _y2
; call _repeat_bitmap
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

rb_stack struc
         rb_wide dw ?                       ; height and width of _bitmap
         rb_height dw ?
         rb_curx dw ?                       ; current _bitmap location
         rb_cury dw ?
         rb_old_y2 dw ?                     ; old cliping borders save
         rb_old_x2 dw ?
         rb_old_y1 dw ?
         rb_old_x1 dw ?
         dd ?x3                             ; edi, esi, ebp
         dd ?                               ; caller
         rb_y2 dw ?                         ; _y2
         rb_x2 dw ?                         ; _x2
         rb_y1 dw ?                         ; _y1
         rb_x1 dw ?                         ; _x1
         rb_bitmap dd ?               ; offset to _bitmap
rb_stack ends

_repeat_bitmap:
         push ebp esi edi                   ; preserve important registers
         sub esp, 16                        ; allocate workspace
         mov ebp, esp                       ; set up stack frame

         mov ax,_cliplt                     ; save old borders just in case
         mov [ebp].rb_old_x1,ax
         mov ax,_cliprt
         mov [ebp].rb_old_x2,ax
         mov ax,_cliptp
         mov [ebp].rb_old_y1,ax
         mov ax,_clipbt
         mov [ebp].rb_old_y2,ax

         mov _x1,4

         mov ax,[ebp].rb_x1                 ; set new borders for clipping
         mov _cliplt,ax
         mov ax,[ebp].rb_x2
         mov _cliprt,ax
         mov ax,[ebp].rb_y1
         mov _cliptp,ax
         mov ax,[ebp].rb_y2
         mov _clipbt,ax

         mov [ebp].rb_curx,0                ; we could start at _x1,_y1 but this
         mov [ebp].rb_cury,0                ; will make offset _backgrounds

         mov esi,[ebp].rb_bitmap
         mov _bitmap,esi
         lodsw                              ; set destination width same as original
         mov [ebp].rb_wide,ax
         lodsw
         mov [ebp].rb_height,ax
nextline:
         mov ax,[ebp].rb_wide
         mov _scale_destwidth,ax
         mov ax,[ebp].rb_height
         mov _scale_destheight,ax

         mov ax,[ebp].rb_curx
         mov _scale_destx,ax
         mov ax,[ebp].rb_cury
         mov _scale_desty,ax

         push ebp
         call _xscale2                      ; draw a transparent _bitmap
         pop ebp

         mov ax,[ebp].rb_curx
         add ax,[ebp].rb_wide
         mov [ebp].rb_curx,ax
         cmp ax,[ebp].rb_x2
         jle s nextline

         mov [ebp].rb_curx,0

         mov ax,[ebp].rb_cury
         add ax,[ebp].rb_height
         mov [ebp].rb_cury,ax
         cmp ax,[ebp].rb_y2
         jle s nextline

         mov ax,[ebp].rb_old_x1
         mov _cliplt,ax
         mov ax,[ebp].rb_old_x2
         mov _cliprt,ax
         mov ax,[ebp].rb_old_y1
         mov _cliptp,ax
         mov ax,[ebp].rb_old_y2
         mov _clipbt,ax

         add esp, 16
         pop edi esi ebp
         ret 12

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _tdraw_scale4 - Draw transparent scaled bitmap using 1/4 xmode method:
;                draws every 4th pixel alike.
; In:
;    ESI - offset of _bitmap to draw, first two words are x,y size
;     AX - x width to scale to
;     BX - y width to scale to
;     CX - x location, non-cartisian
;     DX - y location, non-cartisian
; _current_page - current offset of video memory for page of xmode, see xmode.asm
;
; Out:
;    null
;
; Notes:
;  great  for  explosions/smoke  where  the  _bitmap  does  not have to be  very
;  accuratly drawn - much faster
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

done4:   ret

_tdraw_scale4:
         mov _bitmap,esi
         mov _scale_destwidth,ax
         mov _scale_destheight,bx
         mov _scale_destx,cx
         mov _scale_desty,dx

_xscale4:
         cmp _scale_destwidth, 2            ; if destination width is less than 2
         jl s done4                         ;     then don't draw it.

         cmp _scale_destheight, 2           ; if destination height is less than 2
         jl s done4                         ;     then don't draw it.

         mov ax, _scale_desty               ; if it is completely below the
         cmp ax, _clipbt                    ; lower clip bondry,
         jg s done4                         ;     then don't draw it.

         add ax, _scale_destheight          ; if it is above clip boundries
         dec ax                             ;     then don't draw it.
         cmp ax, _cliptp
         jl s done4

         mov ax, _scale_destx               ; if it is to the right of the
         mov cx, _cliprt                    ; right clip boundry
         cmp ax, _cliprt                    ;     then don't draw it.
         jg s done4

         add ax, _scale_destwidth           ; if it is completely to the left
         dec ax                             ; of the left clip boundry,
         cmp ax, _cliplt                    ;     then don't draw it.
         jl s done4

         mov esi, _bitmap             ; make esi point to _bitmap data
         lodsw                              ; get source x width
         mov sourcewidth,ax
         lodsw                              ; get source y height
         mov sourceheight,ax

         mov ax, _scale_destwidth           ; clippedwidth is initially set to
         mov clippedwidth, ax               ; the requested dest width.

         add ax,ax                          ; initialize the x decision var
         neg ax                             ; to be -2*_scale_destwidth
         mov decisionx, ax                  ;

         mov ax, _scale_destheight          ; clippedheight is initially set to
         mov clippedheight, ax              ; the requested dest size.

         add ax,ax                          ; initialize the y decision var
         neg ax                             ; to be -2*_scale_destheight
         mov decisiony, ax                  ;

         movsx eax, _cliptp                 ; if y is below the top
         mov edx, eax                       ; clipping boundry, then we don't
         sub dx, _scale_desty               ; need to clip the top, so we can
         js s notopclip4                    ; jump over the clipping stuff.

         mov _scale_desty, ax               ; this block performs clipping on the
         sub clippedheight, dx              ; top of the _bitmap.  i have heavily
         movsx ecx, sourceheight            ; optimized this block to use only 4
         imul ecx, edx                      ; 32-bit registers, so i'm not even
         mov eax, ecx                       ; gonna try to explain what it's doing.
         cdq                                ; but i can tell you what results from
         movsx ebx, _scale_destheight       ; this:  the decisiony var is updated
         idiv ebx                           ; to start at the right clipped row.
         movsx edx, sourcewidth             ; y is moved to the top clip
         imul edx, eax                      ; boundry. clippedheight is lowered since
         add esi, edx                       ; we won't be drawing all the requested
         imul eax, ebx                      ; rows. esi is changed to point over
         sub ecx, eax                       ; the _bitmap data that is clipped off.
         sub ecx, ebx                       ;
         add ecx, ecx                       ;
         mov decisiony, cx                  ; <end of top clipping block >

notopclip4:
         mov ax, _scale_desty               ; if the _bitmap doesn't extend over the
         add ax, clippedheight              ; bottom clipping boundry, then we
         dec ax                             ; don't need to clip the bottom, so we
         cmp ax, _clipbt                    ; can jump over the bottom clip code.
         jle s nobottomclip4

         mov ax, _clipbt                    ; clip off the bottom by reducing the
         sub ax, _scale_desty               ; clippedheight so that the _bitmap won't
         inc ax                             ; extend over the lower clipping
         mov clippedheight, ax              ; boundry.

nobottomclip4:
         movsx eax, _cliplt                 ; if x is to the left of the
         mov edx, eax                       ; top clipping boundry, then we don't
         sub dx, _scale_destx               ; need to clip the left, so we can
         js s noleftclip4                   ; jump over the clipping stuff.

         mov _scale_destx, ax               ; this block performs clipping on the
         sub clippedwidth, dx               ; left of the _bitmap.  i have heavily
         movsx ecx, sourcewidth             ; optimized this block to use only 4
         imul ecx, edx                      ; 32-bit registers, so i'm not even
         mov eax, ecx                       ; gonna try to explain what it's doing.
         cdq                                ; but i can tell you what results from
         movsx ebx, _scale_destwidth        ; this:  the decisionx var is updated
         idiv ebx                           ; to start at the right clipped column.
         add esi, eax                       ; x is moved to the left clip
         imul eax, ebx                      ; boundry. clippedwidth is reduced since
         sub ecx, eax                       ; we won't be drawing all the requested
         sub ecx, ebx                       ; cols. esi is changed to point over
         add ecx, ecx                       ; the _bitmap data that is clipped off.
         mov decisionx, cx                  ; <end of left clipping block >

noleftclip4:
         mov ax, _scale_destx               ; if the _bitmap doesn't extend over the
         add ax, clippedwidth               ; right clipping boundry, then we
         dec ax                             ; don't need to clip the right, so we
         cmp ax, _cliprt                    ; can jump over the right clip code.
         jle s noclipright4

         mov ax, _cliprt                    ; clip off the right by reducing the
         sub ax, _scale_destx               ; clippedwidth so that the _bitmap won't
         inc ax                             ; extend over the right clipping
         mov clippedwidth, ax               ; boundry.

         ;calculate starting video address
noclipright4:
         movsx edi, _scale_desty            ; we are going to set edi to start point
         imul edi, xactual/4
         movsx eax, _scale_destx            ; the offset edi is
         mov cx, ax                         ; calculated by:
         shr eax, 2                         ; edi = y*80+x/2
         add eax, _current_page
         add edi,eax                        ; edi is ready!

         mov dx, sc_index                   ; point the vga sequencer to the map
         mov al, map_mask                   ; mask register, so that we only need
         out dx, al                         ; to send out 1 byte per column.

         inc dx                             ; move to the sequencer's data register.
         mov al, all_planes
         out dx, al                         ; select the first plane.

         xor ecx,ecx
         mov cx, sourcewidth                ; use cx for source width
         mov xad, ecx

         shl sourcewidth,1+2                ; 4 times as fast
         shr clippedwidth,2                 ; 1/4 of the plots

         cmp clippedwidth,0                 ; check if <4 wide
         jne s rowloop4
         inc clippedwidth

         align 4                           ; since this point gets jumped to a lot,
         ; make sure that it is dword aligned.
rowloop4:
         push esi                           ; save the starting source index
         push edi                           ; save the starting dest index
         push bp                            ; save the current base pointer

         mov cx, clippedheight              ; use al for row counter (0-239)
         mov bx, decisiony                  ; use bx for decision variable
         mov dx, sourceheight               ; use dx for source height * 2
         add dx, dx
         mov bp, _scale_destheight          ; use bp for dest height * 2
         add bp, bp
         mov ah, [esi]                      ; get the first source pixel
         or ah,ah
         jz s null_loop4                    ; if zero, perform null loop

         align 4                            ; common jump point... align for speed.
columnloop4:
         mov [edi], ah                      ; draw a pixel
         dec cx                             ; decrement line counter
         jz s donewithcol4                  ; see if we're done with this column
         add edi, xactual/4                 ; go on to the next screen row
         add bx, dx                         ; increment the decision variable
         js s columnloop4                   ; draw this source pixel again

incsourcerow4:
         add esi, xad                       ; move to the next source pixel
         sub bx, bp                         ; decrement the decision variable
         jns s incsourcerow4                ; see if we need to skip another source pixel
         mov ah, [esi]                      ; get the next source pixel
         or ah,ah
         jz s null_loop4
         jmp s columnloop4                  ; start drawing this pixel

donewithcol4:
         pop bp                             ; restore bp to access variables
         pop edi                            ; restore di to top row of screen
         pop esi                            ; restore si to top row of source bits

         add edi, 1                         ; go on to next screen column

         mov bx, decisionx                  ; use bx for the x decision variable
         add bx, sourcewidth                ; increment the x decision variable
         mov dx, _scale_destwidth           ; dx = w * 2
         add dx, dx
incsourcecol4:
         inc esi                            ; move to next source column
         sub bx, dx                         ; decrement x decision variable
         jns s incsourcecol4                ; see if we skip another source column
nextcol4:
         mov decisionx, bx                  ; free up bx for colloop
         dec clippedwidth                   ; if we're not at last column
         jnz rowloop4                       ;    then do another column

         ret                                ; we're done!

         align 4                           ; common jump point... align for speed.
null_loop4:
         dec cx                             ; decrement line counter
         jz s donewithcol4                  ; see if we're done with this column
         add edi, xactual/4                 ; go on to the next screen row
         add bx, dx                         ; increment the decision variable
         js s null_loop4                    ; perform more increments
         jmp s incsourcerow4

