;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Filename     : Poly.inc
; Included from: 3D1.ASM, 3D2.ASM, 3D3.ASM
; Description  : 3D xmode, polyfill and object handling routines
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

         public _polyfill                   ; fill polygon
         public _fakeline_horz              ; draw line in memory buffer
         public _fakeline_vert              ; draw line in memory buffer (glenz)
         public _set_clip_absolute          ; set clipping parameters - absolute
         public _set_clip_offset            ; set clipping parameters - offset
         public _fastimultable              ; fast imul table, dw 0-319 * 200
         public _clipped_line               ; draw clipped line from dx,cx to ax,bx colour bp
         public _sortlist                   ; sort vector list
         public _drawvect                   ; draw vectors from command list
         public _copy_virtual_objects       ; copy real objects to virtual list

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _polyfill: Draws a filled polygon given table left and right addresses
;
; In:
;    Regs=none
;
; Memory - these get set up by _fakeline_horz routine
;
;    _colq - colour for polygon
;    _poly_oney - top of polygon in table (maps to y location of screen)
;    _poly_firstbyte[] - left side to begin draw
;    _poly_lastbyte[] - right side to end draw
; _current_page - current offset of video memory for page of xmode, see xmode.asm
;
; Out:
;   null
;
; Notes:
; Call _fakeline_horz to define the edges of your polygon, then call here to fill it
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4
pf_done:
         pop eax
pf_outearly:
         mov _poly_oney,1000                ; reset for next polygon call
         ret

         align 4
_polyfill:
;        out_8 sc_index, map_mask           ; set up for plane select

         xor eax,eax
         mov ebx,_poly_oney                 ; ax=_y1
         cmp bx,_ymins
         jl s pf_missub

         cmp bx,_ymaxs
         jge pf_outearly
         sub bx,_ymins
         mov ax,bx
pf_missub:
         mov ebp,eax                        ; indexer to line
         add ebp,ebp
         add ax, _cliptp

         mov edi, _current_page             ; point to active vga page
         mov eax,[eax*4+_fastimultable]     ; mul _y1 by bytes per line

         add edi,eax                        ; di = start of line _y1
         xor edx,edx

pf_more_lines:
         push edi                           ; save right hand position
         mov ax, [_poly_firstbyte+ebp]
         cmp ax,_xmaxs                      ; check if fill done
         jge pf_done

         xor ebx,ebx
         mov bx,[_poly_lastbyte+ebp]
         add ax,_xcent
         add bx,_xcent

         mov edx,eax                        ; dx = _x1 (pixel position)
         shr edx,2                          ; dx/4 = bytes into line
         add edi,edx                        ; di = addr of upper-left corner

         mov ecx,ebx                        ; cx = _x2 (pixel position)
         shr ecx,2                          ; cx/4 = bytes into line

         cmp edx,ecx                        ; start and end in same band?
         jg pf_exit                         ; skip if _fakeline_horz fails connection
         je pf_one_band_only                ; if so, then special processing

         mov ah,_colq                       ; get fill color
         sub ecx,edx                        ; cx = # bands -1
         mov esi,eax                        ; si = plane#(_x1)
         and esi,plane_bits                 ; if left edge is aligned then
         jz s pf_l_plane_flush              ; no special processing..

; draw "left edge" of 1-3 pixels...

         out_8 sc_data, _left_clip_mask[esi] ; set left edge plane mask

         mov [edi], ah                      ; fill in left edge pixels

         inc edi                            ; point to middle (or right) block
         dec ecx                            ; reset cx instead of jmp pf_right

pf_l_plane_flush:
         inc ecx                            ; add in left band to middle block

; di = addr of 1st middle pixel (band) to fill
; cx = # of bands to fill -1

pf_right:
         mov esi,ebx                        ; get xpos2
         and esi,plane_bits                 ; get plane values
         cmp esi,0003                       ; plane = 3?
         je s pf_r_edge_flush               ; hey, add to middle

; draw "right edge" of 1-3 pixels...

         out_8 sc_data, _right_clip_mask[esi] ; right edge plane mask

         mov esi,edi                        ; get addr of left edge
         add esi,ecx                        ; add width-1 (bands) to point to top of right edge
         dec esi

pf_right_loop:
         mov [esi], ah                      ; fill in right edge pixels

         dec ecx                            ; minus 1 for middle bands
         jz s pf_exit                       ; uh.. no middle bands...

pf_r_edge_flush:

; di = addr of upper left block to fill
; cx = # of bands to fill in (width)

         out_8 sc_data, all_planes          ; write to all planes

         mov dx, xactual/4                  ; dx = di increment
         sub edx, ecx                       ;  = _screen_width-# planes filled

         mov al, ah                         ; colour is in high and low for stosw

pf_middle_loop:
         shr ecx,1                          ; dont use doubleword transfer
         rep stosw
         adc cl,0
         rep stosb
pf_exit:
         pop edi
         mov d [_poly_firstbyte+ebp-2],03e803e8h ; reset table for next polygon (1000 doubleword)
         mov d [_poly_lastbyte+ebp-2],0fc18fc18h ; -1000 doubleword
         add ebp,2
         add edi,xactual/4
         jmp pf_more_lines

pf_one_band_only:
         cmp ax, _cliplt
         jne s pf_nexit
         cmp bx,ax
         je s pf_exit
pf_nexit:
         cmp ax, _cliprt
         je s pf_exit
         mov esi,eax                        ; get left clip mask, save _x1
         and esi,plane_bits                 ; mask out row #
         mov al,_left_clip_mask[esi]        ; get left edge mask
         mov esi,ebx                        ; get right clip mask, save _x2
         and esi,plane_bits                 ; mask out row #
         and al,_right_clip_mask[esi]       ; get right edge mask byte

         out_8 sc_data, al                  ; clip for left & right masks

         mov ah,_colq                       ; get fill color
         mov [edi], ah                      ; fill in pixels
         jmp s pf_exit                      ; outa here, for this line

         align 4
ss_done:
         pop eax
ss_outearly:
         mov _poly_oney,1000                ; reset for next polygon call
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; SS_dosteel: Fill polygon with a sine-waved texture.  Implemented by the use
;             of the "wavey" texture option.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

ss_dosteel:
;          out_8 sc_index, map_mask ; set up for plane select

         xor eax,eax
         mov ebx,_poly_oney                 ; ax=_y1
         cmp bx,_ymins
         jl s ss_missub

         cmp bx,_ymaxs
         jge ss_outearly
         sub bx,_ymins
         mov ax,bx
