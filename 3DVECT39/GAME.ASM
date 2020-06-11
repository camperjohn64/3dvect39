;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : Game.asm
; Included from: Main Assembley module
; Description  : Generic gaming routines
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

         include pmode.ext                  ; protected mode externals by TRAN
         include 3d.ext
         include xmode.ext
         include function.ext

         include font.ext

         include macros.inc
         include equ.inc

         public _determine_volume
         public _determine_panning

         public _rnd

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Determine GUS & SB volume for object
; In:
;    EBX - relative x point of object to determine left/right sound panning of
;    ECX - relative y point
;    EBP - relative z point
; Out:
;    AL = volume (distance 0-15)
; Notes:
;  A call to _setsincose MUST have taken place for this routine to work
;  correctly!  This point you wish to determine panning  for   must  be
;  relative to the camera.  Eg: subtract camera location before call.
;
;  If your runing a SB:
;   mov esi,object #
;   call _get_location
;   call _subtract_camera
;   call _determine_volume
;   mov bl,al               ; <=
;   call _play_sample
;
;  If your runing a GUS:
;   mov esi,object #
;   call _get_location
;   call _subtract_camera
;   call _determine_volume
;   call _determine_panning ; <= this also works with SB, but calculation is useless
;   call _play_sample
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_determine_volume:
         mov eax,ebx                        ; find largest distance
         or eax,eax
         jge s dpno_neg1
         neg eax
dpno_neg1:
         mov esi,ecx
         or esi,esi
         jge s dpno_neg2
         neg esi
dpno_neg2:
         mov edi,ebp
         or edi,edi
         jge s dpno_neg3
         neg edi
dpno_neg3:
         add eax,edi
         add eax,esi

         shr eax,div_256+13
         cmp eax,15
         jge dp_novolumeanyway              ; no volume, no need for pan calculation

         and al,0fh
         xor al,0fh

         ret

dp_novolumeanyway:
         xor eax,eax
         xor ebx,ebx
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Determine GUS panning for object
; In:
;    EBX - relative x point of object to determine left/right sound panning of
;    ECX - relative y point
;    EBP - relative z point
;    AX = volume (distance 0-15, from routine above)
; Out:
;    BH = panning position (0-15)
;    BL = volume after distance adjust (0-15)
; Notes:
;  A call to _setsincose MUST have taken place for this routine to work
;  correctly!  This point you wish to determine panning  for   must  be
;  relative to the camera.  Eg: subtract camera location before call.
;
;  Total time: 8 multiplies, 1 divide.
;
;  Done bother to call this routine if you have a SB, as SB doesnt have
;  left/right anyway.
;
;  The panning routine aborts if the volume is zero!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_determine_panning:
         or ax,ax
         jz _ret

         push ax

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

         call _zsolve
         call _xsolve

         pop bx

         dec esi                            ; prevent z = 0
         add esi,1
         adc esi,0
         cmp esi,0
         jge s dp_noneg
         neg esi

         mov eax,esi
         shr eax,div_256+13
         cmp al,3
         jbe dp_nox
         mov al,03h
dp_nox:
         inc al
         sub bl,al                          ; if sound is behind, decrease volume
         jnc dp_noneg
         xor ebx,ebx
         ret                                ; no volume anyway
dp_noneg:
         call _make3dx

         mov eax,edi
         neg eax
         add eax,32
         shr eax,4+div_256/4

         add ax,8                           ; panning center (balance control)

         mov bh,0
         cmp ax,0
         jl _ret
         mov bh,15
         cmp ax,15
         jg _ret
         mov bh,al
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Randomize number
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

randomnumber    dd 5fe6c809h

_rnd:
         xor eax,randomnumber
         xor eax,edx
         xchg al,ah
         add eax,0cd9c9a8fh
         xor eax,esi
         add eax,edi
         xor eax,0526dafb2h
         add eax,ecx
         xor eax,ebx
         add eax,ebp
         mov randomnumber,eax
         in al,64
         shl eax,8
         in al,65
         shl eax,8
         in al,64
         shl eax,8
         in al,64
         add randomnumber,eax
         mov eax,randomnumber
         ret

         ends
         end
