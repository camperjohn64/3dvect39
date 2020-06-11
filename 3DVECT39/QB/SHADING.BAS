DECLARE FUNCTION c$ (qq!)

x$ = "shading_tables:"
b$ = "  db "

r$ = ","

PRINT "  align 16"
PRINT
PRINT x$

'nu = 64
'nu = 48
'nu = 32
nu = 16: REM number of colours to grab from pal for lambert shading table

DIM x(256)

 FOR xa = 0 TO 255

   x(xa) = ((TAN((xa - 128) / 256) + .5463026) / 1.087545) * nu

 NEXT xa

     PRINT b$;

qw = 16: REM how many numbers to print on the same line

 FOR z = 0 TO 255 STEP qw
    FOR q = 0 TO qw - 1
     PRINT c$(x(z + q));
     IF q <> qw - 1 THEN
       PRINT r$;
     ELSE
       PRINT
     END IF
    NEXT q

    IF z < 255 - qw THEN PRINT b$;
 NEXT z

PRINT " Now replace this in the file MATH.INC"

FUNCTION c$ (qq)

 c$ = LTRIM$(RTRIM$(STR$(INT(qq))))

END FUNCTION

