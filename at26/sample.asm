; SpriteMan
; by Jason Rein
;
; 08/31/03 - It's alive!
; 05/13/05 - Sorta ready for primetime...hey, it works :)
; 05/14/05 - Flexible kernal (just update the constants and/or the sprite data)...
;				- variable sprite height
;				- 1LK+ supported
;				- separate colors for each face
;				- adjustable animation speed
;				- any number of faces supported
;				- mirroring optional when moving left
;				- Sprite Data and Preferences are now in separate files
;				- single, double, or quad width supported
;				- background color now a preference
;
; The purpose of SpriteMan is to demonstrate (and hopefully one day optimize)
; basic sprite movement and animation.
;
; Here's how the horizontal positioning works...
;
;	XPos holds both fine and coarse adjustments:
;								high nybble = fine
;								low nybble = coarse
;	i.e. "$fc" where f = fine and c = coarse
;	When we move right, f decrements and c increments
;	When we move left, f increments and c decrements
;
;	range of fine: 7 -&gt; -7
;	range of coarse: 4 -&gt; 14
;
; While it is possible to calculate XPos in-game, it saves more cycles to
; look it up in a table. This is at the cost of more ROM (160 bytes).
;
; NOTE: The tilde symbol (~) means cycles.


                processor 6502
                include "vcs.h"
                include "macro.h"


				SEG.U vars	; the label "vars" will appear in our symbol table's segment list
				ORG $80		; start of RAM


;------------------------------------------------
; Variables
;------------------------------------------------

spriteYPosition		ds 1	; 192 is at the top of the screen, the constant VALUE_OF_Y_AT_SCREEN_BOTTOM gives us the bottom.
currentSpriteLine	ds 1	; (0 &lt;= currentSpriteLine &lt; SPRITE_HEIGHT) for each frame
hPosition			ds 1
hPositionFrac		ds 1
playerBuffer		ds 1
spriteMoving		ds 1	; Boolean. We use this to see if we stopped moving
animFrameLineCtr	ds 1
faceDelay			ds 1
spriteLineColor		ds 1
hPositionIndex		ds 1
faceDuration		ds 1

;------------------------------------------------
; Constants
;------------------------------------------------

; Modify values to suit style
;
FACE_DURATION = 4			; Number of frames each face lasts on screen. Decrease to speed up, increase to slow down.
SLO_MO_FACE_DURATION = 30	; Same as above, applicable when "slo-mo" is activated (i.e. player holds fire button).
SPRITE_HEIGHT = 19			; Native number of pixels tall the sprite is (before being stretched by a 2LK or whatever).
NUM_ANIMATION_FACES = 2		; Number of faces of animation. (!)Corresponds with number of color tables(!)
MIRROR = 1					; If true, sprite mirrors when moved left.
X_LK = 2					; set to 1 for 1LK, 2 for 2LK, etc.
SPRITE_WIDTH = 1			; set to 1, 2, or 4, anything else is right out
BG_COLOR = $0E				; background color
VALUE_OF_Y_AT_SCREEN_BOTTOM = 192-192/X_LK
VERTICAL_CENTER_OF_SCREEN = 192-(192-VALUE_OF_Y_AT_SCREEN_BOTTOM)/2

;------------------------------------------------
; Macros (hey, my first macros!)
;------------------------------------------------

	MAC KERNAL
		REPEAT X_LK
			sta WSYNC
		REPEND
	ENDM
	
	MAC UP_DIST_MACRO
		inc spriteYPosition
		
		IF X_LK = 1
			inc spriteYPosition		; we move a little extra to speed up vertical motion in 1LK
		ENDIF
	ENDM

	MAC DOWN_DIST_MACRO
		dec spriteYPosition
		
		IF X_LK = 1
			dec spriteYPosition		; we move a little extra to speed up vertical motion in 1LK
		ENDIF
	ENDM
		
;------------------------------------------------
; Start of ROM binary
;------------------------------------------------

		SEG     	; end of uninitialised segment
		ORG $F000

Reset

;------------------------------------------------
; Clear RAM and all TIA registers
;------------------------------------------------

		ldx #0
		txa
Clear	dex
		txs
		pha
		bne Clear 

