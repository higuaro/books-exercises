  processor 6502

  include "vcs.h"

  list on

  MAC INSERT_NOPS  ; insert n nops
.NUM_NOPS SET {1}
    REPEAT .NUM_NOPS
      nop
    REPEND
  ENDM

  org $80
  seg.u variables
;SECONDS ds 1

  seg code
  org $f000

on_start:
  sei
  cld

  lda #0
  tay
  tax
__init_mem:
  txs
  pha
  dex
  bne __init_mem

on_frame:
__vsync_and_vblank:
  lda #2
  sta VBLANK
  sta VSYNC
  sta WSYNC
  sta WSYNC
  lda #0
  sta WSYNC
  sta VSYNC

; 37 lines of vblank
  lda #43
  sta TIM64T
__timer_vblank:
  lda INTIM
  bne __timer_vblank
  sta WSYNC
  sta VBLANK

  lda #79
  sta COLUBK
  lda #19
  sta COLUP0
  sta HMCLR

  ldx #5
set_mis_pos:
  dex
  bne set_mis_pos
  sta RESM0
  lda #2
  sta ENAM0
  lda #%00100000
  sta HMM0
  ldy #192
  sta WSYNC
  sta HMOVE
  lda #%00000000
  sta NUSIZ0

frame:
  sta WSYNC
  ;sta HMOVE
  INSERT_NOPS 12

  dey
  bne frame

overscan:
  lda #2
  sta VBLANK
  lda #35
  sta TIM64T
__timer_overscan
  lda INTIM
  bne __timer_overscan

  sta WSYNC
  jmp on_frame

  org $fffc
  .word on_start
  .word on_start
