	processor 6502
	include "vcs.h"
	include "macro.h"

	org  $f000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; We're going to use a more clever way to position sprites
; ("players") which relies on additional TIA features.
; Because the CPU timing is 3 times as coarse as the TIA's,
; we can only access 1 out of 3 possible positions using
; CPU delays alone.
; Additional TIA registers let us nudge the final position
; by discrete TIA clocks and thus target all 160 positions.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

counter	equ $81

start	CLEAN_START

nextframe
	VERTICAL_SYNC
	
; 34 lines of VBLANK
	ldx #34
lvblank	sta WSYNC
	dex
	bne lvblank

; Instead of representing the horizontal position in CPU clocks,
; we're going to use TIA clocks.

	lda counter	; load the counter as horizontal position
	and #$7f	; force range to (0-127)
	
; We're going to divide the horizontal position by 15.
; The easy way on the 6502 is to subtract in a loop.
; Note that this also conveniently adds 5 CPU cycles
; (15 TIA clocks) per iteration.
	sta WSYNC	; 35th line
	sta HMCLR	; reset the old horizontal position
DivideLoop
	sbc #15		; subtract 15
	bcs DivideLoop	; branch until negative
; A now contains (the remainder - 15).
; We'll convert that into a fine adjustment, which has
; the range -8 to +7.
	eor #7
	asl		; HMOVE only uses the top 4 bits, so shift by 4
	asl
	asl
	asl
; The fine offset goes into HMP0
	sta HMP0
; Now let's fix the coarse position of the player, which as you
; remember is solely based on timing. If you rearrange any of the
; previous instructions, position 0 won't be exactly on the left side.
	sta RESP0
; Finally we'll do a WSYNC followed by HMOVE to apply the fine offset.
	sta WSYNC	; 36th line
	sta HMOVE	; apply offset

; We'll see this method again, and it can be made into a subroutine
; that works on multiple objects.

; Now draw the 192 scanlines, drawing the sprite.
; We've already set its horizontal position for the entire frame,
; but we'll try to draw something real this time, some digits
; lifted from another game.
	ldx #192
	lda #0		; changes every scanline
	ldy #0		; sprite data index
lvscan
	sta WSYNC	; wait for next scanline
	sty COLUBK	; set the background color
	lda NUMBERS,y
	sta GRP0	; set sprite 0 pixels
	iny
	cpy #60
	bcc wrap1
	ldy #0
wrap1
	dex
	bne lvscan
	
; Clear the background color and sprites before overscan
	stx COLUBK
	stx GRP0
; 30 lines of overscan
	ldx #30
lvover	sta WSYNC
	dex
	bne lvover
	
; Cycle the sprite colors for the next frame
	inc counter
	lda counter
	sta COLUP0
	jmp nextframe

; Bitmap pattern for digits

NUMBERS ;;{w:8,h:6,count:10,brev:1};;
	.byte $EE,$AA,$AA,$AA,$EE,$00
        .byte $22,$22,$22,$22,$22,$00
        .byte $EE,$22,$EE,$88,$EE,$00
        .byte $EE,$22,$66,$22,$EE,$00
        .byte $AA,$AA,$EE,$22,$22,$00
        .byte $EE,$88,$EE,$22,$EE,$00
        .byte $EE,$88,$EE,$AA,$EE,$00
        .byte $EE,$22,$22,$22,$22,$00
        .byte $EE,$AA,$EE,$AA,$EE,$00
        .byte $EE,$AA,$EE,$22,$EE,$00
;; end

; Epilogue
	org $fffc
	.word start
	.word start

; QUESTION: What if you don't set the fine offset?
; QUESTION: What if you don't set the coarse offset?
