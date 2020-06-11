;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; DXF to 3DVectors Converter by John McCarthy (Also .PLG converter)
;
; Current DXF types supported: 3DFACE, PFACE
;
; The 3dfaces are between 1 and 4 points where:
;   1 = single point
;   2 = line
;   3 = triangle
;   4 = quadagon (?)
;
; Whereas the PFACE performs the same function but can be a mesh up to:
; 1 to 3000 vertexes    (see maxpolyline below)
; 1 to 2000 connections (see maxconns below)
; 1 to 3000 surfaces    (see maxsurfs below)
;
;Options:
;
;DXF23DV inputname outputname [-s# -x# -y# -z# -mfilename -u# -v# -w# -l -n -q]
;
; -x  x translation for object (before scale) - can be floating point, +z = up
; -y  y translation for object (before scale) - can be floating point, +z = up
; -z  z translation for object (before scale) - can be floating point, +z = up
; -s  scale factor                            - can be floating point
; -u  x translation for object (after scale)  - integer only, +y = down
; -v  y translation for object (after scale)  - integer only, +y = down
; -w  z translation for object (after scale)  - integer only, +y = down
; -m  materials list filename (corresponds to layer names)
; -l  selective layer processing (only process layers that are found
;     in materials file)
; -n  output true calculated surface normal (otherwise 0,0,0), useless option
; -q  negate Y output axis
; -b  sort surfaces based on surface normal (default=sort)
;
; Material names can be as long as ACAD allows!
;
; I you have trouble assigning a material to a line it  may  be  because  the
; layer that the line is on  has  the  shading  option.  Lines  do  not  have
; surface  normals  and  therefore   cannot  have  the  shading  option  set.
; If DXF23DV finds this occurance, it will insert   a  default  texture  that
; has no shading texture.  eg:  0,0,colour,0
;
; If your a total  knumbskull  (like  me)  and  you  get  ACAD's  co-ordinate
; system messed up (like me) you can use  the  -q  option  to  negate  the  Y
; axis and reverse the  orientation  of  the  polygons.  This  will  fix  the
; object if it appears to be "backwards".
;
; Do not use punctuation in your material names or layer names.
; A # sign in the materials means a comment
; A : means to put the following text AFTER the connection data.
;
; Using the PFACE allows ACAD to assign polygons with more  than  4  surfaces.
; This removes the need for polygon optimization  and  gives  greater  control
; over the implementation of surfaces.
;
; The ACAD layer name is matched up with a materials file to give each surface
; a seperate surface type/colour/whatever.  Surfaces can be  selected  through
; AutoCAD to be double sided, shaded, sine waved, or anything the  user  wants
; simply by nameing a new layer and assigning those  surfaces  to  that layer.
; The materials file can then be edited/added in order to obtain  the  results
; the user desires.  If  the  shade  option  is  used,  the  words  0,0,0  are
; AUTOMATICALLY inserted into the face.  There is no need  to  use  the  colon
; option to add them.  For a rundown on the colon option, see version 0.3
;
; Sample materials file follows:
;
;  # This is a comment
;  # There must be 5 fields in each assigned texture!!
;
;  CONSTANT     0,0,0,colour0,0
;  SHADED       0,shade,0,colour1,0
;  SINE         0,wavey,0,colour2+rnd/16,0
;  BOTHSIDES    both,0,0,colour3,0
;  BOTHSHADE    both,shade,0,colour4,0
;  DOUBLESIDED  double,0,0,colour5a,colour5b
;  DOUBLESHADE  double,shade,shade,colour6a,colour6b
;  1SHADE2SINE  0,shade,wavey,colour7a,colour7b
;  1SINE2SHADE  0,wavey,shade,colour8a,colour8b
;  2SINE        double,wavey,wavey,colour9a,colour9b
;  SAMPLESIDE   this is,an example,of what,you can,do!
;  HIBITMAP     himap:,0,5,5
;
; Make sure your 3DFACEs and PFACEs are entered in Counter-Clockwise order!
;
; Version 0.2:
;
;  DXF to 3DV now accepts REND386 .PLG's!!  Note: The maximum number of
;  verticies in any PLG is defined by maxpolyline (see below)
;
;  The materials file can now how the keyword RND in it to generate a random
;  number   between  0  and  255.  This  may  be  useful  for  sine  texture
;  mis-alignment.
;
; Version 0.3:
;
;  Colons can be placed in materials to output text/data/comments after a
;  polygon face definition.
;   Consider a material like so
;    MATERIALXY   0,mesh,0,colourxy,0:;hello there
;   will return a face line like so
;          dw 0,mesh,0,colourxy,0,1,2,3,6,7,1;hello there
;
;  Bitmaps can now be defined in AutoCAD and then placed as part of an object.
;  Notice how I used the new and fancy colon option?
;   eg: a material of
;    HIBITMAP     himap:,0,5,5   ;testtest
;   will return a line of
;          dw himap,29,0,5,5   ;testtest
;
;  To implement the bitmap option, define a 3dface in AutoCAD   on  the  layer
;  hibitmap.  DXF23DV will find the layer, match it up with the material,  and
;  scan for the text "map" in the  material.  If it is found, it will make the
;  surface into a bitmap.  This is good for adding  explosions/static  bitmaps
;  to dead objects.  Check out XWING to see what I mean.
;
; Version 0.4:
;
;  Connection data  is  sorted  according  to  surface  normal.   This  is  in
;  preparation for iteration handling.
;
;  Small bug with .PLG detection fixed. Also fixed a bug with the .PLG surface
;  loading.  Who uses .PLG's anyway right?  Fixed...
;
;  PFACES now work correctly
;
; Version 0.5:
;
;  The option for direct layer name to material has been added. Although this
;  kind of makes the materials file useless and if you make objects like this
;  it could be tough to edit the surface type later.  But anyway, use it like
;  so:  If the layer begins with an underscore, direct copy will take place.
;
;    _0_shade_0_16_0        <= layer name
;
;  This will directly copy the layer name into the object file replacing all _
;  characters with a commas.  Result: 0,shade,0,16,0
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

; Link this with PMODE, FILE, and ARGC

          .386p
          jumps

code32    segment para public use32
          assume cs:code32, ds:code32, ss:code32

          include pmode.ext
          include file.ext
          include argc.ext

          public  _main

matbufsize  = 1500    ; materials list buffer size
yes         = 1
no          = 0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Macros
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

upper     macro regx  ; make register uppercase
          local strl
          cmp regx,"a"
          jb short strl
          cmp regx,"z"
          ja short strl
          sub regx,"a"-"A"
strl:
          endm

imul32    macro regx
          imul regx
          shld edx,eax,1
          inc edx
          shr edx,1
          movsx eax,dx
          endm

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; DATA
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

inputname       db 60 dup (?)
outputname      db 60 dup (?)

buffer          db 60 dup (?)

nx              dd 0      ; translation of location
ny              dd 0
nz              dd 0
scale           dd 0      ; overall scale done after move
nu              dd 0      ; translation of location after scale
nv              dd 0
nw              dd 0

randomnumber    dd 5fe6c809h

fileloc         dd 0      ; current location in DXF file (offset)

dxfo            dd 0      ; start dxf file location
dxfsize         dd 0      ; dxf filesize
mato            dd 0      ; materials file location
matsize         dd 0      ; materials file size
materials       dd 0      ; materials/layer names offset
facetill        dd 0      ; temp 3dface and poly gather length

maxpoints       = 3000    ; max number of unique points in any DXF
maxconns        = 4000    ; maximum connections
maxpolyline     = 3000    ; maximum pface verticies

ox              = 0       ; offsets for points (from conmem)
oy              = ox+maxpoints*4
oz              = oy+maxpoints*4
sd              = oz+maxpoints*4 ; polygon number
p1              = sd+maxconns*4 ; point 1
p2              = p1+maxconns*4 ; point 2
wg              = p2+maxconns*4 ; where going
wc              = wg+maxconns*4 ; where came
ea              = wc+maxconns*4 ; a,b,c,d of plane equation
eb              = ea+maxconns*4
ec              = eb+maxconns*4
ed              = ec+maxconns*4
mt              = ed+maxconns*4 ; texture/layer name
sk              = mt+maxconns*4 ; temp data for sorting
bv              = sk+maxpolyline*4

memoryneeded    = oy+oz+sd+p1+p2+wg+wc+ea+eb+ec+ed+mt+sk+bv+maxpolyline*4

connmem         dd 0      ; memory for points/connection data
points          dd 0      ; number of points
surfaces        dd 0      ; number of surfaces
connections     dd 0      ; number of connections
thismaterial    dd 0      ; current/working material
iterate         db 0      ; flag to use iteration
shouldisort     db 0      ; flag for sorting - always if iteration.
layer           db 0      ; flag for selective layer processing
tnormal         db 0      ; flag for true surface normal output
yneg            db 0      ; flag for y negation
temp1           dd 0
temp2           dd 0
temp3           dd 0
temp4           dd 0

polyindex       dd maxpolyline dup (0)
start           dd 0
startconn       dd 0
pvertexs        dd 0
pfaces          dd 0
colon           dd 0           ; position of colon 0 = none, x = position

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; CODE
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

include extras.rt

errmsg0 db 13,10,'Missing Filename!',0dh,0ah,"$"
errmsg1 db 13,10,'Not Enough Memory!',0dh,0ah,"$"
errmsg2 db 13,10,'Error Opening File!',0dh,0ah,"$"
errmsg3 db 13,10,'Error Loading Materials File!',0dh,0ah,"$"
errmsg4 db 13,10,'Error:Too Many Points in File!',0dh,0ah,"$"
errmsg5 db 13,10,'Error:No 3DFACEs or PFACEs Found in DXF!',0dh,0ah,"$"
errmsg6 db 13,10,'Dont Know How To Handle Parts Of This DXF!',0dh,0ah,"$"
errmsg7 db 13,10,'Error:Nothing to do in .PLG!',0dh,0ah,"$"
okmsg   db 13,10,"AutoCAD .DXF to 3DVECTORS converter by John McCarthy V0.5 (also does .PLG)"
        db 13,10,"DXF23DV inputname outputname [-s# -x# -y# -z# -mfilename -u# -v# -w# -l -n -q]",10,13
        db 13,10," -x  x translation for object (before scale) - can be floating point, +z = up"
        db 13,10," -y  y translation for object (before scale) - can be floating point, +z = up"
        db 13,10," -z  z translation for object (before scale) - can be floating point, +z = up"
        db 13,10," -s  scale factor                            - can be floating point"
        db 13,10," -u  x translation for object (after scale)  - integer only, +y = down"
        db 13,10," -v  y translation for object (after scale)  - integer only, +y = down"
        db 13,10," -w  z translation for object (after scale)  - integer only, +y = down"
        db 13,10," -m  materials list filename (corresponds to layer names)"
        db 13,10," -l  selective layer processing (only process layers that are found"
        db 13,10,"     in materials file)"
        db 13,10," -n  output true calculated surface normal (otherwise 0,0,0), useless option"
        db 13,10," -q  negate Y output axis"
        db 13,10," -b  sort surfaces based on surface normal (default=sort)",13,10
        db 13,10,"Use 3DFACE and PFACE to define your ACAD object."
        db 13,10,"Enter your 3DFACEs and PFACEs in Counter-Clockwise order."
        db 13,10,"BRIAN.MCCARTHY@CANREM.COM",13,10,"$"
okmsg1  db 13,10,"DXF23DV Converter V0.5 - This conversion conforms to version 3DVECT35",13,10,"$"
okmsg2  db 13,10,"Materials Found (Layers):",13,10,"$"
okmsg3  db 13,10,"Conversion Complete.",13,10,"  Points: $"
okmsg4  db "   Surfaces: $"
okmsg5  db "Writing...",13,10,"$"
okmsg6  db "Sorting...",13,10,"$"
okmsg7  db "Done.",13,10,"$"
okmsg8  db "File type: .DXF",13,10,"$"
okmsg9  db "File type: .PLG",13,10,"$"

exiterr0:
        mov edx,offset errmsg0
        call _putdosmsg
        jmp okerr0
exiterr1:
        mov edx,offset errmsg1
        call _putdosmsg
        jmp okerr0
exiterr2:
        mov edx,offset errmsg2
        call _putdosmsg
        jmp okerr0
exiterr3:
        mov edx,offset errmsg3
        call _putdosmsg
        jmp okerr0
exiterr4:
        mov edx,offset errmsg4
        call _putdosmsg
        jmp okerr0
exiterr5:
        mov edx,offset errmsg5
        call _putdosmsg
        jmp okerr0
exiterr6:
        mov edx,offset errmsg6
        call _putdosmsg
        jmp okerr0
exiterr7:
        mov edx,offset errmsg7
        call _putdosmsg
        jmp okerr0
okerr0:
        mov edx,offset okmsg
        call _putdosmsg
        jmp _exit

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Allocate memory
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
_main:
        call _setbuf

        mov eax,matbufsize  ; allocate memory for materials
        call _getmem
        jc exiterr1
        mov materials,eax
        mov edi,eax
        mov ecx,matbufsize/4 ; wipe materials buffer
        xor eax,eax
        rep stosd

        mov eax,memoryneeded
        call _getmem
        jc exiterr1
        mov connmem,eax
        mov edi,eax
        mov ecx,memoryneeded
        xor eax,eax
        rep stosb

        mov points,eax
        mov surfaces,eax
        mov connections,eax

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Parse and open DXF, allocate memory, load DXF, close file
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        xor al,al
        mov edx,offset inputname
        call _cchekstr
        jc exiterr0
        mov edx,offset inputname
        call _openfile
        jc exiterr2
        call _filesize
        mov dxfsize,eax
        call _getmem
        jc exiterr1
        mov dxfo,eax
        mov edx,eax
        mov ecx,dxfsize
        call _readfile
        jc exiterr2
        call _closefile
        mov edx,dxfo
        mov ecx,dxfsize
        call replace

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Parse and open materials file, allocate memory, load file, close file
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov matsize,0
        mov al,"m"                      ; check for filename on commandline
        mov edx,offset buffer
        call _ccheksstr
        jc nomaters
        mov edx,offset buffer
        call _openfile
        jc exiterr3
        call _filesize
        mov matsize,eax
        call _getmem
        jc exiterr1
        mov mato,eax
        mov edx,eax
        mov ecx,matsize
        call _readfile
        jc exiterr3
        call _closefile
        mov edx,mato
        mov ecx,matsize
        call replace
nomaters:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Parse and open output filename
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov al,1                        ; check for filename on commandline
        mov edx,offset outputname
        call _cchekstr
        jc exiterr0
        mov edx,offset outputname
        call _createfile
        jc exiterr0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Get scaling factor for points
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov scale,1*65536
        mov al,"s"
        mov edx,offset buffer
        call _ccheksstr
        jc noscale
        mov edx,offset buffer
        mov eax,dword ptr buffer
        call _get_float32
        mov scale,eax
noscale:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Get position offset for points
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov nx,0
        mov al,"x"
        mov edx,offset buffer
        call _ccheksstr
        jc nox
        mov edx,offset buffer
        call _get_float32
        mov nx,eax
nox:
        mov ny,0
        mov al,"y"
        mov edx,offset buffer
        call _ccheksstr
        jc noy
        mov edx,offset buffer
        call _get_float32
        mov ny,eax
noy:
        mov nz,0
        mov al,"z"
        mov edx,offset buffer
        call _ccheksstr
        jc noz
        mov edx,offset buffer
        call _get_float32
        mov nz,eax
noz:
        mov nu,0
        mov al,"u"
        mov edx,offset buffer
        call _ccheksstr
        jc nou
        mov edx,offset buffer
        call _strhtn
        call _vct32
        mov nu,eax
nou:
        mov nv,0
        mov al,"v"
        mov edx,offset buffer
        call _ccheksstr
        jc nov
        mov edx,offset buffer
        call _strhtn
        call _vct32
        mov nv,eax
nov:
        mov nw,0
        mov al,"w"
        mov edx,offset buffer
        call _ccheksstr
        jc now
        mov edx,offset buffer
        call _strhtn
        call _vct32
        mov nw,eax
now:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Hunt for -i iteration option
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov shouldisort,yes
        mov iterate,no
        mov al,"i"
        call _cchekswitchnc
        jc yesiterate
        mov iterate,yes
        jmp pastsort
yesiterate:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Hunt for -b sorting option
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov al,"b"
        call _cchekswitchnc
        jc pastsort
        mov shouldisort,no
pastsort:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Hunt for -l selective layer option
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov layer,no
        mov al,"l"
        call _cchekswitchnc
        jc yeslayer
        mov layer,yes
yeslayer:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Hunt for -q y negation option
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov yneg,no
        mov al,"q"
        call _cchekswitchnc
        jc yesneg
        mov yneg,yes
yesneg:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Hunt for -n normal output
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov tnormal,no
        mov al,"n"
        call _cchekswitchnc
        jc yesnormal
        mov tnormal,yes
yesnormal:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Test DXF or PLG
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov edx,offset okmsg1
        call _putdosmsg
        call isitadxforplg
        jc do_plg

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Split DXF into single connection data, calc normals, assign materials
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        mov edx,offset okmsg8
        call _putdosmsg
        mov edx,offset okmsg2
        call _putdosmsg

        mov ebp,dxfsize
        add ebp,dxfo
        mov facetill,ebp

        mov eax,dxfo
        mov fileloc,eax
        call dxf_3dfaces

        mov eax,dxfo
        mov fileloc,eax
        call dxf_polylines

        cmp surfaces,0
        jz exiterr5
        jmp cont

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Input PLG
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

do_plg:
        mov edx,offset okmsg9
        call _putdosmsg
        mov edx,offset okmsg2
        call _putdosmsg

        call plg_getall
        cmp surfaces,0
        jz exiterr7

cont:
        mov edx,offset okmsg3
        call _putdosmsg
        mov eax,points
        call _dos_dec16
        mov edx,offset okmsg4
        call _putdosmsg
        mov eax,surfaces
        call _dos_dec16
        call _dos_ret
        call _dos_ret

        call renumber_surfaces
        call collect_points
        call wipe_d
        call sort_them
        mov edx,offset okmsg5
        call _putdosmsg
        call output_file
        mov edx,offset okmsg7
        call _putdosmsg
        call _closefile
        jmp _exit

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search for and (if neccessary) build materials list
;  In:
;   EDX => materials string (layer name) eg db "OBJECT1 "
;  Out:
;   EAX = assigned material number
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

assign_material:
        mov esi,materials
        mov edi,edx
        xor ebp,ebp
amloopb:
        cmp byte ptr [esi],0 ; test if at end of list => add on to list
        je amadditz
amloop:
        mov al,[esi]         ; check if material is already in list
        mov bl,[edi]
        inc esi
        inc edi
        mov cl,al
        or cl,bl
        jz amout

        cmp al,bl
        je amloop
amout:
        dec esi
        cmp al,0
        jne amabort

        cmp bl,"0"
        jae amabortx

        mov eax,ebp          ; material already present, return number
        ret
amadditz:
        push esi
amaddit:
        mov al,[edx]         ; material not found at all, add to list
        mov [esi],al
        inc edx
        inc esi
        cmp al,"0"
        jae amaddit

        pop edx
        push ebp
        push esi
        mov al,"$"
        mov [esi-1],al
        call _putdosmsg
        call _dos_ret
        pop esi

        xor al,al
        mov [esi-1],al
        pop eax

        ret
amabort:
        inc esi              ; material not found, continue checking
        cmp byte ptr [esi],0
        jne amabort

amabortx:
        inc esi
        inc ebp
        mov edi,edx
        jmp amloopb

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Find material number ECX
; In:  ECX = material number to find
; Out: EDX => location of material name (name only, use this to find material in file)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
find_ecx:
        mov edx,materials
        cmp ecx,0
        je _ret
mcxb:
        inc edx
        cmp byte ptr [edx],0
        jne mcxb
        loop mcxb

        inc edx
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Unpad string
; In:  EDX => string eg " , Hello th"
; Out: EDX => string (after spaces, colons, whatever) eg "Hello th"
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
unpad:
        dec edx
upx:
        inc edx
        mov al,[edx]
        cmp al,"-"
        je upretx
        cmp al,"."
        je upretx
        cmp al,"#"
        je upretx
        cmp al,"A"
        jae upretx
        cmp al,"9"
        ja upx
        cmp al,"0"
        jb upx
upretx:
        ret

        db "**Hey - What are you doing ripping my code?!?!**"

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Next string
; In:  EDX => string eg "Hello there mi"
; Out: EDX => next string (after spaces, colons, whatever) eg "there mi"
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
next:
        call unpad
        dec edx
nxc:
        inc edx
        mov al,[edx]
        cmp al,"-"
        je nxc
        cmp al,"."
        je nxc
        cmp al,"#"
        je nxc
        cmp al,"A"
        jae nxc
        cmp al,"9"
        ja nxretc
        cmp al,"0"
        jae nxc
nxretc:
        jmp unpad

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search_string: Find string at EDX in DXF file
; In:
;   EDX => ASCIIZ string to search for (DXF)
;   EDI = location to start search
;   EBP = location to end search
; Out:
;  CF = 1 - not found
;  CF = 0 - found
;   EDI = location where found
; Notes: String at EDI must have a space or zero at end for search tp succeed.
;  eg:  EDX => "HELLO",0
;       EDI => "ABCDHELLOEFGI" will FAIL! - but " ABCDHELLO DKJ" will succeed!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

search_string:
        mov esi,edx
        mov ecx,edi
ssloop:
        mov al,[esi]
        mov ah,[ecx]
        upper al
        upper ah
        inc esi
        inc ecx
        mov bl,al
        or bl,ah
        jz ssout

        cmp al,ah
        je ssloop

        cmp al,0
        jne ssabort

        cmp ah,"0"
        jae ssabort
ssout:
        clc
        ret
ssabort:
        cmp ecx,ebp
        jae ssretx

        inc edi
        jmp search_string
ssretx:
        stc
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search materials file for information on material ECX
; In:  ECX = material number to look for
; Out: EDX => string containing surface information (terminated with db 0,0)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

find_info:
        cmp matsize,0
        je fidodefault

        call find_ecx
        cmp byte ptr [edx],"_" ; check for directo copy of layer name to material
        je _ret                ; yes, direct, exit with EDX => layer name
        mov esi,edx
        mov edx,mato
filoop:
        call unpad
        xor ebx,ebx
ficx:
        mov al,[esi+ebx]
        mov ah,[edx]
        upper al
        upper ah
        inc ebx
        inc edx
        cmp al,ah
        je ficx

        cmp al,0
        je fifoundm

        dec edx
fifinddol:
        inc edx
        cmp byte ptr [edx],0
        jne fifinddol

        mov eax,mato
        add eax,matsize
        cmp edx,eax
        jb filoop
fidodefault:
        mov edx,offset fidefault
        ret

fifoundm:
        dec edx
        mov al,[edx]
        cmp al,"A"
        ja fifinddol
        cmp al,"9"
        ja unpad
        cmp al,"0"
        jae fifinddol
        jmp unpad

fidefault db "0,shade,0,colour,0",0   ; for regular faces
fidefaull db "0,0,0,colour,0",0       ; for lines

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search line for "shade" or "glow"
; In: EDX => string containing surface information (terminated with db 0,0)
; Out: CF = 0 shade found, CF = 1 shade not found    EDX = ?
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
find_shade:
        push edx
find_shadeq:
        mov al,[edx]
        cmp al,0
        je fsnoshade
        inc edx

        upper al
        cmp al,"S"
        jne find_shadeq
        mov al,[edx+0]
        upper al
        cmp al,"H"
        jne find_shadeq
        mov al,[edx+1]
        upper al
        cmp al,"A"
        jne find_shadeq
        mov al,[edx+2]
        upper al
        cmp al,"D"
        jne find_shadeq
        mov al,[edx+3]
        upper al
        cmp al,"E"
        jne find_shadeq

        pop edx
        clc
        ret

fsnoshade:
        pop edx
find_shadez:
        mov al,[edx]
        cmp al,0
        je fsnoshadez
        inc edx

        upper al
        cmp al,"G"
        jne find_shadez
        mov al,[edx+0]
        upper al
        cmp al,"L"
        jne find_shadez
        mov al,[edx+1]
        upper al
        cmp al,"O"
        jne find_shadez
        mov al,[edx+2]
        upper al
        cmp al,"W"
        jne find_shadez

        clc
        ret
fsnoshadez:
        stc
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search line for "map"
; In: EDX => string containing surface information (terminated with db 0,0)
; Out: CF = 0 map found, CF = 1 map not found    EDX = ?
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
find_map:
        push edx
find_mapq:
        mov al,[edx]
        cmp al,0
        je fs_nomap
        inc edx

        upper al
        cmp al,"M"
        jne find_mapq
        mov al,[edx+0]
        upper al
        cmp al,"A"
        jne find_mapq
        mov al,[edx+1]
        upper al
        cmp al,"P"
        jne find_mapq

        pop edx
        clc
        ret

fs_nomap:
        pop edx
        stc
        ret
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Replace 13,10 with 0,0
; In: EDX => start location
;     ECX = length
; Out: ?
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
replace:
        inc ecx
        push ecx
        mov al,10
        mov edi,edx
re10:
        repnz scasb
        cmp ecx,0
        je re13
        mov byte ptr [edi-1],0
        jmp re10
re13:
        mov al,13
        mov edi,edx
        pop ecx
re13s:
        repnz scasb
        cmp ecx,0
        je _ret
        mov byte ptr [edi-1],0
        jmp re13s

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Replace " " with 0
; In: EDX => start location
;     ECX = length
; Out: ?
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
replacesp:
        inc ecx
        push ecx
        mov al," "
        mov edi,edx
resp:
        repnz scasb
        cmp ecx,0
        je _ret
        mov byte ptr [edi-1],0
        jmp resp

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Auto calculate normal
; In:
;  EBX = point 1
;  ECX = point 2
;  EBP = point 3
; Out:
;    EBX = finx = x of surface normal of triangle
;    ECX = finy = y of surface normal of triangle
;    EBP = finz = z of surface normal of triangle
;    EAX = D of equation (Ax+By+Cz=D)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
acalc_normal:
        mov esi,connmem

        mov eax,[esi+ebx*4+ox]
        mov edx,[esi+ebx*4+oy]
        mov edi,[esi+ebx*4+oz]
        mov lx1,eax
        mov ly1,edx
        mov lz1,edi

        mov eax,[esi+ecx*4+ox]
        mov edx,[esi+ecx*4+oy]
        mov edi,[esi+ecx*4+oz]
        mov lx2,eax
        mov ly2,edx
        mov lz2,edi

        mov eax,[esi+ebp*4+ox]
        mov edx,[esi+ebp*4+oy]
        mov edi,[esi+ebp*4+oz]
        mov lx3,eax
        mov ly3,edx
        mov lz3,edi

        call calc_normal
        call calc_d
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Calc_normal: calculate surface normal
;
; In:
;    LX1 - x of point 1 on triangle
;    LY1 - y of point 1 on triangle
;    LZ1 - z of point 1 on triangle
;    LX2 - x of point 2 on triangle
;    LY2 - y of point 2 on triangle
;    LZ2 - z of point 2 on triangle
;    LX3 - x of point 3 on triangle
;    LY3 - y of point 3 on triangle
;    LZ3 - z of point 3 on triangle
;
; Out:
;    EBX = finx = x of surface normal of triangle
;    ECX = finy = y of surface normal of triangle
;    EBP = finz = z of surface normal of triangle
;
; Notes:
; x2 = x2 - x1
; y2 = y2 - y1
; z2 = z2 - z1
;
; x3 = x3 - x1
; y3 = y3 - y1
; z3 = z3 - z1
;
; x = y2 * z3 - z2 * y3
; y = z2 * x3 - x2 * z3
; z = x2 * y3 - y2 * x3
;
; a = SQR(x ^ 2 + y ^ 2 + z ^ 2)
;
; x = INT(x / a * 256 + .5)
; y = INT(y / a * 256 + .5)
; z = INT(z / a * 256 + .5)
;
; This worked for me on the first try!
;
; If you wanted to get the equation of a plane, you could do this after:
;  d = - x * x1 - y * y1 - z * z1
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

lx1  dd 0
ly1  dd 0
lz1  dd 0

lx2  dd 0
ly2  dd 0
lz2  dd 0

lx3  dd 0
ly3  dd 0
lz3  dd 0

finx dd 0
finy dd 0
finz dd 0

calc_normal:
         mov ebx,lx1
         mov ecx,ly1
         mov ebp,lz1

         sub lx2,ebx
         sub ly2,ecx
         sub lz2,ebp

         sub lx3,ebx
         sub ly3,ecx
         sub lz3,ebp

         mov eax,ly2
         mov ebx,lz3
         imul ebx
         mov ecx,eax

         mov eax,lz2
         mov ebx,ly3
         imul ebx
         sub ecx,eax

         mov finx,ecx ; save x of normal

         mov eax,lz2
         mov ebx,lx3
         imul ebx
         mov ecx,eax

         mov eax,lx2
         mov ebx,lz3
         imul ebx
         sub ecx,eax

         mov finy,ecx ; save y of normal

         mov eax,lx2
         mov ebx,ly3
         imul ebx
         mov ecx,eax

         mov eax,ly2
         mov ebx,lx3
         imul ebx
         sub ecx,eax

         mov finz,ecx ; save z of normal

calc_testloop:
         cmp finx,32768 ; make sure (normal^2)*2 is < 2^32
         jge calc_shrit
         cmp finy,32768
         jge calc_shrit
         cmp finz,32768
         jge calc_shrit

         cmp finx,-32768
         jle calc_shrit
         cmp finy,-32768
         jle calc_shrit
         cmp finz,-32768
         jg  ok_2_bite_dust

calc_shrit:
         shr finx,1   ; calculations will be too large if squared, div by 2
         test finx,40000000h
         jz no_neg_calc1
         or   finx,80000000h
no_neg_calc1:
         shr finy,1
         test finy,40000000h
         jz no_neg_calc2
         or   finy,80000000h
no_neg_calc2:
         shr finz,1
         test finz,40000000h
         jz no_neg_calc3
         or   finz,80000000h
no_neg_calc3:
         jmp calc_testloop

ok_2_bite_dust:
         mov eax,finx ; x^2
         mov edi,eax  ; objects
         imul edi
         mov edi,eax

         mov eax,finy ; y^2
         mov esi,eax
         imul esi
         mov esi,eax

         mov eax,finz ; z^2
         mov ebp,eax
         imul ebp

         add eax,esi
         add eax,edi

         call sqrt    ; get square root of number

         mov ecx,eax
         cmp ecx,0
         je lam_abort ; should never happen!

         mov eax,finx
         cdq
         shld edx,eax,10
         shl eax,10   ; set unit vector to 2^12
         idiv ecx
         mov finx,eax

         mov eax,finy
         cdq
         shld edx,eax,10
         shl eax,10
         idiv ecx
         mov finy,eax

         mov eax,finz
         cdq
         shld edx,eax,10
         shl eax,10
         idiv ecx
         mov finz,eax

         mov ebx,finx
         mov ecx,finy
         mov ebp,finz

lam_abort:
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Calc_D: Calculate D portion of equation of a plane
; In:
;    EBX = x of surface normal of triangle
;    ECX = y of surface normal of triangle
;    EBP = z of surface normal of triangle
;    LX1 - x of point on triangle (any point)
;    LY1 - y of point on triangle
;    LZ1 - z of point on triangle
; Out:
;    EDX = EAX = D of equation (Ax+By+Cz=D)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
calc_d:
         mov eax,lx1
         imul ebx
         mov esi,eax

         mov eax,ly1
         imul ecx
         add esi,eax

         mov eax,lz1
         imul ebp
         add eax,esi

         shr eax,2          ; reduce result to avoid inaccuracy
         test eax,20000000h
         jz calc_o
         or  eax,0c0000000h
calc_o:
         mov edx,eax
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Sqrt: Routine courtesy TRAN
;
; In:
;   EAX - number to take root of
; Out:
;   EAX - root
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
sqrtbasetbl db 0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
sqrt:
         pushad
         mov ebp,eax
         bsr ebx,eax
         jnz short sqrtf0
         xor ebx,ebx
sqrtf0:
         shr ebx,3
         lea eax,[ebx*8]
         mov cl,32
         sub cl,al
         rol ebp,cl
         mov eax,ebp
         movzx eax,al
         mov edi,offset sqrtbasetbl
         mov ecx,10h
sqrtl0:
         scasb
         je short sqrtl0d
         jb short sqrtl0d2
         loop sqrtl0
         inc edi
sqrtl0d2:
         dec edi
         inc cl
sqrtl0d:
         movzx edx,byte ptr [edi-1]
         dec cl
         xor cl,0fh
         mov edi,ecx
         mov ecx,ebx
         jecxz short sqrtdone
         sub eax,edx
sqrtml:
         shld eax,ebp,8
         rol ebp,8
         mov ebx,edi
         shl ebx,5
         xor edx,edx
         mov esi,eax
         div ebx
         rol edi,4
         add edi,eax
         add ebx,eax
sqrtf2:
         imul eax,ebx
         mov edx,eax
         mov eax,esi
         sub eax,edx
         jc short sqrtf1
         loop sqrtml
sqrtdone:
         mov [esp+28],edi
         popad
         ret
sqrtf1:
         dec ebx
         dec edi
         movzx eax,bl
         and al,1fh
         jmp sqrtf2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search and Build points table
; In:
;    EBX - x of point
;    ECX - y of point
;    EBP - z of point
; Out:
;    EAX - assigned point number
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
check_point:
        mov eax,ebx
        or eax,ecx
        or eax,ebp
        jnz cpnotnull
        ret
cpnotnull:
        mov esi,connmem
        mov eax,1
cploop:
        cmp dword ptr [esi+eax*4+ox],0
        jne ckdotest
        cmp dword ptr [esi+eax*4+oy],0
        jne ckdotest
        cmp dword ptr [esi+eax*4+oz],0
        jne ckdotest

        mov [esi+eax*4+ox],ebx
        mov [esi+eax*4+oy],ecx
        mov [esi+eax*4+oz],ebp

        inc points
        cmp eax,maxpoints
        jae exiterr4

        ret
ckdotest:
        cmp [esi+eax*4+ox],ebx
        jne cknotest
        cmp [esi+eax*4+oy],ecx
        jne cknotest
        cmp [esi+eax*4+oz],ebp
        jne cknotest
        ret
cknotest:
        inc eax
        cmp eax,maxpoints
        jae exiterr4

        jmp cploop

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Get next number (float) after string EDX
; In: EDX => string to search for
; Out:EAX = 32bit float number (fake float, you know what I mean)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
getnumber:
        mov edi,fileloc
        mov ebp,dxfo
        add ebp,dxfsize
        call search_string
        jc gn_nf
        mov edx,edi
        call next
        mov fileloc,edx
        call _get_float32
        push eax
        mov edx,fileloc
        call next
        mov fileloc,edx
        pop eax
        clc
gn_nf:
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Add DXF into connections, points, calculate normals and load materials.
;
; In:
;   fileloc => location to start checking for 3dfaces
;   filetill => location to end checking for 3dfaces
;
; This adds a DXF file to the already loaded connections (usually empty), but
; you could mix more than one DXF file if you  really  wanted  to.   This  is
; useful for adding only 3dfaces that are within blocks (if option set).
;
; Psuedo code:
;
;Variables p= x(p) y(p) z(p)
;          c= sd(c) p1(c) p2(c) wg(c) wc(c) a(c) b(c) c(c) d(c) mt(c)
; c = connections
; p = points
; sd = surface number
; p1 = point 1 (start of line)
; p2 = point 2 (end of line)
; wg = where are we going
; wc = where did we come from
; a,b,c,d = equation of plane
; mt = material texture for surface (layer name)
;
;search "3DFACE" not found => exit
; search "8"
; call next
; assign material
;
;search "10" => x(p)
;search "20" => y(p)
;search "30" => z(p)
;search "11" => x(p+1)
;search "21" => y(p+1)
;search "31" => z(p+1)
;search "12" => x(p+2)
;search "22" => y(p+2)
;search "32" => z(p+2)
;search "13" => x(p+3)
;search "23" => y(p+3)
;search "33" => z(p+3)
;
;    m(c+0)  = material
;    p1(c+0) =(p+0)
;    p2(c+0) =(p+1)
;    wg(c+0) =(c+1)
;    wc(c+0) =(c+3)
;    m(c+1)  = material
;    p1(c+1) =(p+0)
;    p2(c+1) =(p+1)
;    wg(c+1) =(c+2)
;    wc(c+1) =(c+0)
;    m(c+2)  = material
;    p1(c+2) =(p+0)
;    p2(c+2) =(p+1)
;    wg(c+2) =(c+3)
;    wc(c+2) =(c+1)
;    m(c+3)  = material
;    p1(c+3) =(p+0)
;    p2(c+3) =(p+1)
;    wg(c+3) =(c+0)
;    wc(c+3) =(c+2)
;
;  calc normal
;  calc D
;  d(c+0)=D
;  d(c+1)=D
;  d(c+2)=D
;  d(c+3)=D
;
;  if 10=40
;  if 11=41
;  if 12=42
;     wg(c+2)=c+0
;     wc(c+0)=c+2
;     c=c-1
;     p=p-1
;  p=p+4
;  c=c+4
; goto search face
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

tag1     db "3DFACE",0
tag2     db "8",0
tagx     db "10",0,0
         db "11",0,0
         db "12",0,0
         db "13",0,0
tagy     db "20",0,0
         db "21",0,0
         db "22",0,0
         db "23",0,0
tagz     db "30",0,0
         db "31",0,0
         db "32",0,0
         db "33",0,0

dxf_3dfaces:
         mov edx,offset tag1
         mov edi,fileloc
         mov ebp,facetill
         call search_string
         jc _ret

         mov edx,offset tag2
         mov ebp,facetill
         call search_string
         jc dxf_3dfaces       ; no layer to surface?

         mov edx,edi
         call next
         mov fileloc,edx
         call assign_material
         mov thismaterial,eax

         cmp layer,no
         je dxf_nosel
         mov ecx,eax
         call find_info
         cmp edx,offset fidefault
         je dxf_3dfaces

dxf_nosel:
         mov temp1,0
dxf_lp1:
         mov ecx,temp1
         lea edx,[tagx+ecx*4]
         call getnumber
         add eax,nx
         mov ebx,scale
         imul32 ebx
         add eax,nu
         push eax

         mov ecx,temp1
         lea edx,[tagy+ecx*4]
         call getnumber
         add eax,ny
         mov ebx,scale
         imul32 ebx
         add eax,nw
         push eax

         mov ecx,temp1
         lea edx,[tagz+ecx*4]
         call getnumber
         add eax,nz
         mov ebx,scale
         imul32 ebx
         add eax,nv
         cmp yneg,yes
         je noyneg
         neg eax
noyneg:
         mov ecx,eax
         pop ebp
         pop ebx
         call check_point
         push eax

         inc temp1
         cmp temp1,4
         jne dxf_lp1

         pop edx ; 3
         pop ecx ; 2
         pop ebx ; 1
         pop eax ; 0

         mov ebp,connections
         mov esi,connmem
         mov edi,surfaces

         cmp eax,ecx    ; check for point: 1,1,1,1
         je dxf_point

         cmp eax,ecx    ; check for line: 1,2,1,2  or 1,2,1,1
         je dxf_line

         cmp eax,edx    ; check for triangle:  0 1 2 0 or 0 1 2 2
         je dxf_tri
         cmp ecx,edx
         jne dxf_4point ; must be a 4 point surface...
dxf_tri:
         mov [esi+(ebp+0)*4+p1],eax  ; p1(ebp)=eax
         mov [esi+(ebp+0)*4+p2],ebx  ; p2(ebp)=ebx
         mov [esi+(ebp+1)*4+p1],ebx  ; p1(ebp+1)=ebx
         mov [esi+(ebp+1)*4+p2],ecx  ; p2(ebp+1)=ecx
         mov [esi+(ebp+2)*4+p1],ecx  ; p1(ebp+2)=ecx
         mov [esi+(ebp+2)*4+p2],eax  ; p2(ebp+2)=eax

         mov [esi+(ebp+0)*4+wc],ebp  ; wc(ebp)=ebp+2
         mov [esi+(ebp+1)*4+wc],ebp  ; wc(ebp+1)=ebp+0
         mov [esi+(ebp+2)*4+wc],ebp  ; wc(ebp+2)=ebp+1
         add dword ptr [esi+(ebp+0)*4+wc],2
         add dword ptr [esi+(ebp+2)*4+wc],1

         mov [esi+(ebp+0)*4+wg],ebp  ; wg(ebp)=ebp+1
         mov [esi+(ebp+1)*4+wg],ebp  ; wg(ebp+1)=ebp+2
         mov [esi+(ebp+2)*4+wg],ebp  ; wg(ebp+2)=ebp+0
         add dword ptr [esi+(ebp+0)*4+wg],1
         add dword ptr [esi+(ebp+1)*4+wg],2

         mov [esi+(ebp+0)*4+sd],edi  ; sd(ebp)=surface number
         mov [esi+(ebp+1)*4+sd],edi
         mov [esi+(ebp+2)*4+sd],edi

         mov edi,thismaterial
         mov [esi+(ebp+0)*4+mt],edi  ; set material for surface
         mov [esi+(ebp+1)*4+mt],edi
         mov [esi+(ebp+2)*4+mt],edi

         mov ebp,ecx
         mov ecx,ebx
         mov ebx,eax
         call acalc_normal

         mov edi,connections
         mov esi,connmem

         mov [esi+(edi+0)*4+ea],ebx
         mov [esi+(edi+0)*4+eb],ecx
         mov [esi+(edi+0)*4+ec],ebp
         mov [esi+(edi+0)*4+ed],edx
         mov [esi+(edi+1)*4+ea],ebx
         mov [esi+(edi+1)*4+eb],ecx
         mov [esi+(edi+1)*4+ec],ebp
         mov [esi+(edi+1)*4+ed],edx
         mov [esi+(edi+2)*4+ea],ebx
         mov [esi+(edi+2)*4+eb],ecx
         mov [esi+(edi+2)*4+ec],ebp
         mov [esi+(edi+2)*4+ed],edx

         add surfaces,1
         add connections,3

         jmp dxf_3dfaces

dxf_4point:
         mov [esi+(ebp+0)*4+p1],eax  ; p1(ebp)=eax
         mov [esi+(ebp+0)*4+p2],ebx  ; p2(ebp)=ebx
         mov [esi+(ebp+1)*4+p1],ebx  ; p1(ebp+1)=ebx
         mov [esi+(ebp+1)*4+p2],ecx  ; p2(ebp+1)=ecx
         mov [esi+(ebp+2)*4+p1],ecx  ; p1(ebp+2)=ecx
         mov [esi+(ebp+2)*4+p2],edx  ; p2(ebp+2)=edx
         mov [esi+(ebp+3)*4+p1],edx  ; p1(ebp+3)=edx
         mov [esi+(ebp+3)*4+p2],eax  ; p2(ebp+3)=eax

         mov [esi+(ebp+0)*4+wc],ebp  ; wc(ebp)=ebp+3
         mov [esi+(ebp+1)*4+wc],ebp  ; wc(ebp+1)=ebp+0
         mov [esi+(ebp+2)*4+wc],ebp  ; wc(ebp+2)=ebp+1
         mov [esi+(ebp+3)*4+wc],ebp  ; wc(ebp+3)=ebp+2
         add dword ptr [esi+(ebp+0)*4+wc],3
         add dword ptr [esi+(ebp+2)*4+wc],1
         add dword ptr [esi+(ebp+3)*4+wc],2

         mov [esi+(ebp+0)*4+wg],ebp  ; wg(ebp)=ebp+1
         mov [esi+(ebp+1)*4+wg],ebp  ; wg(ebp+1)=ebp+2
         mov [esi+(ebp+2)*4+wg],ebp  ; wg(ebp+2)=ebp+3
         mov [esi+(ebp+3)*4+wg],ebp  ; wg(ebp+3)=ebp+0
         add dword ptr [esi+(ebp+0)*4+wg],1
         add dword ptr [esi+(ebp+1)*4+wg],2
         add dword ptr [esi+(ebp+2)*4+wg],3

         mov [esi+(ebp+0)*4+sd],edi  ; sd(ebp)=surface number
         mov [esi+(ebp+1)*4+sd],edi
         mov [esi+(ebp+2)*4+sd],edi
         mov [esi+(ebp+3)*4+sd],edi

         mov edi,thismaterial
         mov [esi+(ebp+0)*4+mt],edi  ; set material for surface
         mov [esi+(ebp+1)*4+mt],edi
         mov [esi+(ebp+2)*4+mt],edi
         mov [esi+(ebp+3)*4+mt],edi

         mov ebp,ecx
         mov ecx,ebx
         mov ebx,eax
         call acalc_normal

         mov edi,connections
         mov esi,connmem

         mov [esi+(edi+0)*4+ea],ebx
         mov [esi+(edi+0)*4+eb],ecx
         mov [esi+(edi+0)*4+ec],ebp
         mov [esi+(edi+0)*4+ed],edx
         mov [esi+(edi+1)*4+ea],ebx
         mov [esi+(edi+1)*4+eb],ecx
         mov [esi+(edi+1)*4+ec],ebp
         mov [esi+(edi+1)*4+ed],edx
         mov [esi+(edi+2)*4+ea],ebx
         mov [esi+(edi+2)*4+eb],ecx
         mov [esi+(edi+2)*4+ec],ebp
         mov [esi+(edi+2)*4+ed],edx
         mov [esi+(edi+3)*4+ea],ebx
         mov [esi+(edi+3)*4+eb],ecx
         mov [esi+(edi+3)*4+ec],ebp
         mov [esi+(edi+3)*4+ed],edx

         add surfaces,1
         add connections,4
         jmp dxf_3dfaces
dxf_line:
         mov [esi+(ebp+0)*4+p1],eax  ; p1(ebp)=eax
         mov [esi+(ebp+0)*4+p2],ebx  ; p2(ebp)=ebx
         mov [esi+(ebp+1)*4+p1],ebx  ; p1(ebp+1)=ebx
         mov [esi+(ebp+1)*4+p2],eax  ; p2(ebp+1)=ecx

         mov [esi+(ebp+0)*4+wc],ebp  ; wc(ebp)=ebp+1
         mov [esi+(ebp+1)*4+wc],ebp  ; wc(ebp+1)=ebp+0
         add dword ptr [esi+(ebp+0)*4+wc],1

         mov [esi+(ebp+0)*4+wg],ebp  ; wg(ebp)=ebp+1
         mov [esi+(ebp+1)*4+wg],ebp  ; wg(ebp+1)=ebp+0
         add dword ptr [esi+(ebp+0)*4+wg],1

         mov [esi+(ebp+0)*4+sd],edi  ; sd(ebp)=surface number
         mov [esi+(ebp+1)*4+sd],edi

         mov edi,thismaterial
         mov [esi+(ebp+0)*4+mt],edi  ; set material for surface
         mov [esi+(ebp+1)*4+mt],edi

         xor eax,eax
         mov edi,connections
         mov esi,connmem

         mov [esi+(edi+0)*4+ea],eax
         mov [esi+(edi+0)*4+eb],eax
         mov [esi+(edi+0)*4+ec],eax
         mov [esi+(edi+0)*4+ed],eax
         mov [esi+(edi+1)*4+ea],eax
         mov [esi+(edi+1)*4+eb],eax
         mov [esi+(edi+1)*4+ec],eax
         mov [esi+(edi+1)*4+ed],eax

         add surfaces,1
         add connections,2

         jmp dxf_3dfaces

dxf_point:
         mov [esi+(ebp+0)*4+p1],eax  ; p1(ebp)=eax
         mov [esi+(ebp+0)*4+p2],eax  ; p2(ebp)=ebx

         mov [esi+(ebp+0)*4+wc],ebp  ; wc(ebp)=ebp+0
         mov [esi+(ebp+0)*4+wc],ebp  ; wc(ebp+1)=ebp+0

         mov [esi+(ebp+0)*4+wg],ebp  ; wg(ebp)=ebp+0
         mov [esi+(ebp+1)*4+wg],ebp  ; wg(ebp+1)=ebp+0

         mov [esi+(ebp+0)*4+sd],edi  ; sd(ebp)=surface number

         mov edi,thismaterial
         mov [esi+(ebp+0)*4+mt],edi  ; set material for surface

         xor eax,eax
         mov edi,connections
         mov esi,connmem

         mov [esi+(edi+0)*4+ea],eax
         mov [esi+(edi+0)*4+eb],eax
         mov [esi+(edi+0)*4+ec],eax
         mov [esi+(edi+0)*4+ed],eax

         add surfaces,1
         add connections,1

         jmp dxf_3dfaces

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Input Polyline PFACEs
; In:
;   fileloc => location to start checking for 3dfaces
;   filetill => location to end checking for 3dfaces
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

tag3     db "POLYLINE",0
tag4     db "VERTEX",0
tag70    db "70",0
tag71    db "71",0
tag72    db "72",0
tag73    db "73",0
tag74    db "74",0

dxf_polylines:
         mov edx,offset tag3
         mov edi,fileloc
         mov ebp,facetill
         call search_string
         jc _ret

         mov edx,offset tag2
         mov ebp,facetill
         call search_string
         jc dxf_polylines     ; no layer to polyline?

         mov edx,edi
         call next
         mov fileloc,edx
         call assign_material
         mov thismaterial,eax

         cmp layer,no
         je dxf_pnosel
         mov ecx,eax
         call find_info
         cmp edx,offset fidefault
         je dxf_polylines

dxf_pnosel:
         mov edx,fileloc
         call next
         mov edi,edx
         mov edx,offset tag70
         mov ebp,facetill
         call search_string
         jc exiterr6

         mov edx,edi
         call next
         call _strhtn
         call _vct16
         cmp eax,64
         jne dxf_polylines

         mov edx,fileloc
         call next
         mov edi,edx
         mov edx,offset tag71
         mov ebp,facetill
         call search_string
         jc exiterr6

         mov edx,edi
         call next
         call _strhtn
         call _vct32
         mov pvertexs,eax

         mov edx,fileloc
         call next
         mov edi,edx
         mov edx,offset tag72
         mov ebp,facetill
         call search_string
         jc exiterr6

         mov edx,edi
         call next
         mov fileloc,edx
         call _strhtn
         call _vct32
         mov pfaces,eax
         mov temp2,eax

         mov temp1,1
dxfpv_load:
         mov edi,fileloc
         mov edx,offset tag4
         mov ebp,facetill
         call search_string
         jc exiterr6

         mov fileloc,edi
         mov edx,offset tagx
         call getnumber
         add eax,nx
         mov ebx,scale
         imul32 ebx
         add eax,nu
         push eax

         mov edx,offset tagy
         call getnumber
         add eax,ny
         mov ebx,scale
         imul32 ebx
         add eax,nw
         push eax

         mov edx,offset tagz
         call getnumber
         add eax,nz
         mov ebx,scale
         imul32 ebx
         add eax,nv
         cmp yneg,yes
         je noynegp
         neg eax
noynegp:
         mov ecx,eax
         pop ebp
         pop ebx
         call check_point

         mov edi,temp1
         mov polyindex[edi*4],eax
         inc temp1
         mov eax,temp1
         cmp eax,pvertexs
         jbe dxfpv_load
dxf_pmore:
         mov edi,fileloc       ; now reconstruct polyline into face
         mov edx,offset tag4
         mov ebp,facetill
         call search_string
         jc exiterr6

         mov edx,offset tag71
         call getnumber
         shr eax,16

         mov ebp,connections    ; set first point in poly
         mov startconn,ebp
         mov eax,[polyindex+eax*4]
         mov start,eax
         mov esi,connmem
         mov [esi+ebp*4+p1],eax

         mov edx,offset tag72
         call getnumber
         jc exiterr6
         shr eax,16
         movsx eax,ax
         mov temp3,0
         cmp eax,0
         jge pf_kkl
         neg eax
         mov temp3,1
pf_kkl:
         mov ebp,[polyindex+eax*4]
         cmp ebp,start
         je pf_close
         call addpoint
         cmp temp3,1
         je pf_close

         mov edx,offset tag73
         call getnumber
         jc pf_close
         shr eax,16
         movsx eax,ax
         mov temp3,0
         cmp eax,0
         jge pf_kkq
         neg eax
         mov temp3,1
pf_kkq:
         mov ebp,[polyindex+eax*4]
         cmp ebp,start
         je pf_close
         call addpoint
         cmp temp3,1
         je pf_close

         mov temp4,0
         mov edx,offset tag74
         call getnumber
         jc pf_close
         mov temp4,1   ; temp4 = 1 means calc normal
         shr eax,16
         movsx eax,ax

         mov temp3,0
         cmp eax,0
         jge pf_negit
         neg eax
         mov temp3,1
pf_negit:
         mov ebp,[polyindex+eax*4]
         cmp ebp,start
         je pf_close
         call addpoint
         cmp temp3,0
         je pf_close
pf_multi:
         mov edi,fileloc
         mov edx,offset tag4
         mov ebp,facetill
         call search_string
         jc exiterr6

         mov edx,offset tag73
         call getnumber
         jc exiterr6
         shr eax,16
         movsx eax,ax

         mov temp3,0
         cmp eax,0
         jge pf_negitp
         neg eax
         mov temp3,1
pf_negitp:
         mov ebp,[polyindex+eax*4]
         cmp ebp,start
         je pf_close
         call addpoint
         cmp temp3,1
         je pf_multi
pf_close:
         mov eax,startconn
         mov ebp,connections
         mov esi,connmem
         mov [esi+eax*4+wc],ebp
         mov [esi+ebp*4+wg],eax
         mov ebx,start
         mov [esi+ebp*4+p2],ebx
         mov eax,thismaterial
         mov [esi+ebp*4+mt],eax
         mov eax,surfaces
         mov [esi+ebp*4+sd],eax

         cmp temp4,0
         je pf_nnor

         mov esi,connmem
         mov edx,startconn
         mov ebx,[esi+(edx+0)*4+p1]
         mov ecx,[esi+(edx+0)*4+p2]
         mov ebp,[esi+(edx+1)*4+p2]
         call acalc_normal

         mov esi,connmem
         mov eax,startconn
pf_applyl:
         mov [esi+(eax+0)*4+ea],ebx
         mov [esi+(eax+0)*4+eb],ecx
         mov [esi+(eax+0)*4+ec],ebp
         mov [esi+(eax+0)*4+ed],edx
         mov eax,[esi+(eax+0)*4+wg]
         cmp eax,startconn
         jne pf_applyl

pf_nnor:
         inc connections
         inc surfaces

         dec pfaces
         jnz dxf_pmore

         jmp dxf_polylines
addpoint:
         mov ebp,connections
         mov eax,[polyindex+eax*4]
         mov esi,connmem
         mov [esi+ebp*4+p2],eax
         mov [esi+(ebp+1)*4+p1],eax
         mov [esi+ebp*4+wg],ebp
         inc dword ptr [esi+ebp*4+wg]
         mov eax,surfaces
         mov [esi+ebp*4+sd],eax
         mov eax,thismaterial
         mov [esi+ebp*4+mt],eax
         inc connections
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Find opposite connection for line EBP
; In:  EBX = connection to find pair for
; Out: CF = 1 not found,  CF = 0 connection found at EDI!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

find_pair:
         mov esi,connmem
         mov ecx,[esi+ebp*4+p1]  ; eg have (7,9) look for (9,7)
         mov edx,[esi+ebp*4+p2]
         mov eax,ecx
         or eax,edx
         jz fpnomatch
         xor edi,edi
fploop:
         mov eax,[esi+edi*4+p2]
         mov ebx,[esi+edi*4+p1]

         cmp eax,ecx
         jne fpnotmatch0
         cmp ebx,edx
         jne fpnotmatch0         ; backwards points?

         mov eax,[esi+ebp*4+ea]  ; yes, test if same plane equation
         cmp [esi+edi*4+ea],eax
         jne fpnotmatch1
         mov eax,[esi+ebp*4+eb]
         cmp [esi+edi*4+eb],eax
         jne fpnotmatch1
         mov eax,[esi+ebp*4+ec]
         cmp [esi+edi*4+ec],eax
         jne fpnotmatch1
         mov eax,[esi+ebp*4+ed]
         cmp [esi+edi*4+ed],eax
         jne fpnotmatch1
         mov eax,[esi+ebp*4+mt]  ; same equation, test if same material
         cmp [esi+edi*4+mt],eax
         jne fpnotmatch1

         clc
         ret
fpnotmatch0:
         or eax,ebx
         jz fpnomatch

fpnotmatch1:
         inc edi
         cmp edi,maxpoints
         jl fploop
fpnomatch:
         mov edi,-1
         stc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Renumber surfaces
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
renumber_surfaces:
         xor ebx,ebx
rnloop:
         call rn_lowest
         jc _ret
         call rn_eax2ebx
         inc ebx
         jmp rnloop

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Search for lowest surface number (but above EBX)
; In:  EBX = lowest surface number to test
; Out:
;  CF = 1, not found.
;  CF = 0
;   EAX = lowest surface number
;   EBP = connection number where found
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

rn_lowest:
         mov esi,connmem
         mov ecx,connections
         mov eax,-1
rnlloop:
         mov edx,[esi+(ecx-1)*4+sd]
         cmp ebx,edx
         ja rnlnotel

         cmp eax,edx
         jb rnlnotel

         mov eax,edx
         mov ebp,ecx
         dec ebp
rnlnotel:
         loop rnlloop

         inc eax
         sub eax,1
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Renumber surfaces EAX to EBX
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

rn_eax2ebx:
         mov esi,connmem
         lea edi,[esi+sd]
         mov ecx,connections
rn_eaxl:
         repnz scasd

         cmp ecx,0
         jz _ret

         mov [edi-4],ebx
         jmp rn_eaxl

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Delete unused points and collect
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
collect_points:
         mov esi,connmem
         mov eax,1
coploop:
         lea edi,[esi+p1]
         mov ecx,connections
         repnz scasd
         sub ecx,1
         jnc cpused

         lea edi,[esi+p2]
         mov ecx,connections
         repnz scasd
         sub ecx,1
         jnc cpused

         call cpdeleteit
cpused:
         inc eax
         cmp eax,points
         jne coploop

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Delete point EAX
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
cpdeleteit:
         mov ebp,points
         mov esi,connmem
         lea ecx,[ebp-eax]
         lea edi,[esi+(eax+0)*4+ox]
         lea esi,[esi+(eax+1)*4+ox]
         rep movsd

         mov esi,connmem
         lea ecx,[ebp-eax]
         lea edi,[esi+(eax+0)*4+oy]
         lea esi,[esi+(eax+1)*4+oy]
         rep movsd

         mov esi,connmem
         lea ecx,[ebp-eax]
         lea edi,[esi+(eax+0)*4+oz]
         lea esi,[esi+(eax+1)*4+oz]
         rep movsd

         mov esi,connmem
         mov ecx,connections
         xor ebp,ebp
cpdloop:
         mov ebx,[esi+ebp*4+p1]
         cmp ebx,eax
         jb cpskip1
         dec dword ptr [esi+ebp*4+p1]
cpskip1:
         mov ebx,[esi+ebp*4+p2]
         cmp ebx,eax
         jb cpskip2
         dec dword ptr [esi+ebp*4+p2]
cpskip2:
         inc ebp
         loop cpdloop

         dec points
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Wipe D value from plane equation if no iteration used
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
wipe_d:
         cmp iterate,yes
         je _ret
         mov esi,connmem
         mov ecx,connections
         dec ecx
         xor edx,edx
wdkl:
         mov [esi+(ecx)*4+ed],edx
         loop wdkl

         mov [esi+(ecx)*4+ed],edx
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Output file - file is opened and ready
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

output_file:
         mov ecx,40                    ; output header info
         mov al,"."
         mov edi,offset outputname
         repnz scasb
         mov byte ptr [edi-1],0
         sub edi,offset outputname
         push edi
         push edi

         mov edx,offset header0
         call _write_null
         mov edx,offset header1
         call _write_null
         mov edx,offset outputname
         call _write_null
         pop ecx
         mov edx,offset header7
         add edx,ecx
         call _write_null
         mov edx,offset header2
         call _write_null
         mov edx,offset outputname
         call _write_null
         mov edx,offset header3
         call _write_null
         mov edx,offset outputname
         call _write_null
         pop ecx
         mov edx,offset header4
         add edx,ecx
         call _write_null
         mov eax,points
         call _write_dec16
         mov eax,","
         call _write_string4
         mov eax,surfaces
         call _write_dec16
         call _write_ret

         mov edx,offset header4
         call _write_null
         mov edx,offset header5
         call _write_null
         call _write_ret
         call _write_ret

         mov temp1,1                ; now output points
of_loop1:
         mov edx,offset header4
         call _write_null

         mov esi,connmem
         mov ecx,temp1
         mov eax,[esi+ecx*4+ox]
         mov edx,offset buffer
         call _write_neg16
         call _write_null
         mov eax,","
         call _write_string4
         mov esi,connmem
         mov ecx,temp1
         mov eax,[esi+ecx*4+oy]
         mov edx,offset buffer
         call _write_neg16
         call _write_null
         mov eax,","
         call _write_string4
         mov esi,connmem
         mov ecx,temp1
         mov eax,[esi+ecx*4+oz]
         mov edx,offset buffer
         call _write_neg16
         call _write_null
         mov edx,offset header6
         call _write_null
         mov eax,temp1
         call _write_dec16
         call _write_ret
         inc temp1
         mov ecx,temp1
         cmp ecx,points
         jbe of_loop1
         call _write_ret

         mov temp1,0              ; output surfaces
dp_sloop:
         mov ebx,temp1
         call rn_lowest
         mov temp2,ebp

         mov edx,offset header4
         call _write_null
         mov esi,connmem
         mov ecx,temp2
         mov ecx,[esi+ecx*4+mt]
         call find_info
         mov thismaterial,edx
         mov edx,thismaterial
         call find_shade
         jc dp_noshade0
         mov esi,connmem
         mov ebp,temp2
         mov ebp,[esi+ebp*4+wg]
         mov ebp,[esi+ebp*4+wg]
         cmp ebp,temp2
         jne dp_noshade0
         mov edx,offset fidefaull
         mov thismaterial,edx
dp_noshade0:
         mov edx,thismaterial
         call change_underscore ; if direct copy used (underscore), change to ","
         call write_mat
         mov eax,","
         call _write_string4

         mov edx,thismaterial
         call find_map
         jc dp_nobitmap

         mov ebp,temp2
         mov esi,connmem
         mov eax,[esi+ebp*4+p1]
         call _write_dec16
         jmp dp_noshade

dp_nobitmap:
         mov ebp,temp2
         mov esi,connmem
         mov eax,[esi+ebp*4+p1]
         call _write_dec16
dp_cloop:
         mov temp3,ebp
         mov eax,","
         call _write_string4
         mov esi,connmem
         mov ebp,temp3
         mov eax,[esi+ebp*4+p2]
         call _write_dec16
         mov esi,connmem
         mov ebp,temp3
         mov ebp,[esi+ebp*4+wg]
         cmp temp2,ebp
         jne dp_cloop

         mov edx,thismaterial
         call find_shade
         jc dp_noshade

         mov esi,connmem
         mov ebp,temp2
         mov ebp,[esi+ebp*4+wg]
         mov ebp,[esi+ebp*4+wg]
         cmp ebp,temp2
         je dp_noshade

         cmp tnormal,no
         je normalnormal
         mov eax,","
         call _write_string4
         mov esi,connmem
         mov ebp,temp2
         mov eax,[esi+ebp*4+ea]
         shr eax,2
         mov edx,offset buffer
         call _write_neg16
         call unpad
         call _write_null
         mov eax,","
         call _write_string4
         mov esi,connmem
         mov ebp,temp2
         mov eax,[esi+ebp*4+eb]
         shr eax,2
         mov edx,offset buffer
         call _write_neg16
         call unpad
         call _write_null
         mov eax,","
         call _write_string4
         mov esi,connmem
         mov ebp,temp2
         mov eax,[esi+ebp*4+ec]
         shr eax,2
         mov edx,offset buffer
         call _write_neg16
         call unpad
         call _write_null
         jmp dp_noshade
normalnormal:
         mov edx,offset header9
         call _write_null

dp_noshade:
         call write_colon
         call _write_ret

         inc temp1
         mov ecx,temp1
         cmp ecx,surfaces
         jne dp_sloop

         call _write_ret
         ret

header0  db ";DXF23DV Converter V0.5 - This conversion conforms to version 3DVECT35",13,10,13,10,0
header1  db "h",0
header2  db "-1",13,10,"           dd offset o",0
header3  db " - offset $ - 4",13,10,13,10,"o",0
header4  db "           dw ",0
header5  db "25 dup (0)",0
header6  db "  ; point ",0
header7  db "           dd ",0
header8  db " offset o",0
header9  db ",0,0,0",0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Find if input name is a DXF or a PLG
; Defaults to DXF
; Out: CF = 1, PLG      CF = 0, DXF
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

isitadxforplg:
         mov ecx,40                    ; output header info
         mov al,"."
         mov edi,offset inputname
isloop:
         inc edi
         cmp [edi-1],al
         loopne isloop
         mov al,byte ptr [edi+0]
         upper al
         cmp al,"P"
         jne itsadxf
         mov al,byte ptr [edi+1]
         upper al
         cmp al,"L"
         jne itsadxf
         mov al,byte ptr [edi+2]
         upper al
         cmp al,"G"
         jne itsadxf
         stc
         ret
itsadxf:
         clc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Input PLG file
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

plg_getall:
         mov edx,dxfo
plg_unpad:
         call unpad
         mov al,[edx]
         cmp al,"9"
         jbe plg_start
         call next
         jmp plg_unpad

plg_start:
         mov fileloc,edx
         call _strhtn
         call _vct32
         mov temp2,eax

         mov edx,fileloc
         call next
         call _strhtn
         call _vct32
         mov surfaces,eax

         mov edx,fileloc
         call next
         call next
         mov fileloc,edx

         mov temp1,0         ; begin loading of points
plg_points:
         mov edx,fileloc
         call _get_float32
         add eax,nx
         mov ebx,scale
         imul32 ebx
         add eax,nu
         push eax

         mov edx,fileloc
         call next
         mov fileloc,edx
         call _get_float32
         add eax,ny
         mov ebx,scale
         imul32 ebx
         add eax,nv
         cmp yneg,yes
         je noynegt
         neg eax
noynegt:
         push eax

         mov edx,fileloc
         call next
         mov fileloc,edx
         call _get_float32
         add eax,nz
         mov ebx,scale
         imul32 ebx
         add eax,nw
         push eax

         mov edx,fileloc
         call next
         mov fileloc,edx

         pop ecx
         pop ebx
         pop ebp
         call check_point     ; add point to list

         mov edi,temp1
         mov polyindex[edi*4],eax
         inc temp1
         dec temp2
         jnz plg_points

         mov eax,surfaces     ; begin loading of surfaces
         mov temp2,eax
         xor eax,eax
         mov surfaces,eax

plg_pmore:
         mov edx,fileloc      ; get material.  eg: 0x8001
         call assign_material
         mov thismaterial,eax

         mov edx,fileloc
         call next
         mov fileloc,edx

         call _strhtn         ; number of connections in list
         call _vct32
         mov temp3,eax
         mov temp4,eax

         mov edx,fileloc
         call next
         mov fileloc,edx
         call _strhtn
         call _vct32

         mov start,eax
         mov ebp,connections    ; set first point in poly
         mov startconn,ebp
         mov eax,[polyindex+eax*4]
         mov esi,connmem
         mov [esi+ebp*4+p1],eax

         cmp temp3,1
         je plg_close
         dec temp3
plg_ll:
         mov edx,fileloc
         call next
         mov fileloc,edx
         call _strhtn
         call _vct32

         mov ecx,[polyindex+eax*4]
         mov ebp,start
         cmp ecx,[polyindex+ebp*4]
         je plg_closez

         call addpoint
         dec temp3
         jnz plg_ll
         jmp plg_close

plg_closez:
         dec temp3
         jz plg_close
         mov edx,fileloc
         call next
         mov fileloc,edx
         jmp plg_closez

plg_close:
         mov edx,fileloc
         call next
         mov fileloc,edx

         mov eax,startconn
         mov ebp,connections
         mov esi,connmem
         mov [esi+eax*4+wc],ebp
         mov [esi+ebp*4+wg],eax
         mov ebx,start
         mov ebx,[polyindex+ebx*4]
         mov [esi+ebp*4+p2],ebx
         mov eax,thismaterial
         mov [esi+ebp*4+mt],eax
         mov eax,surfaces
         mov [esi+ebp*4+sd],eax

         cmp temp4,2
         jle plg_nnor

         mov esi,connmem
         mov edx,startconn
         mov ebx,[esi+(edx+0)*4+p1]
         mov ecx,[esi+(edx+0)*4+p2]
         mov ebp,[esi+(edx+1)*4+p2]
         call acalc_normal

         mov esi,connmem
         mov eax,startconn
plg_applyl:
         mov [esi+(eax+0)*4+ea],ebx
         mov [esi+(eax+0)*4+eb],ecx
         mov [esi+(eax+0)*4+ec],ebp
         mov [esi+(eax+0)*4+ed],edx
         mov eax,[esi+(eax+0)*4+wg]
         cmp eax,startconn
         jbe plg_applyl

plg_nnor:
         inc connections
         inc surfaces

         cmp layer,no
         je plg_pnosel
         mov ecx,thismaterial
         call find_info
         cmp edx,offset fidefault
         jne plg_pnosel

         mov ecx,startconn
         mov esi,connmem
         xor eax,eax
plg_clrl:
         mov [esi+(ecx+0)*4+ea],eax
         mov [esi+(ecx+0)*4+eb],eax
         mov [esi+(ecx+0)*4+ec],eax
         mov [esi+(ecx+0)*4+ed],eax
         inc ecx
         cmp ecx,connections
         jne plg_clrl

         mov ecx,startconn
         mov connections,ecx
         dec surfaces

plg_pnosel:
         dec temp2
         jnz plg_pmore

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Randomize number
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_randomize:
         xor eax,randomnumber
         xor eax,edx
         xchg al,ah
         add eax,0cd9c9a8fh
         xor eax,esi
         add eax,edi
         xor eax,0526dafb2h
         add eax,ecx
         xor eax,ebx
         add eax,ebp
         mov randomnumber,eax
         in al,64
         shl eax,8
         in al,65
         shl eax,8
         in al,64
         shl eax,8
         in al,64
         add randomnumber,eax
         mov eax,randomnumber
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Get 8 bit random number from all random bits
; In: Randomnumber
; Out: AL = 8 bit result of all 32 random bits
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_random8:
         mov eax,randomnumber
         xor ah,al
         shr eax,8
         xor ah,al
         shr eax,8
         xor ah,al
         shr eax,8
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Find if "rnd" is on line
; In: EDX => ASCIIZ string
; Out: ECX => rnd   EDX = EDX
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

find_rnd:
         mov ecx,edx
find_rndq:
         mov al,[ecx]
         cmp al,0
         je fsnornd
         inc ecx

         upper al
         cmp al,"R"
         jne find_rndq
         mov al,[ecx+0]
         upper al
         cmp al,"N"
         jne find_rndq
         mov al,[ecx+1]
         upper al
         cmp al,"D"
         jne find_rndq

         dec ecx
         clc
         ret
fsnornd:
         stc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Find if a colon ":" is on line
; In: EDX => ASCIIZ string
; Out:
;   CF = 1 - not found
;    ECX => end of line
;    EAX = 0
;    EDX = EDX
;   CF = 0 - found
;    ECX => ":"
;    EAX => ":"
;    EDX = EDX
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

find_col:
         mov ecx,edx
find_colq:
         mov al,[ecx]
         cmp al,0
         je fsnocol
         inc ecx

         upper al
         cmp al,":"
         jne find_colq

         dec ecx
         mov eax,ecx
         clc
         ret
fsnocol:
         xor eax,eax
         stc
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Write material to file:
;   check for occurance of RND - place number of found
;   check for occurance of colon - place 0 where found, copy to buffer
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

temp5    dd 0

write_mat:
         mov temp5,0
         call find_rnd
         jc _write_coln
_write_nullx:
         mov al,[ecx]
         push ax
         mov al,[ecx+1]
         push ax
         mov al,[ecx+2]
         push ax
         push ecx
         push edx
         push ecx

         call _randomize
         call _random8
         call _cv16

         pop ecx
         push eax
         and al,0fh
         add al,"0"
         mov [ecx+2],al
         pop eax
         push eax
         shr eax,4
         and al,0fh
         add al,"0"
         mov [ecx+1],al
         pop eax
         shr eax,8
         and al,0fh
         add al,"0"
         mov [ecx+0],al

         pop edx
         inc temp5
         call find_rnd
         jnc _write_nullx
         call _write_coln
wri_nx:
         pop ecx
         pop ax
         mov [ecx+2],al
         pop ax
         mov [ecx+1],al
         pop ax
         mov [ecx],al
         dec temp5
         jnz wri_nx

         ret

_write_coln:
         call find_col
         mov colon,eax
         mov byte ptr [ecx],0
         jmp _write_null

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Write out color buffer and restore material (if colon <>0)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

write_colon:
         mov edx,colon
         or edx,edx
         jz wc_nodata

         mov byte ptr [edx],":"
         inc edx
         call _write_null

wc_nodata:
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Sort_them:  Sort surfaces based on equation of plane
; Notes: This routine was much simpler, but it was too slow with objects
;        greater than about 800 surfaces. old sort: 800=3 minutes to sort, yuk!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

sort_them:
         cmp shouldisort,no
         je _ret
         cmp surfaces,2
         jl _ret

         mov edx,offset okmsg6
         call _putdosmsg

         call prep_num
         call prep_normal

         mov temp1,0
         mov temp2,1
st_inner:
         mov eax,temp1
         mov ebx,temp2

         call testeq
         jle st_noswitch

         mov eax,temp1
         mov ebx,temp2
         call switch_em

st_noswitch:
         inc temp2
         mov eax,surfaces
         cmp temp2,eax
         jnae st_inner
         mov eax,temp1
         inc eax
         mov temp2,eax

         inc temp1
         mov eax,surfaces
         dec eax
         cmp temp1,eax
         jnae st_inner

         call re_apply

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Testeq: Compare normal EAX against normal EBX
;  In:
;  EAX = connection for first compare
;  EBX = connection for second compare
;  Out:
;   jl less
;   je equal
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

testeq:
         mov esi,connmem
         mov edx,[esi+eax*4+bv]
         mov ebp,[esi+ebx*4+bv]

         mov ecx,[esi+(ebp)*4+ed] ; get surface normal for inner loop
         cmp ecx,[esi+(edx)*4+ed] ; get surface normal for outer loop
         jne _ret

         mov ecx,[esi+(ebp)*4+ec]
         cmp ecx,[esi+(edx)*4+ec]
         jne _ret

         mov ecx,[esi+(ebp)*4+eb]
         cmp ecx,[esi+(edx)*4+eb]
         jne _ret

         mov ecx,[esi+(ebp)*4+ea]
         cmp ecx,[esi+(edx)*4+ea]
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Switch_em: Switch surfaces EAX and EBX
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

switch_em:
         mov esi,connmem
         mov ecx,[esi+eax*4+sk]
         mov edi,[esi+ebx*4+sk]
         mov [esi+eax*4+sk],edi
         mov [esi+ebx*4+sk],ecx
         mov ecx,[esi+eax*4+bv]
         mov edi,[esi+ebx*4+bv]
         mov [esi+eax*4+bv],edi
         mov [esi+ebx*4+bv],ecx
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Number surfaces in preparation for sort
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

prep_num:
         mov esi,connmem
         xor eax,eax
         mov ecx,surfaces
prep_loop:
         mov [esi+eax*4+sk],eax
         inc eax
         loop prep_loop

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Prepare normal indexers ready for sort
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

prep_normal:
         mov temp1,0
         mov eax,surfaces
         mov temp2,eax
prep_lp:
         mov ebx,temp1
         call rn_lowest
         mov ebx,temp1
         mov esi,connmem
         mov [esi+ebx*4+bv],ebp
         inc temp1
         dec temp2
         jnz prep_lp

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; re_apply sort to surface list
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

re_apply:
         mov temp1,0
re_loop1:
         mov esi,connmem
         mov eax,temp1
         mov ebx,[esi+eax*4+sk]
         xchg eax,ebx
         add ebx,128000
         call rn_eax2ebx
         inc temp1
         mov eax,surfaces
         cmp temp1,eax
         jnae re_loop1

         mov temp1,0
re_loop2:
         mov esi,connmem
         mov eax,temp1
         mov ebx,[esi+eax*4+sk]
         mov eax,ebx
         add eax,128000
         call rn_eax2ebx
         inc temp1
         mov eax,surfaces
         cmp temp1,eax
         jnae re_loop2

         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Change any underscore characters to commas
; In:
;  EDX => ASCIIZ Material to scan/change
; Out:
;  EDX = EDX   if no change
;  EDX = EDX+1 if no changed material
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같


change_underscore:
         cmp byte ptr [edx],"_"
         jne _ret

         inc edx      ; direct copy command used, scan for _ and replace with ,
         mov edi,edx
         mov ecx,31
         mov al,0
         repne scasb
         jcxz _ret

         mov edi,edx
         neg ecx
         add ecx,31
         jcxz _ret

         mov al,"_"
cu_morescan:
         repne scasb
         jcxz _ret
         mov byte ptr [edi-1],","
         jmp cu_morescan

code32   ends
         end
