;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : vars2.inc
; Included from: 3D2.ASM
; Description  : Defined Variables for 3D2.ASM
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

                   align 4

; table of current limitations/restraints - to be used as reference by  user
; at run-time to determine if object code has been assembled with ample room
; for data/variables/point/surfaces etc...

_asm_version       dw 38h
_asm_maxpoints     dw maxpoints
_asm_maxsurfaces   dw maxsurfaces
_asm_maxpolys      dw maxpolys
_asm_maxobjects    dw maxobjects
_asm_number_spaces dw number_of_spaces
_asm_xsize         dw xmax-xmin
_asm_ysize         dw ymax-ymin
_asm_usez          dw usez
_asm_cameraobject  dw cameraobject
_asm_xmode         dw xmode
_asm_ratiox        dw ratiox
_asm_ratioy        dw ratioy
_asm_xactual       dw xactual
_asm_yactual       dw yactual
_asm_pages         dw pages
_asm_shapes        dw numberofshapes
_asm_bitmaps       dw numberofbitmaps
_asm_xpals         dw numberofpals
_asm_div256        dw div_256

                   align 4

_objbase           dd numberofshapes dup (0) ; memory locations of shapes (offsets)
_bitbase           dd numberofbitmaps dup (0) ; memory locations of _bitmaps
_bitx              dd numberofbitmaps dup (0) ; x base size of _bitmaps (for 3d)
_bity              dd numberofbitmaps dup (0) ; y base size of _bitmaps
_xreftable         dd numberofpals dup (o _nullpalette) ; offsets to palette cross referance tables
_stonetbl          dd numberofstones dup (0) ; offsets to stones textures
_stoneadd          db numberofstones dup (0) ; colour addition value for stone textures (0,16,32,...)

_x1                dw ?                     ; points for line draw
_y1                dw ?
_x2                dw ?
_y2                dw ?
rise               dw ?                     ; counter for draw loop
xp                 dd maxpoints dup (?)     ; points breakdown, after _rotate_pointd, 2d,
yp                 dd maxpoints dup (?)     ; x,y points after 3d, are actual location.
zp                 dd maxpoints dup (?)     ; z useless, only good during sort of sides
sides              dw maxsurfaces*maxpolys dup (?) ; visible sides only here (clockwize)
order              dd maxsurfaces dup (?)   ; what order to draw surfaces in.
zeds               dd maxsurfaces dup (?)   ; z values of first point in side, for sort
surfcolors         dw maxsurfaces dup (?)   ; colours for those sides, high and low
colors12           dd 0                     ; colours for sides 1&2
textures           dw maxsurfaces dup (?)   ; commands/textures for sides
texture12          dd 0                     ; textures for sides 1&2
command            dd 0                     ; current command in load_surfaces loop
_showing           dd 0                     ; how many visible sides (total)
pointindex         dd 0                     ; indexer to points, v_xs[],v_ys[],v_zs[]
lindex             dd ?                     ; last indexer to points,
offsides           dd offset sides          ; gets inc'd when object plotted
numsides           dd ?                     ; number of sides total, gets trashed
numpoints          dd ?                     ; number of points, gets trashed
whichside          dd ?                     ; which side am i doing now
                   dw 0                     ; reserved - leave blank
                   tbsize = ymax-ymin
                   if tbsize lt xmax-xmin
                   tbsize = xmax-xmin
                   endif
_poly_firstbyte    dw tbsize dup(1000)      ; table of start and end x points
                   dw 1000                  ; end flag, permanent
                   dw 0                     ; reserved - leave blank
_poly_lastbyte     dw tbsize dup(-1000)
_poly_oney         dd 1000                  ; y start for one polygon draw
leftmost           dw 1000                  ; only used for _fakeline_vert routine
_colq              db ?                     ; colour of this side
lamflag            db ?                     ; is lambert matrix set up for this object?
                   align 4
currobj            dd ?                     ; current object number (for shading)
xad                dd ?                     ; 3d offset of object
yad                dd ?
zad                dd ?
vxcos              dd ?
vxsin              dd ?
vycos              dd ?
vysin              dd ?
vzcos              dd ?
vzsin              dd ?
palxrefx           dd ?                     ; temp xreferance holder
steel              db ?                     ; steel flag, -1 = don't use
steelc             db ?                     ; base colour for steel, taken from _colq
polytype           dd ?                     ; offset for polytype (_fakeline_horz)
minzc              dd ?                     ; minz (for each object)
btolr              dd ?                     ; tolerance (for each object)
fex                dw ?
lastshade          db ?                     ; shade intensity from last calculation

; variables for multiple object routine, you modify these!

                   align 4
