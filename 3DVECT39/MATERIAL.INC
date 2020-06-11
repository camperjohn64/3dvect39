# This is a comment

# There must be 5 fields in each assigned texture!! Textures do not have
# to be capitals, I only did it that way because it looked nice.  Do not
# use punctuation in your texture names. Material names can be  as  long
# as ACAD will allow. The keyword RND  will  generate  a  random  number
# between 0 and 255. There is no need to add 3 extra words if the  shade
# option is used - it will be done  automatically!  Colons  allow  extra
# text or data to be concatenated to the end of the line.

CONSTANT    0,0,0,colour0,0
#SHADED      0,shade,0,colour1,0
SINE        0,wavey,0,colour2+rnd/16,0
BOTHSIDES   both,0,0,colour3,0
BOTHSHADE   both,shade,0,colour4,0
DOUBLESIDED double,0,0,colour5a,colour5b
DOUBLESHADE double,shade,shade,colour6a,colour6b
1SHADE2SINE 0,shade,wavey,colour7a,colour7b
1SINE2SHADE 0,wavey,shade,colour8a,colour8b
2SINE       double,wavey,wavey,colour9a,colour9b
AUTOSHADE   auto_s,0,0,colour0,0
HIBITMAP    himap:,0,5,5
LOBITMAP    lomap:,0,5,5
SHADESTONE  0,shade+stone,0,colour,0
STONE       0,auto_s+stone,0,0,0
MESH        0,mesh,0,colour,0
SAMPLESIDE  this is,an example,of what,you can,do!

#Add your own textures. Then name the ACAD layers to those textures and viola!

#These are example textures for the AUTO1.DWG shape
FACES    0,shade,0,16,0
MIDDLE   0,shade,0,48,0
OTHEREND 0,shade,0,32,0

#Materials examples for REND386 .PLG files
0_x11FF  0,shade,0,16,0
0_x22AA  0,shade,0,48,0

#Isn't this materials file cool? Send me a postcard.

2_LEGR        0,auto_s,0,48,0
3_LEGL        0,auto_s,0,48,0
7_SHOULDERL   0,auto_s,0,48,0
A_BOXL        0,auto_s,0,48,0
9_BOXR        0,auto_s,0,48,0
8_SHOULDERR   0,auto_s,0,48,0
6_SLABBOTTOM  0,auto_s,0,48,0
0_BODYL       0,auto_s,0,48,0
1_BODYR       0,auto_s,0,48,0
4_SLABTOP     0,auto_s,0,48,0
5_SLABMIDDLE  0,auto_s,0,48,0
B_MIDBOX      0,auto_s,0,48,0
C_HEAD        0,auto_s,0,48,0
C_LIGHT       0,auto_s,0,48,0
C_NOSE        0,auto_s,0,46,0

#Lettering, VECTOR SCUM
FRONT         0,auto_s,0,32,0

#Space Ships for GAME
SHADED        0,shade+stone,0,0,0
BOTTOM        0,shade,0,32,0
WINDOW        0,wavey,0,64+rnd/16,0
ENGINE        0,wavey,0,96,0
SHIELD_R      both,glenz+shade,0,1,0
SHIELD_F      both,glenz+shade+inverse,0,1,0

SPOKE1           0,shade,0,spoke1,0
RIMINSIDE        0,shade,0,riminside,0
RIMSIDEWALL1     0,shade,0,riminsidewall1,0
RIMSIDEWALL2     0,shade,0,riminsidewall2,0
RIMSIDEWALLBACK  0,shade,0,back,0
TIRETREAD        0,shade,0,tiretread,0
CENTERHUB        0,shade,0,centerhub,0

GLENZ1        both,glenz+shade,0,1,0
GLENZ2        both,glenz+shade,0,1,0
