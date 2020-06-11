;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : joystick.asm
; Included from: Main Assembley Module
; Description  : Joystick routines
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

         include macros.inc
         include equ.inc

         public _joy_tax
         public _joy_tay
         public _joy_tbx
         public _joy_tby
         public _joy_lastcallstate
         public _joy_thiscallstate

         public _joycenax
         public _joycenay
         public _joycenbx
         public _joycenby
         public _joy_ax
         public _joy_ay
         public _joy_bx
         public _joy_by

         public _joy_deadzone

         public _joy_rawjoystick
         public _joy_justgetbutton
         public _joy_calibratejoystick
         public _joy_waitalloff
         public _joy_cartisianjoystick

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;port 201h :
;
;  bit    JOYSTICK       PADDLE
;  ---    --------       ------
;  7      B  button 2    D button
;  6      B  button 1    C button
;  5      A  button 2    B button
;  4      A  button 1    A button
;  3      B  y-axis      D Coordinate
;  2      B  x-axis      C Coordinate
;  1      A  y-axis      B Coordinate
;  0      A  x-axis      A Coordinate
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         time_out equ 3000                  ; time out before abort
         joyport equ 0201h                  ; joystick port address

_joy_tax dd 0                               ; joystick raw data
_joy_tay dd 0
_joy_tbx dd 0
_joy_tby dd 0
_joy_lastcallstate db 0                     ; last button state / button down      = 0f0h
_joy_thiscallstate db 0                     ; this button state / button up states = 00fh

_joycenax dd 0                              ; center of joystick upon entry
_joycenay dd 0
_joycenbx dd 0
_joycenby dd 0
_joy_ax  dd 0                               ; cartisian joystick co-ordinates
_joy_ay  dd 0
_joy_bx  dd 0
_joy_by  dd 0

_joy_deadzone dd 1000                       ; dead zone where centered joystick has no effect

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Rawjoystick: Get raw joystick data
; In: null
; Out:
;   EAX - x of joystick a
;   EBX - y of joystick a
;   ECX - x of joystick b
;   EDX - y of joystick b
; Notes:
; Machine dependant!
; Routine sets timers running and flags results as they come up.
; This way, all timers are checked at once.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_joy_rawjoystick:
         xor bl,bl                          ; reset attempt flag, when all ports come in, exit

         cmp _joy_tax,-1                    ; test if port operational
         je raw_misxa
         inc bl                             ; count number of ports waiting to come in
         mov _joy_tax,0                     ; init values, -1 = port inactive
raw_misxa:
         cmp _joy_tay,-1
         je raw_misya
         inc bl
         mov _joy_tay,0
raw_misya:
         cmp _joy_tbx,-1
         je raw_misxb
         inc bl
         mov _joy_tbx,0
raw_misxb:
         cmp _joy_tby,-1
         je raw_misyb
         inc bl
         mov _joy_tby,0
raw_misyb:

         cli                                ; irq's off
         mov dx,joyport                     ; joyport address
         xor al,al
         out dx,al

         mov ecx,0                          ; reset timer
         align 4

joyloop:
         in al,dx                           ; get bits from port

         test al,1                          ; timer bit set?
         jnz s notax
         test _joy_tax,-1                   ; value already got?
         jnz s notax
         mov _joy_tax,ecx                   ; set axis value
         dec bl                             ; port is in, flag one less waiting
         jz found_joyval                    ; all ports are in, exit
notax:
         test al,2
         jnz s notay
         test _joy_tay,-1
         jnz s notay
         mov _joy_tay,ecx
         dec bl
         jz found_joyval                    ; all ports are in, exit
notay:
         test al,4
         jnz s notbx
         test _joy_tbx,-1
         jnz s notbx
         mov _joy_tbx,ecx
         dec bl
         jz found_joyval                    ; all ports are in, exit
notbx:
         test al,8
         jnz s notby
         test _joy_tby,-1
         jnz s notby
         mov _joy_tby,ecx
         dec bl
         jz found_joyval                    ; all ports are in, exit
notby:
         inc ecx
         cmp ecx,time_out                   ; abort if ports fail to arrive in time
         jng joyloop

found_joyval:
         sti
         mov eax,_joy_tax                   ; -1 = port inactive
         mov ebx,_joy_tay
         mov ecx,_joy_tbx
         mov edx,_joy_tby

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Justgetbutton:  Get button status
; In:none
; Out:
;   AL - Current button status
;   DL - Button changed status
;
;  7  B  button 2 - 0 = button up,1 = button down
;  6  B  button 1 - 0 = button up,1 = button down
;  5  A  button 2 - 0 = button up,1 = button down
;  4  A  button 1 - 0 = button up,1 = button down
;  3  B  button 2 - 1 = button up,0 = button down
;  2  B  button 1 - 1 = button up,0 = button down
;  1  A  button 2 - 1 = button up,0 = button down
;  0  A  button 1 - 1 = button up,0 = button down
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_joy_justgetbutton: ; get present button status
         mov al,_joy_thiscallstate          ; save button state for next call
         mov _joy_lastcallstate,al
         mov dx, joyport                    ; port address of game adapter
         in al, dx                          ; al = game port state
         and al, 0f0h                       ; lose lower nibble
         mov dh, al                         ; 0f = button down mask
         shr al, 4                          ; shift mask to lower nibble
         or al, dh                          ; al = combined button event mask
         xor al, 0f0h                       ; f0 = button up mask
         xor ah, ah                         ; zero out ah for return
         mov _joy_thiscallstate, al         ; al = current button status
         mov dx,ax
         xor dl,_joy_lastcallstate          ; dl = button changed status
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Calibrate_Joystick: Initial joystick grab
; In=Out=null
; Notes:
;  Joystick values are grabbed on entry and calibrated as if  the joystick was
;  at the center when called.  The joystick re-calculation will not be correct
;  if the user enters the program with the joystick at non-center, or  if  the
;  the user turns the turbo off/on while the program is running.
;
; The joystick buttons must be in an off state before the routine will continue
; It does not HAVE to be off, I just do this so that the user will know if  the
; joystick is stuck up against the monitor or crushed under some books.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_joy_calibratejoystick:
         call _joy_waitalloff               ; wait until button released before entering

         mov _joy_tax,0                     ; clear joystick flags
         mov _joy_tay,0
         mov _joy_tbx,0
         mov _joy_tby,0
         call _joy_rawjoystick              ; get first values
         sub _joy_tax,1                     ; 0 becomes -1
         sub _joy_tay,1                     ; >0 becomes >=0
         sub _joy_tbx,1
         sub _joy_tby,1
         call _joy_rawjoystick              ; get new values, -1's are inactive ports

         cmp _joy_tax,-1                    ; test if joystick A valid
         je cal_noa

         mov eax,_joy_tax                   ; hopefully we have joystick A center
         mov ebx,_joy_tay
         mov _joycenax,eax                  ; save center of joystick
         mov _joycenay,ebx
