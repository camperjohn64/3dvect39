DECLARE FUNCTION c$ (qq!)
REM This qbasic file will pre-calculate the data needed to make background
REM stars.  The file which uses this calculated data is stars.asm.  If you
REM don't have this assembley file, go to nearest corner of room, hang head
REM and cry.

REM to use: qb mstars.bas>stardata.inc

REM The data tables are large but it is expected that the asm routine will
REM be fast as a result of the pre-calculated data.

REM xa=0 to 1024-1
REM ya=0 to 65536-1

REM xl yl zl = xlocation , ylocation...
REM rxa = real x angle (radians)
REM rya = real y angle (rads)
REM t() = theta (y angle,  units: -128 to +127)
REM ya  = theta (y angle,  units: -128 to +127)
REM x1  = x^-1, inverse of where to find x angle in list from rxa
REM xt  = y tolerance at that x angle (255 to 38)

REM Revision: June 15/94  Stars tolerance calculation is now sinusoidal.

n = 1024: REM number of stars, must be 2^x

b$ = "         db  "

x$ = "sxl      db  "
y$ = "syl      db  "
z$ = "szl      db  "
t$ = "sya      db  "
q$ = "xn1      db  "
g$ = "tol      db  "

r$ = ","

fi$ = "         if use_half_stars eq no"
ed$ = "         endif"

PRINT ";";
RANDOMIZE
PRINT
PRINT "; random stars list"
PRINT

DIM x(n), y(n), z(n), t(n), l(n), x1(n), xt(n)

 REM change this tolerance if you change ratiox or xactual or xclipping!!!
 REM these parameters decide the size of clipping depending on
 REM your screen ratio

 qlow = 19: qhi = 73: 'You change these to match your screen size! qlow < qhi

 xt2 = ATN(SQR(qhi ^ 2 - qlow ^ 2) / qlow) * 180 / 3.141592

 FOR xa = 0 TO n - 1

   ya = INT(RND * 65535) - 32767
   rya = ya / 65536 * 3.141592 * 2

   rxa = TAN((xa - n / 2) / n * ATN(3.141592 / 2) * 2 - 3.141592)

   hyp = (qhi * COS(-rxa)) ^ 2 - qlow ^ 2
   IF hyp < 0 THEN xt = 255: GOTO more
   xt = (90 - ATN(SQR(hyp) / qlow) * 180 / 3.141592) / 90 * 256
   IF xt >= xt2 THEN xt = 255
more:

   x = 0
   y = 0
   z = 16384 - 1

   u = y * COS(rxa) - z * SIN(rxa)
   v = y * SIN(rxa) + z * COS(rxa)

   y = u
   z = v

   u = x * COS(rya) - z * SIN(rya)
   v = x * SIN(rya) + z * COS(rya)

   x = u
   z = v

   x(xa) = INT(x / 128)
   y(xa) = -INT(y / 128) - 1
   z(xa) = INT(z / 128)

   t(xa) = INT(ya / 256)
   xt(xa) = INT(xt + .99)

   REM PRINT x(xa),
   REM PRINT y(xa),
   REM PRINT z(xa),

   REM PRINT t(xa),
   REM PRINT rxa,
   REM PRINT rya

 NEXT xa

 FOR j = 0 TO n - .2 STEP .2

   rxa = (TAN((j - n / 2) / n * ATN(3.141592 / 2) * 2 - 3.141592)) / 3.141592 * n + n / 2
   x1(rxa) = INT(j / 4)

 NEXT j

  REM FOR z = 0 TO n - 1
  REM  PRINT x1(z), z
  REM NEXT z

PRINT x$;

 FOR z = 0 TO n - 1 STEP 8


     PRINT c$(x(z)); r$; c$(x(z + 1)); r$; c$(x(z + 2)); r$; c$(x(z + 3)); r$; c$(x(z + 4)); r$;
     PRINT c$(x(z + 5)); r$; c$(x(z + 6)); r$; c$(x(z + 7))
     IF z = 512 THEN PRINT fi$
     IF z < n - 8 THEN PRINT b$;

 NEXT z

PRINT ed$
PRINT
PRINT y$;

 FOR z = 0 TO n - 1 STEP 8

     PRINT c$(y(z)); r$; c$(y(z + 1)); r$; c$(y(z + 2)); r$; c$(y(z + 3)); r$; c$(y(z + 4)); r$;
     PRINT c$(y(z + 5)); r$; c$(y(z + 6)); r$; c$(y(z + 7))
     IF z = 512 THEN PRINT fi$
     IF z < n - 8 THEN PRINT b$;

 NEXT z

PRINT ed$
PRINT
PRINT z$;

 FOR z = 0 TO n - 1 STEP 8

     PRINT c$(z(z)); r$; c$(z(z + 1)); r$; c$(z(z + 2)); r$; c$(z(z + 3)); r$; c$(z(z + 4)); r$;
     PRINT c$(z(z + 5)); r$; c$(z(z + 6)); r$; c$(z(z + 7))
     IF z = 512 THEN PRINT fi$
     IF z < n - 8 THEN PRINT b$;

 NEXT z

PRINT ed$
PRINT
PRINT t$;

 FOR z = 0 TO n - 1 STEP 8

     PRINT c$(t(z)); r$; c$(t(z + 1)); r$; c$(t(z + 2)); r$; c$(t(z + 3)); r$; c$(t(z + 4)); r$;
     PRINT c$(t(z + 5)); r$; c$(t(z + 6)); r$; c$(t(z + 7))
     IF z = 512 THEN PRINT fi$
     IF z < n - 8 THEN PRINT b$;

 NEXT z

PRINT ed$
PRINT
PRINT q$;

 FOR z = 0 TO n - 1 STEP 8

     PRINT c$(x1(z)); r$; c$(x1(z + 1)); r$; c$(x1(z + 2)); r$; c$(x1(z + 3)); r$; c$(x1(z + 4)); r$;
     PRINT c$(x1(z + 5)); r$; c$(x1(z + 6)); r$; c$(x1(z + 7))
     IF z < n - 8 THEN PRINT b$;

 NEXT z

PRINT
PRINT g$;

 FOR z = 0 TO n - 1 STEP 8

     PRINT c$(xt(z)); r$; c$(xt(z + 1)); r$; c$(xt(z + 2)); r$; c$(xt(z + 3)); r$; c$(xt(z + 4)); r$;
     PRINT c$(xt(z + 5)); r$; c$(xt(z + 6)); r$; c$(xt(z + 7))
     IF z = 512 THEN PRINT fi$
     IF z < n - 8 THEN PRINT b$;

 NEXT z

PRINT ed$
PRINT

FUNCTION c$ (qq)

 c$ = LTRIM$(RTRIM$(STR$(qq)))

END FUNCTION

