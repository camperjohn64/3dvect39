INPUT " Palette file           : "; d$
IF d$ = "" THEN d$ = "pal.pal"

INPUT " Start Pel              : "; stp
INPUT " Range        default 16: "; rng
IF rng = 0 THEN rng = 16

INPUT " XRef file name         : "; c$
IF c$ = "" THEN c$ = "dump.glz"

DIM r%(256 * rng + 256), g%(256 * rng + 256), b%(256 * rng + 256)

GOSUB getpal

' Now find all conbinations for glenz/transparent polygons
' Colours with total intensity less than 15 are scrapped (63+63+63=189 max)

pels% = 256 * rng

' Find darkest colour ii% - (for low intensity scrapping)

dd% = 5000
ii% = 1

 FOR z% = 1 TO 255
  d% = r%(z%) + g%(z%) + b%(z%)
  IF d% < dd% THEN dd% = d%: ii% = z%
 NEXT z%

PRINT
PRINT " Generating transparent colours"

 FOR x% = stp TO stp + rng - 1
 i = SQR(r%(x%) ^ 2 + g%(x%) ^ 2 + b%(x%) ^ 2) / 100: ' find intensity of transparant colour

  FOR z% = 0 TO 255
  qq% = z% + (x% - stp) * 256 + 256

  r%(qq%) = (r%(x%) * (1 - i) + r%(z%) * i): ' this is the actual transparent calculation
  g%(qq%) = (g%(x%) * (1 - i) + g%(z%) * i)
  b%(qq%) = (b%(x%) * (1 - i) + b%(z%) * i)

 ' IF z% >= stp AND z% < stp + rng THEN r%(qq%) = r%(z%): g%(qq%) = g%(z%): b%(qq%) = b%(z%)

mok:
  IF r%(qq%) + g%(qq%) + b%(qq%) < 15 THEN r%(qq%) = r%(qq%) * 1.3 + 1: g%(qq%) = g%(qq%) * 1.3 + 1: b%(qq%) = b%(qq%) * 1.3 + 1: GOTO mok

  NEXT z%
 NEXT x%

dist% = 2

PRINT pels%; "new colours calculated"

' Collect and output cross referancing tables

PRINT "Writing cross referancing tables"

OPEN c$ FOR OUTPUT AS #1

 FOR z% = 0 TO rng - 1
 PRINT #1, "xref"; LTRIM$(RTRIM$(STR$(z%))); TAB(10); "db ";

  cc% = 0

  FOR x% = 0 TO 255
  qq% = 256 + z% * 256 + x%

   uu% = 5000

   IF x% = 0 THEN jj% = z% + stp: GOTO skipit

   FOR rr% = 0 TO 255
    ff% = ABS(r%(rr%) - r%(qq%)) + ABS(g%(rr%) - g%(qq%)) + ABS(b%(rr%) - b%(qq%))
    IF ff% < uu% THEN uu% = ff%: jj% = rr%
   NEXT rr%

skipit:
   PRINT #1, LTRIM$(RTRIM$(STR$(jj%)));
   cc% = cc% + 1
   IF cc% < 16 THEN PRINT #1, ",";
   IF cc% = 16 THEN PRINT #1, "": cc% = 0: IF x% <> 255 THEN PRINT #1, TAB(10); "db ";

  NEXT x%
  PRINT #1, ""
 NEXT z%

PRINT #1, ""
CLOSE #1
END

getpal:
OPEN d$ FOR BINARY AS #1

P$ = SPACE$(256 * 3): GET #1, , P$

FOR a = 0 TO 256 - 1
r%(a) = ASC(MID$(P$, a * 3 + 1, 1))
g%(a) = ASC(MID$(P$, a * 3 + 2, 1))
b%(a) = ASC(MID$(P$, a * 3 + 3, 1))
NEXT a

CLOSE #1
RETURN