cal_noa:
         cmp _joy_tbx,-1                    ; test if joystick B valid
         je cal_nob

         mov eax,_joy_tbx                   ; hopefully we have joystick B center
         mov ebx,_joy_tby
         mov _joycenbx,eax                  ; save center of joystick
         mov _joycenby,ebx
cal_nob:
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _joy_cartisianjoystick: Get joystick values in cartisian format.
; In:
;   _joycenax - joystick centers, raw data
;   _joycenay -
;   _joycenbx -
;   _joycenby -
; Out:
; _joy_ax = EAX = x of joystick a (-16384 to 16384)
; _joy_ay = EBX = y of joystick a
; _joy_bx = ECX = x of joystick b
; _joy_by = EDX = y of joystick b
;
; Notes:
; Assuming calibration routine was entered with  the  joystick  in  the  center
; position, this routine should be machine independant.
;
; The dead_zone is the zone on any axis which the joystick center is registered
; as  being zero.  This  prevents  the  joystick  from  jittering  when  it  is
; positioned in the center without anyone touching it.  The  dead_zone  can  be
; set to a high value when selecting menu items and this will produce a  yes/no
; response from the joystick.  The zone can then be set back down low  for  the
; game/demo.
;
; The resulting position should be from -16384 to +16384.   But  it  could  be
; outside this limit if the joystick is not centered correctly  (as  the  real
; world rarely is centered)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_joy_cartisianjoystick:
         call _joy_rawjoystick              ; get joystick values

         mov esi,_joy_deadzone
         push edx

         cmp eax,-1                         ; test if joystick A valid
         je car_noa

         sub eax,_joycenax                  ; convert to cartisian
         sub ebx,_joycenay

         shl eax,14                         ; get ready for divide
         shl ebx,14

         cdq
         mov ebp,_joycenax
         idiv ebp

         cmp eax,esi
         jl car_ca
         sub eax,esi
         jmp car_cc
car_ca:
         neg eax
         cmp eax,esi
         jl car_cb
         neg eax
         add eax,esi
         jmp car_cc
car_cb:
         xor eax,eax
car_cc:
         mov _joy_ax,eax

         mov eax,ebx
         cdq
         mov ebp,_joycenay
         idiv ebp

         cmp eax,esi
         jl car_cz
         sub eax,esi
         jmp car_ce
car_cz:
         neg eax
         cmp eax,esi
         jl car_cd
         neg eax
         add eax,esi
         jmp car_ce
car_cd:
         xor eax,eax                        ; in dead_zone, eax=0
car_ce:
         mov _joy_ay,eax
car_noa:
         pop eax                            ; y co-ordinate of joy B

         cmp ecx,-1                         ; test if joystick B valid
         je car_nob

         sub eax,_joycenbx                  ; convert to cartisian
         sub ecx,_joycenby

         shl eax,14                         ; get ready for divide
         shl ecx,14

         cdq
         mov ebp,_joycenbx
         idiv ebp

         cmp eax,esi
         jl car_cf
         sub eax,esi
         jmp car_ch
car_cf:
         neg eax
         cmp eax,esi
         jl car_cg
         neg eax
         add eax,esi
         jmp car_ch
car_cg:
         xor eax,eax
car_ch:
         mov _joy_by,eax

         mov eax,ecx
         cdq
         mov ebp,_joycenby
         idiv ebp

         cmp eax,esi
         jl car_ci
         sub eax,esi
         jmp car_ck
car_ci:
         neg eax
         cmp eax,esi
         jl car_cj
         neg eax
         add eax,esi
         jmp car_ck
car_cj:
         xor eax,eax                        ; in dead_zone, eax=0
car_ck:
         mov _joy_bx,eax
car_nob:
         mov eax,_joy_ax
         mov ebx,_joy_ay
         mov ecx,_joy_bx
         mov edx,_joy_by

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Wait_all_off: wait for all buttons to return to 0 - abort if ESC pressed
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_joy_waitalloff:
         mov ecx,15                         ; wait must be performed 15 times in case buttons are rusty (like mine...)

wait_all_off2:
         push ecx

wait_all_off3:
         call _joy_justgetbutton
         mov cl,al
         in al,60h                          ; esc pressed on keyboard aborts wait.
         cmp al, 1
         je wait_all_off4
         test cl,3*16                       ; test any button
         jnz wait_all_off3                  ; button up, try again

wait_all_off4:
         pop ecx                            ; button down, make sure it is really down
         loop wait_all_off2

         ret

code32   ends
         end