ss_missub:
         mov bl,_colq                       ; yes, save colour offset and 16 block
         mov steelc,bl
         and steelc,0f0h                   ; save base offset of 16 colour block
         shl bl,2                           ; colour offset is *2 (small) *4 (large)
         add bl,al                          ; make steel always constant
         sub ebx,_poly_oney                 ; *****  ; remove this line if you want sine textures to be "pegged" - eg stationary
         and bl,03fh                        ; colour indexer (so sides look different)
         mov steel ,bl

         mov ebp,eax                        ; indexer to line
         add ebp,ebp
         add ax, _cliptp

         mov edi, _current_page             ; point to active vga page
         mov eax,[eax*4+_fastimultable]     ; mul _y1 by bytes per line

         add edi,eax                        ; di = start of line _y1
         xor edx,edx

ss_more_lines:
         push edi                           ; save right hand position
         mov ax, [_poly_firstbyte+ebp]
         cmp ax,_xmaxs                      ; check if fill done
         jge ss_done

         xor ebx,ebx
         mov bl,steel                      ; use steel texture?
         mov dl,pf_updown[ebx]
         add dl,steelc
         mov _colq,dl
         inc bl
         and bl,03fh                        ; 16 colours, 32 positions for steel texture
         mov steel,bl

         mov bx,[_poly_lastbyte+ebp]
         add ax,_xcent
         add bx,_xcent

         mov edx,eax                        ; dx = _x1 (pixel position)
         shr edx,2                          ; dx/4 = bytes into line
         add edi,edx                        ; di = addr of upper-left corner

         mov ecx,ebx                        ; cx = _x2 (pixel position)
         shr ecx,2                          ; cx/4 = bytes into line

         cmp edx,ecx                        ; start and end in same band?
         jg ss_exit                         ; skip if _fakeline_horz fails connection
         je ss_one_band_only                ; if so, then special processing

         mov ah,_colq                       ; get fill color
         sub ecx,edx                        ; cx = # bands -1
         mov esi,eax                        ; si = plane#(_x1)
         and esi,plane_bits                 ; if left edge is aligned then
         jz s ss_l_plane_flush              ; no special processing..

; draw "left edge" of 1-3 pixels...

         out_8 sc_data, _left_clip_mask[esi] ; set left edge plane mask

         mov [edi], ah                      ; fill in left edge pixels

         inc edi                            ; point to middle (or right) block
         dec ecx                            ; reset cx instead of jmp ss_right

ss_l_plane_flush:
         inc ecx                            ; add in left band to middle block

; di = addr of 1st middle pixel (band) to fill
; cx = # of bands to fill -1

ss_right:
         mov esi,ebx                        ; get xpos2
         and esi,plane_bits                 ; get plane values
         cmp esi,0003                       ; plane = 3?
         je s ss_r_edge_flush               ; hey, add to middle

; draw "right edge" of 1-3 pixels...

         out_8 sc_data, _right_clip_mask[esi] ; right edge plane mask

         mov esi,edi                        ; get addr of left edge
         add esi,ecx                        ; add width-1 (bands) to point to top of right edge
         dec esi

ss_right_loop:
         mov [esi], ah                      ; fill in right edge pixels

         dec ecx                            ; minus 1 for middle bands
         jz s ss_exit                       ; uh.. no middle bands...

ss_r_edge_flush:

; di = addr of upper left block to fill
; cx = # of bands to fill in (width)

         out_8 sc_data, all_planes          ; write to all planes

         mov dx, xactual/4                  ; dx = di increment
         sub edx, ecx                       ;  = _screen_width-# planes filled

         mov al, ah                         ; colour is in high and low for stosw

ss_middle_loop:
         shr ecx,1                          ; dont use doubleword transfer
         jnc s ss_ord
         stosb                              ; if cx odd, store byte first
ss_ord:
         rep stosw
ss_exit:
         pop edi
         mov d [_poly_firstbyte+ebp-2],03e803e8h ; reset table for next polygon (1000 doubleword)
         mov d [_poly_lastbyte+ebp-2],0fc18fc18h ; -1000 doubleword
         add ebp,2
         add edi,xactual/4
         jmp ss_more_lines

ss_one_band_only:
         cmp ax, _cliplt
         jne s ss_nexit
         cmp bx,ax
         je s ss_exit
ss_nexit:
         cmp ax, _cliprt
         je s ss_exit
         mov esi,eax                        ; get left clip mask, save _x1
         and esi,plane_bits                 ; mask out row #
         mov al,_left_clip_mask[esi]        ; get left edge mask
         mov esi,ebx                        ; get right clip mask, save _x2
         and esi,plane_bits                 ; mask out row #
         and al,_right_clip_mask[esi]       ; get right edge mask byte

         out_8 sc_data, al                  ; clip for left & right masks

         mov ah,_colq                       ; get fill color
         mov [edi], ah                      ; fill in pixels
         jmp s ss_exit                      ; outa here, for this line

         align 4

; small steel texture, make sure to set shl bl,*1* before ss_missub:

;pf_updown  db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;           db 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
;           db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;           db 15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0

; large steel texture, make sure to set shl bl,*2* before ss_missub:

pf_updown db 0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9
         db 10,10,11,11,12,12,13,13,14,14,15,15
         db 15,15,14,14,13,13,12,12,11,11,10,10
         db 9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; WN_dowindow:  Fill polygon with a mesh style texture. This plots only every
;               other pixel.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4
wn_done:
         pop eax
wn_outearly:
         mov _poly_oney,1000                ; reset for next polygon call
         ret

         align 4
wn_dowindow:
;          out_8 sc_index, map_mask ; set up for plane select

         xor eax,eax
         mov ebx,_poly_oney                 ; ax=_y1
         cmp bx,_ymins
         jl s wn_missub

         cmp bx,_ymaxs
         jge wn_outearly
         sub bx,_ymins
         mov ax,bx
wn_missub:
         mov ebp,eax                        ; indexer to line
         add ebp,ebp
         add ax, _cliptp

         mov edi, _current_page             ; point to active vga page
         mov ebx,[eax*4+_fastimultable]     ; mul _y1 by bytes per line

         add edi,ebx                        ; edi = start of line _y1
         xor edx,edx
         and eax,1
         mov al,wn_zap[eax]
         mov wn_zip,al

wn_more_lines:
         xor wn_zip,0fh
         push edi                           ; save right hand position
         mov ax, [_poly_firstbyte+ebp]
         cmp ax,_xmaxs                      ; check if fill done
         jge wn_done

         xor ebx,ebx
         mov bx,[_poly_lastbyte+ebp]
         add ax,_xcent
         add bx,_xcent

         mov edx,eax                        ; dx = _x1 (pixel position)
         shr edx,2                          ; dx/4 = bytes into line
         add edi,edx                        ; di = addr of upper-left corner

         mov ecx,ebx                        ; cx = _x2 (pixel position)
         shr ecx,2                          ; cx/4 = bytes into line

         cmp edx,ecx                        ; start and end in same band?
         jg wn_exit                         ; skip if _fakeline_horz fails connection
         je wn_one_band_only                ; if so, then special processing

         mov ah,_colq                       ; get fill color
         sub ecx,edx                        ; cx = # bands -1
         mov esi,eax                        ; si = plane#(_x1)
         and esi,plane_bits                 ; if left edge is aligned then
         jz s wn_l_plane_flush              ; no special processing..