;------------------------------------------------
; Inits
;------------------------------------------------
				
		lda #BG_COLOR
		sta COLUBK
		
		lda #80
		sta hPositionIndex	; initial x pos
		
		lda #VERTICAL_CENTER_OF_SCREEN
		sta spriteYPosition	; initial y pos
		
		lda #$3C
		sta COLUP0
		
		lda #$0E
		sta COLUPF
		
		lda #FACE_DURATION
		sta faceDuration
		sta faceDelay
		
		lda #SPRITE_WIDTH
		cmp #1
		bne NOT_SINGLE
		lda #0					; set to single
		jmp SET_SIZE
NOT_SINGLE
		cmp #2
		bne NOT_DOUBLE
		lda #5					; set to double
		jmp SET_SIZE
NOT_DOUBLE
		lda #7					; set to quad
SET_SIZE
		sta NUSIZ0
		
;------------------------------------------------
; Start Frame
;------------------------------------------------

StartOfFrame
		
;------------------------------------------------
; Vertical Sync (3 scanlines)
;------------------------------------------------

		lda #2
		sta VSYNC		; turn on VSYNC (VSYNC=2 (%00000010))

		sta WSYNC		;\n		sta WSYNC		; &gt; 3 scanlines of VSYNC signal
		sta WSYNC       ;/

		lda #0
		sta VSYNC		; turn off VSYNC by clearing it  

;------------------------------------------------
; Vertical Blank (37 scanlines)
;------------------------------------------------
           		
		lda #0
		sta VBLANK
	
		lda #44             ;[2] VBLANK for 37 lines
		sta TIM64T          ;[3] 44*64 intervals == 2816 cycles == 37.05 scanlines
							
		;--Position sprite horizontally using hPosition
		;
		ldx hPositionIndex		;3	|
		lda hPositionTable,x	;4	|
		sta hPosition			;3	| hPosition = hPositionTable[hPositionIndex]
		and #$0F				;2	|
		tax						;2	| x = (hPosition & $0F) (coarse position)
		sta WSYNC				;3	|
Position
		dex						;2	| Position Sprite Horizontally (coarse adj.)
		bne Position			;2+	| 
		sta RESP0				;3	| 
		sta WSYNC				;3	| 
								;	|
		lda hPosition			;3	|
		and #$F0				;2	| clear coarse nybble
		sta HMP0				;3	| Offset Sprite from Coarse position (fine adj.)
	
	
		;--See about animating SpriteMan's face
		;
		lda spriteMoving
		bne SpriteManMoving		;	if (spriteMoving != false) goto SpriteManMoving
						
		lda #SPRITE_HEIGHT-1	;	// Sprite is idle
		sta animFrameLineCtr	;	animFrameLineCtr = SPRITE_HEIGHT - 1
		jmp EndAnimationChecks	;	goto EndAnimationChecks
 				
SpriteManMoving				
		lda animFrameLineCtr	; Sprite is moving
		cmp #SPRITE_HEIGHT*#NUM_ANIMATION_FACES
		bcs ResetFace			; if (animFrameLineCtr &gt;= height*numFaces) goto ResetFace
		jmp EndAnimationChecks	; else goto EndAnimationChecks
ResetFace
		lda #SPRITE_HEIGHT*#NUM_ANIMATION_FACES-1
		sta animFrameLineCtr	; animFrameLineCtr = (SPRITE_HEIGHT * NUM_ANIMATION_FACES) - 1
EndAnimationChecks

				
		; Start our scanline count (gets decremented)
		ldy #192 					;2

                
VerticalBlank
		lda INTIM				;3
		bne VerticalBlank		;2+
		sta WSYNC				;3 End of Line/Start HBLANK
		

;------------------------------------------------
; Picture (192 scanlines)
;------------------------------------------------
		sta HMOVE					;3
        
        lda #228					;2
		sta TIM64T					;3 36*64 intervals == 14592 cycles == 192 scanlines
		       
