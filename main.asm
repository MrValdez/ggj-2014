;    .byte "NES"
;    .byte $1a
;    .byte $01
;    .byte $01
    
;    .byte $00, $00
;    .byte $00,$00,$00,$00,$00,$00,$00,$00

;    .inesprg 1
;    .ineschr 1
;    .inesmap 0
;    .inesmir 1

;;;;

    .bank 0
    .org $8000  ;;$c000

RESET:
    SEI
    CLD
    
vblankwait1:
    BIT $2002
    BPL vblankwait1

clearmem:
    LDA #$00
    STA $0000, x
    STA $0100, x
    STA $0300, x
    INX
    BNE clearmem

vblankwait2:
    BIT $2002
    BPL vblankwait2
    
InfiniteLoop:
    JMP InfiniteLoop
    
NMI:
    RTI
       
;; Vectors
    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0
    
    .bank 2
    .org $0000
    .incbin "mario.chr"
 