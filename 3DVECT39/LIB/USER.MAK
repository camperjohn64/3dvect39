lib\user.lib  : file.obj kb.obj loadgif.obj

kb.obj    : kb.asm
            tasm kb
            tlib lib\user -+kb.obj

file.obj  : file.asm
            tasm file
            tlib lib\user -+file.obj

loadgif.obj: loadgif.asm
             tasm loadgif
             tlib lib\user -+loadgif.obj
