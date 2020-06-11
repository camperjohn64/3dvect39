if exist pmode.obj goto noasmit
tasm /ml /m2 pmode
:noasmit

make -flib\3d2
make -flib\main

make -flib\3dvect
make -flib\user
make -flib\sfx

tlink /3 /s /x pmode 3d2 main, main2 ,, lib\3dvect lib\sfx lib\user

