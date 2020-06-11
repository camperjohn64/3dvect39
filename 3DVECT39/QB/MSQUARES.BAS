a$ = "0123456789ABCDEF"
w$ = "        dw  "
s$ = "squares dw  "

REM use: qbasic msquares.bas>squares.inc  to dump to disk

c = 0
PRINT "; x squared tables: 256 word entries return ax exponent 2."
PRINT "; in square functions, low byte is only factor!"
PRINT
PRINT "; mov si,ax ; ax must be less then 256! (eg 257*257>65535)"
PRINT "; mov ax,[squares+si]"
PRINT : PRINT s$;

FOR z = 0 TO 255

 x = z ^ 2

 q$ = "0"

 u = INT(x / 256)
 y = INT(u / 16)

 PRINT q$; MID$(a$, y + 1, 1); MID$(a$, (u / 16 - INT(u / 16)) * 16 + 1, 1);

 q$ = "0"

 u = x - u * 256
 y = INT(u / 16)

 PRINT MID$(a$, y + 1, 1); MID$(a$, (u / 16 - INT(u / 16)) * 16 + 1, 1); "h";

 c = c + 1
 IF c < 8 THEN PRINT ","; : GOTO 91

 c = 0
 q = (z - 7)
 u = INT(q * 1000) / 1000

 PRINT " ;"; u
 IF z = 255 THEN GOTO 91

 PRINT ; w$;

91

 NEXT z


