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

    .rsset $0000    ; pointers
pointerLo  .rs 1   ; pointer variables are declared in RAM
pointerHi  .rs 1   ; low byte first, high byte immediately after
    .rsset $0100    ; stacks
    .rsset $0200    ; sprites
    .rsset $0300    ; sound
    .rsset $0700    ; variables
player_animation    .rs 1
avatar_x            .rs 1
avatar_y            .rs 1
avatar_mode         .rs 1
current_fade        .rs 1
current_fade_tick   .rs 1

stage1_monsterA     .rs 1

current_stage       .rs 1
    ; game states
    ; 00 = title
    ; 01 = main menu
    ; 02 = stage 1 (sight)
    ; 03 = stage 2 (form)
    ; 03 = stage 3 (birth)
    ; 04 = stage 4 (violence)
    ; 05 = stage 5 (war)
    ; 06 = stage 6 (death)


; http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=33378
SPRITE_RAM = $0200
;TOTAL_SPRITES = 20
TOTAL_SPRITES = $10

ANIMATION_TICK = $03
LEFTWALL    = $20
RIGHTWALL   = $DE

STAGE1_TARGET   = $80
STAGE2_TARGET   = $40

id_avatar  = 0
id_enemy   = 1

avatar_jump_power = $04

;;;;

    .bank 0
    ;.org $8000  ;;$c000
    .org $c000

    .include "animation.asm"

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
    JSR init_PPU

InfiniteLoop:
    JMP InfiniteLoop

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
    STA SPRITE_RAM, x
    INX
    BNE clearmem

    JSR vblankwait ; second vblank    
    JSR init
    JSR init_PPU
    
init:
    LDA #$80

    LDA #$00
    STA player_animation 
    
    LDA #$00
    STA avatar_mode
    STA current_fade
    STA current_fade_tick    
    STA current_stage 

    STA stage1_monsterA
    RTI

;;;;;;;;;;;;
init_PPU:

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
    STA SPRITE_RAM, x     ; store into RAM address ($0200 + x)
    INX                   ; X = X + 1
    CPX TOTAL_SPRITES     ; Compare X to hex $20, decimal 32
    BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                          ; if compare was equal to X, keep going down

LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address

  LDA #$00
  STA pointerLo       ; put the low byte of the address of background into pointer
  LDA #HIGH(background)
  STA pointerHi       ; put the high byte of the address into pointer
  
  LDX #$00            ; start at pointer + 0
  LDY #$00
OutsideLoop:
  
InsideLoop:
  LDA [pointerLo], y  ; copy one background byte from address in pointer plus Y
  STA $2007           ; this runs 256 * 4 times
  
  INY                 ; inside loop counter
  CPY #$00
  BNE InsideLoop      ; run the inside loop 256 times before continuing down
  
  INC pointerHi       ; low byte went 0 to 256, so high byte needs to be changed now
  
  INX
  CPX #$04
  BNE OutsideLoop     ; run the outside loop 256 times before continuing down
                        
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
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
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

  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

    RTS
;;;;;;;;;;;;    
    
avatarPos:
    LDA SPRITE_RAM
    STA avatar_y
    LDA SPRITE_RAM + 3
    STA avatar_x
    RTS

Gravity:    
    ; BCC/BCS

    ; if < 10, exit
    LDA SPRITE_RAM
    CMP #$A0
    BCS exitGravity

    CLC
    ; top half
    LDA SPRITE_RAM
    ADC #$01      
    STA SPRITE_RAM
    STA SPRITE_RAM + 4     

    ; bottom half
    LDA SPRITE_RAM + 8     
    ADC #$01       
    STA SPRITE_RAM + 8     
    STA SPRITE_RAM + 12    
exitGravity:
    RTS

AnimatePlayer:
    LDX player_animation
    INX
    STX player_animation
    
    ;CPX ANIMATION_TICK
    CPX #$20
    BCS AnimatePlayer_Frame1

    CPX #$10
    BCS AnimatePlayer_Frame2

    LDX player_animation
    RTS
    
