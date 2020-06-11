a$ = "0123456789ABCDEF"
w$ = "        dw  "
s$ = "negtan:"

REM Make ArcTan tables for use in assembler
REM use: qbasic marctan.bas>arctan.inc  to dump to disk

c = 0
PRINT ";           public arctan"
PRINT
PRINT ";arctan:"
PRINT ";           cmp ax,0"
PRINT ";           jl s qd2or3"
PRINT ";           cmp cx,0"
PRINT ";           jge s halftax      ; quadrant 1"
PRINT ";           neg cx             ; quadrant 4, ax=-ax"
PRINT ";           call halftan"
PRINT ";           neg ax"
PRINT ";           shl ax,2"
PRINT ";           ret"
PRINT ";qd2or3:"
PRINT ";           neg ax"
PRINT ";           cmp cx,0"
PRINT ";           jge s qd2"
PRINT ";           neg cx             ; quad 3, ax=ax+8192"
PRINT ";           call halftan"
PRINT ";           add ax,8192"
PRINT ";           shl ax,2"
PRINT ";           ret"
PRINT ";qd2:"
PRINT ";           call halftan"
PRINT ";           neg ax"
PRINT ";           add ax,8192"
PRINT ";           shl ax,2"
PRINT ";           ret"
PRINT ";halftax:"
PRINT ";           call halftan"
PRINT ";           shl ax,2"
PRINT ";           ret"
PRINT
PRINT ";           align 4"
PRINT
PRINT ";halftan:"
PRINT ";           movsx eax,ax"
PRINT ";           movsx ecx,cx"
PRINT ";           mov edx,0"
PRINT
PRINT ";; cx=rise  positive"
PRINT ";; ax=run   positive"
PRINT ";"
PRINT ";           cmp eax,ecx"
PRINT ";           jl s opptan        ; greater than 45 degrees, other side..."
PRINT
PRINT ";           xchg ecx,eax       ; ax<cx"
PRINT ";           shl eax,11         ; *2048"
PRINT ";           div ecx"
PRINT ";           mov si,ax"
PRINT ";           mov ax,w negtan[esi*2] ; resulting angle (0-512 is 0-45) in ax"
PRINT ";           ret"
PRINT
PRINT ";           align 4"
PRINT
PRINT ";opptan:"
PRINT ";           shl eax,11         ; *2048"
PRINT
PRINT ";           div ecx"
PRINT ";           mov si,ax          ; ax remainder"
PRINT ";           mov cx,w negtan[esi*2]"
PRINT ";           mov ax,1000h"
PRINT ";           sub ax,cx          ; resulting angle (2048-4096 is 45-90) in ax"
PRINT ";           ret"
PRINT
PRINT s$
PRINT w$;
    
FOR z = 0 TO 99.6 STEP 99.98 / 2048

 x = INT(ATN(z / 100) / 2 / 3.1415926535# * 1027 * 16)

 IF x = 256 THEN PRINT "100h"; : GOTO 78

 y = INT(x / 256)

 q$ = MID$(a$, y + 1, 1)
                      
 y = INT(x / 16) AND 15

 PRINT q$; MID$(a$, y + 1, 1); MID$(a$, (x / 16 - INT(x / 16)) * 16 + 1, 1); "h";

78

 c = c + 1
 IF c < 8 AND z < 99.55 THEN PRINT ","; : GOTO 91
 IF z >= 99.55 THEN GOTO 91
 c = 0
 q = INT(z - 2.734)
 u = INT(q * 1000) / 1000

 PRINT " ;"; u; "/100"
 IF z > 99.55 THEN GOTO 99

 PRINT ; w$;

91

 NEXT z

99  END

