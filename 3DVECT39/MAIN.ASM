;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : Main.asm
; Included from: Main Assembley Module
; Description  : Main demo of 3dvector library
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
; Send me your protected mode source code!
; Send me your Objects!
; But most of all, Send me a postcard!!!!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         .386p
         jumps

code32   segment para public use32
         assume cs:code32, ds:code32

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; define externals
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         include pmode.ext                  ; protected mode externals
         include xmouse.ext                 ; xmode mouse externals
         include xmode.ext                  ; xmode externals by matt pritchard
         include 3d.ext
         include irq.ext
         include stars.ext
         include font.ext
         include file.ext
         include land.ext
         include argc.ext
         include joystick.ext
         include fade.ext
         include kb.ext
         include function.ext
         include clear.ext
         include gus.ext
         include fx.ext

         include macros.inc
         include equ.inc

         include sphere.inc
         include palette.inc                ; palette

         include objects.inc                ; table of shapes/colours
         include stone0.inc
         include stone1.inc
         include stone2.inc
         include stone3.inc
         include stone4.inc
         include stone5.inc
         include stone6.inc
         include stone7.inc
         include stone8.inc
         include stone9.inc
         include stonea.inc
         include stoneb.inc
         include stonec.inc
         include stoned.inc
         include stonee.inc
         include stonef.inc

         include font0.inc                  ; font 0
         include font1.inc                  ; font 0
         include font2.inc                  ; font length tables

         include explode.ext
         include loadgif.ext
         include dump.glz

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; code
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

giffile  db "main.gif",0
giffile2 db "target.gif",0

         public _main
