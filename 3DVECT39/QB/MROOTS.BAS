a$ = "0123456789ABCDEF"
w$ = "        db  "
s$ = "roots   db  "

REM use: qbasic mroots.bas>roots.inc  to dump to disk

c = 0
PRINT "; square root tables: 256 entries return root of 0-65535."
PRINT "; in square root functions, high byte is only factor!"
PRINT
PRINT "; mov al,ah"
PRINT "; mov ah,0"
PRINT "; mov si,ax"
PRINT "; mov ax,[roots+si]"
PRINT : PRINT s$;

FOR z = 0 TO 255

 x = INT(SQR(z * 256) + .5)

 IF x = 256 THEN PRINT "00100h"; : GOTO 78

 q$ = "0"

 y = INT(x / 16)

 PRINT q$; MID$(a$, y + 1, 1); MID$(a$, (x / 16 - INT(x / 16)) * 16 + 1, 1); "h";

78

 c = c + 1
 IF c < 8 THEN PRINT ","; : GOTO 91

 c = 0
 q = (z - 7) * 256
 u = INT(q * 1000) / 1000

 PRINT " ;"; u
 IF z = 255 THEN GOTO 91

 PRINT ; w$;

91

 NEXT z

