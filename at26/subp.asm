;milquetoast the ghost
;by Kirk Israel
;a cute ghost. press button to say boo!


	processor 6502
	include vcs.h
	include macro.h

;label some variables....
	SEG.U VARS
	ORG $80

;the ghosts height will be in 2 bytes;
;low, high (fractional byte, than integer byte)
;drawing onscreen, we only care about the integer byte
;but we will keep track of both
P0_YPosFromBot ds 2
P0_XPos ds 1	;horizontal position
P0_Y ds 1	;needed for skipdraw
P0_Ptr ds 2	;ptr to current graphic

	SEG CODE
	org $F000

;a few constants...
C_GHOST_SPEED = 300	;subpixel, divide by 256 for pixel speed
C_P0_HEIGHT = 8		;height of ghost sprite
C_KERNAL_HEIGHT = 192	;height of kernal (full screen, single line kernal)

Start
	CLEAN_START

	;black background, white ghost...
	lda #$00
	sta COLUBK
	lda #$0F
	sta COLUP0


	lda #12
	sta P0_YPosFromBot+1	;Initial Y Position in integer part of 2 byte speed

	lda #90
	sta P0_XPos

	lda #>GhostGraphic ;high byte of graphic location
	sta P0_Ptr+1	;store in high byte of graphic pointer



MainLoop
	VERTICAL_SYNC
	lda #43
	sta TIM64T


	;joystick pressed left?
	lda #%01000000
	bit SWCHA
	bne DoneMoveLeft

	dec P0_XPos	;move ghost left

	lda #%00001000   ;a 1 in D3 of REFP0 says make it mirror
	sta REFP0
DoneMoveLeft
	;joystick pressed right?
	lda #%10000000
	bit SWCHA
	bne DoneMoveRight

	inc P0_XPos	;move ghost right

	lda #%00000000
	sta REFP0    	;unmirrored P0

DoneMoveRight

; for up and down, we INC or DEC
; the Y Position
	;joystick down?
	lda #%00010000
	bit SWCHA
	bne DoneMoveDown

	;16 bit math, add both bytes
	;of the ghost speed constant to
	;the 2 bytes of the position
	clc
	lda P0_YPosFromBot
	adc #<C_GHOST_SPEED
	sta P0_YPosFromBot
	lda P0_YPosFromBot+1
	adc #>C_GHOST_SPEED
	sta P0_YPosFromBot+1
DoneMoveDown

	lda #%00100000	;Up?
	bit SWCHA
	bne DoneMoveUp

	;16 bit math, subtract both bytes
	;of the ghost speed constant to
	;the 2 bytes of the position
	sec
	lda P0_YPosFromBot
	sbc #<C_GHOST_SPEED
	sta P0_YPosFromBot
	lda P0_YPosFromBot+1
	sbc #>C_GHOST_SPEED
	sta P0_YPosFromBot+1
DoneMoveUp

	;check firebutton
	ldx INPT4
	bmi MouthIsClosed ;(button not pressed)
MouthIsOpen
	lda #<GhostBooGraphic 	;low byte of ptr is boo graphic
	sta P0_Ptr		;(high byte already set)
	jmp DoneWithMouth
MouthIsClosed
	lda #<GhostGraphic 	;low byte of ptr is normal graphic
	sta P0_Ptr		;(high byte already set)