_main:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; get enviornment: current directory, current file
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         sti
         call _setup_env                    ; set up file envirionment (eg c:\temp\thisprog.exe )
         call _initkb

         mov eax,_lomembase
         mov _filebufloc,eax
         mov _filebuflen,4000h
         add _lomembase,4000h

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sound effects stuff
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        ;call _sfx_find

        ;mov edx,_lomembase          ; DMA buffer        * all this data is ignored *
        ;mov ebx, 1024               ; DMA buffer size   *  if the user has a GUS   *
        ;mov ecx, 22000              ; sample rate
        ;mov eax,_lomembase
        ;add eax, ebx                ; samples are right after DMA buffer
        ;call _sfx_init              ; call this for both soundcards
        ;imul ebx,14042              ; 14042 bytes of sample memory required (0 if GUS)
        ;add _lomembase,eax          ; bump up low memory because of DMA (0 if GUS)
        ;add _lomembase,ebx          ; bump up low memory because of samples required (0 if GUS)

        ;mov edi,offset soundname    ; list of sound effects to load...
        ;mov edx,_lomembase
        ;call _load_sams

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; check for and load 669 - link with argc,kb,gsp669,gs
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; get timer IRQ running
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _irq_setpmirq                 ; set irq running - must be done at start for palette fading
         mov ax, 21694                 ; 1193180/(55 frames a second)
         call _irq_set_timer

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; explode DOS palette to common colour
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov eax,00003f00h                  ; what color to fade to
         mov bh,12                          ; how much to fade each pel
         mov bl,255                         ; how often should i fade the palette
        ;call _fade_all                     ; fade it...
        ;call _wait_for_fade

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; fade palette to black
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov eax,00000000h                  ; what color to fade to
         mov bh,1                           ; how much to fade each pel
         mov bl,120                         ; how often should i fade the palette
        ;call _fade_all                     ; fade it...
        ;call _wait_for_fade

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set xmode
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         pushw xmode
         pushw xactual
         pushw yactual
         pushw pages
         call _set_vga_modex
         cmp ax,-1                          ; test for error in setting videomode
         jne getout
         pushw 1
         call _set_active_page

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; wipe palette after xmode call ('cause INT 10h resets the palette)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov eax,00000000h
         call _wipeoffpalette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set up pointers to object shape data
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call setupbase
         call _joy_calibratejoystick

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; initialize xmode page flipping, font style, and get mouse ready
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov esi,o _font0
         mov edi,o _font1
         mov ebp,o _fontlength
         call _initfont

        ;pushw 150
        ;pushw 150
        ;push offset ex3
        ;push offset mousesavemap
        ;pushw 0
        ;pushw xactual
        ;pushw 0
        ;pushw yactual
        ;call _show_mouse

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; draw borders, title, and cosmetic screen stuff
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov esi,o runscreen                ; this uses the font.asm setup routines
        ;call _fnt_tstring
         mov esi,o runtext
        ;call _fnt_tstring

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; use IRQ to fade palette on
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov esi,o gamecolr
         mov bh,1
         mov bl,180
         call _fade_palette_read

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set clipping paramters (already done, but this shows how set new parameters)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov ax,xmin
         mov bx,ymin
         mov cx,xmax
         mov dx,ymax
        ;call _set_clip_absolute

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set clipping parameters, (these are already set on startup so this isnt really needed)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov ax,xmin
         mov bx,ymin
         mov cx,xmax
         mov dx,ymax
         mov si,_xcenter
         mov di,_ycenter
        ;call _set_clip_offset

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; initialize the _bitmaps: remember first two words are x and y size
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov _bitbase[0*4],offset sphere
         mov _bitx[0*4],30
         mov _bity[0*4],30

         mov _stonetbl[0*4],o headerf       ; stone texture table (second half), 16 shades spread over 32
         mov _stonetbl[1*4],o headerf
         mov _stonetbl[2*4],o headere
         mov _stonetbl[3*4],o headere
         mov _stonetbl[4*4],o headerd
         mov _stonetbl[5*4],o headerd
         mov _stonetbl[6*4],o headerc
         mov _stonetbl[7*4],o headerc
         mov _stonetbl[8*4],o headerb
         mov _stonetbl[9*4],o headerb
         mov _stonetbl[10*4],o headera
         mov _stonetbl[11*4],o headera
         mov _stonetbl[12*4],o header9
         mov _stonetbl[13*4],o header9
         mov _stonetbl[14*4],o header8
         mov _stonetbl[15*4],o header8
         mov _stonetbl[16*4],o header7
         mov _stonetbl[17*4],o header7
         mov _stonetbl[18*4],o header6
         mov _stonetbl[19*4],o header6
         mov _stonetbl[20*4],o header5
         mov _stonetbl[21*4],o header5
         mov _stonetbl[22*4],o header4
         mov _stonetbl[23*4],o header4
         mov _stonetbl[24*4],o header3
         mov _stonetbl[25*4],o header3
         mov _stonetbl[26*4],o header2
         mov _stonetbl[27*4],o header2
         mov _stonetbl[28*4],o header1
         mov _stonetbl[29*4],o header1
         mov _stonetbl[30*4],o header0
         mov _stonetbl[31*4],o header0

         mov _xreftable[32*4],offset xref0 ; glenz vector cross referancing tables
         mov _xreftable[33*4],offset xref0
         mov _xreftable[34*4],offset xref1
         mov _xreftable[35*4],offset xref1
         mov _xreftable[36*4],offset xref2
         mov _xreftable[37*4],offset xref2
         mov _xreftable[38*4],offset xref3
         mov _xreftable[39*4],offset xref3
         mov _xreftable[40*4],offset xref4
         mov _xreftable[41*4],offset xref4
         mov _xreftable[42*4],offset xref5
         mov _xreftable[43*4],offset xref5
         mov _xreftable[44*4],offset xref6
         mov _xreftable[45*4],offset xref6
         mov _xreftable[46*4],offset xref7
         mov _xreftable[47*4],offset xref7
         mov _xreftable[48*4],offset xref8
         mov _xreftable[49*4],offset xref8
         mov _xreftable[50*4],offset xref9
         mov _xreftable[51*4],offset xref9
         mov _xreftable[52*4],offset xref10
         mov _xreftable[53*4],offset xref10
         mov _xreftable[54*4],offset xref11
         mov _xreftable[55*4],offset xref11
         mov _xreftable[56*4],offset xref12
         mov _xreftable[57*4],offset xref12
         mov _xreftable[58*4],offset xref13
         mov _xreftable[59*4],offset xref13
         mov _xreftable[60*4],offset xref14
         mov _xreftable[61*4],offset xref14
         mov _xreftable[62*4],offset xref15
         mov _xreftable[63*4],offset xref15

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; plop some objects in space
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; camera location/angle
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov esi,cameraobject               ; set the camera position
         mov bx,0                           ; camera angle
         mov cx,-16384
         mov bp,0
         call _set_angle
         mov ebx,1350000                    ; camera position
         mov ecx,20000
         mov ebp,-15000
         call _put_object

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; temple
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object ; return si as next available object (1)
         call _init_object
         mov ebx, 510000                    ; to this position (x,y,z)=ebx,ecx,ebp
         mov ecx, 160000                    ; locations are 32 bit
         mov ebp,-240000
         call _put_object                   ; plop..
         mov bx,0                           ; angles are 16 bit
         mov cx,0
         mov bp,0
         call _set_angle                    ; duhhh...i wonder what this call does...
         call _set_object_on                ; turn object si on (make visible)
         call _use_full_rotations           ; full rotations for this object (0)
         mov _userotate[esi],0              ; full rotations for this object (0)
         mov ax,0
         call _set_shape                    ; set object si to shape ax
         mov ebx,000545100h                 ; x,y,z angular velocities
         mov ecx,000a91500h                 ; high word = number of turns/revolutions
         mov ebp,000342300h                 ; lo word = final angle (position)
         mov di,58000                       ; di = time to twist there (total frames)
         call _twist_si                     ; set angular velocity
         call _set_xyzvadds
         mov bl,0                           ; set cross referencing palette (null)
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; wireframe cube
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object
         call _init_object
         mov ebx,230000
         mov ecx,20000
         mov ebp,350000
         call _put_object
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_on
         call _use_full_rotations           ; full rotations for this object (0)
         mov ax,1
         call _set_shape
         mov ebx,000500000h
         mov ecx,000200000h
         mov ebp,000300000h
         mov di,65500
         call _twist_si
         call _set_xyzvadds
         mov bl,0
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; ring
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object
         call _init_object
         mov ebx,80000
         mov ecx,410000
         mov ebp,160000
         call _put_object
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_on
         call _use_full_rotations           ; full rotations for this object (0)
         mov ax,2
         call _set_shape
         mov ebx,000310124h
         mov ecx,0ffbc2340h
         mov ebp,000530100h
         mov di,16000
         call _twist_si
         call _set_xyzvadds
         mov bl,0
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; diamond
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object
         call _init_object
         mov ebx,160000
         mov ecx,-230000
         mov ebp,180000
         call _put_object
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_on
         call _use_full_rotations           ; full rotations for this object (0)
         mov ax,3
         call _set_shape
         mov ebx,000600000h
         mov ecx,0fff23400h
         mov ebp,000100000h
         mov di,21000
         call _twist_si
         call _set_xyzvadds
         mov bl,0
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; rubine (flat diamond)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object
         call _init_object
         mov ebx, 110000                    ; to this position (x,y,z)=ebx,ecx,ebp
         mov ecx,-200000                     ; locations are 32 bit
         mov ebp,-400000
         call _put_object
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_on
         call _use_full_rotations           ; full rotations for this object (0)
         mov ax,4
         call _set_shape
         mov ebx,000200000h
         mov ecx,000100000h
         mov ebp,0ffa00000h
         mov di,12000
         call _twist_si
         call _set_xyzvadds
         mov bl,0
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; vectorball cube thingy
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object ; this next object is the bitmaped cube
         call _init_object
         mov ebx,750000                    ; remove this and see the speed of
         mov ecx,110000                    ; only vectors
         mov ebp,-60000
         call _put_object                   ; note: the _bitmaps take a lot of cpu time
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_on
         call _use_full_rotations           ; full rotations for this object (0)
         mov ax,5
         call _set_shape
         mov ebx,000300000h
         mov ecx,000700000h
         mov ebp,000500000h
         mov di,13000
         call _twist_si
         call _set_xyzvadds

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; stand alone _bitmap
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object ; stand alone bitmap - good for smoke or
         call _init_object
         mov ebx,-5000                      ; explosions
         mov ecx,5000
         mov ebp,25000
         call _put_object                   ; set location
         call _set_object_on                ; turn it on
         mov ax,0                           ; zeroth _bitmap is shape
         call _set_shape                    ; will load from _bitbase[0]
         call _set_to_hi_bitmap             ; it's a bitmap...
         mov bx,500                         ; _bitmap scaling (gets added to _bitx and _bity)
         mov cx,500                         ; _bitmap scaling bx=x scaling, cx=y scaling
         call _set_bitmap_scaling

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; this is the body of those wierd three blocks
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _search_next_available_object
         call _init_object
         mov ebx,-190000
         mov ecx,-280000
         mov ebp,-140000
         call _put_object
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_on
         call _use_full_rotations
         mov ax,6
         call _set_shape
         mov ebx,000600000h
         mov ecx,0fff23400h
         mov ebp,000200000h
         mov di,16000
         call _twist_si
         call _set_xyzvadds
         mov bl,0
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; this defines one "arm" of that wierd block - remember, it is "attached" to the body above
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         inc esi
         call _init_object
         mov ebx,0/256                      ; this is not an actual object, it is only
         mov ecx,0/256                      ; a reference to where the arm will get
         mov ebp,0/256                      ; the angle data from.
         call _put_object                   ; _put_object sets location of arm relative to body
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle                    ; set initial angle of arm (relative to body)
         call _set_object_off
         call _set_sub_object_on
         call _use_full_rotations           ; full = rotation is relative to body , no = arm angle is not relative to body
        ;mov ax,xx                          ; arm shape is already defined in block above
        ;call _set_shape
         mov ebx,000200000h                 ; set anglular velocity of arm (relative to body)
         mov ecx,000600000h
         mov ebp,000120000h
         mov di,22000
         call _twist_si
         call _set_xyzvadds
         mov bl,0                           ; not an object, just angle and location data
         call _set_xref_palette             ; so we dont need this

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; this defines the other "arm"
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         inc esi
         call _init_object
         mov ebx,0/256                      ; the locations of sub_objects are /256 because of the way
         mov ecx,0/256                      ; conversion between real space co-ordinates and object
         mov ebp,0/256                      ; co-ordinates are calculated.  objects are 256 times larger than their appearance in real space
         call _put_object                   ; this is because there is greater accuracy in real space!!
         mov bx,0
         mov cx,0
         mov bp,0
         call _set_angle
         call _set_object_off
         call _set_sub_object_on
         call _use_full_rotations           ; full = rotation is relative to body , no = arm angle is not relative to body
        ;mov ax,xx
        ;call _set_shape
         mov ebx,000220000h
         mov ecx,0ff700000h
         mov ebp,0ffe30000h
         mov di,18000
         call _twist_si
         call _set_xyzvadds
         mov bl,0
         call _set_xref_palette

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; get objects moving
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _irq_findcontrol
         mov _irqcontrol[ecx*4],o _updvectors

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; make camera _rotate_point along z axis if you want - make sure equ.inc has "use_z equ yes"
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         ;mov _eyezadds,50                  ; make the camera _rotate_point along it's z axis (just for fun)
         ;mov esi,cameraobject

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; reset IRQ counter before animation begins
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _irq_resetrastercount         ; done before any animation loop!!!

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; intialize 3d pointers\indexers\sortvalues
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _init_tables                  ; initialize 3d vector stuff

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; example of how to point an object toward another object in a certin time
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         ;mov esi,5                         ; an example of how to use _point_time
         ;mov ebx,-10000                    ; si = obj, bx,cx,bp = location, di = time
         ;mov ecx,-30000
         ;mov ebp,90000
         ;mov edi,150
         ;call _point_time

         call _irq_findcontrol
         mov _irqcontrol[ecx*4],offset _handle_explosions

         mov ebp,_himembase
         mov dl,0
         call _compile_background_dl
         mov clearroutine,ebp

         mov cc3, edi


         jmp jjjjj

clearroutine dd 0
cc2          dd offset _ret
cc3 dd 0

jjjjj:
         mov _himembase,edi

         mov edx,offset giffile
         call _openfile
         jc nogif

         mov edx,_lomembase
         mov ecx,_lomembase
         add edx,8000h
         mov eax,offset _readfile
         call _loadgif

         if yactual lt 400
         call _gif_squeeze_y
         endif
        ;call _gif_squeeze_y
        ;call _gif_squeeze_x

         call _closefile

         push edx
         push edx
         push edx

         pushw 0
         pushw 0
         call _draw_bitmap
         call _flip_page
         pushw 0
         pushw 0
         call _draw_bitmap

         pop eax
         mov bx,0
         mov cx,0
         mov dl,0
         mov ebp,cc3
         call _compile_foreground

         mov cc2,ebp
         mov _himembase,edi
nogif:
         mov edx,offset giffile2
         call _openfile
         jc nogif2

         mov edx,_lomembase
         mov ecx,_himembase
         add edx,8000h
         mov eax,offset _readfile
         call _loadgif

         if yactual lt 400
         call _gif_squeeze_y
         endif

         call _closefile

         pushw 150
         pushw 150
         push edx
         push offset mousesavemap
         pushw 0
         pushw xactual
         pushw 0
         pushw yactual
         call _show_mouse
nogif2:



;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; THE MAIN LOOP...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

ieox:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; point an object toward the camera (just a cheap example)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         ;mov esi,0                         ; try uncommenting this!, this will point
         ;mov edi,2
         ;call _get_displacement
         ;mov esi,2
         ;mov  ax,_vys[esi*2]
         ;mov  di,_vxs[esi*2]
         ;call _point_z
         ;mov esi,2
         ;mov _vzs[esi*2],ax

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; debugging tool: would you believe some idiot actually called me to tell me I
;                 needed more debugging tools - I told him he  needs  to  stop
;                 writing programs with bugs...
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         ;mov eax,your_problem              ; debugging tool                                                    mov eax,your_problem      ; debugging tool!!!!
         ;mov _number_eax,eax
         ;call _put_at_top

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; make sun move around
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         ;add _y_angle_of_sun,150           ; watch the red ring carefully! the sun will move around the room!

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; make camera respond to joystick
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         joystickobject equ 0

         call _joy_cartisianjoystick

         neg ebx                            ; makes the joystick like an airplane...sorta...
         shr ebx,5
         shr eax,5

         mov _vxadds[joystickobject*2],bx
         mov _vyadds[joystickobject*2],ax
         mov _vzadds[joystickobject*2],0
         mov _acountx[joystickobject*2],65000
         mov _acounty[joystickobject*2],65000
         mov _acountz[joystickobject*2],65000
         call _fix_xangle                   ; make it so user doesn wrap around upside down. (so stars wont mess up)

zapl:
         call _joy_justgetbutton
         test al,2                         ; test if second button pressed
         jz dobut2

         dec d qqx

         and eax,1
         xor eax,1
         imul eax,18000

         mov esi,joystickobject             ; move camera...esi - object
         mov ebp,eax                        ; ebp = speed (make it faster!)
         mov edi,10                         ; edi = total time (not in calculation)
         call _set_speed                    ; move object in direction it is pointing
         call _set_xyzadds
         jmp contxx
dobut2:
comment %
         mov edx,offset _explode_main0
         mov ebx,110000 ; x,y,z of explosion
         mov ecx,25000
         mov ebp,-700000
         mov esi,0 ; scaling
         mov edi,0
         call _start_explosion
         jc contxx

         push esi

         mov _xadds[esi*4],05000
         mov _zadds[esi*4],20000
         mov _lcount[esi*2],300

         mov edx,offset _explode_small
         mov ebx,180000 ; x,y,z of explosion
         mov ecx,85000
         mov ebp,-600000
         mov esi,0 ; scaling
         mov edi,0
         call _start_explosion

         pop esi

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
         mov ecx,randomnumber

         call _get_location
         call _subtract_camera
         call _determine_volume
         call _determine_panning


         mov ax,0
         mov dl,0
         mov cl,0

         and ch,7
         mov ch,30
         call _play_sample


         jmp contxx

randomnumber    dd 5fe6c809h
        %
         and eax,2
         shr eax,1
         xor eax,1
         imul eax,-18000                    ; if button 2 pressed, move camera backwards

         mov esi,joystickobject             ; move camera...esi - object
         mov ebp,eax                        ; ebp = speed (make it faster!)
         mov edi,10                         ; edi = total time (not in calculation)
         call _set_speed                    ; move object in direction it is pointing
         call _set_xyzadds
contxx:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; set camera rotation matrix - done once per frame so other routines know how to plot objects
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _copy_virtual_objects
         call _setsincose                   ; set rotation multipliers for eye
        ;call _land_draw                    ; draw background landscape

         mov edi,_current_page
         call clearroutine

        ;call _clearfill                    ; clear video memory before plot

        ;mov esi,1
        ;mov edi,50000
        ;mov ebp,9200
        ;call _set_speed
        ;call _set_xyzadds

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; plot the stars in the _background
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _star_plot                    ; plot background stars

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; plot all objects on screen
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _makeobjs                     ; plot all objects in sides table

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; plot mouse on screen - only a 1 page mouse so it flickers on two pages
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

;         call _instant_mouse               ; plot mouse on screen
;         call _plot_mouse

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; show how long it took to draw that last screen
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         ;mov eax,_irq_tracespast           ; show number of traces past per re-draw
         ;mov _number_eax,eax
         ;call _put_at_top

         mov edi,_current_page
         mov al,1
         call cc2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; show user the new screen
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _flip_page                    ; flip video pages

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; test escape key - if none, return to top of main loop
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         in al,60h                          ; test keyboard
         cmp al,1
         jne ieox
ieo_x2:
         in al,60h                          ; test keyboard
         cmp al,1
         je ieo_x2
getout:

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; make endpage screen
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov eax,0
         mov bh,3
         mov bl,200
         call _fade_all
        ;call _wait_for_fade

         call _mode03
         mov eax,0
         call _wipeoffpalette

         mov edx,offset endtext
         call _putdosmsg

         mov esi,o _default_palette
         mov bh,3
         mov bl,255
         call _fade_palette_read
         call _wait_for_fade
         call _resetkb

         call _irq_resetpmirq               ; reset irq vectors
         call _sfx_uninit                   ; done, clear soundcard

         jmp _exit

qqx dd 400

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sample routines to show how to use some routines
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

comment  %
         push offset gamecolr
         pushw 0
         pushw 255
         pushw 1
         call _load_dac_registers
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov esi,04                         ; esi = object
         mov edi,55                         ; edi = time to get there (# of frames)
         call _cam_newfollow
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov ebx,x
         mov ecx,y
         mov ebp,z
         mov edi,time
         mov esi,cameraobject
         call _move_si
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         block 0,0,319,399,14
         call _flip_page
         block 0,0,319,399,14
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         call _flip_page                    ; example of how to draw a single polygon

         p1x equ -50
         p1y equ -50
         p2x equ -90
         p2y equ 70
         p3x equ 60
         p3y equ 80

         mov _x1,p1x
         mov _y1,p1y
         mov _x2,p2x
         mov _y2,p2y
         call _fakeline_horz

         mov _x1,p2x
         mov _y1,p2y
         mov _x2,p3x
         mov _y2,p3y
         call _fakeline_horz

         mov _x1,p3x
         mov _y1,p3y
         mov _x2,p1x
         mov _y2,p1y
         call _fakeline_horz

         mov _colq,7
         mov steel,-1
         call _polyfill

         call _flip_page

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         mov si,6                           ; move cube around...si - object
         mov ebp,45000                      ; ebp = speed (make it faster!)
         mov di,600                         ; di = total time (not in calculation)
         call _set_speed                    ; move object in direction it is pointing
         call _set_xyzadds
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
%

gtab     db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 011h,012h,013h,014h,015h,016h,017h,018h
         db 019h,01ah,01bh,01ch,01dh,01eh,01fh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
         db 010h,011h,012h,013h,014h,015h,016h,017h
         db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh

         public _putdosmsg
_putdosmsg:
         push ax
         push edx
         add edx,_code32a
         mov al,dl
         and ax,0fh
         shr edx,4
         mov v86r_ds,dx
         mov v86r_dx,ax
         mov v86r_ah,9
         mov al,21h
         int 33h
         pop edx
         pop ax
         ret

hextbl   db '0123456789ABCDEF'

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
; Put 8 digit hex number to screen buffer
; In:
;   EAX - number to put
;   EDI -> screen buffer location to put at
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
_puthexnum:
         push eax ebx ecx edx edi
         mov ebx,offset hextbl
         mov edx,eax
         mov ecx,8
         mov ah,0fh
puthexnuml0:
         rol edx,4
         mov al,dl
         and al,0fh
         xlat
         stosw
         loop puthexnuml0
         pop edi edx ecx ebx eax
         ret

wipe_v_memory:
         rlp edi,0a0000h                    ; wipe video memory
         mov ecx,320*200*4/4/4
         xor eax,eax

         rep stosd

         ret

endtext  db "Doesn't that red diamond look great!",13,10
         db 13,10
         db "John McCarthy tries to be a regular on Digital Pixel: (416) 298-1487",13,10
         db " and on the Toronto VR SIG: (416) 631-6625",13,10
         db 13,10
         db "Or write to this address:",13,10
         db 13,10
         db " John McCarthy",13,10
         db " 1316 Redwood Lane",13,10
         db " Pickering, Ontario.",13,10
         db " Canada, Earth, Milky Way. (for those out-of-towners)",13,10
         db " L1X 1C5",13,10
         db "$"

; screen text for font routines

runscreen:
         border 0,0,xactual-1,yactual-1,16*3
         steelbox 3,3,xactual-1-3,yactual-1-3,16*3,28
         hole xmin+_xcenter-2,ymin+_ycenter-2,xmax+_xcenter+1,ymax+_ycenter+1,16*3
         fillarea xmin+_xcenter,ymin+_ycenter,xmax+_xcenter-1,ymax+_ycenter-1,0
         textend

runtext:
         newtext 35,13,14
         db "3D Vectors in 320x400 Mode-X"

         lowercase

         newtext 15,yactual-32,14
         db "Vector Routines by John McCarthy"

         newtext 11,yactual-22,9
         db "X-Mode Routines by Matt Pritchard"

         newtext 23,yactual-12,12
         db "Protected Mode Header by TRAN"

         textend

mc       = 208                              ; mouse colour block (cyan)

mousebitmap:
         dw 9,9                             ; 9x9 mouse

         db mc+12,mc+12,mc+12,mc+12,mc+12,mc+12,mc+12,mc+12, 0 ; hmmm, I wonder  where
         db mc+02,mc+10,mc+11,mc+11,mc+11,mc+11,mc+05, 0, 0    ; this mouse image came
         db mc+01,mc+08,mc+11,mc+11,mc+11,mc+06, 0, 0, 0       ; from?...sorry guys..
         db mc+00,mc+07,mc+11,mc+11,mc+11,mc+11,mc+12, 0, 0
         db mc+00,mc+05,mc+11,mc+06,mc+11,mc+11,mc+11,mc+12, 0
         db mc+00,mc+04,mc+03,mc+00,mc+03,mc+11,mc+11,mc+11,mc+12
         db mc+00,mc+02,mc+00, 0,mc+00,mc+03,mc+09,mc+05,mc+01
         db mc+00,mc+00, 0, 0, 0,mc+00,mc+03,mc+01, 0
         db 0, 0, 0, 0, 0, 0,mc+00, 0, 0

mousesavemap:
         db 64*64+4 dup (0)

;mousebitmap:
;         dw mousewidth,mouseheight
;         db 9,9,9,9,9,0 ; simple 6x6 mouse
;         db 9,9,9,9,0,0
;         db 9,9,9,9,0,0
;         db 9,9,9,9,9,0
;         db 9,0,0,9,9,9
;         db 0,0,0,0,9,0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Relate point to look and and "sky" point to X,Y and Z angles
; In:
;  EBX = x point to look at
;  ECX = y point to look at
;  EBP = z point to look at
;  EAX = x "sky" point
;  EDX = y "sky" point
;  EDI = z "sky" point
;  ESI = object to obtain angles from
; Out:
;  Angles for object ESI modified!
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_rel_point:
         push esi eax edx edi esi
         call _inverse_rotate
         call _calc_middle
         pop esi
         mov _vxs[esi*2],ax
         mov _vys[esi*2],bx
         mov di,ax
         mov ax,bx
         pop ebp ecx ebx
         call _point_z
         pop esi
         mov _vzs[esi*2],ax
         ret

code32   ends
         end

