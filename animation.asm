AnimatePlayer_Frame1_forme3:
    ; segment 1
    LDA #$40
    STA SPRITE_RAM + 1
    
    LDA SPRITE_RAM + 2
    AND #%10111111
    STA SPRITE_RAM + 2

    ; segment 2
    LDA #$41
    STA SPRITE_RAM + 1 + 4
    
    LDA SPRITE_RAM + 2 + 4
    AND #%10111111
    STA SPRITE_RAM + 2 + 4

    ; segment 3
    LDA #$50
    STA SPRITE_RAM + 9
    
    LDA SPRITE_RAM + 10
    AND #%10111111
    STA SPRITE_RAM + 10

    ; segment 4
    LDA #$51
    STA SPRITE_RAM + 9 + 4
    
    LDA SPRITE_RAM + 10 + 4
    AND #%10111111
    STA SPRITE_RAM + 10 + 4

    LDX #$00
    STX player_animation

    RTS

AnimatePlayer_Frame2_forme3:
    ; segment 1
    LDA #$41
    STA SPRITE_RAM + 1

    LDA SPRITE_RAM + 2
    ORA #%01000000    
    STA SPRITE_RAM + 2    

    ; segment 2
    LDA #$40
    STA SPRITE_RAM + 1 + 4

    LDA SPRITE_RAM + 2 + 4
    ORA #%01000000    
    STA SPRITE_RAM + 2 + 4
    
    ; segment 3
    LDA #$51
    STA SPRITE_RAM + 9

    LDA SPRITE_RAM + 10
    ORA #%01000000
    STA SPRITE_RAM + 10

    LDA #$50
    STA SPRITE_RAM + 9 + 4

    LDA SPRITE_RAM + 10 + 4
    ORA #%01000000
    STA SPRITE_RAM + 10 + 4

    RTS

AnimatePlayer_Frame1_forme4:
    ; segment 1
    LDA #$42
    STA SPRITE_RAM + 1
    
    LDA SPRITE_RAM + 2
    AND #%10111111
    STA SPRITE_RAM + 2

    ; segment 2
    LDA #$43
    STA SPRITE_RAM + 1 + 4
    
    LDA SPRITE_RAM + 2 + 4
    AND #%10111111
    STA SPRITE_RAM + 2 + 4

    ; segment 3
    LDA #$52
    STA SPRITE_RAM + 9
    
    LDA SPRITE_RAM + 10
    AND #%10111111
    STA SPRITE_RAM + 10

    ; segment 4
    LDA #$53
    STA SPRITE_RAM + 9 + 4
    
    LDA SPRITE_RAM + 10 + 4
    AND #%10111111
    STA SPRITE_RAM + 10 + 4

    LDX #$00
    STX player_animation

    RTS

AnimatePlayer_Frame2_forme4:
    ; segment 1
    LDA #$43
    STA SPRITE_RAM + 1

    LDA SPRITE_RAM + 2
    ORA #%01000000    
    STA SPRITE_RAM + 2    

    ; segment 2
    LDA #$42
    STA SPRITE_RAM + 1 + 4

    LDA SPRITE_RAM + 2 + 4
    ORA #%01000000    
    STA SPRITE_RAM + 2 + 4
    
    ; segment 3
    LDA #$53
    STA SPRITE_RAM + 9

    LDA SPRITE_RAM + 10
    ORA #%01000000
    STA SPRITE_RAM + 10

    LDA #$52
    STA SPRITE_RAM + 9 + 4

    LDA SPRITE_RAM + 10 + 4
    ORA #%01000000
    STA SPRITE_RAM + 10 + 4

    RTS
