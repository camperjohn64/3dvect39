;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
;        Filename     : land.asm
;        Included from: Main Assembley Module
;        Description  : Draw _background Horizon
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
; Simple non-rotatable background landscape.  Cannot be used with z rotations
; that is - it only draws a flat backgound landscape.  Use this  in  place of
; _clearfill routine.  This routine wipes all video memory within the current
; clipping parameters and puts the "landscape" in the background.
;
; NOTE: This routine sets the flag useclear=no and therefore  shuts  off  the
;       _clearfill routine in poly.inc.  This is done since  screen  clearing
;       is done at the same time as drawing the background landscape.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

         include pmode.ext                  ; protected mode externals by TRAN
         include 3d.ext
         include xmode.ext
         include macros.inc
         include equ.inc

         public _land_draw
         public _land_ground
         public _land_sky

; horizon:
;    y = -yratio*sin(_eyeax)

_land_sky    db 0
_land_ground db 22

_land_draw:
         out_8 sc_data, all_planes          ; write to all planes

         mov ebp,100000

         mov eax,_esinx
         neg eax
         imul ebp
         shrd eax,edx,14
         mov ecx,eax

         mov eax,_ecosx
         imul ebp
         shrd eax,edx,14
         mov ebp,eax

         cmp ebp,2500
         jg do_a
         mov ebp,2500
do_a:
         call _make3dy

         mov si,cx
         add si,_ymins

         movzx edi,_cliptp
         mov edi,_fastimultable[edi*4]
         movzx ecx,_cliplt
         shr ecx,2
         add edi,ecx
         add edi,_current_page

         mov dx,_ymaxs                      ; dx = counter
         sub dx,_ymins
         movzx edx,dx

         movzx ecx,_xmaxs
         sub cx,_xmins
         mov ebx,xactual
         sub bx,cx
         shr ebx,2
         shr cx,3                           ; /4/2
         mov ebp,ecx
         mov ah,_land_sky                   ; background sky colour
         mov al,_land_sky

plot_loop1:
         cmp si,0                           ; check for horizon
         jge here_s_johnny
         mov ecx,ebp
pl_1x:
         rep stosw
         add edi,ebx
         inc esi
         dec edx
         jnz plot_loop1

         ret

here_s_johnny:
         mov ah,_land_ground
         mov al,_land_ground

plot_loop2:
         mov ecx,ebp
pl_2x:
         rep stosw
         add edi,ebx
         dec edx
         jnz plot_loop2

         ret

code32   ends
         end
