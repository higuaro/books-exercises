	processor 6502
        include "vcs.h"
        include "macro.h"
        include "xmacro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This example demonstrates a scene with a full-screen
; playfield, and a single sprite overlapping it.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        seg.u Variables
	org $80

PFPtr	word	; pointer to playfield data
PFIndex	byte	; offset into playfield array
PFCount byte	; lines left in this playfield segment
Temp	byte	; temporary
YPos	byte	; Y position of player sprite
XPos	byte	; X position of player sprite
SpritePtr word  ; pointer to sprite bitmap table
ColorPtr  word  ; pointer to sprite color table

; Temporary slots used during kernel
Bit2p0	byte
Colp0	byte
YP0	byte

; Height of sprite in scanlines
SpriteHeight	equ 9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	seg Code
        org $f000

Start
	CLEAN_START
; Set up initial pointers and player position        
        lda #<PlayfieldData
        sta PFPtr
        lda #>PlayfieldData
        sta PFPtr+1
        lda #<Frame0
        sta SpritePtr
        lda #>Frame0
        sta SpritePtr+1
        lda #<ColorFrame0
        sta ColorPtr
        lda #>ColorFrame0
        sta ColorPtr+1
        lda #242
        sta YPos
        lda #38
        sta XPos

NextFrame
	VERTICAL_SYNC

; Set up VBLANK timer
	TIMER_SETUP 37
        lda #$88
        sta COLUBK	; bg color
        lda #$5b
        sta COLUPF	; fg color
        lda #$68
        sta COLUP0	; player color
        lda #1
        sta CTRLPF	; symmetry
        lda #0
        sta PFIndex	; reset playfield offset
; Set temporary Y counter and set horizontal position
        lda YPos
        sta YP0		; yp0 = temporary counter
        lda XPos
        ldx #0
        jsr SetHorizPos
        sta WSYNC
        sta HMOVE	; gotta apply HMOVE
; Wait for end of VBLANK
	TIMER_WAIT
        lda #0
        sta VBLANK