; draw "left edge" of 1-3 pixels...

         mov dx,sc_data
         mov al,_left_clip_mask[esi]
         and al,wn_zip
         out dx,al

         mov [edi], ah                      ; fill in left edge pixels

         inc edi                            ; point to middle (or right) block
         dec ecx                            ; reset cx instead of jmp wn_right

wn_l_plane_flush:
         inc ecx                            ; add in left band to middle block

; di = addr of 1st middle pixel (band) to fill
; cx = # of bands to fill -1

wn_right:
         mov esi,ebx                        ; get xpos2
         and esi,plane_bits                 ; get plane values
         cmp esi,0003                       ; plane = 3?
         je s wn_r_edge_flush               ; hey, add to middle

; draw "right edge" of 1-3 pixels...

         mov dx,sc_data
         mov al,_right_clip_mask[esi]
         and al,wn_zip
         out dx,al

         mov esi,edi                        ; get addr of left edge
         add esi,ecx                        ; add width-1 (bands) to point to top of right edge
         dec esi

wn_right_loop:
         mov [esi], ah                      ; fill in right edge pixels

         dec ecx                            ; minus 1 for middle bands
         jz s wn_exit                       ; uh.. no middle bands...

wn_r_edge_flush:

; di = addr of upper left block to fill
; cx = # of bands to fill in (width)

         out_8 sc_data, wn_zip              ; write to all planes

         mov dx, xactual/4                  ; dx = di increment
         sub edx, ecx                       ;  = _screen_width-# planes filled

         mov al, ah                         ; colour is in high and low for stosw

wn_middle_loop:
         shr ecx,1                          ; dont use doubleword transfer
         jnc s wn_ord
         stosb                              ; if cx odd, store byte first
wn_ord:
         rep stosw
wn_exit:
         pop edi
         mov d [_poly_firstbyte+ebp-2],03e803e8h ; reset table for next polygon (1000 doubleword)
         mov d [_poly_lastbyte+ebp-2],0fc18fc18h ; -1000 doubleword
         add ebp,2
         add edi,xactual/4
         jmp wn_more_lines

wn_one_band_only:
         cmp ax, _cliplt
         jne s wn_nexit
         cmp bx,ax
         je s wn_exit
wn_nexit:
         cmp ax, _cliprt
         je s wn_exit
         mov esi,eax                        ; get left clip mask, save _x1
         and esi,plane_bits                 ; mask out row #
         mov al,_left_clip_mask[esi]        ; get left edge mask
         mov esi,ebx                        ; get right clip mask, save _x2
         and esi,plane_bits                 ; mask out row #
         and al,_right_clip_mask[esi]       ; get right edge mask byte
         and al,wn_zip

         out_8 sc_data, al                  ; clip for left & right masks

         mov ah,_colq                       ; get fill color
         mov [edi], ah                      ; fill in pixels
         jmp s wn_exit                      ; outa here, for this line

wn_zap   db 5,0ah                           ; %0101,%1010
wn_zip   db 0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; DG_doglenz:  Fill polygon with a glenz style vector.  This routine fills
;              up/down, not left/right like _polyfill.  To set up the _poly_firstbyte
;              and _poly_lastbyte tables for this routine, you must call _fakeline_vert.
;              Do not use _fakeline_horz, as _fakeline_horz fills left/right.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

dg_doglenz:
         xor esi,esi
         xor eax,eax

         mov ebx,_poly_oney                 ; ax=_x1
         cmp bx,_xmins
         jl s dg_missub

         cmp bx,_xmaxs
         jge wn_outearly
         sub bx,_xmins
         mov ax,bx
dg_missub:
         mov ebp,eax                        ; indexer to line
         add ebp,ebp
         add ax, _cliplt
         mov ebx,eax

;          out_8 sc_index,map_mask
         out_8 gc_index,read_map

dg_mnloop:
         mov ax, [_poly_firstbyte+ebp]
         cmp ax, _ymaxs
         jg s dg_doneall
         mov si, [_poly_lastbyte+ebp]
         sub si,ax
         jz s dg_doneline

         inc ax
         mov edi, _current_page             ; point to active vga page
         add ax,_ycent
         movzx eax,ax
         add edi,[eax*4+_fastimultable]     ; mul _y1 by bytes per line

         mov ecx,ebx                        ; si = -len, bx = start, edi = screen (left)
         mov eax,ebx
         shr eax,2
         add edi,eax

         mov al, 1                          ; map mask & plane select register
         and cl, plane_bits                 ; get plane bits
         shl al, cl                         ; get plane select value
         out_8 sc_data, al                  ; select plane
         mov al, cl
         out_8 gc_index+1, al

         xor ecx,ecx
         mov cl,_colq
         mov ecx,[_xreftable+ecx*4]
         xor eax,eax

dg_mainloop:
         mov al,[edi]
         mov al,[ecx+eax]
         mov [edi],al
         add edi,xactual/4
         dec esi
         jnz s dg_mainloop
dg_doneline:
         mov d [_poly_firstbyte+ebp-2],03e803e8h ; reset table for next polygon (1000 doubleword)
         mov d [_poly_lastbyte+ebp-2],0fc18fc18h ; -1000 doubleword
         add ebp,2
         inc ebx
         jmp dg_mnloop
dg_doneall:
         mov _poly_oney,1000
         mov leftmost,1000
         ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; DS_dostone:  Fill polygon with a stone texture. Fill is performed
;              up/down, not left/right like _polyfill.  To set up the _poly_firstbyte
;              and _poly_lastbyte tables for this routine, you must call _fakeline_vert.
;              Do not use _fakeline_horz, as _fakeline_horz fills left/right.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

ds_dostone:
         xor esi,esi
         xor eax,eax

         mov ebx,_poly_oney                 ; ax=_x1
         cmp bx,_xmins
         jl s ds_missub

         cmp bx,_xmaxs
         jge wn_outearly
         sub bx,_xmins
         mov ax,bx
ds_missub:
         mov ebp,eax                        ; indexer to line
         add ebp,ebp
         add ax, _cliplt
         mov ebx,eax

         xor ecx,ecx
         mov cl,_colq
         mov al,[_stoneadd+ecx]
         mov _colq,al
         mov ecx,[_stonetbl+ecx*4]
         mov edx,[ecx]
         add edx,ecx
         add ecx,[ecx+4]
         mov ds_ggh,edx
         mov eax,_poly_oney
         sub ax,_xmins
         jnl s ds_nol
         neg eax
         cmp ax,_cliplt
         jbe ds_llk
         mov ax,_cliplt