Picture	
									; Load Player sprite and color. (10~)
		lda playerBuffer			;2
		sta GRP0					;3	GRP0 = playerBuffer
		lda spriteLineColor			;2
		sta COLUP0					;3	COLUP0 = spriteLineColor

									; Clear the playerBuffer. (5~)
		lda #0						;2
		sta playerBuffer			;3	playerBuffer = 0
		
									; See if this is the line where we start drawing the sprite. (Y:10~, N:6~)
		cpy spriteYPosition			;3
		bne SkipActivatePlayer		;2+	if (y != spriteYPosition) goto SkipActivatePlayer
		lda #SPRITE_HEIGHT-1		;2	else
		sta currentSpriteLine		;3	currentSpriteLine = SPRITE_HEIGHT-1
SkipActivatePlayer
		
									; See if we are drawing sprite data on this line. (Y:5~, N:6~)
		lda currentSpriteLine		;3
		bmi EndPlayerDraw			;2+	if (currentSpriteLine &lt; 0) goto EndPlayerDraw

									; Load sprite graphic and color buffers. (20~)
		ldx animFrameLineCtr		;3
		lda SpriteGraphicTable,x	;4
		sta playerBuffer			;3	playerBuffer = SpriteGraphicTable[animFrameLineCtr]
		lda SpriteColorTable,x		;4
		sta spriteLineColor			;3	spriteLineColor = SpriteColorTable[animFrameLineCtr]
		
									; Decrement our counters. (10~)
		dec currentSpriteLine		;5 currentSpriteLine -= 1
		dec animFrameLineCtr		;5
EndPlayerDraw  
		
		dey
		
		KERNAL						; execute appropriate number of sta WSYNC's
		
		lda INTIM			;[2]
		bne Picture			;[2+]
		
		; VBLANK
		lda #%00000010				;2
		sta VBLANK           		;3 end of screen - enter blanking
                
;------------------------------------------------
; Overscan (30 scanlines)
;------------------------------------------------

		lda #36				;2
		sta TIM64T			;3 36*64 intervals == 2304 cycles == 30.3 scanlines
		
		; Manage the frame delay between face animations.
		;
StartFaceStuff
		dec faceDelay			;	faceDelay -= 1
		lda faceDelay			;
		beq ResetFaceDelay		;	if (faceDelay == 0) then goto ResetFaceDelay
		lda animFrameLineCtr	;	&lt;-else force another frame of the current face
		clc						;	by bringing the animFrameLineCtr where
		adc #SPRITE_HEIGHT		;	it was at the start of this frame.
		sta animFrameLineCtr	;	(i.e. add SPRITE_HEIGHT to it)
		jmp EndFaceStuff
ResetFaceDelay
		lda faceDuration
		sta faceDelay			;	faceDelay = faceDuration
EndFaceStuff


		; Prepare movement variables.
		;
		lda #0
		sta spriteMoving		; default to not moving
		
		lda #4
		sta faceDuration
		
		;--See if the fire button was pressed--
		;		
		lda #%10000000			; read button input
		bit INPT4
		bne ButtonNotPressed	; skip if button not pressed
		inc spriteMoving		; button pressed
		lda SLO_MO_FACE_DURATION
		sta faceDuration		; activate to animate slowly w/button
ButtonNotPressed

		
		;--Check Joystick for Horizontal Motion--
		;
		lda #%10000000
		bit SWCHA
		beq Right
		lsr
		bit SWCHA
		beq Left
		jmp CheckV
				
Right	ldx hPositionIndex
		cpx #160-#SPRITE_WIDTH*#8	; take into account sprite width when at right edge
		beq MoveH
		
		inx						; increment the hPositionIndex
		inc spriteMoving		; Sprite is not idle
		jmp ReflectRight

Left	ldx hPositionIndex
		cpx #0
		beq MoveH
				
		dex
		inc spriteMoving		; Sprite is not idle
		lda #MIRROR
		beq MoveH				; if (MIRROR == 0) goto MoveH
		jmp ReflectLeft

ReflectRight
		lda #0
		sta REFP0		; No Reflect P0
		jmp MoveH
		
ReflectLeft
		lda #%0001000
		sta REFP0		; Reflect P0
				
MoveH	stx hPositionIndex

			
		;--Check Joystick for Vertical Motion--
		;
CheckV	lda #%00100000
		bit SWCHA
		beq Down
		lsr
		bit SWCHA
		beq Up
		jmp Overscan
		
