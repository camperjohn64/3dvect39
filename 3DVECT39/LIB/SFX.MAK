lib\sfx.lib   : gus.obj fx.obj gsp669.obj

gus.obj   : gus.asm
            tasm gus
            tlib lib\sfx -+gus

gsp669.obj: gsp669.asm
            tasm gsp669
            tlib lib\sfx -+gsp669

fx.obj    : fx.asm
            tasm fx
            tlib lib\sfx -+fx