ds_llk:
         add ecx,eax
ds_nol:
         xor eax,eax
         mov ax,_cliplt
         add ecx,eax
         mov ds_yvar,ecx
         mov ax,leftmost
         add ax,_ycent
         jnl s ds_mnloop2
         xor eax,eax
ds_mnloop2:
         sub ds_ggh,eax
ds_mnloop:
         mov dx, [_poly_firstbyte+ebp]
         cmp dx, _ymaxs
         jg ds_doneall
         mov si, [_poly_lastbyte+ebp]
         sub si,dx
         jle s ds_doneline

         inc dx
         mov edi, _current_page             ; point to active vga page
         add dx,_ycent
         movzx edx,dx
         add edi,[edx*4+_fastimultable]     ; mul _y1 by bytes per line

         mov ecx,ebx                        ; si = -len, bx = start, edi = screen (left)
         mov eax,ebx
         shr eax,2
         add edi,eax

         mov al, 1                          ; map mask & plane select register
         and cl, plane_bits                 ; get plane bits
         shl al, cl                         ; get plane select value
         mov ecx,edx
         out_8 sc_data, al                  ; select plane

         mov eax,ds_yvar
         movzx eax,byte ptr [eax]
         add ecx,eax
         add ecx,ds_ggh
         mov dl,_colq

ds_mainloop:
         mov al,[ecx]                       ; the stone copy loop!
         add al,dl
         mov [edi],al
         add edi,xactual/4
         inc ecx
         dec esi
         jnz s ds_mainloop

ds_doneline:
         mov d [_poly_firstbyte+ebp-2],03e803e8h ; reset table for next polygon (1000 doubleword)
         mov d [_poly_lastbyte+ebp-2],0fc18fc18h ; -1000 doubleword
         add ebp,2
         inc ebx
         inc ds_yvar
         jmp ds_mnloop
ds_doneall:
         mov _poly_oney,1000
         mov leftmost,1000
         ret

ds_ggh   dd 0
ds_yvar  dd 0

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Table of values for fast multiplication by screen width
; eg  mov eax,[esi*4+_fastimultable] ; eax = esi*320
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_fastimultable label dword
         i=0
         rept yactual
         dd i*(xactual/4)
         i=i+1
         endm

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; Hey! where is my postcard! see readme.doc file and send me that postcard!
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _fakeline_horz: Draw a line in tables _poly_firstbyte,_poly_lastbyte, adjust _poly_oney if neccessary
;
; In:
;    Regs=none
; Memory:
;    _x1 - x of line - cartisian format
;    _y1 - y of line
;    _x2 - x of line
;    _y2 - y of line
;
; Out:
;    Regs=none
;
; Notes:
;
; Line is not drawn on screen  but  is  drawn  in  memory  tables.    To  use,
; tables  must  be  clear,   (default  is    always    clear),    just    draw
; line around screen, in any order, then  call  _polyfill.  The  polygon  will
; be drawn and checked in memory, then _polyfill will plop it on  the  current
; page.  _polyfill routine clears tables during plot so tables are  ready  for
; more lines and more polygons.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4
_fakeline_horz:
         mov ax,_y1
         cmp _y2,ax                         ; flip order of points if drawing up
         jg s okorder
         mov bx,_x1
         xchg bx,_x2
         xchg bx,_x1
         xchg ax,_y2
         mov _y1,ax
okorder:
         movsx eax,ax
         cmp eax,_poly_oney
         jge s nonew_poly_oney
         mov _poly_oney,eax
nonew_poly_oney:

         mov ax,_x2                         ; ax=x
         sub ax,_x1
         mov bx,_y2                         ; bx=y
         sub bx,_y1
         jle sliver

         mov rise,bx
         movsx ebx,bx

         shl eax,16
         cdq
         idiv ebx
         mov ebp,eax                        ; ebp = slope*65536 (allows decimals)

         mov ax,_ymins
         cmp _y1,ax                         ; check if above screen
         jge s li_abov1
         sub ax,_y1                         ; ax = abs(difference of ymin-_y1)
         sub rise,ax                        ; dec counter
         jle li_out                         ; line totally off screen

         movsx eax,ax                       ; prepare for 32bit mul
         imul ebp
         shr eax,16                         ; get top word
         add _x1,ax                         ; set new _x1,_y1 pair
         mov ax,_ymins
         mov _y1,ax
li_abov1:
         movsx edx,_x1
         shl edx,16
         mov cx,rise
         mov ax,_y1
         movzx ebx,ax                       ; bx pointer first/_poly_lastbyte table
         sub bx,_ymins
         add ebx,ebx                        ; bx now word

         add eax,ecx                        ; will line go off bottom of screen?
         cmp ax,_ymaxs
         jl s linep                         ; no...
         sub ax,_ymaxs                      ; yes, truncate cx for early exit
         sub cx,ax
         jle s li_out                       ; right off screen
linep:
         mov eax,edx
         mov di,_xmins
         mov si,_xmaxs1
         and ecx,0000ffffh

         align 4
lineloopclip:
         shr edx,16                         ; main line drawing loop (clipped)

         cmp dx,di
         jnge s nou
         cmp dx,si
         jnle s noqq
noq:
         cmp dx,_poly_firstbyte[ebx]        ; fix first and _poly_lastbyte table
         jge s ci1
         mov _poly_firstbyte[ebx],dx
ci1:
         cmp dx,_poly_lastbyte[ebx]
         jng s ci2
         mov _poly_lastbyte[ebx],dx
ci2:
         add eax,ebp
         mov edx,eax
         add ebx,2
         dec ecx
         jnz s lineloopclip
li_out:
         ret
nou:
         mov dx,di
         jmp s noq
noqq:
         mov dx,si
         jmp s noq

         align 4
sliver:
         movzx ebx,_y1                      ; bx pointer first/_poly_lastbyte table

         cmp bx,_ymaxs
         jge li_out
         cmp bx,_ymins                      ; clip to borders
         jl li_out

         sub bx,_ymins
         add ebx,ebx                        ; ebx now word

         mov cx,_x1
         cmp cx,_xmins
         jge s nouq1
         mov cx,_xmins
nouq1:
         cmp cx,_xmaxs
         jl s noqq1
         mov cx,_xmaxs1
noqq1:
         cmp cx,_poly_firstbyte[ebx]        ; fix first and _poly_lastbyte table
         jg s ci1q1
         mov _poly_firstbyte[ebx],cx
