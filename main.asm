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

;;;;;;;;;;;;
;http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=6082
        ;  PPUCTRL ($2000)
        ;  76543210
        ;  | ||||||
        ;  | ||||++- Base nametable address
        ;  | ||||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
        ;  | |||+--- VRAM address increment per CPU read/write of PPUDATA
        ;  | |||     (0: increment by 1, going across; 1: increment by 32, going down)
        ;  | ||+---- Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000)
        ;  | |+----- Background pattern table address (0: $0000; 1: $1000)
        ;  | +------ Sprite size (0: 8x8; 1: 8x16)
        ;  |
        ;  +-------- Generate an NMI at the start of the
        ;            vertical blanking interval vblank (0: off; 1: on)
;    LDA #%10010000 ;enable NMI, sprites from Pattern 0, background from Pattern 1
    LDA #%10000000 ;enable NMI, sprites from Pattern 0
    STA $2000

;http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=4440
        ;PPUMASK ($2001)
        ;76543210
        ;||||||||
        ;|||||||+- Grayscale (0: normal color; 1: AND all palette entries
        ;|||||||   with 0x30, effectively producing a monochrome display;
        ;|||||||   note that colour emphasis STILL works when this is on!)
        ;||||||+-- Disable background clipping in leftmost 8 pixels of screen
        ;|||||+--- Disable sprite clipping in leftmost 8 pixels of screen
        ;||||+---- Enable background rendering
        ;|||+----- Enable sprite rendering
        ;||+------ Intensify reds (and darken other colors)
        ;|+------- Intensify greens (and darken other colors)
        ;+-------- Intensify blues (and darken other colors)
;    LDA #%00011110 ; enable sprites, enable background
    LDA #%00010000 ; enable sprites
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
    ;;This is the PPU clean up section, so rendering the next frame starts properly.
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
    .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F     ;background palette
;    .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F
;    .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C     ;sprite palette data
    .db $0F,$1C,$15,$20,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C     ;sprite palette data


sprites:
;http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=6082
;  76543210
;  |||   ||
;  |||   ++- Color Palette of sprite.  Choose which set of 4 from the 16 colors to use
;  |||
;  ||+------ Priority (0: in front of background; 1: behind background)
;  |+------- Flip sprite horizontally
;  +-------- Flip sprite vertically
    ;vert tile attr horiz
    .db $80, $00, $00, $80   ;sprite 0
    .db $80, $01, $00, $88   ;sprite 1
    .db $88, $02, $00, $80   ;sprite 2
    .db $88, $03, $00, $88   ;sprite 3



;;;;;;;;;;
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0
    
    .bank 2
    .org $0000
    .incbin "game.chr"
 