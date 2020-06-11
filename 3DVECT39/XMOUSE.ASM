;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : More.inc
; Included from: Main assembley module
; Description  : X mode Mouse routines
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
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

         include pmode.ext                  ; protected mode externals
         include xmode.ext                  ; include externals for xmode routines
         include clear.ext
         include macros.inc

         public _show_mouse
         public _get_mouse_position
         public _plot_mouse
         public _instant_mouse
         public _compiled_mouse
         public _remove_mouse
         public _mousex
         public _mousey
         public _mousebuttons
         public _mousebitmap
         public _mousesavemap

         public _ismouse
         public _mousex1
         public _mousex2
         public _mousey1
         public _mousey2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; x-mode mouse routines in protected mode for 3d vectors source
;
; _show_mouse (int x, int y, int xclipl, int xclipr, int yclipt, int yclipb)
; _get_mouse_position
; _plot_mouse
; _remove_mouse
; _instant_mouse
;
; after ploting mouse, _sync_display is not called
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_ismouse      db -1  ; is mouse present?
_mousex1      dw ?
_mousex2      dw ?   ; clipping parameters
_mousey1      dw ?
_mousey2      dw ?
_mousex       dw 0   ; mouse location, buttons
_mousey       dw 0
_mousebuttons dw 0
_mousebitmap  dd ?
_mousesavemap dd ?

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _show_mouse (int x, int y, int xclipl, int xclipr, int yclipt, int yclipb)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

sm_stack struc
         dd ?                               ; ebp
         dd ?                               ; caller
         my2       dw ?
         my1       dw ?
         mx2       dw ?
         mx1       dw ?                     ; clipping parameters of mouse
         savemap   dd ?                     ; enough memory for saved screen data
         mousemap  dd ?                     ; bitmap to use for mouse
         setm_ypos dw ?                     ; y pos of mouse
         setm_xpos dw ?                     ; x pos of mouse
sm_stack ends

_show_mouse:
         push ebp
         call _remove_mouse
         mov v86r_ax,0                      ; enable mouse
         mov al,33h
         int 33h
         mov ah,v86r_ah                     ; check if hardware/driver installed
         xor ah,255
         mov _ismouse, ah
         jne sm_nomouse                     ; no mouse, exit
         mov ebp, esp                       ; set up stack frame
         mov edx,[ebp].savemap
         mov _mousesavemap,edx
         mov ecx,[ebp].mousemap
         mov _mousebitmap,ecx
         mov ebx,[ecx]                      ; transfer x,y size of mouse bitmap
         mov [edx],ebx

         mov cx, [ebp].setm_xpos
         mov dx, [ebp].setm_ypos

         mov v86r_ax,4                      ; position mouse
         mov v86r_cx,cx
         mov v86r_dx,dx
         int 33h

         mov ebp, esp                       ; set up stack frame
         mov cx, [ebp].mx1
         mov dx, [ebp].mx2
         shl cx,1
         mov ebx,_mousebitmap
         sub dx,[ebx]
         shl dx,1

         mov v86r_ax,7                      ; set screen size
         mov v86r_cx,cx
         mov v86r_dx,dx
         int 33h                            ; *2 gives greater resolution!!!!!

         mov ebp, esp                       ; set up stack frame
         mov cx, [ebp].my1
         mov dx, [ebp].my2
         shl cx,1
         mov ebx,_mousebitmap
         sub dx,[ebx+2]
         shl dx,1

         mov v86r_ax,8
         mov v86r_cx,cx
         mov v86r_dx,dx
         int 33h

         mov v86r_ax,15                     ; set mouse mickeys (8 = default)
         mov v86r_cx,8
         mov v86r_dx,8
         int 33h

sm_nomouse:
         mov firstcall,0                    ; first call to mouse routines, reset
         pop ebp
         ret 20

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Guess what this does?
; In = none
; Out = cx = mouse x
;       dx = mouse y
;       bx = mouse buttons
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_get_mouse_position:
         cmp _ismouse,0
         jne _ret
         mov v86r_ax,3                      ; call bios routines
         mov al,33h
         int 33h
         mov bx,v86r_bx                     ; button status, mid right left=%111
         mov cx,v86r_cx                     ; coloum
         mov dx,v86r_dx                     ; row
         mov _mousebuttons,bx               ; save button status
         shr cx,1                           ; compensate for resolution!!!
         shr dx,1
         mov _mousex,cx
         mov _mousey,dx

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Plot mouse at new location. must be called every frame
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

firstcall     db 0

_plot_mouse:
         cmp _ismouse,0                     ; plot mouse needs modification
         jne _ret                           ; if used with page flipping, (save
                                            ; more than one page)
         call _remove_mouse
         mov firstcall,1

         call _get_mouse_position           ; get new mouse location

         mov esi,_mousebitmap
         mov bx, [esi+2]                    ; counters
         mov ax, [esi]
         mov esi,_mousesavemap
         mov [esi],ax
         mov [esi+2],bx
         add esi, 4                         ; indexer to bitmap saved data

pl_morew:
         push ax esi cx dx bx                ; save data under new cursor
         push cx dx
         call _read_point
         pop bx dx cx esi
         mov b [esi],al
         pop ax
         inc esi
         inc cx
         dec ax
         cmp ax,0
         jne pl_morew

         inc dx
         mov cx,_mousex
         mov edi,_mousebitmap
         mov ax,[edi]
         dec bx
         cmp bx,0
         jne pl_morew

         push edi
         pushw _mousex
         pushw _mousey
         call _tdraw_bitmap                 ; draw new mouse

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Plot single mouse, doesnt remember background
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_instant_mouse:
         cmp _ismouse,0
         jne _ret

         call _get_mouse_position           ; get new mouse location

         mov eax,_mousebitmap
         push eax
         pushw _mousex
         pushw _mousey
         call _tdraw_bitmap                 ; draw new mouse

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Plot compiled mouse, doesnt remember background
; In: EAX => compiled bitmap routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_compiled_mouse:
         cmp _ismouse,0
         jne _ret

         push eax

         call _get_mouse_position           ; get new mouse location

         mov bx,cx
         mov cx,dx

         call _compile_xy

         mov edi,_current_page
         add edi,esi

         pop ebp
         call ebp                           ; draw new mouse

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Remove mouse from screen - plot old stuff back underniegth
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_remove_mouse:
         cmp firstcall,0                    ; check if mouse on screen
         je _ret

         mov eax,_mousesavemap
         push eax
         pushw _mousex
         pushw _mousey
         call _draw_bitmap                  ; restore old data under cursor
         mov firstcall,0                    ; mouse is gone, say so

         ret

code32   ends
         end