AnimatePlayer_Frame1:
    LDX avatar_mode
    CPX #$00
    BEQ AnimatePlayer_Frame1_forme1_branch
    BNE .nextF1
    RTS
.nextF1
    CPX #$01
    BEQ AnimatePlayer_Frame1_forme2_branch
    BNE .nextF2
    RTS
.nextF2
    CPX #$02
    BEQ AnimatePlayer_Frame1_forme3_branch
    BNE .nextF3
    RTS
.nextF3
    CPX #$03
    BEQ AnimatePlayer_Frame1_forme4_branch
    RTS
    
AnimatePlayer_Frame1_forme1_branch:    
    JSR AnimatePlayer_Frame1_forme1
    RTS
AnimatePlayer_Frame1_forme2_branch:    
    JSR AnimatePlayer_Frame1_forme2
    RTS
AnimatePlayer_Frame1_forme3_branch:    
    JSR AnimatePlayer_Frame1_forme3
    RTS
AnimatePlayer_Frame1_forme4_branch:    
    JSR AnimatePlayer_Frame1_forme4
    RTS
    
AnimatePlayer_Frame2:
    LDX avatar_mode
    CPX #$00
    BEQ AnimatePlayer_Frame2_forme1_branch
    CPX #$01
    BEQ AnimatePlayer_Frame2_forme2_branch
    CPX #$02
    BEQ AnimatePlayer_Frame2_forme3_branch
    CPX #$03
    BEQ AnimatePlayer_Frame2_forme4_branch
    RTS
    
AnimatePlayer_Frame2_forme1_branch:    
    JSR AnimatePlayer_Frame2_forme1
    RTS
AnimatePlayer_Frame2_forme2_branch:    
    JSR AnimatePlayer_Frame2_forme2
    RTS
AnimatePlayer_Frame2_forme3_branch:    
    JSR AnimatePlayer_Frame2_forme3
    RTS
AnimatePlayer_Frame2_forme4_branch:    
    JSR AnimatePlayer_Frame2_forme4
    RTS
     
UpdateInputs:
Controller1_A:
    LDX avatar_mode
    CPX #$01
    BCC out     ; only avatar from stage 1 and up can jump

    ; top half
    LDA SPRITE_RAM
    CLC
    SBC #avatar_jump_power       
    STA SPRITE_RAM
    STA SPRITE_RAM + 4     

    ; bottom half
    LDA SPRITE_RAM + 8     
    CLC           
    SBC #avatar_jump_power
    STA SPRITE_RAM + 8     
    STA SPRITE_RAM + 12    
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
    ; top half
    SEC
    LDA SPRITE_RAM + 3
    ; can't go past wall
    CMP #LEFTWALL
    BCC out
    
    SEC
    SBC #$01        
    STA SPRITE_RAM + 3
    LDA SPRITE_RAM + 4 + 3
    SBC #$01        
    STA SPRITE_RAM + 4 + 3

    ; bottom half
    LDA SPRITE_RAM + 8 + 3
    SBC #$01        
    STA SPRITE_RAM + 8 + 3
    LDA SPRITE_RAM + 8 + 4 + 3
    SBC #$01        
    STA SPRITE_RAM + 8 + 4 + 3
    JSR AnimatePlayer
out:
    RTS

Controller1_Right:   
    ; top half
    LDA SPRITE_RAM + 3
    ; can't go past wall
    CMP #RIGHTWALL
    BCS out2

    CLC
    ADC #$01        
    STA SPRITE_RAM + 3
    LDA SPRITE_RAM + 4 + 3
    ADC #$01        
    STA SPRITE_RAM + 4 + 3

    ; bottom half
    LDA SPRITE_RAM + 8 + 3
    ADC #$01        
    STA SPRITE_RAM + 8 + 3
    LDA SPRITE_RAM + 8 + 4 + 3
    ADC #$01        
    STA SPRITE_RAM + 8 + 4 + 3

    JSR AnimatePlayer