ci1q1:
         cmp cx,_poly_lastbyte[ebx]
         jng s ci6q1
         mov _poly_lastbyte[ebx],cx
ci6q1:
         mov cx,_x2
         cmp cx,_xmins
         jge s nouq2
         mov cx,_xmins
nouq2:
         cmp cx,_xmaxs
         jl s noqq2
         mov cx,_xmaxs1
noqq2:
         cmp cx,_poly_firstbyte[ebx]        ; fix first and _poly_lastbyte table
         jg s ci1q2
         mov _poly_firstbyte[ebx],cx
ci1q2:
         cmp cx,_poly_lastbyte[ebx]
         jng s ci6q
         mov _poly_lastbyte[ebx],cx
ci6q:
         ret

         align 4

_fakeline_vert:
         mov ax,_x2
         mov bx,_y2
         cmp bx,leftmost
         jg fg_not1
         mov leftmost,bx
fg_not1:
         xchg _y1,ax
         xchg _x1,bx
         cmp ax,leftmost
         jg fg_not2
         mov leftmost,ax
fg_not2:
         mov _x2,ax
         mov _y2,bx

         mov ax,_y1
         cmp _y2,ax                         ; flip order of points if drawing up
         jg s okorderg
         mov bx,_x1
         xchg bx,_x2
         xchg bx,_x1
         xchg ax,_y2
         mov _y1,ax
okorderg:
         movsx eax,ax
         cmp eax,_poly_oney
         jge s nonew_poly_oneyg
         mov _poly_oney,eax
nonew_poly_oneyg:

         mov ax,_x2                         ; ax=x
         sub ax,_x1
         mov bx,_y2                         ; bx=y
         sub bx,_y1
         jle sliverg

         mov rise,bx
         movsx ebx,bx

         shl eax,16
         cdq
         idiv ebx
         mov ebp,eax                        ; ebp = slope*65536 (allows decimals)

         mov ax,_xmins
         cmp _y1,ax                         ; check if above screen
         jge s li_abov1g
         sub ax,_y1                         ; ax = abs(difference of ymin-_y1)
         sub rise,ax                        ; dec counter
         jle li_outg                        ; line totally off screen

         movsx eax,ax                       ; prepare for 32bit mul
         imul ebp
         shr eax,16                         ; get top word
         add _x1,ax                         ; set new _x1,_y1 pair
         mov ax,_xmins
         mov _y1,ax
li_abov1g:
         movsx edx,_x1
         shl edx,16
         mov cx,rise
         mov ax,_y1
         movzx ebx,ax                       ; bx pointer first/_poly_lastbyte table
         sub bx,_xmins
         add ebx,ebx                        ; bx now word

         add eax,ecx                        ; will line go off bottom of screen?
         cmp ax,_xmaxs
         jl s linepg                        ; no...
         sub ax,_xmaxs                      ; yes, truncate cx for early exit
         sub cx,ax
         jle s li_outg                      ; right off screen
linepg:
         mov eax,edx
         mov di,_ymins1
         mov si,_ymaxs1
         and ecx,0000ffffh

         align 4
lineloopg:
         shr edx,16                         ; main line drawing loop!!!

         cmp dx,di
         jg s noug
         mov dx,di
         jmp s noqg
noug:
         cmp dx,si
         jl s noqg
         mov dx,si
noqg:
         cmp dx,_poly_firstbyte[ebx]        ; fix first and _poly_lastbyte table
         jge s ci1g
         mov _poly_firstbyte[ebx],dx
ci1g:
         cmp dx,_poly_lastbyte[ebx]
         jng s ci2g
         mov _poly_lastbyte[ebx],dx
ci2g:
         add eax,ebp
         mov edx,eax
         add ebx,2
         dec ecx
         jnz s lineloopg
li_outg:
         ret

         align 4
sliverg: ret
         movzx ebx,_y1                      ; bx pointer first/_poly_lastbyte table

         cmp bx,_xmaxs
         jge li_outg
         cmp bx,_xmins                      ; clip to borders
         jl li_outg

         sub bx,_ymins
         add ebx,ebx                        ; ebx now word

         mov cx,_x1
         cmp cx,_ymins
         jge s nouq1g
         mov cx,_ymins
nouq1g:
         cmp cx,_ymaxs
         jl s noqq1g
         mov cx,_ymaxs1
noqq1g:
         cmp cx,_poly_firstbyte[ebx]        ; fix first and _poly_lastbyte table
         jg s ci1q1g
         mov _poly_firstbyte[ebx],cx
ci1q1g:
         cmp cx,_poly_lastbyte[ebx]
         jng s ci6q1g
         mov _poly_lastbyte[ebx],cx
ci6q1g:
         mov cx,_x2
         cmp cx,_ymins
         jge s nouq2g
         mov cx,_ymins
nouq2g:
         cmp cx,_ymaxs
         jl s noqq2g
         mov cx,_ymaxs1
noqq2g:
         cmp cx,_poly_firstbyte[ebx]        ; fix first and _poly_lastbyte table
         jg s ci1q2g
         mov _poly_firstbyte[ebx],cx
ci1q2g:
         cmp cx,_poly_lastbyte[ebx]
         jng s ci6qg
         mov _poly_lastbyte[ebx],cx
