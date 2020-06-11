;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : equ.inc
; Included from: 3D1.ASM, 3D2.ASM, 3D3.ASM
; Description  : Conditional assembley variables and general constants.
;              : No data is here, just parameters
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

yes             equ 0
no              equ -1

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; constants for optimal conditional assembley
; don't pay for features you'll never use! (timewise)
; these are the most _sineifigant factors in determining speed!!
; note:_bitmaps also slow things down...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

usez            equ yes        ; z camera rotations ommited if no, saves 12 imuls
                               ; this speeds up computation in "_compound" matrix
div_256         equ 8          ; will all locations be divided by 256? (set to 8 or 0)

; thats the end of conditional assembley constants!

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; colour crap
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

bulletcolour    equ 4          ; what colour is single point object, from palette
shading_colours equ 32         ; number of colours for _lambert shading, 16 or 32. see math.inc

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; variables for object and polygon routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

tolerance       equ 300        ; max center of gravity offset for objects/ratio (onscreen pixel distance)
ztruncate       equ 80         ; if z< ztruncate, z=ztruncate:for _make3d (16 bit distance)
minz            equ 100        ; minimum z before object can be seen:for _make1obj (16 bit distance)
maxz            equ 500000     ; maximum distance in any axis object can be seen (24 bit distance)
followtol       equ 15         ; tolerance if already looking at object,_cam_newfollow (angle)
collision       equ 10         ; tolerence for merging two objects into 1 (for 3d3, 16 bit distance)

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; polygon constants
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

maxpoints       equ 700        ; max points (*total* on screen if 3d2)
maxsurfaces     equ 700        ; max object surfaces (*total* on screen if 3d2)
mult            equ 4          ; shl ax,mult for number of sides
maxpolys        equ 16         ; 2^mult   ; max sides to a polygon,must = 2^mult,keep small!!
maxobjects      equ 40         ; 50,100,?? ; number of objects possible on screen at once

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; data definition allocation
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

numberofshapes  equ 32         ; number of 3d shapes to allocate space for
numberofbitmaps equ 32         ; number of bitmaps to allocate space for
numberofpals    equ 256        ; number of selectable palette cross refnce tables
numberofstones  equ 256        ; number of stones textures available

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Options for objects - note, some of these commands must be allowed to overlap
; point,line,texture,himap,lomap must not be at the same bit  location  as  the
; texture options.  eg line cannot equal 128 because  this  would  get  smushed
; with shade.
;
; To re-cap:
;
; There cannot be conflicts between (texture options) and (surface types)
;
; There cannot be conflicts between (surface types) and (surface commands or
; internal commands or visibility commands)
;
; Conflicts between (texture options) and (surface commands or internal
; commands or visibility commands) are not important
;
; The texture options wavey,mesh and  glenz MUST be accessable from the  high
; byte of a register.  Considering these  options cannot  be  combined,  they
; can be added to perform other texture options.  See poly.inc for the  table
; Anything with the glenz texture in it, will be polyfilled up/down. Textures
; without the glenz option will be filled left/right.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; texture options
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
wavey           equ 512        ; texture options see objects.inc for explanations
shade           equ 2
inverse         equ 4
glow            equ shade+inverse
last            equ 8
texture         equ 16
mesh            equ 256
auto_s          equ 128        ; pre-calculate shading intensity when angles=0,0,0
glenz           equ 1024
stone           equ glenz+mesh ; copy _bitmap to screen (non-rotatable,non-scalable)

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; surface types
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
point           equ 32         ; surface types
line            equ 64         ; these options must not conflict with the stuff above or below

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; surface commands
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
iterate         equ 256
matrix          equ 512

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; internal commands, not for use by you
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
normal          equ 1024
centroid        equ 1

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; visibility determination methods
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
both            equ 1
double          equ 2
onscr           equ 4
check           equ 8

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; special non-surface oriented commands
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
special         equ 128        ; any command that the high bit set (128) will not have any connection data
himap           equ special+0
lomap           equ special+1
push_matrix     equ special+2  ; push matrix
pop_matrix      equ special+3  ; pop matrix
push_location   equ special+4  ; push location
pop_location    equ special+5  ; pop location
sub_object      equ special+6  ; sub_object = matrix+check+iteration+both,?,?,?,?,0,0
static_sub_object equ special+7 ; non-rotatable sub_object = check+iteration+both,?,?,?,?,0,0
gosub           equ special+8  ; just like the basic command - sends the connection routine to another location in memory (16bit relative), pushes old offset
return          equ special+9  ; just like the basic command - return offset from stack and go to it (32bit absolute)
goto_offset     equ special+10 ; just like the basic command - go to offset specified (16bit relative)

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; commands for _onoff[esi]
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mainobject_on   equ 1
sub_object_on   equ 2
hold_object     equ 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; commands for _userotate[esi]
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
full_rotations  equ 0          ; object has full rotation capability
no_rotation     equ 1          ; object has no rotation
s_point         equ point      ; static point/bullet
s_himap         equ himap      ; object is a static bitmap - like explosions...
s_lomap         equ lomap

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; animation settings
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