v_whatshape        dw maxobjects+1 dup (0)  ; shapes of objects or bitmaps (0,1,2...)
v_bitobjx          dw maxobjects+1 dup (0)  ; bitmap additional scaling x
v_bitobjy          dw maxobjects+1 dup (0)  ; bitmap additional scaling y
v_xs               dd maxobjects+1 dup (0)  ; locations of objects
v_ys               dd maxobjects+1 dup (0)
v_zs               dd maxobjects+1 dup (0)
v_vxs              dw maxobjects+1 dup (0)  ; angles of objects
v_vys              dw maxobjects+1 dup (0)
v_vzs              dw maxobjects+1 dup (0)
v_palxref          db maxobjects+1 dup (0)  ; palette cross reference for each object
v_userotate        db maxobjects+1 dup (0)  ; rotation type,0 = full,1 = camera
v_onoff            db maxobjects+1 dup (0)  ; is object on/off
                   dd 0                     ; buffer, leave this here dragon breath!
                   align 4

_whatshape         dw maxobjects+1 dup (0)  ; shapes of objects or bitmaps (0,1,2...)
_bitobjx           dw maxobjects+1 dup (0)  ; bitmap additional scaling x
_bitobjy           dw maxobjects+1 dup (0)  ; bitmap additional scaling y
_xs                dd maxobjects+1 dup (0)  ; locations of objects
_ys                dd maxobjects+1 dup (0)
_zs                dd maxobjects+1 dup (0)
_vxs               dw maxobjects+1 dup (0)  ; angles of objects
_vys               dw maxobjects+1 dup (0)
_vzs               dw maxobjects+1 dup (0)
_palxref           db maxobjects+1 dup (0)  ; palette cross reference for each object
_userotate         db maxobjects+1 dup (0)  ; rotation type,0 = full,1 = camera
_onoff             db maxobjects+1 dup (0)  ; is object on/off
                   align 4

_xadds             dd maxobjects+1 dup (0)  ; linear velocities of objects
_yadds             dd maxobjects+1 dup (0)
_zadds             dd maxobjects+1 dup (0)
_vxadds            dw maxobjects+1 dup (0)  ; anglular velocities
_vyadds            dw maxobjects+1 dup (0)
_vzadds            dw maxobjects+1 dup (0)
_lcount            dw maxobjects+1 dup (0)  ; linear counter
_acountx           dw maxobjects+1 dup (0)  ; angular counters
_acounty           dw maxobjects+1 dup (0)
_acountz           dw maxobjects+1 dup (0)

;
;
;
;
;
;

; flags to disable/enable routines: disable = -1, enable >=0

_cam_follow        dd no                    ; what object are we following, -1 = none
_cam_wherelook     dd no                    ; what object do we force camera to look at

_cam_oldspeed      dd ?                     ; how fast to move, temp counter

; camera variables = was last object in object list, now is zero'th

eyex               equ d [v_xs+cameraobject*4] ; camera location (actual, dont modify)
eyey               equ d [v_ys+cameraobject*4]
eyez               equ d [v_zs+cameraobject*4]
eyeax              equ w [v_vxs+cameraobject*2] ; angles for camera
eyeay              equ w [v_vys+cameraobject*2]
eyeaz              equ w [v_vzs+cameraobject*2]

_eyex              equ d [_xs+cameraobject*4] ; camera location (virtual, modify these!)
_eyey              equ d [_ys+cameraobject*4]
_eyez              equ d [_zs+cameraobject*4]
_eyeax             equ w [_vxs+cameraobject*2] ; angles for camera
_eyeay             equ w [_vys+cameraobject*2]
_eyeaz             equ w [_vzs+cameraobject*2]

_eyexadds          equ d [_xadds+cameraobject*4] ; eye location velocity
_eyeyadds          equ d [_yadds+cameraobject*4]
_eyezadds          equ d [_zadds+cameraobject*4]
_eyevxadds         equ w [_vxadds+cameraobject*2] ; eye angular velocities
_eyevyadds         equ w [_vyadds+cameraobject*2]
_eyevzadds         equ w [_vzadds+cameraobject*2]
_eyelcount         equ w [_lcount+cameraobject*2] ; eye linear count (how many times to move)
_eyeacountx        equ w [_acountx+cameraobject*2] ; eye angular counts
_eyeacounty        equ w [_acounty+cameraobject*2]
_eyeacountz        equ w [_acountz+cameraobject*2]

                   align 4

_ecosx             dd ?                     ; multipliers of eyeax and eyeaz
_esinx             dd ?                     ; reset at begining of each new frame
_ecosy             dd ?
_esiny             dd ?
_ecosz             dd ?
_esinz             dd ?

vcosx              dd ?                     ; temp storage for object matrix calculation
vsinx              dd ?                     ; can be used if needed during draw
vcosy              dd ?
vsiny              dd ?
vcosz              dd ?
vsinz              dd ?