ci6qg:
         ret

         db " **** Hey, What are you doing ripping my code?! **** "

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _set_clip_absolute: Set clipping parameters - non cartisian
;
; In:
;    AX - left   for clip
;    BX - top    for clip
;    CX - right  for clip
;    DX - bottom for clip
; Out:
;    ?
;
; Notes:
; Set new clipping parameters where center is in middle of points ax,bx cx,dx
; where points are absolutes! eg (10,10) (50,50) would be a small  window  in
; the top corner of the screen.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_clip_absolute:

         mov si,cx                          ; calc center based on points
         sub si,ax
         shr si,1
         add si,ax

         mov di,dx
         sub di,bx
         shr di,1
         add di,bx

         sub ax,si                          ; now make points offset from center
         sub cx,si
         sub bx,di
         sub dx,di                          ; fall through to _set_clip_offset

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
;
; _set_clip_offset: Set clipping parameters - cartisian
;
; In:
;    AX - left   for clip - in cartisian format
;    BX - top    for clip
;    CX - right  for clip
;    DX - bottom for clip
;    SI - x of screen center - in cartisian format
;    DI - y of screen center
; Out:
;    ?
;
; Notes:
;
; Set new clipping parameters. does  all  pre-calculation   for  variables  and
; resets _poly_oney, _poly_firstbyte and _poly_lastbyte table.  SI,DI is center of screen.  AX,BX
; and CX,DX are topleft and botright points to clip to.  clipping will  include
; minimum clip variables but will exclude maximum clip variables.  eg -160,-100
; +160,+100, with center 160,100 are valid clip parameters.  points are offsets
; from center, not absolutes! this allows you to have the camera looking to the
; left or right of where the pilot/plane is moving  without  having  to  change
; the camera angle. Note: this can only change slightly as  distortion  occures
; with too large an offset.  Make sure to assemble the original file  with  the
; maximum Y size you will ever need so tables are set to correct size.  You can
; never increase the total screen Y  clipping  beyond  the  original  assembley
; restraints, but you can create any sized smaller windows.
;
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_set_clip_offset:
         mov bp,dx
         sub bp,bx
         cmp bp,ymax-ymin                   ; check input parameters with assembley restraints
         jg you_must_assemble_original_file_with_larger_clipping_parameters_to_achieve_this

         mov _xmins,ax
         mov _xmaxs,cx
         mov _ymins,bx
         mov _ymaxs,dx
         mov _xcent,si
         mov _ycent,di

         mov _cliptp,di
         add _cliptp,bx

         mov _ycentp1,di
         inc _ycentp1

         mov _ycents1,di
         dec _ycents1

         mov _clipbt,di
         add _clipbt,dx
         dec _clipbt

         mov _cliplt,si
         add _cliplt,ax

         mov _cliprt,si
         add _cliprt,cx
         dec _cliprt

         mov xmaxxcent,si
         add xmaxxcent,cx

         mov ymaxycent,di
         add ymaxycent,dx

         mov _xmins1,ax
         dec _xmins1

         mov _xmaxs1,cx
         dec _xmaxs1

         mov _ymins1,bx
         dec _ymins1

         mov _ymaxs1,dx
         dec _ymaxs1

         movsx eax,ax
         movsx ebx,bx
         movsx ecx,cx
         movsx edx,dx

         mov xmit,eax
         mov xmat,ecx
         mov ymit,ebx
         mov ymat,edx

         sub xmit,tolerance
         add xmat,tolerance
         sub ymit,tolerance
         add ymat,tolerance

you_must_assemble_original_file_with_larger_clipping_parameters_to_achieve_this:
         ret

         align 4

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _drawvect: Draw vectors from sides list.
; In=Out=null
;
; Notes:
; Number of "sides" is "_showing".  Commands are in "textures" lists.  All
; of this is set up by Load_points and Loadsides routines.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

dv_none2:
         ret
_drawvect:
         cmp _showing,0                     ; no sides visible?
         je s dv_none2

         mov whichside,0                    ; start at side 0
         mov ebp,order[0]                   ; indexer to sides
dv_loop2:
         test textures[ebp],line+himap+point+texture+glenz ; test if line, point, scalable bitmap or bitmapped texture
         jnz dv_testit                      ; yes, do other routine

         mov polytype,offset _fakeline_horz
dv_contq:
         shl ebp,mult
         mov dx,sides[ebp]                  ; first point is end flag
         mov fex,dx
dv_loop1:
         movzx esi,sides[ebp]               ; get point, shl 1 not needed, pre-shl'ed
         mov eax,[xp+esi]
         mov ebx,[yp+esi]
         mov _x1,ax
         mov _y1,bx

         mov si,[sides+ebp+2]               ; get next point

         cmp si,fex                         ; test if last = first, therefore done
         pushf

         mov eax,[xp+esi]
         mov ebx,[yp+esi]

         mov _x2,ax
         mov _y2,bx

         push ebp
         call [polytype]                    ; draw next line
         pop ebp

         add ebp,2                          ; bump to next pointer now
         popf                               ; was this point equal to the first point?
         jne s dv_loop1                     ; no, draw more lines

         mov esi,whichside                  ; set colour for this side
         mov esi,order[esi]
         mov al,b surfcolors[esi]
         mov _colq,al

         xor ecx,ecx
         mov cl,byte ptr textures[esi+1]    ; use register which we can access low byte
         and cl,7
         call [polyjumps+ecx*4]
dv_return:
         add whichside,4                    ; bump bp to next block of points
         mov ebp,whichside
         mov ebp,order[ebp]                 ; get sort order
         dec _showing                       ; count for all sides
         jne dv_loop2
dv_none:
         ret

polyjumps dd offset _polyfill               ; 0             ; solid fill
         dd offset wn_dowindow              ; 256           ; mesh
         dd offset ss_dosteel              ; 512           ; sine wave
         dd offset 0                        ; 512+256
         dd offset dg_doglenz               ; 1024          ; glenz vector
         dd offset ds_dostone               ; 1024+256      ; stone texture
         dd offset 0                        ; 1024+512
         dd offset 0                        ; 1024+512+256
dv_assinez:
         mov polytype,offset _fakeline_vert
         jmp dv_contq

         align 4
dv_testit:
         mov ax,textures[ebp]               ; perform command, return to dv_return
         test eax,glenz
         jnz dv_assinez
         test eax,line
         jnz dv_doline
         test eax,point
         jnz dv_dopoint
         test eax,texture
         jnz dv_texture

; draw bitmap at location x,y,z

         shl ebp,mult
         push eax ebp

         movzx ebx,w [sides+4+ebp]
         movzx ecx,w [sides+6+ebp]

         movzx esi,[sides+2+ebp]
         shl esi,2                          ; si = dword
         add ebx,_bitx[esi]
         add ecx,_bity[esi]                 ; ebx,ecx = top corner of _bitmap in 3d

         mov eax,_bitbase[esi]
         mov _bitmap,eax

         mov si,[sides+0+ebp]
         mov ebp,[zp+esi]

         call _make3d                       ; ebx,ecx = difference from center

         pop ebp

         movzx esi,[sides+0+ebp]   ; get point
         mov eax,[xp+esi]
         mov ebp,[yp+esi]

         sub ax,bx              ; bx = x width/2  ax, bp = top corner
         sub bp,cx              ; cx = y height/2

         add ax,_xcent
         add bp,_ycent
         mov _scale_destx,ax
         mov _scale_desty,bp

         add bx,bx
         add cx,cx

         mov _scale_destwidth,bx
         mov _scale_destheight,cx

         pop eax
         test al,lomap-himap                ; test to use 1/4 scale _bitmap or full scale
         jz s noq19

         call _xscale4
         jmp dv_return

         align 4
noq19:
         call _xscale2
noq7:
         jmp dv_return

         align 4