number_of_spaces equ 20        ; number of spaces free for animation headers

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; where is the camera in the list
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

cameraobject    equ 0          ; camera is zero'th object in list

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; ===== general xmode constants =====
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

false           equ 0
true            equ -1
nil             equ 0

b               equ byte ptr
w               equ word ptr
d               equ dword ptr
o               equ offset
f               equ far ptr
s               equ short
?x4             equ <?,?,?,?>
?x3             equ <?,?,?>

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; ===== vga register values =====
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

vga_segment     equ d 0a0000h  ; vga memory segment (ok, this is protected mode, right?, so this is the actual address - hahahaha to all you real mode losers...)

attrib_ctrl     equ 03c0h      ; vga attribute controller
gc_index        equ 03ceh      ; vga graphics controller
sc_index        equ 03c4h      ; vga sequencer controller
sc_data         equ 03c5h      ; vga sequencer data port
crtc_index      equ 03d4h      ; vga crt controller
crtc_data       equ 03d5h      ; vga crt controller data
misc_output     equ 03c2h      ; vga misc register
input_1         equ 03dah      ; input status #1 register

dac_write_addr  equ 03c8h      ; vga dac write addr register
dac_read_addr   equ 03c7h      ; vga dac read addr register
pel_data_reg    equ 03c9h      ; vga dac/pel data register r/w

pixel_pan_reg   equ 033h       ; attrib index: pixel pan reg
map_mask        equ 002h       ; sequ index: write map mask reg
read_map        equ 004h       ; gc index: read map register
start_disp_hi   equ 00ch       ; crtc index: display start hi
start_disp_lo   equ 00dh       ; crtc index: display start lo

map_mask_plane1 equ 00102h     ; map register + plane 1
map_mask_plane2 equ 01102h     ; map register + plane 2
all_planes_on   equ 00f02h     ; map register + all bit planes

chain4_off      equ 00604h     ; chain 4 mode off
async_reset     equ 00100h     ; (a)synchronous reset
sequ_restart    equ 00300h     ; sequencer restart

latches_on      equ 00008h     ; bit mask + data from latches
latches_off     equ 0ff08h     ; bit mask + data from cpu

vert_retrace    equ 08h        ; input_1: vertical retrace bit
plane_bits      equ 03h        ; bits 0-1 of xpos = plane #
all_planes      equ 0fh        ; all bit planes selected
char_bits       equ 0fh        ; bits 0-3 of character data

get_char_ptr    equ 01130h     ; vga bios func: get char set
rom_8x8_lo      equ 03h        ; rom 8x8 char set lo pointer
rom_8x8_hi      equ 04h        ; rom 8x8 char set hi pointer