_vmatrix           dd 9 dup (?)             ; 3x3 rotation matrix for object (includes eye)
_tmatrix           dd 9 dup (?)             ; 3x3 temp rotation matrix for hierarchys
_ematrix           dd 9 dup (?)             ; 3x3 rotation matrix for eye (32 bit)
_lmatrix           dd 3 dup (?)             ; 1x3 z resultant matrix for _lambert shading

_y_angle_of_sun    dd 1500h                 ; where is the sun? for shading

; clipping variables in memory locations, pre-calculated!
; xactual and yactual basically don't change but clipping can to allow
; windows (rear view mirror, view airplanes menu, auxilary views, rear gunner)
;
; when flipping between windows, also flip _cam_follow, _cam_wherelook
; _cam_oldspeed, _clr_lxupdate, _clr_lyupdate, camera variables/angles/speeds (obviously).

_cliplt            dw _xcenter+xmin         ; _xcenter+xmin
_cliprt            dw _xcenter+xmax-1       ; _xcenter+xmax-1
_cliptp            dw _ycenter+ymin         ; _ycenter+ymin
_clipbt            dw _ycenter+ymax-1       ; _ycenter+ymax-1

_xcent             dw _xcenter
_ycent             dw _ycenter
_ycents1           dw _ycenter-1
_ycentp1           dw _ycenter+1

xmaxxcent          dw xmax+_xcenter

ymaxycent         dw ymax+_ycenter

_xmins             dw xmin
_xmins1            dw xmin-1
_xmaxs             dw xmax
_xmaxs1            dw xmax-1

_ymins             dw ymin
_ymins1            dw ymin-1
_ymaxs             dw ymax
_ymaxs1            dw ymax-1

xmit               dd xmin-tolerance        ; tolerance is max object size/ratio
xmat               dd xmax+tolerance
ymit               dd ymin-tolerance
ymat               dd ymax+tolerance

; routines for screen stretching

_make3d            dd offset _user3d        ; calculate 3d ?actual*?/z (both x and y)
_make3dx           dd offset _user3dx       ; xactual*x/z
_make3dy           dd offset _user3dy       ; yactual*y/z

; variables for icon scale routine

_bitmap            dd ?
_scale_destwidth   dw ?
_scale_destheight  dw ?
_scale_destx       dw ?
_scale_desty       dw ?

sourcewidth        dw ?                     ; workspace for icon scale routine
sourceheight       dw ?
decisionx          dw ?
decisiony          dw ?
clippedwidth       dw ?
clippedheight      dw ?

                   public _objbase
                   public _bitbase
                   public _bitx
                   public _bity
                   public _xreftable
                   public _stonetbl
                   public _stoneadd

                   public _xs
                   public _ys
                   public _zs
                   public _xadds
                   public _yadds
                   public _zadds
                   public _vxs
                   public _vys
                   public _vzs
                   public _vxadds
                   public _vyadds
                   public _vzadds
                   public _lcount
                   public _acountx
                   public _acounty
                   public _acountz
                   public _whatshape
                   public _palxref
                   public _userotate
                   public _bitobjx
                   public _bitobjy

                   public _eyex
                   public _eyey
                   public _eyez
                   public _eyeax
                   public _eyeay
                   public _eyeaz
                   public _eyexadds
                   public _eyeyadds
                   public _eyezadds
                   public _eyevxadds
                   public _eyevyadds
                   public _eyevzadds
                   public _eyelcount
                   public _eyeacountx
                   public _eyeacounty
                   public _eyeacountz

                   public _onoff

                   public _vmatrix
                   public _tmatrix
                   public _ematrix
                   public _lmatrix
                   public _y_angle_of_sun
                   public _ecosx
                   public _esinx
                   public _ecosy
                   public _esiny
                   public _ecosz
                   public _esinz

                   public _bitmap
                   public _scale_destwidth
                   public _scale_destheight
                   public _scale_destx
                   public _scale_desty

                   public _x1
                   public _y1
                   public _x2
                   public _y2
                   public _colq

                   public _poly_oney
                   public _poly_firstbyte
                   public _poly_lastbyte
                   public _showing

                   public _cliplt
                   public _cliprt
                   public _cliptp
                   public _clipbt
                   public _xcent
                   public _ycent
                   public _xmins
                   public _xmins1
                   public _xmaxs
                   public _xmaxs1
                   public _ymins
                   public _ymins1
                   public _ymaxs
                   public _ymaxs1

                   public _make3d
                   public _make3dx
                   public _make3dy

                   public _asm_version
                   public _asm_maxpoints
                   public _asm_maxsurfaces
                   public _asm_maxpolys
                   public _asm_maxobjects
                   public _asm_number_spaces
                   public _asm_xsize
                   public _asm_ysize
                   public _asm_usez
                   public _asm_cameraobject
                   public _asm_xmode
                   public _asm_ratiox
                   public _asm_ratioy
                   public _asm_xactual
                   public _asm_yactual
                   public _asm_pages

