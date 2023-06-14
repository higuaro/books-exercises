  PROCESSOR 6502

  INCLUDE "vcs.h"
  INCLUDE "macro.h"

  LIST ON           ; turn on program listing, for debugging on Stella

;=============================================================================
; MACROS
;=============================================================================

  MAC DEBUG_SUB_KERNEL
.BGCOLOR SET {1}
.KERNEL_LINES SET {2}
    lda #.BGCOLOR
    sta COLUBK
    ldx #.KERNEL_LINES
.loop:
    dex
    sta WSYNC
    bne .loop
  ENDM

  MAC LOAD_PTR
.POINTER SET {1}
.ADDRESS SET {2}
    lda #<.ADDRESS
    sta .POINTER
    lda #>.ADDRESS
    sta .POINTER+1
  ENDM

;=============================================================================
; SUBROUTINES
;=============================================================================

; empty atm

;=============================================================================
; CONSTANTS
;=============================================================================
RND_MEM_LOC_1 = $c1   ; "random" memory locations to sample the upper/lower
RND_MEM_LOC_2 = $e5   ; bytes when the machine starts.

BKG_LIGHT_GRAY = #13
DINO_HEIGHT = #39
DINO_X = #10                 ; fixed, the dino remains locked in its x position
DINO_X_DIV_5 = DINO_X / #5   ;

SKY_KERNEL_LINES = #62
CACTUS_KERNEL_LINES = #62

;=============================================================================
; MEMORY / VARIABLES
;=============================================================================
  SEG.U variables
  ORG $80

RND_SEED .word           ; 2 bytes
DINO_Y .byte             ; 3 bytes
BG_COLOUR .byte          ; 4 bytes
PTR_DINO_SPRITE .word    ; 6 bytes

;=============================================================================
; ROM / GAME CODE
;=============================================================================
  SEG code
  ORG $f000

  ; -----------------------
  ; RESET
  ; -----------------------
reset:
  sei     ; SEt Interruption disable
  cld     ; (CLear Decimal) disable BCD math

  ; At the start, the machine memory could be in any state, and that's good!
  ; We can use those leftovers for the random seed before doing a ZP cleaning
  lda #<RND_SEED
  adc RND_MEM_LOC_1
  sta RND_SEED
  ;
  lda #>RND_SEED
  adc RND_MEM_LOC_2
  sta RND_SEED+1

  ; -----------------------
  ; CLEAR ZERO PAGE MEMORY
  ; -----------------------
  ldx #0
  txa
  tay     ; Y = A = X = 0
__clear_mem:
  dex
  txs
  pha
  bne __clear_mem

  ; -----------------------
  ; GAME INITIALIZATION
  ; -----------------------
  lda #$51
  sta DINO_Y

  lda #BKG_LIGHT_GRAY
  sta BG_COLOUR

  LOAD_PTR PTR_DINO_SPRITE, DINO_SPRITE_1

;=============================================================================
; FRAME
;=============================================================================
frame:

.vsync_and_vblank:
  ; last line of overscan
  ;inc <RND_SEED
  sta WSYNC

  ; -----------------------
  ; V-SYNC (3 scanlines)
  ; -----------------------
__vsync:
  lda #2
  sta VBLANK ; Enable VBLANK (and turn off video signal)
  sta VSYNC  ; VBLANK = VSYNC = A (A=2) enables vsync/vblank
    inc <RND_SEED
    adc >RND_SEED
  sta WSYNC  ; 1st line of vsync
  sta WSYNC  ; 2nd line of vsync
    lda #0   ; A <- 0
  sta WSYNC  ; 3rd (final) line of vsync
  sta VSYNC  ; VSYNC = A (A=0) disables vsync

  ; -----------------------
  ; V-BLANK (37 scanlines)
  ; -----------------------
  ; Set the timer for the remaining VBLANK period (37 lines)
  ; 76 cpu cycles per scanline, 37 * 76 = 2812 cycles / 64 ticks => 43
  lda #43
  sta TIM64T

  ; -----------------------
  ; FRAME SETUP/LOGIC
  ; -----------------------
  lda #BKG_LIGHT_GRAY
  sta COLUBK
  sta HMCLR    ; Clear horizontal motion registers

  ;lda 

  lda #0
