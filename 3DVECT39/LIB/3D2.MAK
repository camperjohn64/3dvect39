
3d2.obj          : 3d2.asm poly.inc macros.inc equ.inc vars2.inc\
                   math.inc xscale.inc tables.inc
  tasm $(TASM_OPTIONS) /kh10000 3d2

irq.obj      : irq.asm
  tasm $(TASM_OPTIONS) irq

pmode.obj    : pmode.asm
  tasm $(TASM_OPTIONS) /m2 pmode

