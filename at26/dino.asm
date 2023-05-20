  processor 6502

  include "vcs.h"
  list on
; -----------------------------------------------------------------------------
; MACROS
; -----------------------------------------------------------------------------
  mac DEC_Y_AND_END_SCANLINE
    ; These 2 instructions take place at the end of the scanline
    dey                 ; 2
    sta WSYNC           ; 3
    ; Both sta HMOVE and BNE happen at the beginning of all but the 1st scanline
    ; thus each of the remaining 191 scanlines starts with 6 cycles
    sta HMOVE           ; 3
    bne _kernel         ; 3/4 Within the contex of this macro this branch will
                        ;     be always taken, but it might cross page boundary
                        ;     hence the 4
                        ;
                        ; 11/12 cycles to start/finish the scanline :(
  endm

  mac DEBUG_SUB_KERNEL
.BGCOLOR set {1}
    lda #.BGCOLOR
    sta COLUBK
    DEC_Y_AND_END_SCANLINE
  endm

; -----------------------------------------------------------------------------
; CONSTANTS
; -----------------------------------------------------------------------------
KERNEL_TABLE_BASE = $fc00

RND_MEM_LOC_1 = $c1   ; "random" memory locations to sample the upper/lower 
RND_MEM_LOC_2 = $e5   ; bytes when the machine starts. 

BKG_LIGHT_GRAY = #13
DINO_HEIGHT = 39

; -----------------------------------------------------------------------------
; MEMORY / VARIABLES
; -----------------------------------------------------------------------------
  seg.u variables
  org $80

CURRENT_SUB_KERNEL .word ; 2 bytes
RND_SEED .word           ; 4 bytes
DINO_Y .byte             ; 5 bytes

; -----------------------------------------------------------------------------
; ROM / CODE
; -----------------------------------------------------------------------------
  seg code
  org $f000

  ; -----------------------
  ; RESET
  ; -----------------------
on_reset:
  sei     ; SEt Interruption disable
  cld     ; (CLear Decimal) disable BCD math

  ; At the start, the machine memory could be in any state, and that's good!
  ; We can use those leftovers for the random seed before doing a ZP cleaning
  lda <RND_SEED
  adc RND_MEM_LOC_1
  sta <RND_SEED
  ;
  lda >RND_SEED
  adc RND_MEM_LOC_2
  sta >RND_SEED

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

  lda <#__score_kernel_setup
  sta CURRENT_SUB_KERNEL
  lda >#__score_kernel_setup
  sta CURRENT_SUB_KERNEL+1

  ; -----------------------
  ; FRAME
  ; -----------------------
on_frame:

_vsync_and_vblank:
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

  lda #0
__vblank:
  lda INTIM
  bne __vblank 
               ; 2752 cycles + 2 from bne, 2754 (out of 2812 vblank)
  sta WSYNC
  sta VBLANK   ; Disables VBLANK (A=0)
  sta HMOVE

; -----------------------------------------------------------------------------
; BEGIN KERNEL
; -----------------------------------------------------------------------------
  ldy #192
_kernel:
  lda KERNEL_TABLE_BASE,y         ; 5
  sta CURRENT_SUB_KERNEL          ; 3
  lda KERNEL_TABLE_BASE+1,y       ; 5
  sta CURRENT_SUB_KERNEL+1        ; 3
  jmp (CURRENT_SUB_KERNEL)        ; 5 - 21 cycles just to start the line!!! NAH

__score_kernel_setup:
  DEBUG_SUB_KERNEL #$10

__score_kernel:
  DEBUG_SUB_KERNEL #$20

__clouds_kernel_setup:
  DEBUG_SUB_KERNEL #$30

__clouds_kernel:
  DEBUG_SUB_KERNEL #$40

__sky_kernel_setup:
  DEBUG_SUB_KERNEL #$50

__sky_kernel:
  DEBUG_SUB_KERNEL #$60

__cactus_kernel_setup:
  DEBUG_SUB_KERNEL #$70

__cactus_kernel:
  DEBUG_SUB_KERNEL #$80

__floor_kernel:
  DEBUG_SUB_KERNEL #$AA

; -----------------------------------------------------------------------------
; END KERNEL
; -----------------------------------------------------------------------------

  ; -----------------------
  ; OVERSCAN (30 scanlines)
  ; -----------------------
  ; 30 lines of OVERSCAN, 30 * 76 / 64 = 35
  lda #30
  sta TIM64T
  lda #2
  sta VBLANK
__overscan:
  lda INTIM
    inc <RND_SEED
    ;adc >RND_SEED
  bne __overscan

  ; We're on the final OVERSCAN line and 40 cpu cycles remain,
  ; do the jump now to consume some cycles and a WSYNC at the 
  ; beginning of the next frame to consume the rest
  jmp on_frame

  seg data
; -----------------------------------------------------------------------------
; KERNEL TABLE
; -----------------------------------------------------------------------------
; A table to store the jump labels for the different kernel sub-sections
  org #KERNEL_TABLE_BASE

  ds.w #2, __score_kernel_setup
  ds.w #8, __score_kernel
  ds.w #2, __clouds_kernel_setup
  ds.w #10, __clouds_kernel
  ds.w #2, __sky_kernel_setup
  ds.w #10, __sky_kernel
  ds.w #2, __cactus_kernel_setup
  ds.w #10, __cactus_kernel
  ds.w #2, __floor_kernel

; -----------------------------------------------------------------------------
; SPRITE GRAPHICS DATA
; -----------------------------------------------------------------------------
  org $fe00

  ; -----------------------------------------------
  ; Graphics Data from PlayerPal 2600
  ; https://alienbill.com/2600/playerpalnext.html
  ; -----------------------------------------------

DINO_TAIL:
  .byte #%00000000
  .byte #%00000000
  .byte #%00011000
  .byte #%00011000
  .byte #%00010000
  .byte #%00010000
  .byte #%00011000
  .byte #%00011000
  .byte #%00011101
  .byte #%00011101
  .byte #%00111111
  .byte #%00111111
  .byte #%01111111
  .byte #%01111111
  .byte #%11111111
  .byte #%11111111
  .byte #%11111111
  .byte #%11111111
  .byte #%11001111
  .byte #%11001111
  .byte #%10000111
  .byte #%10000111
  .byte #%10000011
  .byte #%10000011
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000001
  .byte #%00000000
  .byte #%00000000
  
DINO_HEAD_0:
  .byte #%00000000
  .byte #%00000000
  .byte #%11000000
  .byte #%11000000
  .byte #%10000000
  .byte #%10000000
  .byte #%10000000
  .byte #%10000000
  .byte #%10000000
  .byte #%10000000
  .byte #%11000000
  .byte #%11000000
  .byte #%11000000
  .byte #%11000000
  .byte #%11100000
  .byte #%11100000
  .byte #%11101000
  .byte #%11101000
  .byte #%11111000
  .byte #%11111000
  .byte #%11100000
  .byte #%11100000
  .byte #%11100000
  .byte #%11100000
  .byte #%11111100
  .byte #%11111100
  .byte #%11110000
  .byte #%11110000
  .byte #%11111111
  .byte #%11111111
  .byte #%11111111
  .byte #%11111111
  .byte #%11111111
  .byte #%11111111
  .byte #%10111111
  .byte #%10111111
  .byte #%11111110
  .byte #%11111110


; -----------------------------------------------------------------------------
; ROM SETUP
; -----------------------------------------------------------------------------
  org $fffc
    .word on_reset ; reset button signal
    .word on_reset ; IRQ
