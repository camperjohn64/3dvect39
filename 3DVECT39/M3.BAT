if exist pmode.obj goto noasmit
tasm /ml /m2 pmode
:noasmit

make -flib\3d3
make -flib\main

make -flib\3dvect
make -flib\user
make -flib\sfx

tlink /3 /s /x pmode 3d3 main, main3 ,, lib\3dvect lib\sfx lib\user

