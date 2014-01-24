;    .byte "NES"
;    .byte $1a
;    .byte $01
;    .byte $01
    
;    .byte $00, $00
;    .byte $00,$00,$00,$00,$00,$00,$00,$00

    .inesprg 1   ; 1x 16KB PRG code
    .ineschr 1   ; 1x  8KB CHR data
    .inesmap 0   ; mapper 0 = NROM, no bank swapping
    .inesmir 1   ; background mirroring

    .rsset $0000

buttons1    .rs 1

;;;;

    .bank 0
    .org $8000  ;;$c000
    ;.org $c000

vblankwait:
    BIT $2002
    BPL vblankwait
    RTS
    
RESET:
    SEI
    CLD
    LDX #$40
    STX $4017    ; disable APU frame IRQ
    LDX #$FF
    TXS          ; Set up stack
    INX          ; now X = 0
    STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    STX $4010    ; disable DMC IRQs    

    JSR vblankwait ; first vblank

clearmem:
    LDA #$00
    STA $0000, x
    STA $0100, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
    LDA #$FE
    STA $0200, x
    INX
    BNE clearmem

    JSR vblankwait ; second vblank
    
;;;;;;;;;;;    
LoadPalettes:
    LDA $2002    ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006    ; write the high byte of $3F00 address
    LDA #$00
    STA $2006    ; write the low byte of $3F00 address
    LDX #$00

LoadPalettesLoop:
    LDA palette, x        ;load palette byte
    STA $2007             ;write to PPU
    INX                   ;set index to next byte
    CPX #$20            
    BNE LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done

LoadSprites:
    LDX #$00              ; start at 0
LoadSpritesLoop:
    LDA sprites, x        ; load data from address (sprites +  x)
    STA $0200, x          ; store into RAM address ($0200 + x)
    INX                   ; X = X + 1
    CPX #$20              ; Compare X to hex $20, decimal 32
    BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadBackground:

  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0

LoadBackgroundLoop:
  LDA background, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down             

LoadAttribute:
    LDA $2002             ; read PPU status to reset the high/low latch
    LDA #$23
    STA $2006             ; write the high byte of $23C0 address
    LDA #$C0
    STA $2006             ; write the low byte of $23C0 address
    LDX #$00              ; start out at 0

LoadAttributeLoop:
    LDA attribute, x      ; load data from address (attribute + the value in x)
    STA $2007             ; write to PPU
    INX                   ; X = X + 1
    CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
    BNE LoadAttributeLoop

;;;;;;;;;;;;
    LDA #%10010000 ;enable NMI, sprites from Pattern 0, background from Pattern 1
    STA $2000

    LDA #%00011110 ; enable sprites, enable background
    STA $2001
;;;;;;;;;;;;    
    
InfiniteLoop:
    JMP InfiniteLoop

UpdateInputs:
Controller1_A: 
    RTS
Controller1_B:
    RTS
Controller1_Up:
    RTS
Controller1_Select:
    RTS
Controller1_Start:
    RTS
Controller1_Down:
    RTS
Controller1_Left:
    RTS
Controller1_Right:
    LDA $0203       ; load sprite X position
    CLC             ; make sure the carry flag is clear
    ADC #$01        ; A = A + 1
    STA $0203       ; save sprite X position
    RTS
    
NMI:
    LDA #$00
    STA $2003  ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014  ; set the high byte (02) of the RAM address, start the transfer
    JSR ReadInput
        
ReadInput:

ReadController1:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
ReadController1Loop:
    LDA $4016
    LSR A            ; bit0 -> Carry
    ROL buttons1     ; bit0 <- Carry
    DEX
    BNE ReadController1Loop
    ;RTS

    LDA buttons1
    ; A B S St U D L R
    AND #%10000000
    BEQ Controller1_ADone
    JSR Controller1_A
Controller1_ADone:    
    LDA buttons1
    AND #%01000000
    BEQ Controller1_BDone
    JSR Controller1_B
Controller1_BDone:    
    LDA buttons1
    AND #%00100000
    BEQ Controller1_SelectDone
    JSR Controller1_Select
Controller1_SelectDone:    
    LDA buttons1
    AND #%00010000
    BEQ Controller1_StartDone
    JSR Controller1_Start
Controller1_StartDone:    
    LDA buttons1
    AND #%00001000
    BEQ Controller1_UpDone
    JSR Controller1_Up
Controller1_UpDone:    
    LDA buttons1
    AND #%00000100
    BEQ Controller1_DownDone
    JSR Controller1_Down
Controller1_DownDone:    
    LDA buttons1
    AND #%00000010
    BEQ Controller1_LeftDone
    JSR Controller1_Left
Controller1_LeftDone:    
    LDA buttons1
    AND #%00000001
    BEQ Controller1_RightDone
    JSR Controller1_Right
Controller1_RightDone:    
    RTI

PPUCleanUp:
    LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    STA $2000
    LDA #%00011110   ; enable sprites, enable background, no clipping on left side
    STA $2001
    LDA #$00        ;;tell the ppu there is no background scrolling
    STA $2005
    STA $2005

    RTI
       
;; Vectors
    .bank 1
    .org $E000
palette:
;    .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
    .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F
    .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C


sprites:
    ;vert tile attr horiz
    .db $80, $32, $00, $80   ;sprite 0
    .db $80, $33, $00, $88   ;sprite 1
    .db $88, $34, $00, $80   ;sprite 2
    .db $88, $35, $00, $88   ;sprite 3

background:
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 1
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky ($24 = sky)
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;row 2
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  ;;all sky
    .db $24,$24,$24,$24,$45,$45,$24,$24,$45,$45,$45,$45,$45,$45,$24,$24  ;;row 3
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$53,$54,$24,$24  ;;some brick tops
    .db $24,$24,$24,$24,$47,$47,$24,$24,$47,$47,$47,$47,$47,$47,$24,$24  ;;row 4
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$55,$56,$24,$24  ;;brick bottoms

attribute:
    .db %00000000, %00010000, %0010000, %00010000, %00000000, %00000000, %00000000, %00110000
    .db $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms



;;;;;;;;;;
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0
    
    .bank 2
    .org $0000
    .incbin "mario.chr"
 