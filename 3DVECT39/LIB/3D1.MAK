
3d1.obj          : 3d1.asm poly.inc macros.inc equ.inc vars1.inc\
                   math.inc xscale.inc tables.inc
  tasm $(TASM_OPTIONS) /kh10000 3d1

irq.obj      : irq.asm
  tasm $(TASM_OPTIONS) irq

pmode.obj    : pmode.asm
  tasm $(TASM_OPTIONS) /m2 pmode

