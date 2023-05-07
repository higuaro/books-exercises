  processor 6502
  include "vcs.h"
  include "macro.h"

  seg code
  org $f000   ; The memory bus is way to access the entire hardware.
              ; As a recap:
              ; $00-$7f  - TIA registers \ this area is known as the 
              ; $80-$ff  - Main memory   / Zero Page Region
              ; <RIOT>
              ; $f000-$ffff - ROM

power_on_or_reset:
  sei       ; Set Interrupt Disable - disable interruptions
  cld       ; Clear Decimal Mode - disable BCD math mode

  ldx  #0
  txa
  tay
__clear_zp:
  dex
  txs
  pha
  bne __clear_zp


frame:
  ; VSYNC signal
  lda  #2
  sta  VBLANK
  sta  VSYNC
  sta  WSYNC
  sta  WSYNC
  lsr
  sta  WSYNC

  ; Continue with the 37 lines of VBLANK, for which we will use a timer
  ; there are 76 CPU cycles per scanline, so VBLANK is 37 * 76 cpu cycles = 
  ; 2812 cpu cycles. Here I use the 64 cycles timer, with ; 43 ticks: 
  ; 43 ticks * 64 cycles is 2752 cycles. Leaving 60 cpu cycles to spare that
  ; can then be consumed with a WSYNC
  lda  #43
  sta  TIM64T
__on_vblank_tmr:
  lda  


  jmp frame


  org  $fffc
  .word reset   ; at $fffc we store the 16 address of the program start
  .word reset   ; at $fffe we store again the same address