out2:
    RTS

ReadInput:

ReadController1:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016

    ; A B S St U D L R
    LDA $4016
    AND #%00000001
    BEQ Controller1_ADone
    JSR Controller1_A
Controller1_ADone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_BDone
    JSR Controller1_B
Controller1_BDone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_SelectDone
    JSR Controller1_Select
Controller1_SelectDone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_StartDone
    JSR Controller1_Start
Controller1_StartDone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_UpDone
    JSR Controller1_Up
Controller1_UpDone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_DownDone
    JSR Controller1_Down
Controller1_DownDone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_LeftDone
    JSR Controller1_Left
Controller1_LeftDone:    
    LDA $4016
    AND #%00000001
    BEQ Controller1_RightDone
    JSR Controller1_Right
Controller1_RightDone:    
    RTS

CheckCollision:
    JSR Stage1_CheckCollision
CheckCollisionEnd:
    RTS

Stage1_CheckCollision:
    ; only for stage 1
    LDX avatar_mode
    CPX #$00
    BEQ Stage1_CheckCollision_Go
    RTS
    
Stage1_CheckCollision_Go:
    ; check flag if stage1 enemy is still alive
    LDX stage1_monsterA
    CPX #$00
    BEQ CheckCollisionEnd       ;; todo: possible bug?
        
    ; check player against block (hack: 1st pass)
    LDA SPRITE_RAM + 3
    CLC
    ADC #$8        ;avatar is 16 pixels wide
    CMP #STAGE1_TARGET
    BCC CheckCollisionEnd

    ; move monster to the left as a "new monster"
    LDA #STAGE2_TARGET
    STA SPRITE_RAM + 16 + 3
    STA SPRITE_RAM + 16 + 8 + 3
    LDA #STAGE2_TARGET
    CLC
    ADC #$8
    STA SPRITE_RAM + 16 + 4 + 3
    STA SPRITE_RAM + 16 + 8 + 4 + 3
    
    LDA stage1_monsterA
    ADC #$01
    STA stage1_monsterA

    ; check player against block (hack: 1st pass)
    LDA SPRITE_RAM + 3
    CLC
    ADC #$8        ;avatar is 16 pixels wide
    CMP #STAGE1_TARGET
    BCS OnCollision

    RTS
    
OnCollision:
    LDA avatar_mode
    CLC
    ADC #$01
    STA avatar_mode

    LDA current_stage
    ADC #$01
    STA current_stage
    RTS
    
EnemyUpdate:
    JSR CheckCollision

;    LDX #$0D
;    JSR DoEnemyUpdate
;    JMP DoEnemyUpdate
;    JMP DoEnemyUpdate
;    JMP DoEnemyUpdate
    RTS
    
DoEnemyUpdate:
    ; top half (HORZ)
;    SEC
;    LDA SPRITE_RAM + 3
    SEC
    SBC #$01        
    STA SPRITE_RAM + 3,x
;    LDA SPRITE_RAM + 4 + 3,x
;    SBC #$01        
;    STA SPRITE_RAM + 4 + 3,x

    ; bottom half
;    LDA SPRITE_RAM + 8 + 3,x
;    SBC #$01        
;    STA SPRITE_RAM + 8 + 3,x
;    LDA SPRITE_RAM + 8 + 4 + 3,x
;    SBC #$01        
;    STA SPRITE_RAM + 8 + 4 + 3,x
    
    RTS

FadeUpdate:
    LDA current_stage
    CMP #$03            ; fade only after stage 3
    BCS FadeExit
    
    LDA current_fade_tick
    ADC #$01
    STA current_fade_tick
    CMP #$3F
    BCS FadeExit

    LDA #$00
    STA current_fade_tick
    LDA current_fade
    CMP #$C0
    BEQ Fade2
    
    LDA current_fade
    ADC #$01
    STA current_fade
    