dv_dopoint:
         mov dx,surfcolors[ebp]             ; get colour of point

         shl ebp,mult
         movzx esi,[sides+ebp]              ; get point x,y
         mov ebx,[xp+esi]
         mov ecx,[yp+esi]

         cmp bx,_xmins                      ; check if on screen
         jl s noq7
         cmp bx,_xmaxs
         jge s noq7
         cmp cx,_ymins
         jl s noq7
         cmp cx,_ymaxs                      ; _ymaxs1 if larger pixel
         jge s noq7

         mov edi, _current_page             ; point to active vga page

         add bx,_xcent
         add cx,_ycent

         mov bp,dx                          ; save colour

         mov si,cx
         mov eax,[esi*4+_fastimultable]     ; get offset to start of line

         mov cx, bx                         ; copy to extract plane # from
         shr bx, 2                          ; x offset (bytes) = xpos/4
         add bx, ax                         ; offset = width*ypos + xpos/4

         mov ax, map_mask_plane1            ; map mask & plane select register
         and cl, plane_bits                 ; get plane bits
         shl ah, cl                         ; get plane select value
         out_16 sc_index, ax                ; select plane

         and ebx,0000ffffh
         mov ax,bp                          ; re-get colour
         mov [edi+ebx],al                   ; draw pixel, low is top, high is bottom
;          add edi,xactual/4
;          mov [edi+ebx],ah        ; draw larger bullet/pixel (high byte)

; if drawing larger pixel, change above code to this!
;          cmp cx,_ymaxs1
;          jge s noa7

         jmp dv_return

         align 4

; handle line command from _drawvect, uses _clipped_line routine

dv_doline:
         mov edi,ebp                        ; save...
         mov bp,surfcolors[ebp]

         shl edi,mult
         movzx esi,[sides+edi]              ; get first point
         mov edx,[xp+esi]
         mov ecx,[yp+esi]

         mov si,[sides+edi+2]               ; second point indexer

         mov eax,[xp+esi]                   ; now load up second point
         mov ebx,[yp+esi]

         call _clipped_line
         jmp dv_return                      ; return to _drawvect

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _clipped_line: Draw clipped line in cartesian format from (dx,cx) to (ax,bx)
;               using colour bp
; In:
;   AX - _x2
;   BX - _y2
;   CX - _y1
;   DX - _x1
;   BP - Colour
;  _current_page - current screen start location
; Out:null
;
; Similar routine to _fakeline_horz but faster,  more accurate and draws directly
; to screen (_current_page).  Routine updates clearing borders (if used)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_clipped_line:
         cmp bx,cx                          ; flip order of points if drawing up
         jg s r_okorder
         xchg bx,cx
         xchg ax,dx
r_okorder:
         mov _x1,dx
         mov _y1,cx
         mov _x2,ax
         mov _y2,bx

         sub ax,dx
         sub bx,cx

         mov dx,bp
         mov _colq,dl

         mov dx,_ymaxs
         cmp _y1,dx
         jge cl_return

         mov rise,bx
         movsx ebx,bx
         or ebx,ebx
         jne s r_nsliver

         mov bx, _y1
         cmp bx, _ymins                     ; draw sliver, avoid divide by zero
         jl cl_return
         cmp bx, dx                         ; dx = ymax
         jge cl_return

         add bx,_ycent
         movzx esi,bx
         mov eax,[esi*4+_fastimultable]     ; get offset to start of line
         mov edi, _current_page
         add edi, eax                       ; edi = starting y location

         mov rise,1

         mov dx, _x1                        ; from here...
         mov si, _x2                        ;            ..to here

         cmp si,_xmins
         jge s u_nou3
         mov si,_xmins
u_nou3:
         cmp si,_xmaxs
         jl s u_noq3
         mov si,_xmaxs1
u_noq3:
         jmp r_splint                       ; re-enter draw later in code

         align 4
r_nsliver:
         shl eax,16
         cdq
         idiv ebx
         mov ebp,eax                        ; ebp = slope*65536 (allows decimals)

         mov ax,_ymins
         cmp _y1,ax                         ; check if above screen
         jge s r_li_abov1
         sub ax,_y1                         ; ax = abs(difference of ymin-_y1)
         sub rise,ax                        ; dec counter
         jle cl_return                      ; line totally off screen

         movsx eax,ax                       ; prepare for 32bit mul
         imul ebp
         shr eax,16                         ; get top word
         add _x1,ax                         ; set new _x1,_y1 pair
         mov ax,_ymins
         mov _y1,ax

r_li_abov1:
         mov bx,_y1                         ; bx distance from top of screen
         add bx,_ycent
         movzx esi,bx                       ; calculate screen address
         mov eax,[esi*4+_fastimultable]     ; get offset to start of line
         mov edi, _current_page
         add edi,eax                        ; edi = starting y location

         movsx edx,_x1
         shl edx,16
         mov cx,rise
         mov ax,_y1
         add ax,cx                          ; will line go off bottom of screen?
         cmp ax,_ymaxs
         jl s r_linep                       ; no...
         sub ax,_ymaxs                      ; yes, truncate cx for early exit
         sub rise,ax
         jle cl_return
r_linep:
         mov eax,edx
         and ecx,0000ffffh

         mov esi,edx
         shr esi,16

         cmp si,_xmins
         jge s r_nou
         mov si,_xmins
r_nou:
         cmp si,_xmaxs
         jl s r_noq
         mov si,_xmaxs1

         align 4
r_noq:

r_lineloop:
         add eax,ebp                        ; main line drawing loop!!! (for lines)
         mov edx,eax
         shr edx,16
r_splint:
         cmp dx,_xmins
         jge s u_nou
         mov dx,_xmins
         cmp dx,si
         je r_mis
u_nou:
         cmp dx,_xmaxs
         jl s u_noq
         mov dx,_xmaxs1
         cmp dx,si
         je r_mis
u_noq:
         push edx edi ebp eax               ; save for next line
         cmp dx,si
         jle s r_no_switch
         xchg dx,si
r_no_switch:

         add dx,_xcent
         add si,_xcent

         mov ax,dx
         mov bx,si
         mov _x2,si

         movzx edx,dx
         shr edx,2                          ; dx/4 = bytes into line
         add edi,edx                        ; di = addr of upper-left corner
         movzx ecx,bx                       ; cx = _x2 (pixel position)
         shr ecx,2                          ; cx/4 = bytes into line

         cmp dx,cx                          ; start and end in same band?
         je rf_one_band_only                ; if so, then special processing

         sub cx,dx                          ; cx = # bands -1
         mov esi,eax                        ; si = plane#(_x1)
         and esi,plane_bits                 ; if left edge is aligned then
         jz s rf_l_plane_flush              ; no special processing..

; draw "left edge" of 1-3 pixels...

         out_8 sc_data, _left_clip_mask[esi] ; set left edge plane mask

         mov al,_colq                       ; get fill color
         mov [edi], al                      ; fill in left edge pixels

         inc edi                            ; point to middle (or right) block
         dec ecx                            ; reset cx instead of jmp s rf_right

rf_l_plane_flush:
         inc ecx                            ; add in left band to middle block

