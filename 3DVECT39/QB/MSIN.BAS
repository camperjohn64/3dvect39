REM Warning, this file is old, (I've lost my updated version for 4096 angles)

a$ = "0123456789ABCDEF"
w$ = "        dw  "
s$ = "sinus   dw  "
c$ = "cosinus dw  "

REM use: qbasic msin.bas>sin.inc  to dump to disk

c = 0
PRINT "; sine tables: 1024 entries each.  therefore 90 degrees is now 256[si]"
PRINT "; 180 = 512, 360 = 1024 = 0.  and ax,03FFh to truncate angle"
PRINT : PRINT s$;

FOR z = 0 TO 359.98 + 90 STEP 360 / 1024

 x = INT(SIN(z / 360 * 2 * 3.14159265#) * 256 + .5)

 IF x = 256 THEN PRINT "00100h"; : GOTO 78

 q$ = "000"
 IF x < 0 THEN q$ = "0FF": x = 256 + x

 y = INT(x / 16)

 PRINT q$; MID$(a$, y + 1, 1); MID$(a$, (x / 16 - INT(x / 16)) * 16 + 1, 1); "h";

78

 c = c + 1
 IF c < 8 THEN PRINT ","; : GOTO 91

 c = 0
 q = z - 2.4609
 u = INT(q * 1000) / 1000

 IF ABS(z - 90) < 1 THEN PRINT " ;"; u: PRINT : PRINT c$; : GOTO 91

 PRINT " ;"; u
 IF z > 359 + 90 THEN GOTO 91

 PRINT ; w$;

91

 NEXT z