Down	ldx spriteYPosition
		cpx #VALUE_OF_Y_AT_SCREEN_BOTTOM+#SPRITE_HEIGHT+2
		beq Overscan		; if we're at the bottom of the screen goto Overscan
		DOWN_DIST_MACRO		; else move down
		inc spriteMoving	; Sprite is moving
		jmp Overscan

Up		ldx spriteYPosition
		cpx #192
		beq Overscan		; if we're at the top of the screen goto Overscan
		UP_DIST_MACRO
		inc spriteMoving	; Sprite is moving

Overscan
		lda INTIM			;2
		bne Overscan		;2+
		sta WSYNC			;3
		
		jmp StartOfFrame

;------------------------------------------------------------------------------

;------------------------------------------------
; Graphics Data
;------------------------------------------------

		org $FE00

;################################################
; Sprite Graphic Data

SpriteGraphicTable

;---Graphics Data from PlayerPal 2600---

Frame0
        .byte #%00011000;$02
        .byte #%00010000;$02
        .byte #%00011000;$02
        .byte #%00011101;$02
        .byte #%00111111;$02
        .byte #%01111111;$02
        .byte #%01111111;$02
        .byte #%11111111;$02
        .byte #%11111111;$02
        .byte #%11001111;$02
        .byte #%10000111;$02
        .byte #%10000011;$02
        .byte #%00000001;$02
        .byte #%00000001;$02
        .byte #%00000001;$02
        .byte #%00000001;$02
        .byte #%00000001;$02
        .byte #%00000001;$02
        .byte #%00000000;$02
Frame1
        .byte #%11000000;$02
        .byte #%10000000;$02
        .byte #%10000000;$02
        .byte #%10000000;$02
        .byte #%11000000;$02
        .byte #%11000000;$02
        .byte #%11100000;$02
        .byte #%11100000;$02
        .byte #%11101000;$02
        .byte #%11111000;$02
        .byte #%11100000;$02
        .byte #%11100000;$02
        .byte #%11111100;$02
        .byte #%11110000;$02
        .byte #%11111111;$02
        .byte #%11111111;$02
        .byte #%11111111;$02
        .byte #%10111111;$02
        .byte #%11111110;$02
;---End Graphics Data---


;################################################
; Sprite Color Data

SpriteColorTable

	; Color for Face 0
;---Color Data from PlayerPal 2600---

ColorFrame0
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
ColorFrame1
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
        .byte #$02;
;---End Color Data---

hPositionTable
			.byte 				  $34,$24,$14,$04,$F4,$E4,$D4,$C4,$B4,$A4,$94	; 0-10
			.byte $75,$65,$55,$45,$35,$25,$15,$05,$F5,$E5,$D5,$C5,$B5,$A5,$95	; 11-25
			.byte $76,$66,$56,$46,$36,$26,$16,$06,$F6,$E6,$D6,$C6,$B6,$A6,$96	; 26-40
			.byte $77,$67,$57,$47,$37,$27,$17,$07,$F7,$E7,$D7,$C7,$B7,$A7,$97	; 41-55
			.byte $78,$68,$58,$48,$38,$28,$18,$08,$F8,$E8,$D8,$C8,$B8,$A8,$98	; 56-70
			.byte $79,$69,$59,$49,$39,$29,$19,$09,$F9,$E9,$D9,$C9,$B9,$A9,$99	; 71-85
			.byte $7A,$6A,$5A,$4A,$3A,$2A,$1A,$0A,$FA,$EA,$DA,$CA,$BA,$AA,$9A	; 86-100
			.byte $7B,$6B,$5B,$4B,$3B,$2B,$1B,$0B,$FB,$EB,$DB,$CB,$BB,$AB,$9B	; 101-115
			.byte $7C,$6C,$5C,$4C,$3C,$2C,$1C,$0C,$FC,$EC,$DC,$CC,$BC,$AC,$9C	; 116-130
			.byte $7D,$6D,$5D,$4D,$3D,$2D,$1D,$0D,$FD,$ED,$DD,$CD,$BD,$AD,$9D	; 131-145
			.byte $7E,$6E,$5E,$4E,$3E,$2E,$1E,$0E,$FE,$EE,$DE,$CE,$BE,$AE		; 146-159
			

		;----------------
		org $FFFA

InterruptVectors

		.word Reset           ; NMI
		.word Reset           ; RESET
		.word Reset           ; IRQ
