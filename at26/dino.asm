  processor 6502

  include "vcs.h"

; -----------------------------------------------------------------------------
;   CONSTANTS
; -----------------------------------------------------------------------------

RANDOM_MEM_0 = $c1
RANDOM_MEM_1 = $e5

BKG_LIGHT_GRAY = #13
DINO_HEIGHT = 39

; -----------------------------------------------------------------------------
;   MEMORY / VARIABLES
; -----------------------------------------------------------------------------
  seg.u variables
  org $80

RND_SEED .word ; 2 bytes
DINO_Y .byte   ; 3 bytes

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
  ; I can use those leftovers for the random seed before doing a ZP cleaning
  lda <RND_SEED
  adc RANDOM_MEM_0
  sta <RND_SEED
  ;
  lda >RND_SEED
  adc RANDOM_MEM_1
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
  ; INITIALIZATION
  ; -----------------------
  lda #80
  sta DINO_Y

  ; -----------------------
  ; FRAME
  ; -----------------------
on_frame:

_vsync_and_vblank:
  ; last line of overscan
  inc <RND_SEED
  sta WSYNC

  ; -----------------------
  ; V-SYNC (3 scanlines)
  ; -----------------------
__vsync:
  lda #2
  sta VSYNC  ; VSYNC = A (A=2) enables vsync
    inc <RND_SEED
    lda #0
    adc >RND_SEED
  sta WSYNC
    inc <RND_SEED
    adc >RND_SEED
  sta WSYNC
    inc <RND_SEED
    adc >RND_SEED
  sta WSYNC
  sta VSYNC  ; VSYNC = A (A=0) disables vsync

  ; -----------------------
  ; V-BLANK (37 scanlines)
  ; -----------------------
  ; Set the timer for the remaining VBLANK period (37 lines)
  ; 76 cpu cycles per scanline, 37 * 76 = 2812 cycles / 64 ticks => 43
  lda #43
  sta TIM64T

  ; frame update logic
  lda #BKG_LIGHT_GRAY
  sta COLUBK

  lda #0
__vblank:
  lda INTIM
    inc <RND_SEED
    adc >RND_SEED
  bne __vblank 
               ; 2752 cycles + 2 from bne, 2754 (out of 2812 vblank)
  sta HMCLR    ; Clear horizontal motion registers
  sta WSYNC
  sta VBLANK   ; Disables VBLANK (A=0)

; -----------------------------------------------------------------------------
; KERNEL
; -----------------------------------------------------------------------------
  ldy #192
_kernel:
  ;sta HMCLR            ; 3
  ; book routine
  ; ================
  ; txa                ; 2
  ; sec                ; 2
  ; sbc YPos           ; 3
  ; cmp #SpriteHeight  ; 2
  ; bcc InSprite       ; 2/3 = 11/12 cycles

  ; Both a BNE and sta HMOVE happen at the beginning of all but the 1st scanline
  ; thus we start each of the remaining relevant 191 scalines with 6 cycles
  ; bne _kernel        ; 3
  ; sta HMOVE          ; 3
  ; ================
  ; Dino sprite section
  sec                  ; 2
  tya                  ; 2
  sbc DINO_Y           ; 3
  cmp #DINO_HEIGHT     ; 2
  bcs __no_dino        ; 2/3 = 11/12 cycles (total so far 17/18)

  ; Branch not taken, 17 cycles
  ;


; Load dino sprite data
  tax                  ; 2
  lda DINO_TAIL,X      ; 4
  sta GRP0             ; 3
  lda DINO_HEAD_0,X    ; 4
  sta GRP1             ; 3 (total so far 16 + 17 = 33 cycles)
  sta RESP0            ; 3  38 cycles, f(38) = 10px
  sta RESP1            ; 3  41 cycles

  lda $10              ; 2  graphics for player 1 offset 1px left
  sta HMP1             ; 3  fine positioning for the dino head
  ; Formula for horizontal position in pixels
  ; f(cycles) = (cycles - 23 [HBLANK]) / 3 [TIA] + 5 [TIA HOR DELAY]

  lda #2
  sta ENAM0
  sta RESM0


__no_dino:  ; if branch taken, 12 cycles
  nop


  lda #0
  sta ENAM0


  dey                  ; 2
  sta WSYNC            ; 3
  sta HMOVE            ; 3
  bne _kernel          ; 2/3

; -----------------------------------------------------------------------------

  ; -----------------------
  ; OVERSCAN (30 scanlines)
  ; -----------------------
  ; 30 lines of OVERSCAN, 30 * 76 / 64 = 35
  lda #35
  sta TIM64T
  lda #2
  sta VBLANK
  lda #0
__overscan:
  lda INTIM
    inc <RND_SEED
    adc >RND_SEED
  bne __overscan

  ; We're on the final OVERSCAN line and 40 cpu cycles remain,
  ; do the jump now to consume some cycles and a WSYNC at the 
  ; beginning of the next frame to consume the rest
  jmp on_frame


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

