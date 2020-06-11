CLS
RANDOMIZE
DIM a(1000), b(1000)
DIM hh(1000)

newparams:
SCREEN 0
WIDTH 80, 50
CLS

INPUT " Start Pel              : "; qaa
INPUT " Range        default 8 : "; qqb
IF d$ = "" THEN INPUT " Palette     def 32.pal : "; d$

INPUT " Length of table def 500:"; ggh
INPUT " Y Variance      def 100:"; yvar
INPUT " Width           def 320:"; wd

INPUT " Dump file name (no extension!):"; c$
INPUT " Dump starting character:"; h$

IF wd = 0 THEN wd = 320
IF yvar = 0 THEN yvar = 100

IF ggh = 0 THEN ggh = 500
IF yvar = 0 THEN yvar = 100

IF qqb < 2 THEN qqb = 8
IF d$ = "" THEN d$ = "32.pal"

IF c$ = "" THEN c$ = "stone32"

SCREEN 13: DEF SEG = &HA000

GOSUB getpal

again:
a(0) = RND(1) * qqb + qaa
FOR x = 1 TO ggh
kkkjj:
 a(x) = INT(RND(1) * qqb + qaa)
 b(x) = a(x)
 IF ABS(a(x) - a(x - 1)) <= 0 THEN GOTO kkkjj
NEXT x

g = 0
h = 0
i = 0
j = 0
k = 0
q = 0

FOR x = 1 TO wd
eerr:
 q = q + 1
 n = RND(1) * (yvar - 5)
 IF ABS(g - n) < yvar / 3 THEN GOTO eerr
 IF q > 5 THEN GOTO oks
 IF ABS(h - n) < yvar / 6 THEN GOTO eerr
 IF ABS(i - n) < yvar / 8 THEN GOTO eerr
 IF ABS(j - n) < yvar / 10 THEN GOTO eerr
 IF ABS(k - n) < yvar / 10 THEN GOTO eerr
oks:
 k = j
 j = i
 i = h
 h = g
 g = n
 hh(x) = INT(n)

NEXT x

intensity = 256: ' used for darken
level = 0

redraw:

hhj = wd
'IF hhj > 320 THEN hhj = 320

FOR x = 0 TO hhj - 1
 FOR y = 0 TO 200
  h = x + y * 320&
  q = hh(x + 1) + y + level
  POKE h, a(q + 1)
 NEXT y
oop:
x$ = INKEY$
IF x$ <> "" THEN GOTO aborted
NEXT x

LOCATE 1, 1
FOR z = 1 TO 20 * RND(1): PRINT "": NEXT z
PRINT "s=save, space=recycle, q=quit"
PRINT "r=redraw,d=color down, u=color up"
PRINT "[=view bottom,]= view top."
PRINT "+ - start pel up/down"

llkk:
DO
x$ = INKEY$
LOOP WHILE x$ = ""
aborted:
IF x$ = " " THEN GOTO again
IF x$ = "r" THEN GOTO redraw
IF x$ = "d" THEN GOTO darken
IF x$ = "u" THEN GOTO light
IF x$ = "a" THEN GOTO newparams
IF x$ = "q" THEN END
IF x$ = "s" THEN GOTO filesave
IF x$ = "[" THEN GOTO light3
IF x$ = "]" THEN GOTO light4
IF x$ = "+" THEN GOTO mainup
IF x$ = "-" THEN GOTO maindown

GOTO llkk

light3:
 level = 200
 GOTO redraw
light4:
 level = 0
 GOTO redraw

darken:
 intensity = intensity - 3
 IF intensity <= 0 THEN intensity = 256
 GOTO kkll2
light:
 intensity = intensity + 3
 IF intensity >= 256 THEN intensity = 0
kkll2:
 FOR z = 0 TO ggh
  a(z) = INT((b(z) - qaa) / 256 * intensity + qaa)
 NEXT z
GOTO redraw

mainup:
FOR z = 0 TO ggh
b(z) = b(z) + 1
NEXT z
GOTO kkll2

maindown:
FOR z = 0 TO ggh
b(z) = b(z) - 1
NEXT z
GOTO kkll2

filesave:
SCREEN 0
WIDTH 80, 50

q$ = c$ + h$ + ".inc"

OPEN q$ FOR OUTPUT AS #1

 PRINT #1, "header"; h$; " dd offset stonel"; h$; " - offset $"
 PRINT #1, "        dd offset stoney"; h$; " - offset $"
 PRINT #1, ""
 PRINT #1, "stonel"; h$; " db ";

  z = 1
  FOR c = 1 TO ggh
   PRINT #1, LTRIM$(RTRIM$(STR$(a(c))));
   z = z + 1
   IF z = 17 AND c <> ggh THEN z = 1: PRINT #1, "": PRINT #1, "        db "; : GOTO hhggff
   IF c <> ggh THEN PRINT #1, ",";
hhggff:
  NEXT c

 PRINT #1, ""
 PRINT #1, ""
 PRINT #1, "stoney"; h$; " db ";

 c = ASC(h$)
 c = c + 1
 IF c = 58 THEN c = 97
 h$ = CHR$(c)

  z = 1
  FOR c = 1 TO wd
   PRINT #1, LTRIM$(RTRIM$(STR$(hh(c))));
   z = z + 1
   IF z = 17 AND c <> wd THEN z = 1: PRINT #1, "": PRINT #1, "        db "; : GOTO hhggff2
   IF c <> wd THEN PRINT #1, ",";
hhggff2:
  NEXT c

PRINT #1, ""
PRINT #1, ""
CLOSE #1

PRINT " File saved as:"; q$
PRINT ""
PRINT " n = new parameters"
PRINT " c = continue with old"
PRINT " q = quit"

llkkf:
DO
x$ = INKEY$
LOOP WHILE x$ = ""

IF x$ = "n" THEN GOTO newparams
IF x$ = "c" THEN SCREEN 13: GOSUB getpal: GOTO redraw
IF x$ = "q" THEN END
GOTO llkkf
END

getpal:
OPEN d$ FOR BINARY AS #1

P$ = SPACE$(256 * 3): GET #1, , P$
OUT &H3C7, 0: OUT &H3C8, 0
FOR a = 1 TO 256 * 3: OUT &H3C9, ASC(MID$(P$, a, 1)): NEXT

CLOSE #1
RETURN




