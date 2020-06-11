# This is a comment

# There must be 5 fields in each assigned texture!!  Textures do not have
# to be capitals, I only did it that way because it looked nice.  Do  not
# use punctuation in your texture names.  Material names can be  as  long
# as ACAD will allow.  The keyword RND  will  generate  a  random  number
# between 0 and 255.  There is no need to add 3 extra word  if the  shade
# option is used - it will be  done  automatically!  Colons  allow  extra
# text or data to be concatenated to the end of the line.

CONSTANT     0,0,0,colour0,0
SHADED       0,shade,0,colour1,0
SINE         0,wavey,0,colour2+rnd/16,0
BOTHSIDES    both,0,0,colour3,0
BOTHSHADE    both,shade,0,colour4,0
DOUBLESIDED  double,0,0,colour5a,colour5b
DOUBLESHADE  double,shade,shade,colour6a,colour6b
1SHADE2SINE  0,shade,wavey,colour7a,colour7b
1SINE2SHADE  0,wavey,shade,colour8a,colour8b
2SINE        double,wavey,wavey,colour9a,colour9b
AUTOSHADE    auto_s,0,0,colour0,0
HIBITMAP     himap:,0,5,5
LOBITMAP     lomap:,0,5,5
SHADESTONE   0,shade+stone,0,colour,0
STONE        0,stone,0,colour,0
MESH         0,mesh,0,colour,0
SAMPLESIDE   this is,an example,of what,you can,do!

#Add your own textures. Then name the ACAD layers to those textures and viola!

#These are example textures for the AUTO1.DWG shape
FACES        0,shade,0,16,0
MIDDLE       0,shade,0,48,0
OTHEREND     0,shade,0,32,0

#Materials examples for REND386 .PLG files
0x11FF       0,shade,0,16,0
0x22AA       0,shade,0,48,0

#Isn't this materials file cool?  Send me a postcard.
