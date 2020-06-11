DECLARE FUNCTION c$ (qq!)
b$ = "  db "
r$ = ","

y = 128
x = INT(y * COS(3.141592 / 4))

t = x * y

PRINT ";Total table length:"; t; ",Table size:"; y; "*"; x
PRINT ";Maximum Radius of Circle to Fit Inside Table:"; y
PRINT

DIM x(x * y + y)

FOR u = 0 TO x - 1
 FOR v = 0 TO y - 1
  x(u * y + v) = INT(SQR(u ^ 2 + v ^ 2) + .5)
 NEXT v
NEXT u

 PRINT b$;

 FOR z = 0 TO t - 1 STEP 16

     PRINT c$(x(z)); r$; c$(x(z + 1)); r$; c$(x(z + 2)); r$; c$(x(z + 3)); r$; c$(x(z + 4)); r$;
     PRINT c$(x(z + 5)); r$; c$(x(z + 6)); r$; c$(x(z + 7)); r$;
     PRINT c$(x(z + 8)); r$; c$(x(z + 9)); r$; c$(x(z + 10)); r$; c$(x(z + 11)); r$; c$(x(z + 12)); r$;
     PRINT c$(x(z + 13)); r$; c$(x(z + 14)); r$; c$(x(z + 15))

     IF z < t - 16 THEN PRINT b$;

 NEXT z

FUNCTION c$ (qq)

 c$ = LTRIM$(RTRIM$(STR$(qq)))

END FUNCTION