__vblank:
  lda INTIM
  bne __vblank
               ; 2752 cycles + 2 from bne, 2754 (out of 2812 vblank)
  sta WSYNC
  sta VBLANK   ; Disables VBLANK (A=0)
  ;sta HMOVE

;=============================================================================
; BEGIN KERNEL
;=============================================================================
kernel:

.score_kernel_setup:
  DEBUG_SUB_KERNEL #$10, #2

.score_kernel:
  DEBUG_SUB_KERNEL #$20, #10

.clouds_kernel_setup:
  DEBUG_SUB_KERNEL #$30, #2

.clouds_kernel:
  DEBUG_SUB_KERNEL #$40, #20

.sky_kernel_setup: ; >>> 2 lines <<<
  lda BG_COLOUR    ; 3
  sta COLUBK       ; 3

  ; Set the dino x position and keep it fixed for the rest of the kernel
  ; by doing this, I lose GRP0 forever but feels that I can save some cycles
  ldx #DINO_X_DIV_5
__dino_coarse_pos:
  dex
  bne __dino_coarse_pos
  sta RESMP0 ; M0 will be 3 cycles (9 px) far from P0
  sta RESP0
  sta WSYNC

  ;-----------------------------------
  ; Get ready for the .sky_kernel
  ;-----------------------------------
  ldx #SKY_KERNEL_LINES  ; 62 lines atm
  ldy #0

  ; T0D0: later set the coarse position of the cactus or pterodactile
  sta WSYNC

.sky_kernel:
  lda (PTR_DINO_SPRITE),y
  sta GRP0
  iny
  dex
  sta WSYNC
  bne .sky_kernel

  ldx #SKY_KERNEL_LINES  ; 62 lines atm
.cactus_kernel: ; 62 lines atm
  lda (PTR_DINO_SPRITE),y
  sta GRP0
  iny
  dex
  sta WSYNC
  bne .cactus_kernel

.floor_kernel:
  DEBUG_SUB_KERNEL #$AA, #1

.gravel_kernel:
  DEBUG_SUB_KERNEL #$C8, #9

.void_kernel:
  DEBUG_SUB_KERNEL #$FA, #31

;=============================================================================
; END KERNEL
;=============================================================================

  ; -----------------------
  ; OVERSCAN (30 scanlines)
  ; -----------------------
  ; 30 lines of OVERSCAN, 30 * 76 / 64 = 35
  lda #35
  sta TIM64T
  lda #2
  sta VBLANK
.overscan:
  lda INTIM
    ;inc <RND_SEED
    ;adc >RND_SEED
  bne .overscan

  ; We're on the final OVERSCAN line and 40 cpu cycles remain,
  ; do the jump now to consume some cycles and a WSYNC at the 
  ; beginning of the next frame to consume the rest
  jmp frame

;=============================================================================
; SPRITE GRAPHICS DATA
;=============================================================================
  SEG data
  ORG $fe00

  ; -----------------------------------------------
  ; Graphics Data from PlayerPal 2600
  ; https://alienbill.com/2600/playerpalnext.html
  ; -----------------------------------------------

DINO_SPRITE_1:
  .ds 90
  .byte %11111110
  .byte %11111110
  .byte %10111111
  .byte %10111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111000
  .byte %11111000
  .byte %11111110
  .byte %11111110
  .byte %00011111
  .byte %00011111
  .byte %00111111
  .byte %00111111
  .byte %11111111
  .byte %11111111
  .byte %11111101
  .byte %11111101
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11101100
  .byte %11101100
  .byte %11000100
  .byte %11000100
  .byte %10000100
  .byte %10000100
  .byte %11000110
  .byte %11000110
  .ds 25

DINO_MIS_OFFSET:
  .ds 90
  .byte %11111110
  .byte %11111110
  .byte %10111111
  .byte %10111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111000
  .byte %11111000
  .byte %11111110
  .byte %11111110
  .byte %00011111
  .byte %00011111
  .byte %00111111
  .byte %00111111
  .byte %11111111
  .byte %11111111
  .byte %11111101
  .byte %11111101
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11101100
  .byte %11101100
  .byte %11000100
  .byte %11000100
  .byte %10000100
  .byte %10000100
  .byte %11000110
  .byte %11000110
  .ds 25
;=============================================================================
; ROM SETUP
;=============================================================================
  ORG $fffc
  .word reset ; reset button signal
  .word reset ; IRQ
