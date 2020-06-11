;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : explode.asm
; Included from: Main Assembley Module
; Description  : Explosion handler
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
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

         include pmode.ext                  ; protected mode externals by TRAN
         include 3d.ext
         include function.ext

         include macros.inc
         include equ.inc

         public _handle_explosions
         public _start_explosion

ex_off   dd maxobjects dup (0)
ex_sx    dw maxobjects dup (0)
ex_sy    dw maxobjects dup (0)

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Start explosion
; In:
;  EDX => dw explosion table: dw bitmap#, xscale,yscale  (-1 terminated)
;   EBX - x location
;   ECX - y location
;   EBP - z location
;   SI => additional x scaling for explosion.
;   DI => additional y scaling for explosion.
; Out:
;  CS - no object free for explosion
;  CC - object exploded!
;   ESI => object # of explosion (in case you want to add velocity, whatever)
;
;Notes: an example of an explosion table:
;
; _explode_main1:
;         dw 15,140,140 ; bitmap number, x scale, y scale
;         dw 15,150,150
;         dw 15,160,160
;         dw 15,170,170
;         dw 13,180,180
;         dw 13,190,190
;         .
;         .
;         .
;         dw 7, 93, 93
;         dw 7, 90, 90
;         dw 7, 85, 85
;         dw 7, 80, 80
;         dw -1         ; end flag
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_start_explosion:
         push ebx ecx ebp esi edi edx
         call _search_next_available_object
         pop edx edi eax ebp ecx ebx
         jc _ret

         mov ex_sx[esi*2],ax
         mov ex_sy[esi*2],di
         mov ex_off[esi*4],edx

         call _init_object
         call _set_to_hi_bitmap
         call _put_object

ex_update_esi:
         mov edx,ex_off[esi*4]
         mov ax,[edx]
         cmp ax,-1
         jz short ex_remove
         mov _whatshape[esi*2],ax
         mov ax,[edx+2]
         add ax,ex_sx[esi*2]
         mov _bitobjx[esi*2],ax
         mov ax,[edx+4]
         add ax,ex_sy[esi*2]
         mov _bitobjy[esi*2],ax
         add ex_off[esi*4],6
         mov _onoff[esi],mainobject_on
         clc
         ret

ex_remove:
         mov ex_off[esi*4],0
         mov _onoff[esi],0
         clc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Handle explosions:
;
; Call this routine once per frame update to animate the explosions
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_handle_explosions:
         xor ebx,ebx
         mov ecx,maxobjects
         mov esi,ecx
ex_loop:
         dec esi
         cmp ex_off[esi*4],ebx
         loope short ex_loop
         jcxz _ret
         call ex_update_esi
         jmp short ex_loop

code32   ends
         end