DoneWithMouth


	;for Battlezone style exact horizontal repositioning
	;subroutine as rediscovered by R. Mundschau and explained by Andrew Davie,
	;set A = desired horizontal position, then X to object
	;to be positioned (0->4 = P0->BALL)
	lda P0_XPos
	ldx #0
	jsr bzoneRepos


	;for skipDraw, P0_Y needs to be set (usually during VBLANK)
	;to Vertical Position (0 = top) + height of sprite - 1.
	;we're storing distance from bottom, not top, so we have
	;to start with the kernal height and YPosFromBot...
	lda #C_KERNAL_HEIGHT + #C_P0_HEIGHT - #1
	sec
	sbc P0_YPosFromBot+1 ;subtract integery byte of distance from bottom
	sta P0_Y


	;we also need to adjust the graphic pointer for skipDraw
	;it equals what it WOULD be at 'normally' - it's position
	;from bottom plus sprite height - 1.
	;(note this requires that the 'normal' starting point for
	;the graphics be at least align 256 + kernalheight ,
	;or else this subtraction could result in a 'negative'
	; (page boundary crossing) value
	lda P0_Ptr
	sec
	sbc P0_YPosFromBot+1	;integer part of distance from bottom
	clc
	adc #C_P0_HEIGHT-#1
	sta P0_Ptr	;2 byte

WaitForVblankEnd
	lda INTIM
	bne WaitForVblankEnd
	ldy #C_KERNAL_HEIGHT - 1; (off by one error)

	sta WSYNC
	sta HMOVE ;move objecs that were finely positioned

	sta VBLANK

;main scanline loop...
ScanLoop
;skipDraw
; draw player sprite 0:
	lda     #C_P0_HEIGHT-1     ; 2
	dcp     P0_Y            ; 5 (DEC and CMP)
	bcs     .doDraw0        ; 2/3
	lda     #0              ; 2
	.byte   $2c             ;-1 (BIT ABS to skip next 2 bytes)
.doDraw0:
	lda     (P0_Ptr),y      ; 5
	sta     GRP0            ; 3 = 18 cycles (constant, if drawing or not!)

	sta WSYNC

	dey
	bne ScanLoop

	lda #2
	sta WSYNC
	sta VBLANK
	ldx #30
OverScanWait
	sta WSYNC
	dex
	bne OverScanWait
	jmp  MainLoop


	;Battlezone style exact horizontal repositioning
	;subroutine as rediscovered by R. Mundschau and explained by Andrew Davie,
	;set A = desired horizontal position, then X to object
	;to be positioned (0->4 = P0->BALL)

bzoneRepos
	sta WSYNC                   ; 00     Sync to start of scanline.
	sec                         ; 02     Set the carry flag so no borrow will be applied during the division.
.divideby15
	sbc #15                     ; 04     Waste the necessary amount of time dividing X-pos by 15!
	bcs .divideby15             ; 06/07  11/16/21/26/31/36/41/46/51/56/61/66

	tay
	lda fineAdjustTable,y       ; 13 -> Consume 5 cycles by guaranteeing we cross a page boundary
	sta HMP0,x

	sta RESP0,x                 ; 21/ 26/31/36/41/46/51/56/61/66/71 - Set the rough position.
	rts
;-----------------------------
; This table converts the "remainder" of the division by 15 (-1 to -15) to the correct
; fine adjustment value. This table is on a page boundary to guarantee the processor
; will cross a page boundary and waste a cycle in order to be at the precise position
; for a RESP0,x write

            ORG $FE00
fineAdjustBegin

            DC.B %01110000 ; Left 7
            DC.B %01100000 ; Left 6
            DC.B %01010000 ; Left 5
            DC.B %01000000 ; Left 4
            DC.B %00110000 ; Left 3
            DC.B %00100000 ; Left 2
            DC.B %00010000 ; Left 1
            DC.B %00000000 ; No movement.
            DC.B %11110000 ; Right 1
            DC.B %11100000 ; Right 2
            DC.B %11010000 ; Right 3
            DC.B %11000000 ; Right 4
            DC.B %10110000 ; Right 5
            DC.B %10100000 ; Right 6
            DC.B %10010000 ; Right 7

fineAdjustTable EQU fineAdjustBegin - %11110001 ; NOTE: %11110001 = -15


	org $FEC0




GhostGraphic
        .byte #%11110000
        .byte #%01111100
        .byte #%00111111
        .byte #%11111101
        .byte #%10110110
        .byte #%00111110
        .byte #%00101010
        .byte #%00011100


GhostBooGraphic
        .byte #%11110000
        .byte #%01111100
        .byte #%00111110
        .byte #%01100101
        .byte #%10100011
        .byte #%10111110
        .byte #%00101010
        .byte #%00011100



	org $FFFC
	.word Start
	.word Start
