
3d3.obj          : 3d3.asm poly.inc macros.inc equ.inc vars3.inc\
                   math.inc xscale.inc tables.inc
  tasm $(TASM_OPTIONS) 3d3

irq.obj      : irq.asm
  tasm $(TASM_OPTIONS) irq

pmode.obj    : pmode.asm
  tasm $(TASM_OPTIONS) /m2 pmode


