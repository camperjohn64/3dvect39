DECLARE FUNCTION f$ (g!)

PRINT "Calculate Surface Normal Based on 3 Points"
PRINT
PRINT "Can be used to pre-calculate normals for  objects.   Also  could"
PRINT "be used to test if a multi-sided  polygon  is  flat  or  curved."
PRINT "(curved ploygons can't be plotted well, flat polygons will  have"
PRINT "the same  surface  normal  regardless  of  points  selected  for"
PRINT "calculation)."
PRINT
PRINT "Remember, the routine pre_cal_lambert will calculate all surface"
PRINT "normals for you.!!!"
PRINT

INPUT "Filename to output data words to:(enter = none)"; a$

goagain:
PRINT
PRINT "Enter co-ordinates of first 3 points in polygon (counter-clockwise)"
PRINT "(remember, negative y is up)"
PRINT

IF a$ <> "" AND z = 0 THEN OPEN a$ FOR OUTPUT AS #1: z = 1

INPUT x1, y1, z1
INPUT x2, y2, z2
INPUT x3, y3, z3

x2 = x2 - x1
y2 = y2 - y1
z2 = z2 - z1

x3 = x3 - x1
y3 = y3 - y1
z3 = z3 - z1

x = y2 * z3 - z2 * y3
y = z2 * x3 - x2 * z3
z = x2 * y3 - y2 * x3

a = SQR(x ^ 2 + y ^ 2 + z ^ 2) / 255

x = INT(x / a + .5)
y = INT(y / a + .5)
z = INT(z / a + .5)

PRINT
PRINT "Your Gouraud/Lambert shading values are:"

PRINT "x="; x; " y="; y; " z="; z
PRINT "  dw "; f$(x); ","; f$(y); ","; f$(z)
IF a$ <> "" THEN PRINT #1, "  dw "; f$(x); ","; f$(y); ","; f$(z)

d$(0) = "That was Fun, Lets do it again!"
d$(1) = "Hey, I liked that, you got more?"
d$(2) = "OOooo, Thats and interesting number isn't it, lets do another one"
d$(3) = "Pre_cal_lambert does this for you, you know..."

PRINT
PRINT d$(RND * 3)
GOTO goagain:

REM Dot Product...  A dot B=AX*BX+AY*BY+AZ*BZ=some scalar

REM Normalize...A<bar>=[AX/|A|,AY/|A|,AZ/|A|]=some vector. Each component is
REM divided by the length of the vector (sqrt(x*x+y*y+z*z)).

FUNCTION f$ (g)

      f$ = LTRIM$(RTRIM$(STR$(g)))

END FUNCTION

