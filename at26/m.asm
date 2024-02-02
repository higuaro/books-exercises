  processor 6502
  include "vcs.h"

  ; macros
  mac insert_nops
.num_nops set {1}
    repeat .num_nops
      nop
    repend
  endm

  seg.u variables

  seg data
  org $80

  org $F000

on_reset:
  clc
  sei 

  ldy #0
  tya
  tax
_clear_mem:
  dex
  txs
  pha
  bne _clear_mem

  ; global config
on_frame:

_vblank_and_vsync:
  lda #2
  sta VBLANK   ; turn vidoe signal off
  sta VSYNC    ; \
    sta WSYNC  ;  |
    sta WSYNC  ;  | vsync
    lda #0     ;  |
    sta WSYNC  ;  |
  sta VSYNC    ; /

  lda #43      ;
  sta TIM64T   ; timer 64 starts ticking

  sta HMCLR             ; Clear horizontal motion registers

  ; frame config
  lda #84
  sta COLUBK

  lda #55
  sta COLUP0

  insert_nops #5

  sta RESM0
  sta RESP0
  ;nop


__vblank_tmr:
  lda INTIM
  bne __vblank_tmr
  ; A will be 0 here
  sta WSYNC
  sta VBLANK  ; turn on video signal

  ldy #192
_kernel:
  tya

  ; if 50 <= y <= 75  ==> if 0 <= y - 50 <= 25
  ; 256 - (a - b) -> a >= b --> c = 1; a < b --> c = 0
  cmp #75
  bcs _no_paint
  cmp #50
  bcc _no_paint

  lda #34
  sta COLUBK

  lda #2
  sta ENAM0
  lda #%11111110
  sta GRP0
  lda #2
  sta HMM0                              ; 3
  jmp _painted

  ; else

_no_paint:
  lda #84
  sta COLUBK

  lda #0
  sta GRP0
  sta ENAM0

_painted:

  dey
  sta WSYNC
  sta HMOVE
  bne _kernel

_overscan:
  lda #35
  sta TIM64T

__overscan_tmr:
  lda INTIM
  bne __overscan_tmr
  sta WSYNC
  jmp on_frame

  org $FFFC
  .word on_reset
  .word on_reset
