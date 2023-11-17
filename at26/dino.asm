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

  MAC INSERT_NOPS  ; insert n nops 
.NUM_NOPS SET {1}
    REPEAT .NUM_NOPS
      nop
    REPEND
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
DINO_HEIGHT = #20
DINO_POS_Y = #8

SKY_KERNEL_LINES = #31
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
PTR_DINO_OFFSET .word  ; 8 bytes
PTR_DINO_MIS .word  ; 10 bytes

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
  lda #DINO_POS_Y+#DINO_HEIGHT
  sta DINO_BOTTOM_Y

  lda #BKG_LIGHT_GRAY
  sta BG_COLOUR

  lda #<[DINO_SPRITE_1 - DINO_POS_Y]
  sta PTR_DINO_SPRITE
  lda #>[DINO_SPRITE_1 - DINO_POS_Y]
  sta PTR_DINO_SPRITE+1

  lda #<[DINO_SPRITE_OFFSET - DINO_POS_Y]
  sta PTR_DINO_OFFSET
  lda #>[DINO_SPRITE_OFFSET - DINO_POS_Y]
  sta PTR_DINO_OFFSET+1

  lda #<[DINO_MIS_OFFSET - DINO_POS_Y]
  sta PTR_DINO_MIS
  lda #>[DINO_MIS_OFFSET - DINO_POS_Y]
  sta PTR_DINO_MIS+1

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

  INSERT_NOPS 7    ; 14 Fix the dino_x position for the rest of the kernel
                   ;    (notice I'm not starving for ROM atm of writing this)
  sta RESMP0       ; 3  TV beam should now be at a dino coarse x position
  sta RESP0        ; 3  M0 will be 3 cycles (9 px) far from P0

  ldy #SKY_KERNEL_LINES    ; 3  The sky is 31 2x scanlines

  ; T0D0: set the coarse position of the cactus/pterodactile
  sta WSYNC                ; 3

.sky_kernel:;----->>> 31 2x scanlines <<<-----
  ; 1st scanline =============
  tya                                   ; 2 - A = current scanline (Y)
  sec                                   ; 2
  sbc DINO_BOTTOM_Y                     ; 3 - A = X - DINO_BOTTOM_Y
  adc #DINO_HEIGHT                      ; 2
  bcc __y_not_within_dino               ; 2/3
  lda (PTR_DINO_SPRITE),y               ; 5+
  sta GRP0                              ; 3
  lda #2 
  sta ENAM0
  lda (PTR_DINO_MIS),y                  ; 5+
  asl
  asl
  and %00011000
  sta NUSIZ0

  lda #0                                ; 2
  sta HMP0                              ; 3
  sta HMM0

__y_not_within_dino:

  sta WSYNC                             ; 3
  sta HMOVE                             ; 3

  ; 2nd scanline =============
  INSERT_NOPS 10                        ; 24
  lda (PTR_DINO_OFFSET),y             ; 5+
  sta HMP0                              ; 3

  sta WSYNC                             ; 3
  sta HMOVE                             ; 3

  dey                                   ; 2
  bne .sky_kernel                       ; 2/3

  ;ldx #SKY_KERNEL_LINES  ; 31 2x scan-lines atm
.cactus_kernel:; ----->>> 31 2x scanlines <<<-----
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

DINO_SPRITE_1:
;          /-8 bits-\                          offset   sprite bits
;          |███████ |                 |███████ |  0      %11111110
;         █|█ ██████|                █|█ ██████|  0      %10111111
;         █|████████|                █|████████|  0      %11111111
;         █|████████|                █|████████|  0      %11111111
;         █|████████|                █|████████|  0      %11111111
;         █|████    |                .|▒████   | +1      %11111000
;         █|██████  |                .|▒██████ | +1      %11111110
;  █     ██|███     |         █     ..|▒▒███   | +2      %11111000
;  █    ███|███     |         █    ...|▒▒▒███  | +3      %11111100
;  ██  ████|█████   |         ██  █...|▒▒▒█████| +3      %11111111
;  ████████|███ █   |         █████...|▒▒▒███ █| +3      %11111101
;  ████████|███     |         ████....|▒▒▒▒▒███| +5      %11111111
;   ███████|██      |          █......|▒▒▒▒▒▒██| +6      %11111111
;    ██████|██      |           ......|▒▒▒▒▒▒██| +6      %11111111
;     ███ █|█       |            ... .|▒▒▒ ▒█  | +5      %11101100
;     ██   |█       |            ..   |▒▒   █  | +5      %11000100
;     █    |█       |            .    |▒    █  | +5      %10000100
;     ██   |██      |            ..   |▒▒   ██ | +5      %11000110
;           76543210                   12345678
;
  .ds 1             ; <------ clears GRP0 so the last row doesn't repeat
  .byte %11000110   ;  ▒▒   ██
  .byte %10000100   ;  ▒    █
  .byte %11000100   ;  ▒▒   █
  .byte %11101100   ;  ▒▒▒ ▒█
  .byte %11111111   ;  ▒▒▒▒▒▒██
  .byte %11111111   ;  ▒▒▒▒▒▒██
  .byte %11111111   ;  ▒▒▒▒▒███
  .byte %11111101   ;  ▒▒▒███ █
  .byte %11111111   ;  ▒▒▒█████
  .byte %11111100   ;  ▒▒▒███
  .byte %11111000   ;  ▒▒███
  .byte %11111110   ;  ▒██████
  .byte %11111000   ;  ▒████
  .byte %11111111   ;  ████████
  .byte %11111111   ;  ████████
  .byte %11111111   ;  ████████
  .byte %10111111   ;  █ ██████
  .byte %11111110   ;  ███████
  .ds 1             ; <- this is to match the size of the pixel offsets table
DINO_SPRITE_1_END = * ; * means 'here' or 'this'

DINO_SPRITE_DEAD:
  .ds 1             ;
  .byte %11000110   ;  ▒▒   ██
  .byte %10000100   ;  ▒    █
  .byte %11000100   ;  ▒▒   █
  .byte %11101100   ;  ▒▒▒ ▒█
  .byte %11111111   ;  ▒▒▒▒▒▒██
  .byte %11111111   ;  ▒▒▒▒▒▒██
  .byte %11111111   ;  ▒▒▒▒▒███
  .byte %11111101   ;  ▒▒▒███ █
  .byte %11111111   ;  ▒▒▒█████
  .byte %11111100   ;  ▒▒▒███
  .byte %11111000   ;  ▒▒███
  .byte %11110000   ;  ▒███
  .byte %11111110   ;  ▒██████
  .byte %11111111   ;  ████████
  .byte %11111111   ;  ████████
  .byte %10111111   ;  █ ██████
  .byte %01011111   ;   █ █████
  .byte %10111110   ;  █ █████
  .ds 1

DINO_SPRITE_OFFSET:
;       LEFT  <---------------------------------------------------------> RIGHT
;offset (px)  | -7  -6  -5  -4  -3  -2  -1  0  +1  +2  +3  +4  +5  +6  +7  +8
;value in hex | 70  60  50  40  30  20  10 00  F0  E0  D0  C0  B0  A0  90  80
  .ds 1
  .byte $00  ;  ▒▒   ██    |  -5
  .byte $00  ;  ▒    █     |  -5
  .byte $00  ;  ▒▒   █     |  -5
  .byte $00  ;  ▒▒▒ ▒█     |  -5
  .byte $F0  ;  ▒▒▒▒▒▒██   |  -6
  .byte $00  ;  ▒▒▒▒▒▒██   |  -6
  .byte $10  ;  ▒▒▒▒▒███   |  -5
  .byte $20  ;  ▒▒▒███ █   |  -3
  .byte $00  ;  ▒▒▒█████   |  -3
  .byte $00  ;  ▒▒▒███     |  -3
  .byte $10  ;  ▒▒███      |  -2
  .byte $10  ;  ▒██████    |  -1
  .byte $00  ;  ▒████      |  -1
  .byte $10  ;  ████████   |   0 <-- Any pixel offset has to be applied on the
  .byte $00  ;  ████████   |   0     previous scanline so it takes effect on
  .byte $00  ;  ████████   |   0     the next scanline, then it remains for the
  .byte $00  ;  █ ██████   |   0     next scanlines
  .byte $00  ;  ███████    |   0
  .ds 1      ; <- this resets the HMP0 register back to 0
DINO_MIS_OFFSET:
;
; M0 is strobed at a moment T
;   |         +--- then GRP0 is strobed at T+3 CPU cycles (9 pixels) after M0
;   |         |
;   v         v                                      missile offset and size
;  |         |███████          |         |███████           0  0
;  |█        |█ ██████         |        █|█ ██████         +8  1
;  |█        |████████         |        █|████████         +8  1
;  |█        |████████         |        █|████████         +8  1
;  |█        |████████         |        █|████████         +8  1
;  |        ▒|████             |        ▒|████              0  0
;  |    ?   ▒|██████           |        ▒|██████            0  0
;  |█   |  ▒▒|███              | █     ▒▒|███              +1  1
;  |█   v ▒▒▒|███              | █    ▒▒▒|███              +1  1
;  |██  █ ▒▒▒|█████            | ██  █▒▒▒|█████            +1  2 (repeat?)
;  |█████ ▒▒▒|███ █            | █████▒▒▒|███ █            +1  8
;  |████▒▒▒▒▒|███              | ███X▒▒▒▒|███              +1  4 or rmore
;  | █ ▒▒▒▒▒▒|██               |  █▒▒▒▒▒▒|██               +1  1 or more
;  |   ▒▒▒▒▒▒|██               |   ▒▒▒▒▒▒|██                0  0
;  |    ▒▒▒ ▒|█                |    ▒▒▒ ▒|█                 0  0
;  |    ▒▒   |█                |    ▒▒   |█                 0  0
;  |    ▒    |█                |    ▒    |█                 0  0
;  |    ▒▒   |██               |    ▒▒   |██                0  0
;  |-- 9 px -|                 |-- 9 px -|
;   012345678                   012345678       X means overlapping pixel

                  ; offset in px      missile   missile
  .ds 1           ;  012345678         offset    size (NUSIZE bits 5,4)
  .byte %00       ; |    ▒▒   |██         0        0
  .byte %00       ; |    ▒    |█          0        0
  .byte %00       ; |    ▒▒   |█          0        0
  .byte %00       ; |    ▒▒▒ ▒|█          0        0
  .byte %00       ; |   ▒▒▒▒▒▒|██         0        0
  .byte %11100000 ; |  █▒▒▒▒▒▒|██        +2        1 or more
  .byte %11110000 ; | ███X▒▒▒▒|███       +1        4 or rmore
  .byte %11110000 ; | █████▒▒▒|███ █     +1        8
  .byte %11110000 ; | ██  █▒▒▒|█████     +1        2
  .byte %11110000 ; | █   ^▒▒▒|███       +1        1
  .byte %11110000 ; | █   | ▒▒|███       +1        1
  .byte %00       ; |     ?  ▒|██████     0        0
  .byte %00       ; |        ▒|████       0        0
  .byte %10000000 ; |        █|████████  +8        1
  .byte %10000000 ; |        █|████████  +8        1
  .byte %10000000 ; |        █|████████  +8        1
  .byte %10000000 ; |        █|█ ██████  +8        1
  .byte %00       ; |         |███████    0        0
  .ds 1           ; |         |  

; .ds 1           ;  012345678         offset    size (NUSIZE bits 5,4)
; .byte %00       ; |    ▒▒   |██         0        0
; .byte %00       ; |    ▒    |█          0        0
; .byte %00       ; |    ▒▒   |█          0        0
; .byte %00       ; |    ▒▒▒ ▒|█          0        0
; .byte %00       ; |   ▒▒▒▒▒▒|██         0        0
; .byte %11100110 ; |  █▒▒▒▒▒▒|██        +2        1 or more
; .byte %11111010 ; | ███X▒▒▒▒|███       +1        4 or rmore
; .byte %11111110 ; | █████▒▒▒|███ █     +1        8
; .byte %11110110 ; | ██  █▒▒▒|█████     +1        2
; .byte %11110010 ; | █   ^▒▒▒|███       +1        1
; .byte %11110010 ; | █   | ▒▒|███       +1        1
; .byte %00       ; |     ?  ▒|██████     0        0
; .byte %00       ; |        ▒|████       0        0
; .byte %10000010 ; |        █|████████  +8        1
; .byte %10000010 ; |        █|████████  +8        1
; .byte %10000010 ; |        █|████████  +8        1
; .byte %10000010 ; |        █|█ ██████  +8        1
; .byte %00       ; |         |███████    0        0
; .ds 1           ; |         |  
;                   |         | ^ █ sprite pixels (GRP0)
;                       ^ 
;               █ missile pixels and 
;               ▒ shifted sprite pixels (GRP0 after HMOVE)

;=============================================================================
; ROM SETUP
;=============================================================================
  ORG $fffc
  .word reset ; reset button signal
  .word reset ; IRQ