; Set up timer (in case of bugs where we don't hit exactly)
	TIMER_SETUP 192
        SLEEP 10 ; to make timing analysis work out

NewPFSegment
; Load a new playfield segment.
; Defined by length and then the 3 PF registers.
; Length = 0 means stop
        ldy PFIndex	; load index into PF array
        lda (PFPtr),y	; load length of next segment
        beq NoMoreSegs	; == 0, we're done
        sta PFCount	; save for later
; Preload the PF0/PF1/PF2 registers for after WSYNC
        iny
        lda (PFPtr),y	; load PF0
        tax		; PF0 -> X
        iny
        lda (PFPtr),y	; load PF1
        sta Temp	; PF1 -> Temp
        iny
        lda (PFPtr),y	; load PF2
        iny
        sty PFIndex
        tay		; PF2 -> Y
; WSYNC, then store playfield registers
; and also the player 0 bitmap for line 2
        sta WSYNC
        stx PF0		; X -> PF0
        lda Temp
        sta PF1		; Temp -> PF1
        lda Bit2p0	; player bitmap
        sta GRP0	; Bit2p0 -> GRP0
        sty PF2		; Y -> PF2
; Load playfield length, we'll keep this in X for the loop
        ldx PFCount
KernelLoop
; Does this scanline intersect our sprite?
        lda #SpriteHeight	; height in 2xlines
        isb YP0			; INC yp0, then SBC yp0
        bcs .DoDraw		; inside bounds?
        lda #0			; no, load the padding offset (0)
.DoDraw
; Load color value for both lines, store in temp var
	pha			; save original offset
        tay			; -> Y
        lda (ColorPtr),y	; color for both lines
        sta Colp0		; -> colp0
; Load bitmap value for each line, store in temp var
	pla
	asl			; offset * 2
	tay			; -> Y
	lda (SpritePtr),y	; bitmap for first line
        sta Bit2p0		; -> bit2p0
        iny
	lda (SpritePtr),y	; bitmap for second line
; WSYNC and store values for first line
        sta WSYNC
        sta GRP0	; Bit1p0 -> GRP0
        lda Colp0
        sta COLUP0	; Colp0 -> COLUP0
        dex
        beq NewPFSegment	; end of this playfield segment?
; WSYNC and store values for second line
        sta WSYNC
        lda Bit2p0
        sta GRP0	; Bit2p0 -> GRP0
        jmp KernelLoop
NoMoreSegs
; Change colors so we can see when our loop ends
	lda #0
        sta COLUBK
; Wait for timer to finish
        TIMER_WAIT

; Set up overscan timer
	TIMER_SETUP 29
	lda #2
        sta VBLANK
        jsr MoveJoystick
        TIMER_WAIT
        jmp NextFrame

SetHorizPos
	sta WSYNC	; start a new line
        bit 0		; waste 3 cycles
	sec		; set carry flag
DivideLoop
	sbc #15		; subtract 15
	bcs DivideLoop	; branch until negative
	eor #7		; calculate fine offset
	asl
	asl
	asl
	asl
	sta RESP0,x	; fix coarse position
	sta HMP0,x	; set fine offset
	rts		; return to caller

; Read joystick movement and apply to object 0
MoveJoystick
; Move vertically
; (up and down are actually reversed since ypos starts at bottom)
	ldx YPos
	lda #%00100000	;Up?
	bit SWCHA
	bne SkipMoveUp
        cpx #175
        bcc SkipMoveUp
        dex
SkipMoveUp
	lda #%00010000	;Down?
	bit SWCHA 
	bne SkipMoveDown
        cpx #254
        bcs SkipMoveDown
        inx
SkipMoveDown
	stx YPos
; Move horizontally
        ldx XPos
	lda #%01000000	;Left?
	bit SWCHA
	bne SkipMoveLeft
        cpx #1
        bcc SkipMoveLeft
        dex
SkipMoveLeft
	lda #%10000000	;Right?
	bit SWCHA 
	bne SkipMoveRight
        cpx #153
        bcs SkipMoveRight
        inx
SkipMoveRight
	stx XPos
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        align $100; make sure data doesn't cross page boundary
PlayfieldData
	.byte  4,#%00000000,#%11111110,#%00110000
	.byte  8,#%11000000,#%00000001,#%01001000
	.byte 15,#%00100000,#%01111110,#%10000100
	.byte 20,#%00010000,#%10000000,#%00010000
	.byte 20,#%00010000,#%01100011,#%10011000
	.byte 15,#%00100000,#%00001100,#%01000100
	.byte  8,#%11000000,#%00110000,#%00110010
	.byte  4,#%00000000,#%11000000,#%00001100
	.byte 0

;; Bitmap data "standing" position
Frame0
	.byte #0
	.byte #0
;;{w:8,h:16,brev:1,flip:1};;
        .byte #%01101100;$F6
        .byte #%00101000;$86
        .byte #%00101000;$86
        .byte #%00111000;$86
        .byte #%10111010;$C2
        .byte #%10111010;$C2
        .byte #%01111100;$C2
        .byte #%00111000;$C2
        .byte #%00111000;$16
        .byte #%01000100;$16
        .byte #%01111100;$16
        .byte #%01111100;$18
        .byte #%01010100;$18
        .byte #%01111100;$18
        .byte #%11111110;$F2
        .byte #%00111000;$F4
;; Color data for each line of sprite
;;{pal:"vcs"};;
ColorFrame0
	.byte #$FF;
	.byte #$86;
	.byte #$86;
	.byte #$C2;
	.byte #$C2;
	.byte #$16;
	.byte #$16;
	.byte #$18;
	.byte #$F4;
;;
; Epilogue
	org $fffc
        .word Start
        .word Start