; di = addr of 1st middle pixel (band) to fill
; cx = # of bands to fill -1

rf_right:
         mov esi,ebx                        ; get xpos2
         and esi,plane_bits                 ; get plane values
         cmp esi,0003                       ; plane = 3?
         je s rf_r_edge_flush               ; hey, add to middle

; draw "right edge" of 1-3 pixels...

         out_8 sc_data, _right_clip_mask[esi] ; right edge plane mask

         mov esi,edi                        ; get addr of left edge
         add esi,ecx                        ; add width-1 (bands) to point to top of right edge
         dec esi

         mov al,_colq                       ; get fill color

rf_right_loop:
         mov [esi], al                      ; fill in right edge pixels

         dec ecx                            ; minus 1 for middle bands
         jz rf_exit                         ; uh.. no middle bands...

rf_r_edge_flush:

; di = addr of upper left block to fill
; cx = # of bands to fill in (width)

         out_8 sc_data, all_planes          ; write to all planes

         mov edx, xactual/4                 ; dx = di increment
         sub edx, ecx                       ;  = _screen_width-# planes filled

         mov al, _colq                      ; get fill color
         mov ah, al                         ; colour is in high and low for stosw
         push ax                            ; make colour 32 bit
         shl eax,16
         pop ax

rf_middle_loop:
         shr ecx,1                          ; use doubleword transfer
         jnc s rf_ord
         stosb                              ; if cx odd, store byte first
rf_ord:
         rep stosw
         jmp s rf_exit                      ; outa here, for this line

rf_one_band_only:
         mov esi,eax                        ; get left clip mask, save _x1
         and esi,plane_bits                 ; mask out row #
         mov al,_left_clip_mask[esi]        ; get left edge mask
         mov esi,ebx                        ; get right clip mask, save _x2
         and esi,plane_bits                 ; mask out row #
         and al,_right_clip_mask[esi]       ; get right edge mask byte

         out_8 sc_data, al                  ; clip for left & right masks

         mov al, _colq                      ; get fill color
         mov [edi], al                      ; fill in pixels
rf_exit:
         pop eax ebp edi esi                ; pop screen left address
r_mis:
         add edi, xactual/4
         dec rise
         jg r_lineloop

cl_return:
         ret

         align 4
dv_texture:
         ;movzx ebx,surfcolors[ebp]
         ;mov eax,_bitbase[ebx*4]
         ;mov _scaled_texture_bitmap_offset,eax
         ;
         ;shl ebp,mult
         ;
         ;mov bx,[sides+0+ebp]
         ;mov ax,xp[ebx]
         ;mov bx,yp[ebx]
         ;mov _tex_xorg+0,ax
         ;mov _tex_yorg+0,bx
         ;
         ;mov bx,[sides+2+ebp]
         ;mov ax,xp[ebx]
         ;mov bx,yp[ebx]
         ;mov _tex_xorg+2,ax
         ;mov _tex_yorg+2,bx
         ;
         ;mov bx,[sides+4+ebp]
         ;mov ax,xp[ebx]
         ;mov bx,yp[ebx]
         ;mov _tex_xorg+4,ax
         ;mov _tex_yorg+4,bx
         ;
         ;mov bx,[sides+6+ebp]
         ;mov ax,xp[ebx]
         ;mov bx,yp[ebx]
         ;mov _tex_xorg+6,ax
         ;mov _tex_yorg+6,bx
         ;
         ;call _tex_drawtexturemap          ; not implemented yet!

         jmp dv_return

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; _sortlist:  Bubble sort for sides
; In=Out=null
;
; Sort is not  perfect   since  many  sides  can  use  the  same  point.
; If this point is the first point in the list and therefore zeds[] uses
; the same point for sort, the routine may mess up when plotting at some
; acute angles.  If you ever notice this, you are way  too  picky.   You
; could fix this by adjusting the load_sides routine to search  for  the
; closest z point.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

         align 4

_sortlist dd o shell_sort                   ; offset to requested sort type

minusd   equ offset zeds - offset order

shell_sort:
         mov  ebx,_showing

         align 4
mainwhile:
         shr  ebx,1
         mov  ebp,ebx
         shl  ebp,2

         align 4
while_inner:
         xor  edx,edx
         mov  esi,o zeds
         mov  ecx,_showing
         sub  ecx,ebx

         align 4
forloop: mov  eax,[esi]
         cmp  [esi+ebp],eax
         jle  nextfor

         xchg eax,[esi+ebp]
         mov  [esi],eax

         mov  eax,[esi - minusd]
         xchg eax,[esi - minusd + ebp]
         mov  [esi - minusd],eax

         mov  edx,1

         align 4
nextfor: add  esi,4
         loop forloop

         cmp  edx,1
         je  while_inner

         cmp  ebx,1
         jne   mainwhile
         ret

         align 4
bubble_sort:
         xor  edx,edx
         mov  esi,o zeds
         mov  ecx,_showing
         dec  ecx

         align 4
bforloop:mov  eax,[esi]
         cmp  [esi+4],eax
         jle  bnextfor

         xchg eax,[esi+4]
         mov  [esi],eax

         mov  eax,[esi - minusd]
         xchg eax,[esi - minusd + 4]
         mov  [esi - minusd],eax

         mov  edx,1

         align 4
bnextfor:add  esi,4
         loop bforloop

         cmp  edx,1
         je  bubble_sort

         ret

selection_sort:
         mov esi,_showing
         cmp esi,3                          ; if only one surface, exit
         jbe qke

         shl esi,2                          ; esi = dword
         add esi,o order

         align 4
nextcx:
         sub esi,4                          ; point to last word in order[] table

         mov ebp,esi                        ; set order pointer
         mov ebx,d [esi]                    ; get order[si]

         mov edi,esi
         add edi,minusd
         mov ecx,d [edi]                    ; get zeds[si]

         align 4
nextdx:
         sub edi,4
         sub ebp,4

         cmp ecx,d [edi]                    ; zeds is point from side, should be max z
         jle s donothing
         xchg ecx,d [edi]                   ; don't flip entire side, just indexers to it
         xchg ebx,d [ebp]
donothing:
         cmp ebp,o order                    ; check bp = 0
         jne s nextdx

         mov [esi + minusd],ecx
         mov [esi],ebx

         cmp esi,o order + 4
         jne s nextcx
qke:
         ret
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Copy real objects to virtual objects.  You MUST call this routine before
; you draw your objects or they will be in the same place as last time.
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

_copy_virtual_objects:
         mov edi,o v_whatshape
         mov esi,o _whatshape
         mov ecx,((2+2+2+4+4+4+2+2+2+1+1+1)*(maxobjects+1)+4)/4
         rep movsd
         ret

