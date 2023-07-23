  PROCESSOR 6502

  INCLUDE "vcs.h"

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

  MAC LOAD_ADDRESS_TO_PTR
.ADDRESS SET {1}
.POINTER SET {2}
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
RND_MEM_LOC_2 = $e5   ; bytes when the machine starts. Hopefully this finds
                      ; some garbage values that can be used as seed

BKG_LIGHT_GRAY = #13
DINO_HEIGHT = #39
DINO_X = #10                 ; Fixed, the dino remains locked in its x position
DINO_X_DIV_5 = DINO_X / #5   ; for the whole game

SKY_KERNEL_LINES = #62
CACTUS_KERNEL_LINES = #62

;=============================================================================
; MEMORY / VARIABLES
;=============================================================================
  SEG.U variables
  ORG $80

RND_SEED .word           ; 2 bytes
DINO_BOTTOM_Y .byte      ; 3 bytes DINO_Y + DINO_HEIGHT
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
  ; We can use those leftover bytes as seed for RND before doing cleaning ZP
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
  txs  ; This is the classic trick that exploits the fact that both
  pha  ; the stack and ZP RAM are the very same 128 bytes
  bne __clear_mem

  ; -----------------------
  ; GAME INITIALIZATION
  ; -----------------------
  lda #$10+#DINO_HEIGHT
  sta DINO_BOTTOM_Y

  lda #BKG_LIGHT_GRAY
  sta BG_COLOUR

  LOAD_ADDRESS_TO_PTR DINO_SPRITE_1, PTR_DINO_SPRITE

;=============================================================================
; FRAME
;=============================================================================
frame:

.vsync_and_vblank:
  lda #2     ;
  sta VBLANK ; Enables VBLANK (and turns video signal off)

  ;inc <RND_SEED
  ; last line of overscan
  sta WSYNC

  ; -----------------------
  ; V-SYNC (3 scanlines)
  ; -----------------------
__vsync:
  sta VSYNC  ; Enables VSYNC
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
  lda #BKG_LIGHT_GRAY   ;
  sta COLUBK            ; Set initial background
  sta HMCLR             ; Clear horizontal motion registers

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

.score_kernel_setup:;---->>> 2 scanlines <<<----
  DEBUG_SUB_KERNEL #$10, #2

.score_kernel:;---------->>> 10 scanlines <<<---
  DEBUG_SUB_KERNEL #$20, #10

.clouds_kernel_setup:;-->>> 2 scanlines <<<-----
  DEBUG_SUB_KERNEL #$30, #2

.clouds_kernel:;-------->>> 20 scanlines <<<----
  DEBUG_SUB_KERNEL #$40, #20

.sky_kernel_setup:;----->>> 2 scanlines <<<-----
  lda BG_COLOUR    ; 3
  sta COLUBK       ; 3

  ; Fix the dino_x position for the rest of the kernel
  ldx #DINO_X_DIV_5
__dino_coarse_pos:
  dex
  bne __dino_coarse_pos
  ; beam should be now at dino X (coarse dino x)
  sta RESMP0 ; M0 will be 3 cycles (9 px) far from P0
  sta RESP0
  sta WSYNC

  ; T0D0: set the coarse position of the cactus/pterodactile
  sta WSYNC
  
  ;-----------------------------------
  ; Prepare for the .sky_kernel
  ;-----------------------------------
  ldx #SKY_KERNEL_LINES    ; The sky is 62 scanlines
.sky_kernel:
  txa  ; A <- current scanline (Y)
  sbc DINO_BOTTOM_Y ; dino bottom y + 1
  adc #DINO_HEIGHT+1
  bcc __skip_dino_in_sky
  tay
  lda (PTR_DINO_SPRITE),y
  sta GRP0

__skip_dino_in_sky:
  dex
  sta WSYNC
  bne .sky_kernel

  ldx #SKY_KERNEL_LINES  ; 62 lines atm
.cactus_kernel: ; 62 lines atm
  DEBUG_SUB_KERNEL #$90, #62
  ; txa  ; A <- current scanline (Y)
  ; sbc DINO_BOTTOM_Y ; dino bottom y + 1
  ; adc #DINO_HEIGHT+1
  ; bcc __skip_dino_in_catcus
  ; tay
  ; lda (PTR_DINO_SPRITE),y
  ; sta GRP0

; __skip_dino_in_catcus:
;   dex
;   bne .cactus_kernel

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
  ;SEG data
  ;ORG $fe00

  ; -----------------------------------------------
  ; Graphics Data from PlayerPal 2600
  ; https://alienbill.com/2600/playerpalnext.html
  ; -----------------------------------------------

DINO_SPRITE_1:
  .ds 1
  .byte %11000110
  .byte %11000110
  .byte %10000100
  .byte %10000100
  .byte %11000100
  .byte %11000100
  .byte %11101100
  .byte %11101100
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111101
  .byte %11111101
  .byte %11111111
  .byte %11111111
  .byte %00111111
  .byte %00111111
  .byte %00011111
  .byte %00011111
  .byte %11111110
  .byte %11111110
  .byte %11111000
  .byte %11111000
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %10111111
  .byte %10111111
  .byte %11111110
  .byte %11111110
  .ds 1

DINO_MIS_OFFSET:
  .ds 1
  .byte %11000110
  .byte %11000110
  .byte %10000100
  .byte %10000100
  .byte %11000100
  .byte %11000100
  .byte %11101100
  .byte %11101100
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111101
  .byte %11111101
  .byte %11111111
  .byte %11111111
  .byte %00111111
  .byte %00111111
  .byte %00011111
  .byte %00011111
  .byte %11111110
  .byte %11111110
  .byte %11111000
  .byte %11111000
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %10111111
  .byte %10111111
  .byte %11111110
  .byte %11111110
  .ds 1
;=============================================================================
; ROM SETUP
;=============================================================================
  ORG $fffc
  .word reset ; reset button signal
  .word reset ; IRQ
