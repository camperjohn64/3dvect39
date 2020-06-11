;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : objects.inc
; Included from: Main.asm
; Description  : Some sample objects for 3dVect.zip
;
; Written by: John McCarthy
;             1316 Redwood Lane
;             Pickering, Ontario.
;             Canada, Earth, Milky Way (for those out-of-towners)
;             L1X 1C5
;
; Internet/Usenet:  BRIAN.MCCARTHY@CANREM.COM
;         Fidonet:  Brian McCarthy 1:229/15
;   RIME/Relaynet: ->CRS
;
; Home phone, (905) 831-1944, don't call at 2 am eh!
;
; John Mccarthy would really love to work for a company programming Robots
; or doing some high intensive CPU work.  Hint. Hint.
;
; Send me your protected mode source code!
; Send me your Objects!
; But most of all, Send me a postcard!!!!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

setupbase:
         mov _objbase[0*4],offset headercube4
         mov _objbase[1*4],offset headercube2
         mov _objbase[2*4],offset headerring
         mov _objbase[3*4],offset headerdiamond
         mov _objbase[4*4],offset headerrubine
         mov _objbase[5*4],offset column
         mov _objbase[6*4],offset archmiddle
        ;mov _objbase[7*4],offset archend
        ;mov _objbase[8*4],offset bigoildrum
        ;mov _objbase[9*4],offset ship1
         mov _objbase[5*4],offset headercube3
         mov _objbase[6*4],offset headerarm

         ;mov _objbase[0*4],offset platform1
         ;mov _objbase[1*4],offset platform2
         ;mov _objbase[2*4],offset platform3
         ;mov _objbase[0*4],offset ship1

         mov _objbase[0*4],offset futurecrewrip1
         ;mov _objbase[0*4],offset formula
         ;mov _objbase[0*4],offset inca
         ;mov _objbase[0*4],offset htracer
         ;mov _objbase[1*4],offset hacad1

         mov esi,0                          ; from object #
         mov edi,6                          ; to object #
         call _set_up_all_lambert           ; find and set up shading tables

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Shape data can be almost as large as you need it 'till it crashes. Try a cube
; 20000_x20000_x20000.    Calculations  use  32  bit  registers  and  can  handle
; up to 16 bit locations.  Keeping the object size small will  allow  a  larger
; visible space.  But larger objects will allow you to get  closer  with   more
; accuracy in the mathematics of rotations.  Remember, if you make a really big
; object, set minz to the largest object on the screen so the large object wont
; mess up when you get really close to it.  I have generally found that  larger
; objects "look" better as they have great mathematical resolution.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Format for objects:
;
; headerthing:
;  dd max,min    ; max = maximum distance object can be seen, min = closest
;                ; distance object is allowed to be seen (can be negative)
;                ; eg dd 5000000,200.  If negative, object must be made up
;                ; of only sub-objects!!!
;  dd res1       ; distance for resolution1, eg 6000
;  dd offset thing1 - offset $ - 4  ; pointer to resolution1
;  dd -1         ; last resolution flag
;  dd offset thing2 - offset $ - 4  ; pointer to resolution2
;
; thing1:
;  dw xx         ; number of points
;  dw yy         ; number of surfaces
;  dw 25 dup (0) ; 25 future use words/options
;
;  dw xx,yy,zz   ; x,y,z of point 0
;  dw xx,yy,zz   ; x,y,z of point 1
;  dw xx,yy,zz   ; x,y,z of point 2
;  ...
;
;  dw command
;  dw texture for side 1
;  dw texture for side 2
;  dw colour for side 1
;  dw colour for side 2
;  dw connection data eg (1,2,3,4,1)
;  dw [?,?,?] [optional surface normal if command 128 used]
;  dw more connection data...
;
; to re-cap: dw command,texture1,texture2,colour1,colour2,connection,[0,0,0]
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; List of texture bits to date: (options grouped by function:)
;
; Note: "visible" = "points appear counter-clockwise"
;
; Texture definitions:
;
;   0       - normal surface, no features, constant colour.
;   wavey   - steel texture for surface 0 = none,  colour  offset  determines
;             screen offset for texture.  eg 16+7 will use colour block 16-31
;             but make the sine wave texture 14 (7*2) lines down. this is  so
;             all sine wave textures do not appear on the same line.  Windows
;             and engines look good with this feature.  This  option  can  be
;             combined with shading  if  you  want  to  mis-align  sine  wave
;             patterns.
;   shade   - _lambert shading bit, must have normal calculated or  at  least
;             have    free    space     for    _pre_cal_lambert    to    use:
;             eg x,x,x,x,x,1,2,3,1,?,?,?<- these 3 words are surface normal!
;   inverse - inversion bit for shading option.  0=normal shading, 1=inverse
;             inversion automatically occures when other side is displayed.
;   glow    - =shade+inverse
;   last    - colour has same colour as previous surface (used when
;             you want gourad shading, but want to avoid  duplicate
;             calculations - don't set gourad bit if this  is  what
;             you use it for.) when this is used, the colour number
;             determines the new colour block to use.  the  shading
;             of this colour will be the same as the surface before
;             it, but the colour block can be different.
;   mesh    - see the line below? that sort if dot on/dot off thing? thats a
;             mesh texture.  can be combined with shading.
;   glenz   - glenz vector (you know, the stained glass type of  thingy)
;             The colour of surface refers to a cross referanced palette
;             from which the glenz polygon will derive it's new colours.
;             Put the cross referancing palette  offset  into  _xreftable
;             and make the colour index the palette in the table.  Glenz
;             vectors can be used with the shading  option  to  get  the
;             same type of effect as in  Second  Unreal.   Shaded  Glenz
;             Vectors are made by simply having multiple cross referance
;             palettes and setting the surface to  "shade".   This  will
;             select the appropriate table based on surface normal. This
;             option can be combined with shading.
;   stone   - this texture is like the stone texture I saw  in Alone In The
;             Dark.   The   stone   texture   offset    is    loaded   from
;             [_stonetbl+colour*4].  Use the Qbasic  program   stone.bas  to
;             generate more stone textures with different colours or ranges
;             This option can be combined with shading.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Commands:
;
;   point   - defines a single point; must be repeated! eg dw 64,col,3,3
;   line    - if used, defines a line (must be set to define a true line)
;   himap   - if set, defines a _bitmap,eg: point #, _bitmap #, x scale,y scale
;   lomap   - uses 1/4 scaled _bitmap (every 4'th pixel is sampled), fast
;
;   iterate - generate iteration if side visible (iteration = sub-object)
;   matrix  - modify matrix when generating iteration.  matrix object
;             offset is 3rd word (6'th byte) in future use words.
;
;   both    - side is always visible no matter angle, skips counter-clowise test
;           - "both sides have same texture"
;   double  - side is always visible but other side has other colour
;             "double sided surface"
;             note: if this is used, option "both" must not be used!!
;   onscr   - test if side is on screen - don't use if all points are
;             outside clipping parameters.
;   check   - dont plot this side, just use as test points for visibility.
;             this is mostly used with iterations.
;   gosub   - push current offset and go to another location (offset location - offset $)
;   return  - just like a qbasic return
;   goto    - like qbasic - go to another offset (offset location - offset $)
;   push_matrix        - push rotation matrix
;   pop_matrix         - pop rotation matrix
;   push_location      - push 3d centriodal location
;   pop_location       - pop 3d centroidal location
;   sub_object         - sub_object = matrix+check+iteration+both,?,?,?,?,0,0
;   static_sub_object  - non-rotatable sub_object = check+iteration+both,?,?,?,?,0,0
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; There are two kinds of _bitmaps and points.  Those which  are  inside  objects
; and those which are seperate objects themselves. If _userotate object  command
; is set to 32 or 64, then the entire object is considered to be either a point
; or _bitmap.  But if _userotate is not set this way, then  a  normal  object  is
; drawn and _bitmaps then come from within the object definitions (below).  this
; way, _bitmaps and points can be either part of a larger object,  or  they  are
; computed fast on their own. (eg explosions and bullets as  seperate  objects)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Note: when writing surface descriptions, try to make the  first value unique
; from any other first value.  This way, the sort routine  will  give  a  more
; accurate sorting of sides. eg 1,3,6,1  2,4,1,2  rather than 1,3,6,1  1,2,4,1
; If this doesnt give you what you want, then try making the first two  points
; the farthest points from the objects centroid.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; To recap:
;
;        0 = constant colour, only visible from counter-clockwise side
;    wavey = sine texture
;    shade = shading - requires 3 blank words for surface normal eg dw 0,0,0
;  inverse = invert the shading direction, 0=normal, 1=sun is other way.
;     last = use intensity from previous surface (not colour, only intensity)
;     mesh = see through mesh - solid colour
;    glenz = cross referancing vector - load from screen, xrefs it, put back
;    stone = stone texture.  use stone.bas to make more textures.
;
;    point = point
;     line = line
;    himap = _bitmap (scalable, non-rotatable)
;    lomap = _bitmap (scalable, non-rotatable)
;  iterate = generate iteration if side visible
;     both = always visible
;   double = always visible but other side has high byte colour,"double sided"
;    onscr = plot side only if all the following points are on the screen
;    check = dont plot side but use the following points as a test for visiblity
;
; What you can't mix on a single surface: "double" with "both"!!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; You do not have to define a point for the center of the  object.  the  point
; 0 defines the center of the object.  This is different from earlier versions
; This point will ALWAYS be calculated and will always be the zero'th point.
;
; Iterations may or may not have an extra centroid point calculated  for  you.
; Whether or not a new point is added to  the  points  list  is  dependant  on
; whether or not a new centroid must be calculated.  Hmmm, how  can  I explain
; this...Ok, centroids are calculated with new matricies or centroid  offsets,
; they are also calculated if the centroid flag is set (4'th word).  So,  what
; does this mean to the lowly reader (you).  Some examples of iterations where
; new points are added to points list.
;
; Eg:
;  an iteration where new centroid IS NOT calculated and IS NOT inserted
;
;   dw iteration,0,0,colour,0 ,1,2,3,4,1
;       dw 1,1
;       dw 25 dup (0)
;          x y z
;       dw 5,5,5                 ; point 20 (for example)
;       dw 0,0,0,colour, 20,5,20 ; notice how this surface uses newly created point
;
;  an iteration where new centroid IS calculated and IS inserted
;
;   dw iteration+matrix,0,0,colour,0 ,1,2,3,4,1
;       dw 1,1
;       dw 25 dup (0)
;          x y z
;       dw 5,5,5                 ; point is now 21 (because matrix calculated new centroid)
;       dw 0,0,0,colour, 21,5,21 ; same surface as above.
;
; The "sub_object" command also forces a centroid to be calculated, and will
; also insert a new point into the points list.  Be aware of it's presance!
;
; Note: The centroid is always calculated as the zero'th point. The above rules
; only apply to whether or not a new centroid will appear  as  an  EXTRA  point
; in an ITERATION.
;
; Questions to ask yourself in trying to figure out the above text:
;   Have I made an iteration that has any centroidal offset?
;   Have I used the matrix command?
;   Hahe I used the sub_object command?
;   Have I set bit 0 of the 4'th word in the 25 dup's to 1?
;   Am I sexually frustrated?
; If you answer yes to any of these questions, then a new centroidal point will
; be calculated and inserted into the points list even if you dont ask for it!
;
; If you want to negate the effects of centroid  point  insertion,  simply  set
; the 7'th word (14'th byte) in those 25 dup's to 1. See below for more info.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Here is a simple rundown of what those 25 extra words do:
;
;  dw x,y ; x=number of points,y=number of surfaces (but you knew that right?)
;
;  dw ? ; reserved for memory offset if an iteration is skipped   (leave blank)
;  dw ? ; reserved for point offset if an iteration is skipped    (leave blank)
;  dw ? ; reserved,is there a new center of gravity to calculate? (leave blank)
;       ; you could force this value to 1 (centroid in equ.inc) if you  wanted
;       ; to have a new centroid calculated with the iteration.
;  dw x,y,z ; new center-of-gravity point.  lets say you want a  subsurface  to
;           ; be offset by a certin spacial location, you can set these 3 words
;           ; to be "added" to any points you  are  adding  to  the  sub-object
;           ; listen bub, just mess around with it and you'll get  the  idea...
;  dw #     ; new load object offset for matrix compounding - this is only used
;           ; if the sub-object has a new matrix. (for rotation). commands like
;           ; matrix and sub_object access this word to determine where  in the
;           ; object lists (xs,ys,zs,_xadds,_zadds...) to get the  location and
;           ; rotation information about  the  sub-object.  check out the block
;           ; with the two smaller rotating  blocks  and  then look in main.asm
;           ; to figure out how to use this.  usual  values are 1 or 2, maybe 3
;           ; up to the number of extra sub_objects you've got.
;  dw #     ; connection data addition value.  this value  gets  added  to  the
;           ; connection data. eg: lets say you've got an object that starts at
;           ; point 3 and goes to 12, but you want to make it into a sub_object
;           ; (part of something larger) and you  want to change the connection
;           ; data to have a range of 25 to  36.  just put the value 22 in here
;           ; and all connection  data  within the object (and all sub_objects,
;           ; even in  sub_objects  within  sub_objects)  will  have this value
;           ; added to it.  this is usefull for, lets say,  making  a formation
;           ; of airplanes one big object instead  of  drawing  each individual
;           ; airplane. (if by some freak accident you wanted to do that)
;  dd #     ; maximum distance object can be seen (maxz)
;  dd #     ; minimum distance object can be seen (minz) - this can be negative
;           ; if you want.  but if it is  negative,  the  entire   object  must
;           ; be made up of sub-objects.  If these are left at zero, they  will
;           ; be forced to good values (_pre_cal_lambert does this).
;  dd #     ; screen tolerancing.  this is used to determine how  far  off  the
;           ; screen an object will remain visable.  past this, the object will
;           ; not be drawn.  try 1, then try 500. you'll  get  the  idea.  (get
;           ; close to the object.) if this is left  blank,  a  value  will  be
;           ; placed in for you.
;  dw 11 dup 0 ; future use bytes
;
; To re-cap, the 25 word header looks like this:
;
;offset         쿹ength&type    쿭escription
;컴컴컴컴컴컴컴컵컴컴컴컴컴컴컴컵컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; 0             �1 word (resrvd)쿽ffset to next iteration (skip entire iteration)
; 2             �1 word (resrvd)쿻umber of points in entire iteration
; 4             �1 word (resrvd)쿬entroid flag (bit 0)
;
; 6             �3 words x,y,z  쿻ew centroid for points (and all following iterations!)
; 12            �1 word         �"new object angle" matrix load location (from _vxs[],_vys[]... (single,eg: 1,2,3...)
; 14            �1 word         쿬onnection data addition value (can be negative!)
; 16            �1 dword        쿺aximum distance object can be seen (maxz)
; 20            �1 dword        쿺inimum distance object can be seen (minz)
; 24            �1 dword        퀂creen tolerancing
;               �               �
; 28            �11 words       쿯uture use
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

headercube1 dd -1
         dd offset cube1a - offset $ - 4

cube1a   dw 8                               ; how many points
         dw 6                               ; how many surfaces
         dw 25 dup (0)                      ; future use
         ;    x   y   z
         dw -270, 270, 270                  ;1
         dw -270,-270, 270                  ;2
         dw 270,-270, 270                   ;3
         dw 270, 270, 270                   ;4
         dw -270, 270,-270                  ;5
         dw -270,-270,-270                  ;6
         dw 270,-270,-270                   ;7
         dw 270, 270,-270                   ;8

         dw 0,0,0,16*8+12 ,0 ,1,2,3,4,1     ; surface connection data, and colours
         dw 0,wavey,0,16*7+6 ,0 ,8,7,6,5,8  ; end point=start point means done side
         dw 0,wavey,0,16*3+9 ,0 ,4,3,7,8,4
         dw 0,shade,0,16*5+0 ,0 ,5,6,2,1,5 ,0,0,0 ;<-- _lambert shading
         dw 0,shade,0,16*2+0 ,0 ,5,1,4,8,5 ,0,0,0 ;<-- normal gets shoved
         dw 0,shade,0,16*11+0 ,0 ,2,6,7,3,2 ,0,0,0 ;<-- here, leave blank

headercube2 dd -1
         dd offset cube2a - offset $ - 4

cube2a   dw 8                               ; how many points
         dw 9                               ; how many surfaces
         dw 25 dup (0)
         ;    x   y   z
         dw -270, 270, 270                  ;1
         dw -270,-270, 270                  ;2
         dw 270,-270, 270                   ;3
         dw 270, 270, 270                   ;4
         dw -270, 270,-270                  ;5
         dw -270,-270,-270                  ;6
         dw 270,-270,-270                   ;7
         dw 270, 270,-270                   ;8

         dw double,shade,wavey,16*4+0,16*6,1,2,3,4,1,0,0,0 ; command,txt1,txt2,col1,col2, surface connection data
         dw 0,0,0,16*2+4 ,0,6,2,6           ; end point=start point means done side
         dw 0,0,0,16*2+15,0,7,3,7           ; <-- these are lines
         dw 0,0,0,16*2+12,0,8,4,8
         dw 0,0,0,16*3+8 ,0,5,1,5
         dw 0,0,0,16*4+10,0,6,7,6
         dw 0,0,0,16*3+14,0,7,8,7
         dw 0,0,0,16*7+13,0,8,5,8
         dw 0,0,0,16*5+12,0,5,6,5

headercube3 dd 4000
         dd offset cube3a - offset $ - 4
         dd -1
         dd offset cube3b - offset $ - 4

cube3a   dw 44                              ; how many points
         dw 45                              ; how many surfaces
         dw 25 dup (0)                      ; future use
         ;    x   y   z
         dw -70, 70, 70                     ;1
         dw -70, 70, 35                     ;2
         dw -70, 70, 0                      ;3
         dw -70, 70,-35                     ;4

         dw -70,-70, 70                     ;5
         dw -70,-70, 35                     ;6
         dw -70,-70, 0                      ;7
         dw -70,-70,-35                     ;8

         dw 70,-70, 70                      ;9
         dw 70,-70, 35                      ;10
         dw 70,-70, 0                       ;11
         dw 70,-70,-35                      ;12

         dw 70, 70, 70                      ;13
         dw 70, 70, 35                      ;14
         dw 70, 70, 0                       ;15
         dw 70, 70,-35                      ;16

         dw -70, 70,-70                     ;17
         dw -70, 35,-70                     ;18
         dw -70, 0,-70                      ;19
         dw -70,-35,-70                     ;20
         dw -70,-70,-70                     ;21

         dw 70, 70,-70                      ;22
         dw 70, 35,-70                      ;23
         dw 70, 0,-70                       ;24
         dw 70,-35,-70                      ;25
         dw 70,-70,-70                      ;26

         dw -70, 35, 70                     ;27
         dw -70, 0, 70                      ;28
         dw -70,-35, 70                     ;29

         dw 70, 35, 70                      ;30
         dw 70, 0, 70                       ;31
         dw 70,-35, 70                      ;32

         dw -35,-70, 70                     ;33
         dw 0,-70, 70                       ;34
         dw 35,-70, 70                      ;35

         dw -35,-70,-70                     ;36
         dw 0,-70,-70                       ;37
         dw 35,-70,-70                      ;38

         dw -35, 70,-70                     ;39
         dw 0, 70,-70                       ;40
         dw 35, 70,-70                      ;41

         dw -35, 70, 70                     ;42
         dw 0, 70, 70                       ;43
         dw 35, 70, 70                      ;44

         dw himap,01,0,2,2
         dw himap,02,0,2,2
         dw himap,03,0,2,2
         dw himap,04,0,2,2
         dw himap,05,0,2,2
         dw himap,06,0,2,2
         dw himap,07,0,2,2
         dw himap,08,0,2,2
         dw himap,09,0,2,2
         dw himap,10,0,2,2
         dw himap,11,0,2,2
         dw himap,12,0,2,2
         dw himap,13,0,2,2
         dw himap,14,0,2,2
         dw himap,15,0,2,2
         dw himap,16,0,2,2
         dw himap,17,0,2,2
         dw himap,18,0,2,2
         dw himap,19,0,2,2
         dw himap,20,0,2,2
         dw himap,21,0,2,2
         dw himap,22,0,2,2
         dw himap,23,0,2,2
         dw himap,24,0,2,2
         dw himap,25,0,2,2
         dw himap,26,0,2,2
         dw himap,27,0,2,2
         dw himap,28,0,2,2
         dw himap,29,0,2,2
         dw himap,30,0,2,2
         dw himap,31,0,2,2
         dw himap,32,0,2,2
         dw himap,33,0,2,2
         dw himap,34,0,2,2
         dw himap,35,0,2,2
         dw himap,36,0,2,2
         dw himap,37,0,2,2
         dw himap,38,0,2,2
         dw himap,39,0,2,2
         dw himap,40,0,2,2
         dw himap,41,0,2,2
         dw himap,42,0,2,2
         dw himap,43,0,2,2
         dw himap,44,0,2,2 

         dw himap,0,0,30,30                 ; center, change to lomap and see!

cube3b   dw 44                              ; this is same as above but since _bitmaps can't be seen
         dw 44                              ; from far, i use the same cube with points instead.
         dw 25 dup (0)                      ; future use
         ;    x   y   z
         dw -70, 70, 70                     ;1  ; this is an example of how to use the
         dw -70, 70, 35                     ;2  ; different resolutions based on distance
         dw -70, 70, 0                      ;3  ; you could get rid of half of these points
         dw -70, 70,-35                     ;4  ; and still have it "look" the same because

         dw -70,-70, 70                     ;5  ; of the great distance at which this will
         dw -70,-70, 35                     ;6  ; be seen
         dw -70,-70, 0                      ;7
         dw -70,-70,-35                     ;8

         dw 70,-70, 70                      ;9
         dw 70,-70, 35                      ;10
         dw 70,-70, 0                       ;11
         dw 70,-70,-35                      ;12

         dw 70, 70, 70                      ;13
         dw 70, 70, 35                      ;14
         dw 70, 70, 0                       ;15
         dw 70, 70,-35                      ;16

         dw -70, 70,-70                     ;17
         dw -70, 35,-70                     ;18
         dw -70, 0,-70                      ;19
         dw -70,-35,-70                     ;20
         dw -70,-70,-70                     ;21

         dw 70, 70,-70                      ;22
         dw 70, 35,-70                      ;23
         dw 70, 0,-70                       ;24
         dw 70,-35,-70                      ;25
         dw 70,-70,-70                      ;26

         dw -70, 35, 70                     ;27
         dw -70, 0, 70                      ;28
         dw -70,-35, 70                     ;29

         dw 70, 35, 70                      ;30
         dw 70, 0, 70                       ;31
         dw 70,-35, 70                      ;32

         dw -35,-70, 70                     ;33
         dw 0,-70, 70                       ;34
         dw 35,-70, 70                      ;35

         dw -35,-70,-70                     ;36
         dw 0,-70,-70                       ;37
         dw 35,-70,-70                      ;38

         dw -35, 70,-70                     ;39
         dw 0, 70,-70                       ;40
         dw 35, 70,-70                      ;41

         dw -35, 70, 70                     ;42
         dw 0, 70, 70                       ;43
         dw 35, 70, 70                      ;44

         dw 0,0,0,28,0, 01,01
         dw 0,0,0,28,0, 02,02
         dw 0,0,0,28,0, 03,03
         dw 0,0,0,28,0, 04,04
         dw 0,0,0,28,0, 05,05
         dw 0,0,0,28,0, 06,06
         dw 0,0,0,28,0, 07,07
         dw 0,0,0,28,0, 08,08
         dw 0,0,0,28,0, 09,09
         dw 0,0,0,28,0, 10,10
         dw 0,0,0,28,0, 11,11
         dw 0,0,0,28,0, 12,12
         dw 0,0,0,28,0, 13,13
         dw 0,0,0,28,0, 14,14
         dw 0,0,0,28,0, 15,15
         dw 0,0,0,28,0, 16,16
         dw 0,0,0,28,0, 17,17
         dw 0,0,0,28,0, 18,18
         dw 0,0,0,28,0, 19,19
         dw 0,0,0,28,0, 20,20
         dw 0,0,0,28,0, 21,21
         dw 0,0,0,28,0, 22,22
         dw 0,0,0,28,0, 23,23
         dw 0,0,0,28,0, 24,24
         dw 0,0,0,28,0, 25,25
         dw 0,0,0,28,0, 26,26
         dw 0,0,0,28,0, 27,27
         dw 0,0,0,28,0, 28,28
         dw 0,0,0,28,0, 29,29
         dw 0,0,0,28,0, 30,30
         dw 0,0,0,28,0, 31,31
         dw 0,0,0,28,0, 32,32
         dw 0,0,0,28,0, 33,33
         dw 0,0,0,28,0, 34,34
         dw 0,0,0,28,0, 35,35
         dw 0,0,0,28,0, 36,36
         dw 0,0,0,28,0, 37,37
         dw 0,0,0,28,0, 38,38
         dw 0,0,0,28,0, 39,39
         dw 0,0,0,28,0, 40,40
         dw 0,0,0,28,0, 41,41
         dw 0,0,0,28,0, 42,42
         dw 0,0,0,28,0, 43,43
         dw 0,0,0,28,0, 44,44

         dw himap,0,0,30,30                 ; 0 = center of object

headerring dd -1
         dd offset ringa - offset $ - 4

ringa    dw 32
         dw 32
         dw 25 dup (0)                      ; future use
         ;    x   y   z
         dw -40*4, 80*4, 30*4               ; 1
         dw -80*4, 40*4, 30*4               ; 2
         dw -80*4,-40*4, 30*4               ; 3
         dw -40*4,-80*4, 30*4               ; 4
         dw 40*4,-80*4, 30*4                ; 5
         dw 80*4,-40*4, 30*4                ; 6
         dw 80*4, 40*4, 30*4                ; 7
         dw 40*4, 80*4, 30*4                ; 8
         dw -40*4, 20*4, 45*4               ; 9
         dw -40*4,-20*4, 45*4               ;10
         dw -20*4,-40*4, 45*4               ;11
         dw 20*4,-40*4, 45*4                ;12
         dw 40*4,-20*4, 45*4                ;13
         dw 40*4, 20*4, 45*4                ;14
         dw 20*4, 40*4, 45*4                ;15
         dw -20*4, 40*4, 45*4               ;16
         dw -40*4, 80*4,-30*4               ;17
         dw -80*4, 40*4,-30*4               ;18
         dw -80*4,-40*4,-30*4               ;19
         dw -40*4,-80*4,-30*4               ;20
         dw 40*4,-80*4,-30*4                ;21
         dw 80*4,-40*4,-30*4                ;22
         dw 80*4, 40*4,-30*4                ;23
         dw 40*4, 80*4,-30*4                ;24
         dw -40*4, 20*4,-45*4               ;25
         dw -40*4,-20*4,-45*4               ;26
         dw -20*4,-40*4,-45*4               ;27
         dw 20*4,-40*4,-45*4                ;28
         dw 40*4,-20*4,-45*4                ;29
         dw 40*4, 20*4,-45*4                ;30
         dw 20*4, 40*4,-45*4                ;31
         dw -20*4, 40*4,-45*4               ;32

         dw 0,shade,0,16*4+0,0 ,2,9,16,1,2 ,0,0,0 ; these  zeros   get   filled
         dw 0,shade,0,16*4+0,0 ,3,10,9,2,3 ,0,0,0 ; with the calculated surface
         dw 0,shade,0,16*4+0,0 ,4,11,10,3,4 ,0,0,0 ; normal.  we could calculate
         dw 0,shade,0,16*4+0,0 ,5,12,11,4,5 ,0,0,0 ; them ourselves but god, too
         dw 0,shade,0,16*4+0,0 ,6,13,12,5,6 ,0,0,0 ; much work.
         dw 0,shade,0,16*4+0,0 ,7,14,13,6,7 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,8,15,14,7,8 ,0,0,0 ; remember, if you remove  the
         dw 0,shade,0,16*4+0,0 ,1,16,15,8,1 ,0,0,0 ; shading parameter  then  you
         dw 0,shade,0,16*4+0,0 ,1,17,18,2,1 ,0,0,0 ; must remove these 0's
         dw 0,shade,0,16*4+0,0 ,2,18,19,3,2 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,3,19,20,4,3 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,4,20,21,5,4 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,5,21,22,6,5 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,6,22,23,7,6 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,7,23,24,8,7 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,8,24,17,1,8 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,10,26,25,9,10 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,11,27,26,10,11 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,12,28,27,11,12 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,13,29,28,12,13 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,14,30,29,13,14 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,15,31,30,14,15 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,15,16,32,31,15 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,32,16,9,25,32 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,18,25,26,19,18 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,19,26,27,20,19 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,20,27,28,21,20 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,21,28,29,22,21 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,22,29,30,23,22 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,23,30,31,24,23 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,24,31,32,17,24 ,0,0,0
         dw 0,shade,0,16*4+0,0 ,17,32,25,18,17 ,0,0,0

headerdiamond dd -1
         dd offset diamonda - offset $ - 4

diamonda dw 13
         dw 17
         dw 25 dup (0)                      ; future use

         dw -100*4, 50*4, 0
         dw -100*4, -50*4, 0
         dw -50*4,-100*4, 0
         dw 50*4,-100*4, 0
         dw 100*4, -50*4, 0
         dw 100*4, 50*4, 0
         dw 50*4, 100*4, 0
         dw -50*4, 100*4, 0
         dw -50*4, 50*4, 40*4
         dw -50*4, -50*4, 40*4
         dw 50*4, -50*4, 40*4
         dw 50*4, 50*4, 40*4
         dw 0*4, 0*4,-120*4

         dw both,shade+glenz,0,32,0 ,1,2,10,9,1,0,0,0
         dw both,shade+glenz,0,32,0 ,10,3,4,11,10,0,0,0
         dw both,shade+glenz,0,32,0 ,12,11,5,6,12,0,0,0
         dw both,shade+glenz,0,32,0 ,8,9,12,7,8,0,0,0
         dw both,shade+glenz,0,32,0 ,2,3,10,2,0,0,0
         dw both,shade+glenz,0,32,0 ,11,4,5,11,0,0,0
         dw both,shade+glenz,0,32,0 ,7,12,6,7,0,0,0
         dw both,shade+glenz,0,32,0 ,1,9,8,1,0,0,0
         dw both,shade+glenz,0,32,0 ,9,10,11,12,9,0,0,0
         dw both,shade+glenz,0,32,0 ,8,13,1,8,0,0,0
         dw both,shade+glenz,0,32,0 ,1,13,2,1,0,0,0
         dw both,shade+glenz,0,32,0 ,2,13,3,2,0,0,0
         dw both,shade+glenz,0,32,0 ,3,13,4,3,0,0,0
         dw both,shade+glenz,0,32,0 ,4,13,5,4,0,0,0
         dw both,shade+glenz,0,32,0 ,5,13,6,5,0,0,0
         dw both,shade+glenz,0,32,0 ,6,13,7,6,0,0,0
         dw both,shade+glenz,0,32,0 ,7,13,8,7,0,0,0

headerrubine dd -1
         dd offset rubinea - offset $ - 4

rubinea  dw 16
         dw 20                              ; 18 sides + 1 gosub + 1 return
         dw 25 dup (0)                      ; future use

         dw -100*4, 50*4, 0*4               ; 1
         dw -100*4, -50*4, 0*4              ; 2
         dw -50*4,-100*4, 0*4               ; 3
         dw 50*4,-100*4, 0*4                ; 4
         dw 100*4, -50*4, 0*4               ; 5
         dw 100*4, 50*4, 0*4                ; 6
         dw 50*4, 100*4, 0*4                ; 7
         dw -50*4, 100*4, 0*4               ; 8
         dw -50*4, 50*4, 40*4               ; 9
         dw -50*4, -50*4, 40*4              ;10
         dw 50*4, -50*4, 40*4               ;11
         dw 50*4, 50*4, 40*4                ;12
         dw -50*4, 50*4, -40*4              ;13
         dw -50*4, -50*4, -40*4             ;14
         dw 50*4, -50*4, -40*4              ;15
         dw 50*4, 50*4, -40*4               ;16

         dw 0,shade,0,32+0,0 ,1,2,10,9,1 ,0,0,0 ; these surfaces are tested 1st
         dw 0,shade,0,32+0,0 ,10,3,4,11,10 ,0,0,0
         dw 0,shade,0,32+0,0 ,12,11,5,6,12 ,0,0,0
         dw 0,shade,0,32+0,0 ,8,9,12,7,8 ,0,0,0
         dw 0,shade,0,32+0,0 ,2,3,10,2 ,0,0,0

         dw gosub,offset example_of_a_subroutine - offset $

         dw 0,shade,0,32+0,0 ,11,4,5,11 ,0,0,0 ; these surfaces are tested last
         dw 0,shade,0,32+0,0 ,7,12,6,7 ,0,0,0
         dw 0,shade,0,32+0,0 ,1,9,8,1 ,0,0,0
         dw 0,shade,0,32+0,0 ,9,10,11,12,9 ,0,0,0
         dw 0,shade,0,32+0,0 ,6,5,15,16,6 ,0,0,0
         dw 0,shade,0,32+0,0 ,15,4,3,14,15 ,0,0,0 ; object exits here...

example_of_a_subroutine:
         dw 0,shade,0,32+0,0 ,16,15,14,13,16 ,0,0,0 ; these surfaces are tested 2nd
         dw 0,shade,0,32+0,0 ,13,14,2,1,13 ,0,0,0
         dw 0,shade,0,32+0,0 ,7,16,13,8,7 ,0,0,0
         dw 0,shade,0,32+0,0 ,5,4,15,5 ,0,0,0
         dw 0,shade,0,32+0,0 ,14,3,2,14 ,0,0,0
         dw 0,shade,0,32+0,0 ,8,13,1,8 ,0,0,0
         dw 0,shade,0,32+0,0 ,6,16,7,6 ,0,0,0
         dw return

; This  object  is  an  example   of   how   to  use  the  iteration  command.
; Notice how  there  are  only   6 main  surfaces  and  then  5  sub  surfaces.
; If the main surface is not visible,then the sub surfaces are totally skipped.
; _pre_cal_lambert calculates the code offsets in case side is not visible,  but
; I have provided a few to give you an example of what _pre_cal_lambert will do.

; This demonstrates only one level of iteration, you can have as  many
; levels as you want.  Notice how sub iterations are written just like
; main objects.

; Concave surfaces work well when put inside iterations (saves cpu time), but
; convex surfaces don't work well. eg, insides  of  volcanos  are  great  for
; cutting cpu time, but exterior things like rooftop buildings must  be  done
; seperatly (Hint - Inlay the rooftop building below the edge of the roof and
; you can now have the building and all the stuff on the roof in a iteration)

; Iterations save MEGA cpu time!!!

         align 4

headercube4 dd -1                           ; -1=end flag (last resolution)
         dd offset cube4a - offset $ - 4

cube4a   dw 8                               ; how many points
         dw 6                               ; how many surfaces
         dw 25 dup (0)                      ; future use
         ;    x   y   z
         dw -70*4, 70*4, 70*4               ;1 ; the main cube (defines exterior for checking)
         dw -70*4,-70*4, 70*4               ;2
         dw 70*4,-70*4, 70*4                ;3
         dw 70*4, 70*4, 70*4                ;4
         dw -70*4, 70*4,-70*4               ;5
         dw -70*4,-70*4,-70*4               ;6
         dw 70*4,-70*4,-70*4                ;7
         dw 70*4, 70*4,-70*4                ;8

         dw check+iterate,0,0,0,0,1,2,3,1   ; test main surface, dont plot, just check dot product

         dw 4                               ; 4 extra points if visible    (for this iteration, doesn't
         dw 5                               ; 5 extra surfaces if visible   include iterations of iterations)

         dw 0                               ; reserved for offset of new startup location if failure - directs code to next valid surface
         dw 0                               ; reserved for TOTAL number of points to skip if failure - ends up as 4, number of points within iteration

         dw 23 dup (0)                      ; for future use

         ;    x   y   z
         dw -45*4, 45*4, 70*4               ; 9
         dw -45*4,-45*4, 70*4               ;10
         dw 45*4,-45*4, 70*4                ;11
         dw 45*4, 45*4, 70*4                ;12

         ; these sides are always visible (both) because the above  check
         ; confirmed the dot product.  setting "both" option saves time for
         ; checking each surface because the main surface was  visible.
         ; this saves 2 imuls per surface. eg: check the  main  surface
         ; for visibility and all sub surfaces must also be visible.

         dw both,glow ,0, 16*4+0,0,9,10,11,12,9, 0,0,0 ; glow is inverse gouraud shading, what the heck, lets get creative...
         dw both,shade,0, 16*3+0,0,1,2,10,9,1 ,0,0,0
         dw both,last ,0, 16*3+0,0,2,3,11,10,2 ; last = use previous colour (uses gourad)
         dw both,last ,0, 16*3+0,0,3,4,12,11,3 ; previous surface must always
         dw both,last ,0, 16*3+0,0,4,1,9,12,4 ; be visible if this is used

         dw check+iterate,0,0,0,0 ,8,7,6,8  ; testing visibility only requires a triangle, not whole surface

         dw 4                               ; same as above but different points used...
         dw 5

         dw 25 dup (0)

         ;    x   y   z
         dw -45*4, 45*4,-70*4               ;13
         dw -45*4,-45*4,-70*4               ;14
         dw 45*4,-45*4,-70*4                ;15
         dw 45*4, 45*4,-70*4                ;16

         dw both,glow ,0,16*2+0,0,13,16,15,14,13, 0,0,0
         dw both,shade,0,16*7+0,0,5,13,14,6,5 , 0,0,0
         dw both,last ,0,16*7+0,0,6,14,15,7,6
         dw both,last ,0,16*7+0,0,7,15,16,8,7
         dw both,last ,0,16*7+0,0,8,16,13,5,8

         dw check+iterate,0,0,0,0 ,4,3,7,4

         dw 4                               ; concave side, notice how I use the commands below because
         dw 5                               ; we know this side is concave.

         dw 25 dup (0)

         ;    x   y   z
         dw 30*4, 45*4, 45*4                ;17 - make x=70 and plane will be flat
         dw 30*4,-45*4, 45*4                ;18
         dw 30*4,-45*4,-45*4                ;19
         dw 30*4, 45*4,-45*4                ;20

         dw both,shade,0,16*6+0,0 ,17,18,19,20,17, 0,0,0
         dw 0, shade,0,16*9+0,0 ,4,3,18,17,4, 0,0,0 ; <-commands here, i have removed
         dw 0, shade,0,16*9+0,0 ,3,7,19,18,3, 0,0,0 ; "both", 'cause these sides are not
         dw 0, shade,0,16*9+0,0 ,8,20,19,7,8, 0,0,0 ; on the same plane as the original
         dw 0, shade,0,16*9+0,0 ,8,4,17,20,8, 0,0,0 ; iteration check

         dw check+iterate,0,0,0,0 ,5,6,2,5

         dw 4                               ; another concave side
         dw 5

         dw 25 dup (0)

         ;    x   y   z
         dw -30*4, 45*4, 45*4               ;21 ; points are accumulated from original.
         dw -30*4,-45*4, 45*4               ;22 ; eg: <-this point will always be point #22
         dw -30*4,-45*4,-45*4               ;23 ; regardless of whether the above iterations
         dw -30*4, 45*4,-45*4               ;24 ; were processed.

         dw both,shade,0, 16* 2+0,0,21,24,23,22,21, 0,0,0
         dw 0 ,shade,0, 16* 8+0,0,1,21,22,2,1, 0,0,0
         dw 0 ,shade,0, 16* 8+0,0,5,24,21,1,5, 0,0,0
         dw 0 ,shade,0, 16* 8+0,0,6,23,24,5,6, 0,0,0
         dw 0 ,shade,0, 16* 8+0,0,6,2,22,23,6, 0,0,0

         dw check+iterate,0,0,0,0 ,5,1,4,5

         dw 4
         dw 5

         dw 25 dup (0)

         ;    x   y   z
         dw -45*4, 70*4,-45*4               ;25
         dw -45*4, 70*4, 45*4               ;26
         dw 45*4, 70*4, 45*4                ;27
         dw 45*4, 70*4,-45*4                ;28

         dw both,glow ,0, 16*2+0,0,25,26,27,28,25, 0,0,0
         dw both,shade ,0, 16*3+0,0,5,1,26,25,5, 0,0,0
         dw both,last ,0, 16*3+0,0,1,4,27,26,1
         dw both,last ,0, 16*3+0,0,4,8,28,27,4
         dw both,last ,0, 16*3+0,0,8,5,25,28,8

         dw check+iterate,0,0,0,0 ,2,6,7,2

         dw 4
         dw 5

         dw 25 dup (0)

         ;    x   y   z
         dw -45*4,-70*4,-45*4               ;29
         dw -45*4,-70*4, 45*4               ;30
         dw 45*4,-70*4, 45*4                ;31
         dw 45*4,-70*4,-45*4                ;32

         dw both,glow ,0,16*5 +0,0,29,32,31,30,29, 0,0,0
         dw both,shade,0,16*2 +0,0,6,29,30,2,6, 0,0,0
         dw both,last ,0,16*2 +0,0,2,30,31,3,2
         dw both,last ,0,16*2 +0,0,3,31,32,7,3
         dw both,last ,0,16*2 +0,0,7,32,29,6,7

         align 4

headerarm dd -1
         dd offset cheaparma - offset $ - 4

cheaparma dw 8                              ; how many points
         dw 12                              ; how many surfaces
         dw 25 dup (0)                      ; future use
         ;    x   y   z
         dw -70*4, 25*4, 110*4              ;1
         dw -70*4,-25*4, 110*4              ;2
         dw 70*4,-25*4, 110*4               ;3
         dw 70*4, 25*4, 110*4               ;4
         dw -70*4, 25*4,-110*4              ;5
         dw -70*4,-25*4,-110*4              ;6
         dw 70*4,-25*4,-110*4               ;7
         dw 70*4, 25*4,-110*4               ;8

         dw normal,shade+mesh,0,16*6 ,0 ,1,2,3,4,1 ,0,0,0
         dw normal,shade+mesh,0,16*6 ,0 ,8,7,6,5,8 ,0,0,0
         dw normal,shade+mesh,0,16*6 ,0 ,4,3,7,8,4 ,0,0,0
         dw normal,shade+mesh,0,16*6 ,0 ,5,6,2,1,5 ,0,0,0
         dw normal,shade+mesh,0,16*6 ,0 ,5,1,4,8,5 ,0,0,0
         dw normal,shade+mesh,0,16*6 ,0 ,2,6,7,3,2 ,0,0,0
         dw push_location
         dw push_matrix
         dw sub_object                      ; this is the same as dw matrix+check+iterate+both,0,0,0,0,0,0

         dw 8                               ; how many points
         dw 6                               ; how many surfaces

         dw 0,0                             ; reserved, offset of total skip, number of points to skip
         dw 0                               ; flag, +1=is there a point offset below0
         dw 100,520,0                       ; point offset
         dw 1                               ; new matrix load location
         dw 9                               ; point addition for connection data (all points are now point+8, eg 1+8,2+8...)
         dd 5000000                         ; maximum distance object is seen
         dd 200                             ; minimum distance object is seen
         dd 300                             ; tolerancing for x/y max/min

         dw 11 dup (0)                      ; future use
         ;    x   y   z
         dw -35*4, 30*4, 30*4               ;10
         dw -35*4,-30*4, 30*4               ;11
         dw 20*4,-30*4, 30*4                ;12
         dw 20*4, 30*4, 30*4                ;13
         dw -35*4, 20*4,-20*4               ;14
         dw -35*4,-20*4,-20*4               ;15
         dw 40*4,-20*4,-20*4                ;16
         dw 40*4, 20*4,-20*4                ;17

         dw normal,shade,0,16*4 ,0 ,1,2,3,4,1 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,8,7,6,5,8 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,4,3,7,8,4 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,5,6,2,1,5 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,5,1,4,8,5 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,2,6,7,3,2 ,0,0,0

         dw pop_matrix
         dw pop_location
         dw sub_object                      ; this is the same as dw matrix+check+iterate+both,0,0,0,0,0,0

         dw 8                               ; how many points
         dw 6                               ; how many surfaces

         dw 0,0                             ; reserved
         dw 0                               ; reserved
         dw -100,-530,0                     ; point offset
         dw 2                               ; new matrix load location
         dw 18                              ; connection addition (base)

         dw 17 dup (0)                      ; future use
         ;    x   y   z
         dw -40*4, 40*4, 30*4               ;19
         dw -40*4,-40*4, 30*4               ;20
         dw 20*4,-40*4, 30*4                ;21
         dw 20*4, 40*4, 30*4                ;21
         dw -30*4, 20*4,-50*4               ;22
         dw -30*4,-20*4,-50*4               ;23
         dw 40*4,-20*4,-50*4                ;24
         dw 40*4, 20*4,-50*4                ;25

         dw normal,shade,0,16*8 ,0 ,1,2,3,4,1 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,8,7,6,5,8 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,4,3,7,8,4 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,5,6,2,1,5 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,5,1,4,8,5 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,2,6,7,3,2 ,0,0,0

; This is the same object as the boxes above but without  the  main  box.
; notice how it starts with 0 points!  the entire object simply points to
; other sub-objects.

headerarm2 dd -1
         dd offset cheaparma2 - offset $ - 4

cheaparma2 dw 0                             ; how many points
         dw 6                               ; how many surfaces
         dw 25 dup (0)                      ; future use

         dw push_location
         dw push_matrix
         dw sub_object                      ; this is the same as dw matrix+check+iterate,0,0,0,0,0,0

         dw 8                               ; how many points
         dw 6                               ; how many surfaces

         dw 0,0                             ; reserved, offset of total skip, number of points to skip
         dw 0                               ; flag, +1=is there a point offset below0
         dw 20,130,0                        ; point offset
         dw 1                               ; new matrix load location
         dw 1

         dw 17 dup (0)                      ; future use
         ;    x   y   z
         dw -35, 30, 30                     ;2
         dw -35,-30, 30                     ;3
         dw 20,-30, 30                      ;4
         dw 20, 30, 30                      ;5
         dw -35, 20,-20                     ;6
         dw -35,-20,-20                     ;7
         dw 40,-20,-20                      ;8
         dw 40, 20,-20                      ;9

         dw normal,shade,0,16*4 ,0 ,1+0,2+0,3+0,4+0,1+0 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,8+0,7+0,6+0,5+0,8+0 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,4+0,3+0,7+0,8+0,4+0 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,5+0,6+0,2+0,1+0,5+0 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,5+0,1+0,4+0,8+0,5+0 ,0,0,0
         dw normal,shade,0,16*4 ,0 ,2+0,6+0,7+0,3+0,2+0 ,0,0,0

         dw pop_matrix
         dw pop_location
         dw sub_object                      ; this is the same as dw matrix+check+iterate,0,0,0,0,0,0

         dw 8                               ; how many points
         dw 6                               ; how many surfaces

         dw 0,0                             ; reserved
         dw 0
         dw 20,-120,0                       ; point offset
         dw 2                               ; new matrix load location
         dw 2

         dw 17 dup (0)                      ; future use
         ;    x   y   z
         dw -40, 40, 30                     ;11
         dw -40,-40, 30                     ;12
         dw 20,-40, 30                      ;13
         dw 20, 40, 30                      ;14
         dw -30, 20,-50                     ;15
         dw -30,-20,-50                     ;16
         dw 40,-20,-50                      ;17
         dw 40, 20,-50                      ;18

         dw normal,shade,0,16*8 ,0 ,1+8*1,2+8*1,3+8*1,4+8*1,1+8*1 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,8+8*1,7+8*1,6+8*1,5+8*1,8+8*1 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,4+8*1,3+8*1,7+8*1,8+8*1,4+8*1 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,5+8*1,6+8*1,2+8*1,1+8*1,5+8*1 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,5+8*1,1+8*1,4+8*1,8+8*1,5+8*1 ,0,0,0
         dw normal,shade,0,16*8 ,0 ,2+8*1,6+8*1,7+8*1,3+8*1,2+8*1 ,0,0,0

archmiddle dd -1
         dd offset arch1 - offset $ - 4

arch1    dw 20
         dw 10
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw 402, 240,-100                   ; 1
         dw 402, 240, 100                   ; 2
         dw 402,-240,-100                   ; 3
         dw 402,-240, 100                   ; 4
         dw -402,-240,-100                  ; 5
         dw -402,-240, 100                  ; 6
         dw -402, 240,-100                  ; 7
         dw -402, 240, 100                  ; 8

         dw -330, 100,-100                  ; 9
         dw -330, 100, 100                  ; 10
         dw -250, 50,-100                   ; 11
         dw -250, 50, 100                   ; 12
         dw -100, 0,-100                    ; 13
         dw -100, 0, 100                    ; 14
         dw 50, 50,-100                     ; 15
         dw 50, 50, 100                     ; 16
         dw 130, 100,-100                   ; 17
         dw 130, 100, 100                   ; 18
         dw 200, 240,-100                   ; 19
         dw 200, 240, 100                   ; 20

         dw iterate+onscr+check,0,0,0,0,1,3,5,7,1

         dw 0
         dw 6
         dw 25 dup (0)

         dw both,0,0,16*6+7,0 ,1,3,17,19,1
         dw both,0,0,16*6+7,0 ,17,3,15,17
         dw both,0,0,16*6+7,0 ,15,3,5,13,15
         dw both,0,0,16*6+7,0 ,13,5,11,13
         dw both,0,0,16*6+7,0 ,11,5,9,11
         dw both,0,0,16*6+7,0 ,9,5,7,9

         dw iterate+onscr+check,0,0,0,0,2,8,6,4,2

         dw 0
         dw 6
         dw 0,0,0,0,0,0,0,1
         dw 17 dup (0)

         dw both,0,0,16*6+14,0 ,1,3,17,19,1
         dw both,0,0,16*6+14,0 ,17,3,15,17
         dw both,0,0,16*6+14,0 ,15,3,5,13,15
         dw both,0,0,16*6+14,0 ,13,5,11,13
         dw both,0,0,16*6+14,0 ,11,5,9,11
         dw both,0,0,16*6+14,0 ,9,5,7,9

         dw 0,0,0,16*6+15,0, 3,4,6,5,3
         dw 0,0,0,16*6+4,0, 1,19,20,2,1

         dw 0,0,0,16*6+13,0, 7,8,10,9,7
         dw 0,0,0,16*6+12,0, 9,10,12,11,9
         dw 0,0,0,16*6+11,0, 11,12,14,13,11
         dw 0,0,0,16*6+ 9,0, 13,14,16,15,13
         dw 0,0,0,16*6+ 7,0, 15,16,18,17,15
         dw 0,0,0,16*6+ 6,0, 17,18,20,19,17

archmiddl6 dd -1
         dd offset arch6 - offset $ - 4

arch6    dw 20
         dw 10
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw -100, 240,-402                  ; 1
         dw 100, 240,-402                   ; 2
         dw -100,-240,-402                  ; 3
         dw 100,-240,-402                   ; 4
         dw -100,-240, 402                  ; 5
         dw 100,-240, 402                   ; 6
         dw -100, 240, 402                  ; 7
         dw 100, 240, 402                   ; 8

         dw -100, 100, 330                  ; 9
         dw 100, 100, 330                   ; 10
         dw -100, 50, 250                   ; 11
         dw 100, 50, 250                    ; 12
         dw -100, 0, 100                    ; 13
         dw 100, 0, 100                     ; 14
         dw -100, 50, -50                   ; 15
         dw 100, 50, -50                    ; 16
         dw -100, 100,-130                  ; 17
         dw 100, 100,-130                   ; 18
         dw -100, 240,-200                  ; 19
         dw 100, 240,-200                   ; 20

         dw iterate+onscr+check,0,0,0,0,1,3,5,7,1

         dw 0
         dw 6
         dw 25 dup (0)

         dw both,0,0,16*6+7,0 ,1,3,17,19,1
         dw both,0,0,16*6+7,0 ,17,3,15,17
         dw both,0,0,16*6+7,0 ,15,3,5,13,15
         dw both,0,0,16*6+7,0 ,13,5,11,13
         dw both,0,0,16*6+7,0 ,11,5,9,11
         dw both,0,0,16*6+7,0 ,9,5,7,9

         dw iterate+onscr+check,0,0,0,0,2,8,6,4,2

         dw 0
         dw 6
         dw 0,0,0,0,0,0,0,1
         dw 17 dup (0)

         dw both,0,0,16*6+14,0 ,1,3,17,19,1
         dw both,0,0,16*6+14,0 ,17,3,15,17
         dw both,0,0,16*6+14,0 ,15,3,5,13,15
         dw both,0,0,16*6+14,0 ,13,5,11,13
         dw both,0,0,16*6+14,0 ,11,5,9,11
         dw both,0,0,16*6+14,0 ,9,5,7,9

         dw 0,0,0,16*6+15,0, 3,4,6,5,3
         dw 0,0,0,16*6+4,0, 1,19,20,2,1

         dw 0,0,0,16*6+13,0, 7,8,10,9,7
         dw 0,0,0,16*6+12,0, 9,10,12,11,9
         dw 0,0,0,16*6+11,0, 11,12,14,13,11
         dw 0,0,0,16*6+ 9,0, 13,14,16,15,13
         dw 0,0,0,16*6+ 7,0, 15,16,18,17,15
         dw 0,0,0,16*6+ 6,0, 17,18,20,19,17

archmiddl3 dd -1
         dd offset arch3 - offset $ - 4

arch3    dw 20
         dw 10
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw -402, 240, 100                  ; 1
         dw -402, 240,-100                  ; 2
         dw -402,-240, 100                  ; 3
         dw -402,-240,-100                  ; 4
         dw 402,-240, 100                   ; 5
         dw 402,-240,-100                   ; 6
         dw 402, 240, 100                   ; 7
         dw 402, 240,-100                   ; 8

         dw 330, 100, 100                   ; 9
         dw 330, 100,-100                   ; 10
         dw 250, 50, 100                    ; 11
         dw 250, 50,-100                    ; 12
         dw 100, 0, 100                     ; 13
         dw 100, 0,-100                     ; 14
         dw -50, 50, 100                    ; 15
         dw -50, 50,-100                    ; 16
         dw -130, 100, 100                  ; 17
         dw -130, 100,-100                  ; 18
         dw -200, 240, 100                  ; 19
         dw -200, 240,-100                  ; 20

         dw iterate+onscr+check,0,0,0,0,1,3,5,7,1

         dw 0
         dw 6
         dw 25 dup (0)

         dw both,0,0,16*6+14,0 ,1,3,17,19,1
         dw both,0,0,16*6+14,0 ,17,3,15,17
         dw both,0,0,16*6+14,0 ,15,3,5,13,15
         dw both,0,0,16*6+14,0 ,13,5,11,13
         dw both,0,0,16*6+14,0 ,11,5,9,11
         dw both,0,0,16*6+14,0 ,9,5,7,9

         dw iterate+onscr+check,0,0,0,0,2,8,6,4,2

         dw 0
         dw 6
         dw 0,0,0,0,0,0,0,1
         dw 17 dup (0)

         dw both,0,0,16*6+7,0 ,1,3,17,19,1
         dw both,0,0,16*6+7,0 ,17,3,15,17
         dw both,0,0,16*6+7,0 ,15,3,5,13,15
         dw both,0,0,16*6+7,0 ,13,5,11,13
         dw both,0,0,16*6+7,0 ,11,5,9,11
         dw both,0,0,16*6+7,0 ,9,5,7,9

         dw 0,0,0,16*6+15,0, 3,4,6,5,3
         dw 0,0,0,16*6+4,0, 1,19,20,2,1

         dw 0,0,0,16*6+ 5,0, 7,8,10,9,7
         dw 0,0,0,16*6+ 6,0, 9,10,12,11,9
         dw 0,0,0,16*6+ 8,0, 11,12,14,13,11
         dw 0,0,0,16*6+10,0, 13,14,16,15,13
         dw 0,0,0,16*6+11,0, 15,16,18,17,15
         dw 0,0,0,16*6+13,0, 17,18,20,19,17

archmiddl4 dd -1
         dd offset arch4 - offset $ - 4

arch4    dw 20
         dw 10
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw 100, 240, 402                   ; 1
         dw -100, 240, 402                  ; 2
         dw 100,-240, 402                   ; 3
         dw -100,-240, 402                  ; 4
         dw 100,-240,-402                   ; 5
         dw -100,-240,-402                  ; 6
         dw 100, 240,-402                   ; 7
         dw -100, 240,-402                  ; 8

         dw 100, 100,-330                   ; 9
         dw -100, 100,-330                  ; 10
         dw 100, 50,-250                    ; 11
         dw -100, 50,-250                   ; 12
         dw 100, 0,-100                     ; 13
         dw -100, 0,-100                    ; 14
         dw 100, 50, 50                     ; 15
         dw -100, 50, 50                    ; 16
         dw 100, 100, 130                   ; 17
         dw -100, 100, 130                  ; 18
         dw 100, 240, 200                   ; 19
         dw -100, 240, 200                  ; 20

         dw iterate+onscr+check,0,0,0,0,1,3,5,7,1

         dw 0
         dw 6
         dw 25 dup (0)

         dw both,0,0,16*6+7,0 ,1,3,17,19,1
         dw both,0,0,16*6+7,0 ,17,3,15,17
         dw both,0,0,16*6+7,0 ,15,3,5,13,15
         dw both,0,0,16*6+7,0 ,13,5,11,13
         dw both,0,0,16*6+7,0 ,11,5,9,11
         dw both,0,0,16*6+7,0 ,9,5,7,9

         dw iterate+onscr+check,0,0,0,0,2,8,6,4,2

         dw 0
         dw 6
         dw 0,0,0,0,0,0,0,1
         dw 17 dup (0)

         dw both,0,0,16*6+14,0 ,1,3,17,19,1
         dw both,0,0,16*6+14,0 ,17,3,15,17
         dw both,0,0,16*6+14,0 ,15,3,5,13,15
         dw both,0,0,16*6+14,0 ,13,5,11,13
         dw both,0,0,16*6+14,0 ,11,5,9,11
         dw both,0,0,16*6+14,0 ,9,5,7,9

         dw 0,0,0,16*6+15,0, 3,4,6,5,3
         dw 0,0,0,16*6+4,0, 1,19,20,2,1

         dw 0,0,0,16*6+13,0, 7,8,10,9,7
         dw 0,0,0,16*6+12,0, 9,10,12,11,9
         dw 0,0,0,16*6+11,0, 11,12,14,13,11
         dw 0,0,0,16*6+ 9,0, 13,14,16,15,13
         dw 0,0,0,16*6+ 7,0, 15,16,18,17,15
         dw 0,0,0,16*6+ 6,0, 17,18,20,19,17

archend  dd -1
         dd offset arch2 - offset $ - 4

arch2    dw 21
         dw 11
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw 402, 240,-100                   ; 1
         dw 402, 240, 100                   ; 2
         dw 402,-240,-100                   ; 3
         dw 402,-240, 100                   ; 4
         dw -402,-240,-100                  ; 5
         dw -402,-240, 100                  ; 6
         dw -402, 240,-100                  ; 7
         dw -402, 240, 100                  ; 8

         dw -330, 100,-100                  ; 9
         dw -330, 100, 100                  ; 10
         dw -250, 50,-100                   ; 11
         dw -250, 50, 100                   ; 12
         dw -100, 0,-100                    ; 13
         dw -100, 0, 100                    ; 14
         dw 50, 50,-100                     ; 15
         dw 50, 50, 100                     ; 16
         dw 130, 100,-100                   ; 17
         dw 130, 100, 100                   ; 18
         dw 200, 240,-100                   ; 19
         dw 200, 240, 100                   ; 20

         dw 200,-240, 100                   ; 21

         dw iterate+onscr+check,0,0,0,0,1,3,5,7,1

         dw 0
         dw 6
         dw 25 dup (0)

         dw both,0,0,16*6+7,0 ,1,3,17,19,1
         dw both,0,0,16*6+7,0 ,17,3,15,17
         dw both,0,0,16*6+7,0 ,15,3,5,13,15
         dw both,0,0,16*6+7,0 ,13,5,11,13
         dw both,0,0,16*6+7,0 ,11,5,9,11
         dw both,0,0,16*6+7,0 ,9,5,7,9

         dw iterate+onscr+check,0,0,0,0,2,8,6,4,2

         dw 0
         dw 6
         dw 0,0,0,0,0,0,0,1
         dw 17 dup (0)

         dw both,0,0,16*6+14,0 ,20,17,19,20
         dw both,0,0,16*6+14,0 ,17,20,15,17
         dw both,0,0,16*6+14,0 ,15,20,5,13,15
         dw both,0,0,16*6+14,0 ,13,5,11,13
         dw both,0,0,16*6+14,0 ,11,5,9,11
         dw both,0,0,16*6+14,0 ,9,5,7,9

         dw 0,0,0,16*6+15,0, 3,4,6,5,3
         dw 0,0,0,16*6+4,0, 1,19,20,2,1
         dw 0,0,0,16*6+7,0, 1,2,4,3,1

         dw 0,0,0,16*6+13,0, 7,8,10,9,7
         dw 0,0,0,16*6+12,0, 9,10,12,11,9
         dw 0,0,0,16*6+11,0, 11,12,14,13,11
         dw 0,0,0,16*6+ 9,0, 13,14,16,15,13
         dw 0,0,0,16*6+ 7,0, 15,16,18,17,15
         dw 0,0,0,16*6+ 6,0, 17,18,20,19,17

column   dd -1
         dd offset colmn1 - offset $ - 4

colmn1   dw 16
         dw 8
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw 32,-450,-80                     ; 1
         dw 80,-450,-32                     ; 2
         dw 80,-450, 32                     ; 3
         dw 32,-450, 80                     ; 4
         dw -32,-450, 80                    ; 5
         dw -80,-450, 32                    ; 6
         dw -80,-450,-32                    ; 7
         dw -32,-450,-80                    ; 8
         dw 32, 450,-80                     ; 9
         dw 80, 450,-32                     ;10
         dw 80, 450, 32                     ;11
         dw 32, 450, 80                     ;12
         dw -32, 450, 80                    ;13
         dw -80, 450, 32                    ;14
         dw -80, 450,-32                    ;15
         dw -32, 450,-80                    ;16

         dw 0,0,0,16*3+ 6,0, 1,8,16,9,1
         dw 0,0,0,16*3+ 8,0, 2,1,9,10,2
         dw 0,0,0,16*3+10,0, 3,2,10,11,3
         dw 0,0,0,16*3+12,0, 4,3,11,12,4
         dw 0,0,0,16*3+14,0, 5,4,12,13,5
         dw 0,0,0,16*3+11,0, 6,5,13,14,6
         dw 0,0,0,16*3+ 9,0, 7,6,14,15,7
         dw 0,0,0,16*3+ 7,0, 8,7,15,16,8

fourdrums dd -1
         dd offset oil4 - offset $ - 4

oil4     dw 0
         dw 4
         dw 25 dup (0)

         dw static_sub_object

         dw 16
         dw 9
         dw 0,0,0
         dw 2000,0,-2000
         dw 0,0
         dw 17 dup (0)

         dw 290,-350,-700                   ; 1
         dw 700,-350,-290                   ; 2
         dw 700,-350, 290                   ; 3
         dw 290,-350, 700                   ; 4
         dw -290,-350, 700                  ; 5
         dw -700,-350, 290                  ; 6
         dw -700,-350,-290                  ; 7
         dw -290,-350,-700                  ; 8
         dw 290, 350,-700                   ; 9
         dw 700, 350,-290                   ;10
         dw 700, 350, 290                   ;11
         dw 290, 350, 700                   ;12
         dw -290, 350, 700                  ;13
         dw -700, 350, 290                  ;14
         dw -700, 350,-290                  ;15
         dw -290, 350,-700                  ;16

         dw 0,0,0,16*2+ 6,0, 1,8,16,9,1
         dw 0,0,0,16*2+ 8,0, 2,1,9,10,2
         dw 0,0,0,16*2+10,0, 3,2,10,11,3
         dw 0,0,0,16*2+12,0, 4,3,11,12,4
         dw 0,0,0,16*2+14,0, 5,4,12,13,5
         dw 0,0,0,16*2+11,0, 6,5,13,14,6
         dw 0,0,0,16*2+ 9,0, 7,6,14,15,7
         dw 0,0,0,16*2+ 7,0, 8,7,15,16,8
         dw 0,0,0,16*2+15,0, 1,2,3,4,5,6,7,8,1

         dw static_sub_object

         dw 16
         dw 9
         dw 0,0,0
         dw 0,0,4000
         dw 0,16
         dw 17 dup (0)

         dw 290,-350,-700                   ; 1
         dw 700,-350,-290                   ; 2
         dw 700,-350, 290                   ; 3
         dw 290,-350, 700                   ; 4
         dw -290,-350, 700                  ; 5
         dw -700,-350, 290                  ; 6
         dw -700,-350,-290                  ; 7
         dw -290,-350,-700                  ; 8
         dw 290, 350,-700                   ; 9
         dw 700, 350,-290                   ;10
         dw 700, 350, 290                   ;11
         dw 290, 350, 700                   ;12
         dw -290, 350, 700                  ;13
         dw -700, 350, 290                  ;14
         dw -700, 350,-290                  ;15
         dw -290, 350,-700                  ;16

         dw 0,0,0,16*2+ 6,0, 1,8,16,9,1
         dw 0,0,0,16*2+ 8,0, 2,1,9,10,2
         dw 0,0,0,16*2+10,0, 3,2,10,11,3
         dw 0,0,0,16*2+12,0, 4,3,11,12,4
         dw 0,0,0,16*2+14,0, 5,4,12,13,5
         dw 0,0,0,16*2+11,0, 6,5,13,14,6
         dw 0,0,0,16*2+ 9,0, 7,6,14,15,7
         dw 0,0,0,16*2+ 7,0, 8,7,15,16,8
         dw 0,0,0,16*2+15,0, 1,2,3,4,5,6,7,8,1

         dw static_sub_object

         dw 16
         dw 9
         dw 0,0,0
         dw -4000,0,0
         dw 0,32
         dw 17 dup (0)

         dw 290,-350,-700                   ; 1
         dw 700,-350,-290                   ; 2
         dw 700,-350, 290                   ; 3
         dw 290,-350, 700                   ; 4
         dw -290,-350, 700                  ; 5
         dw -700,-350, 290                  ; 6
         dw -700,-350,-290                  ; 7
         dw -290,-350,-700                  ; 8
         dw 290, 350,-700                   ; 9
         dw 700, 350,-290                   ;10
         dw 700, 350, 290                   ;11
         dw 290, 350, 700                   ;12
         dw -290, 350, 700                  ;13
         dw -700, 350, 290                  ;14
         dw -700, 350,-290                  ;15
         dw -290, 350,-700                  ;16

         dw 0,0,0,16*2+ 6,0, 1,8,16,9,1
         dw 0,0,0,16*2+ 8,0, 2,1,9,10,2
         dw 0,0,0,16*2+10,0, 3,2,10,11,3
         dw 0,0,0,16*2+12,0, 4,3,11,12,4
         dw 0,0,0,16*2+14,0, 5,4,12,13,5
         dw 0,0,0,16*2+11,0, 6,5,13,14,6
         dw 0,0,0,16*2+ 9,0, 7,6,14,15,7
         dw 0,0,0,16*2+ 7,0, 8,7,15,16,8
         dw 0,0,0,16*2+15,0, 1,2,3,4,5,6,7,8,1

         dw static_sub_object

         dw 16
         dw 9
         dw 0,0,0
         dw 0,0,-4000
         dw 0,48
         dw 17 dup (0)

         dw 290,-350,-700                   ; 1
         dw 700,-350,-290                   ; 2
         dw 700,-350, 290                   ; 3
         dw 290,-350, 700                   ; 4
         dw -290,-350, 700                  ; 5
         dw -700,-350, 290                  ; 6
         dw -700,-350,-290                  ; 7
         dw -290,-350,-700                  ; 8
         dw 290, 350,-700                   ; 9
         dw 700, 350,-290                   ;10
         dw 700, 350, 290                   ;11
         dw 290, 350, 700                   ;12
         dw -290, 350, 700                  ;13
         dw -700, 350, 290                  ;14
         dw -700, 350,-290                  ;15
         dw -290, 350,-700                  ;16

         dw 0,0,0,16*2+ 6,0, 1,8,16,9,1
         dw 0,0,0,16*2+ 8,0, 2,1,9,10,2
         dw 0,0,0,16*2+10,0, 3,2,10,11,3
         dw 0,0,0,16*2+12,0, 4,3,11,12,4
         dw 0,0,0,16*2+14,0, 5,4,12,13,5
         dw 0,0,0,16*2+11,0, 6,5,13,14,6
         dw 0,0,0,16*2+ 9,0, 7,6,14,15,7
         dw 0,0,0,16*2+ 7,0, 8,7,15,16,8
         dw 0,0,0,16*2+15,0, 1,2,3,4,5,6,7,8,1

bigoildrum dd -1
         dd offset oil1 - offset $ - 4

oil1     dw 16
         dw 9
         dw 0,0,0,0,0,0,0,0
         dw 17 dup (0)

         dw 290,-350,-700                   ; 1
         dw 700,-350,-290                   ; 2
         dw 700,-350, 290                   ; 3
         dw 290,-350, 700                   ; 4
         dw -290,-350, 700                  ; 5
         dw -700,-350, 290                  ; 6
         dw -700,-350,-290                  ; 7
         dw -290,-350,-700                  ; 8
         dw 290, 350,-700                   ; 9
         dw 700, 350,-290                   ;10
         dw 700, 350, 290                   ;11
         dw 290, 350, 700                   ;12
         dw -290, 350, 700                  ;13
         dw -700, 350, 290                  ;14
         dw -700, 350,-290                  ;15
         dw -290, 350,-700                  ;16

         dw 0,0,0,16*2+ 6,0, 1,8,16,9,1
         dw 0,0,0,16*2+ 8,0, 2,1,9,10,2
         dw 0,0,0,16*2+10,0, 3,2,10,11,3
         dw 0,0,0,16*2+12,0, 4,3,11,12,4
         dw 0,0,0,16*2+14,0, 5,4,12,13,5
         dw 0,0,0,16*2+11,0, 6,5,13,14,6
         dw 0,0,0,16*2+ 9,0, 7,6,14,15,7
         dw 0,0,0,16*2+ 7,0, 8,7,15,16,8
         dw 0,0,0,16*2+15,0, 1,2,3,4,5,6,7,8,1

         align 4

futurecrewrip1:
         dd -1
         dd offset fcrip1 - offset $ - 4

fcrip1:  dw 17
         dw 12
         dw 25 dup (0)

         dw -200, 130,-200
         dw 200, 130,-200
         dw 200, 130, 200
         dw -200, 130, 200
         dw -110, 0,-110
         dw -55, 5,-110
         dw 55, 5,-110
         dw 110, 0,-110
         dw 110, 5, -55
         dw 110, 5, 55
         dw 110, 0, 110
         dw 55, 5, 110
         dw -55, 5, 110
         dw -110, 0, 110
         dw -110, 5, 55
         dw -110, 5, -55
         dw 0,-280, 0

         dw double,0,0,16*3+11,16*1+ 3, 1,2,8,5,1
         dw double,0,0,16*3+14,16*1+ 5, 2,3,11,8,2
         dw double,0,0,16*3+ 8,16*1+ 7, 3,4,14,11,3
         dw double,0,0,16*3+ 4,16*1+ 9, 4,1,5,14,4
         dw double,0,0,16*3+15,16*1+0, 17,5,6,17
         dw double,0,0,16*3+15,16*1+0, 17,7,8,17
         dw double,0,0,16*3+12,16*1+2, 17,8,9,17
         dw double,0,0,16*3+12,16*1+2, 17,10,11,17
         dw double,0,0,16*3+ 9,16*1+4, 17,11,12,17
         dw double,0,0,16*3+ 9,16*1+4, 17,13,14,17
         dw double,0,0,16*3+ 6,16*1+6, 17,14,15,17
         dw double,0,0,16*3+ 6,16*1+6, 17,16,5,17


zzline dd -1
       dd offset zz1 - offset $ - 4

zz1:   dw 1
       dw 1

       dw 25 dup (0)

       dw 0,0,2000

       dw 0,0,0,14,0,0,1,0

