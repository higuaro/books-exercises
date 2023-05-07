  list on
  processor 6502

  include "vcs.h"

  seg.u variables
  org $80

  seg code
  org $f000

on_reset:
  sei
  cld

  ldx #0
  txa
  tay
__init_zp:
  dex
  txs
  pha
  bne __init_zp


on_frame:
;vsync:
  lda #2     ;
  sta VSYNC  ; VSYNC enable
  sta WSYNC
  sta WSYNC
  lda #0 
  sta WSYNC
  sta VSYNC

vblank:
  lda #2     ;
  sta VBLANK ; VBLANK enable
  lda #43
  sta TIM64T

  ; VBLANK things
  lda #0
  sta HMCLR

  lda #18
  sta COLUBK
  lda #$ff
  sta COLUP0

  sta RESM0      ; strobe
  lda #2
  sta ENAM0
  lda #%00010100
  sta NUSIZ0
  sta WSYNC
  
  lda #$41
  sta COLUPF
  sta RESBL
  lda #2
  sta ENABL
  ; CTRLPF   00xx 0xxx   
  lda %00110000
  sta CTRLPF

  lda #$70
  sta HMBL

__vblank_tmr:
  lda INTIM
  bne __vblank_tmr

  ; HERE 54 cpu cycles to spare

  ldy #192 
  sta WSYNC
  sta VBLANK  
  
kernel:
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  
  sta RESBL
  sta RESBL
  sta RESBL
  
  sta WSYNC
  sta HMOVE
  dey
  bne kernel

overscan:
  lda #35
  sta TIM64T
  lda #2
  sta VBLANK
__overscan_tmr:
  lda INTIM
  bne __overscan_tmr
  sta WSYNC

  jmp on_frame


  org $fffc
  .word on_reset
  .word on_reset
