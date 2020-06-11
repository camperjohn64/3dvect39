\lib\3dvect.lib :font.obj   stars.obj   xmode.obj   joystick.obj\
                 xmouse.obj land.obj    fade.obj\
                 function.obj           explode.obj clear.obj\
                 game.obj               irq.obj

TASM_OPTIONS = /ml

font.obj     : font.asm font0.inc font1.inc font2.inc
  tasm $(TASM_OPTIONS) font
  tlib lib\3dvect -+font.obj

stars.obj    : stars.asm equ.inc
  tasm $(TASM_OPTIONS) stars
  tlib lib\3dvect -+stars.obj

xmode.obj    : xmode.asm
  tasm $(TASM_OPTIONS) xmode
  tlib lib\3dvect -+xmode.obj

joystick.obj : joystick.asm
  tasm $(TASM_OPTIONS) joystick
  tlib lib\3dvect -+joystick.obj

xmouse.obj   : xmouse.asm
  tasm $(TASM_OPTIONS) xmouse
  tlib lib\3dvect -+xmouse.obj

land.obj     : land.asm equ.inc
  tasm $(TASM_OPTIONS) land
  tlib lib\3dvect -+land.obj

fade.obj     : fade.asm equ.inc
  tasm $(TASM_OPTIONS) fade
  tlib lib\3dvect -+fade.obj

function.obj : function.asm equ.inc
  tasm $(TASM_OPTIONS) function
  tlib lib\3dvect -+function.obj

explode.obj  : explode.asm
  tasm $(TASM_OPTIONS) explode
  tlib lib\3dvect -+explode.obj

clear.obj    : clear.asm equ.inc
  tasm $(TASM_OPTIONS) clear
  tlib lib\3dvect -+clear.obj

irq.obj      : irq.asm
  tasm $(TASM_OPTIONS) irq
  tlib lib\3dvect -+irq.obj

game.obj     : game.asm equ.inc
  tasm $(TASM_OPTIONS) game
  tlib lib\3dvect -+game.obj