num_modes       equ 8          ; # of mode x variations

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mode x definitions
;
;  0 =  320 x 200
;  1 =  320 x 400
;  2 =  360 x 200
;  3 =  360 x 400
;  4 =  320 x 240
;  5 =  320 x 480
;  6 =  360 x 240
;  7 =  360 x 480
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

videomode       equ 1

                if videomode eq 0

xmode           equ videomode
xmax            equ 160        ; right colomn just beyond screen for clipping
xmin            equ -160       ; left coloumn on screen, x's must be "and 0fffch"
ymax            equ 100        ; lower row just beyond screen
ymin            equ -100       ; upper row on screen
xactual         equ 320        ; guess...
yactual         equ 200

_xcenter        equ 160        ; screen center x,y for actual screen point (0,0)
_ycenter        equ 100        ; make sure clipping still stays inside screen

ratiox          equ 320        ; aspect ratio for 3d conversion (zoom)
ratioy          equ 240        ; make x and y different to fine tune (draw circle)
pages           equ 4          ; # of video pages mode will support, (don't modify)

                elseif videomode eq 1

xmode           equ videomode
xmax            equ 160
xmin            equ -160
ymax            equ 200
ymin            equ -200
xactual         equ 320
yactual         equ 400

_xcenter        equ 160
_ycenter        equ 200

ratiox          equ 320
ratioy          equ 464
pages           equ 2

                elseif videomode eq 2

xmode           equ videomode
xmax            equ 180
xmin            equ -180
ymax            equ 100
ymin            equ -100
xactual         equ 360
yactual         equ 200

_xcenter        equ 180
_ycenter        equ 100

ratiox          equ 320
ratioy          equ 240
pages           equ 3

                elseif videomode eq 3

xmode           equ videomode
xmax            equ 180
xmin            equ -180
ymax            equ 200
ymin            equ -200
xactual         equ 360
yactual         equ 400

_xcenter        equ 180
_ycenter        equ 200

ratiox          equ 300
ratioy          equ 416
pages           equ 1

                elseif videomode eq 4

xmode           equ videomode
xmax            equ 160
xmin            equ -160
ymax            equ 120
ymin            equ -120
xactual         equ 320
yactual         equ 240

_xcenter        equ 160
_ycenter        equ 120

ratiox          equ 300
ratioy          equ 280
pages           equ 3

                elseif videomode eq 5

xmode           equ videomode
xmax            equ 160
xmin            equ -160
ymax            equ 240
ymin            equ -240
xactual         equ 320
yactual         equ 480

_xcenter        equ 160
_ycenter        equ 240

ratiox          equ 260
ratioy          equ 460
pages           equ 1

                elseif videomode eq 6

xmode           equ videomode
xmax            equ 180
xmin            equ -180
ymax            equ 120
ymin            equ -120
xactual         equ 360
yactual         equ 240

_xcenter        equ 180
_ycenter        equ 120

ratiox          equ 320
ratioy          equ 260
pages           equ 3

                elseif videomode eq 7

xmode           equ videomode
xmax            equ 180
xmin            equ -180
ymax            equ 240
ymin            equ -240
xactual         equ 360
yactual         equ 480

_xcenter        equ 180
_ycenter        equ 240

ratiox          equ 280
ratioy          equ 448
pages           equ 1

; if videomode = -1, custom configuration

                elseif videomode eq -1

xmode           equ 1
xmax            equ 160
xmin            equ -160
ymax            equ 200
ymin            equ -200
xactual         equ 320
yactual         equ 400

_xcenter        equ 160
_ycenter        equ 200

ratiox          equ 320
ratioy          equ 464
pages           equ 2

; if videomode = -2, custom configuration

                elseif videomode eq -2

xmode           equ 0
xmax            equ 36*4
xmin            equ -36*4
ymax            equ 60
ymin            equ -60
xactual         equ 320
yactual         equ 200

_xcenter        equ 160
_ycenter        equ 100

ratiox          equ 320
ratioy          equ 240
pages           equ 2

                endif