Fade1:
    LDA $2002    ; read PPU status to reset the high/low latch to high
    LDA #$3F
    STA $2006    ; write the high byte of $3F10 address
    LDA #$00
    STA $2006    ; write the low byte of $3F10 address

    LDA #$0F 
    STA $2007
    LDA #$27 
    STA $2007
    LDA #$11
    STA $2007
    LDA #$2A
    STA $2007
    JMP FadeUpdateReset

Fade2:    
    LDA $2002    ; read PPU status to reset the high/low latch to high
    LDA #$3F
    STA $2006    ; write the high byte of $3F10 address
    LDA #$00
    STA $2006    ; write the low byte of $3F10 address

    LDA #$0F 
    STA $2007
    LDA #$27 
    STA $2007
    LDA #$21
    STA $2007
    LDA #$19
    STA $2007
    JMP FadeUpdateReset

FadeUpdateReset:
    LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    STA $2000
    LDA #%00011110   ; enable sprites, enable background, no clipping on left side
    STA $2001
    LDA #$00        ;;tell the ppu there is no background scrolling
    STA $2005

FadeExit:
    RTS
    
MainLoop:
    JSR ReadInput
    JSR Gravity
    JSR EnemyUpdate
    JSR FadeUpdate
    RTS
    
NMI:
    LDA #$00
    STA $2003  ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014  ; set the high byte (02) of the RAM address, start the transfer
    
    JSR MainLoop

PPUCleanUp:
    ;;This is the PPU clean up section, so rendering the next frame starts properly.
    LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
    STA $2000
    LDA #%00011110   ; enable sprites, enable background, no clipping on left side
    STA $2001
    LDA #$00        ;;tell the ppu there is no background scrolling
    STA $2005

    RTI
       
;; Vectors
    .bank 1
    .org $E000

background:

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 01
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 02
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 03 
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 04
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 05
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 06
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 07
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 08
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 09
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 10
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 11
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 12
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 13
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 14
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 15
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 16
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 17
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 18
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 19
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 20
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 21
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 22
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $20,$21,$23,$22,$22,$21,$23,$23,$21,$20,$22,$22,$23,$21,$20,$20   ;; 23
  .db $30,$31,$33,$32,$32,$31,$33,$33,$31,$30,$32,$32,$33,$31,$30,$30  

  .db $30,$31,$33,$32,$32,$31,$33,$33,$31,$30,$32,$32,$33,$31,$30,$30   ;; 24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 25
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 26
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 27
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 28
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 29
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24   ;; 30
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24  

attribute:
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111
;  .db %00000000, %01010101, %10101010, %11111111, %00000000, %01010101, %10101010, %11111111

  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000


palette:
    ;background palette
;    .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F   
    .db $FF,$FF,$FF,$FF,    $0F,$27,$21,$19,    $0F,$27,$21,$19,    $0F,$27,$21,$19
        

;    .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F  ;mario

    ;sprite palette data
    .db $0F,$27,$21,$19,    $0F,$27,$21,$19,    $0F,$27,$21,$19,    $0F,$27,$21,$19
;  .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette


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
 
    ; player
    .db $80, $2C, $00, $20
    .db $80, $2D, $00, $28
    .db $88, $3C, $00, $20
    .db $88, $3D, $00, $28

   ; monster1 
    .db $A0, $2C, $00, STAGE1_TARGET
    .db $A0, $2D, $00, STAGE1_TARGET + $8
    .db $A8, $3C, $00, STAGE1_TARGET
    .db $A8, $3D, $00, STAGE1_TARGET + $8

    ; monster2
;    .db $A0, $2C, $00, $E0
;    .db $A0, $2D, $00, $E8
;    .db $A8, $3C, $00, $E0
;    .db $A8, $3D, $00, $E8
    
;;;;;;;;;;
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0
    
    .bank 2
    .org $0000
    .incbin "game.chr"
;    .incbin "mario.chr"
 