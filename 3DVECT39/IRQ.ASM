;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : Irq.asm
; Included from: Main Assembley Module
; Description  : Irq handler for timing/tracking vertical retrace
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

         include pmode.ext
         include macros.inc

         public _irq_setpmirq
         public _irq_resetpmirq
         public _irq_resetrastercount
         public _irq_timeraster
         public _irq_set_timer
         public _irq_reset_timer
         public _irq_findcontrol

         public _irq_tracespast
         public _irq_framenumber

         public _irqcontrol

         input_1 equ 03dah                  ; input status #1 register

         pmodeirq equ 0                     ; you could also use irq 8

number_of_irq_subroutines equ 8

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

_irq_tracespast  dd 0                       ; contains frame speed (irq driven)
_irq_framenumber dd 0                       ; number of frames total,eg 23400 = 13 mins
rmirqbuf   db 21 dup(?)                     ; buffer for rm IRQ callback code
ormirqvect dd 0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Protected mode IRQ handler
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

pmirq0:                                     ; protected mode IRQ0 handler
         push eax
         mov al,20h
         out 20h,al
         sti
         cld
         push ebx ecx edx esi edi ebp ds
         mov ds, [cs:_seldata]

; put your protected mode irq code here!!!!!
;-------------------------------------------



;-------------------------------------------

; now my code, this is where I inc that variable
; protected mode version is easy!

         inc _irq_tracespast
         inc _irq_framenumber

         i = 0
         rept number_of_irq_subroutines
         call [d _irqcontrol+i*4]           ; call selected IRQ subroutines
         i=i+1
         endm

         pop ds ebp edi esi edx ecx ebx eax
         iretd

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _irq_setpmirq: Get protected mode IRQ going
; In=Out=Null
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_setpmirq:
         pushad
         mov ax,900h
         int 31h
         push ax

         mov bl,pmodeirq
         mov edx,offset pmirq0
         call _setirqvect
         xor al,al
         call _setirqmask
         mov edi,offset rmirqbuf
         call _rmpmirqset
         mov ormirqvect,eax

         call _irq_timeraster
         call _irq_set_timer

         pop ax
         int 31h
         popad
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _irq_resetpmirq: Unhook protected mode IRQ and reset original timer
; In=Out=Null
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_resetpmirq:
         mov ax, 900h
         int 31h
         push ax

         mov bl,pmodeirq
         mov eax,ormirqvect
         call _rmpmirqfree

         mov al,1
         call _setirqmask

         pop ax
         int 31h

         jmp _irq_reset_timer

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Set Irq speed
; In:
;  AX = 1193180/# interrupts per second
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_set_timer:
         push ax
         mov al,36h
         out 43h,al
         pop ax
         out 40h,al
         mov al,ah
         out 40h,al

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Reset Irq speed to default speed
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_reset_timer:                           ; reset timer for exit
         mov al,36h
         out 43h,al

         mov ax,0
         out 40h,al
         out 40h,al
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _irq_resetrastercount: reset counters (done before anmation loop)
; In=Out=Null
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_resetrastercount:                      ; reset count before any animation loop
         mov _irq_tracespast,1
         mov _irq_framenumber,0
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _irq_timeraster: Guess what this does?
; In=Null
; Out:
;   AX=time for raster to occure
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_timeraster:
         pushad

         mov ax, 900h
         int 31h
         push ax

         mov dx, input_1                    ; input# 1 reg
loop1:
         in al,dx                           ; wait for vsync
         test al,8
         jnz loop1
loop2:
         in al,dx
         test al,8
         jz loop2

         mov al,36h                         ; reset timer
         out 43h,al
         mov al,0
         out 40h,al
         mov al,0
         out 40h,al
loop3:
         in al,dx                           ; wait for vsync
         test al,8
         jnz loop3
loop4:
         in al,dx
         test al,8
         jz loop4

         xor al,al                          ; this calculation code courtesy future_crew
         out 43h,al                         ; from mental.exe
         in al,40h
         mov ah,al
         in al,40h
         xchg al,ah
         neg ax
         shr ax,1
         movzx eax,ax
         mov [esp+30],ax

         pop ax
         int 31h

         popad
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Find next available control vector
; Out:
;  CF - 1 no control availeble
;    ECX = ?
;  CF - 0 control available
;    ECX = next usable jump number. eg  _irqcontrol[ecx*4] (0,1,2,3...)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irq_findcontrol:
         push eax edi
         mov ecx,number_of_irq_subroutines
         mov edi,offset _irqcontrol
         mov eax,offset _ret
         repnz scasd
         neg ecx
         sub ecx,-number_of_irq_subroutines+1
         pop edi eax
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; These are the user difinable IRQ controlled jump vectors:
;
; You can have a certine function performed every  vertical retrace just
; by setting these to point to the code you wish to  be   called.   When
; you want to disable the subroutine, just reset these vectors to offset
; _ret.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_irqcontrol:
         rept number_of_irq_subroutines
         dd offset _ret
         endm

code32   ends
         end
