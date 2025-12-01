; z80dasm 1.1.6                                                 
; command line: z80dasm -l -b blockfile -g0 -t -a invaders.bin  
                                                                
	org	00000h                                                     
                                                                
                                                                
; BLOCK 'a' (start 0x0000 end 0x0bf7)                           
a_first:                                                        
    nop                              ; 0000     00               ;  This provides a slot ...
    nop                              ; 0001     00               ;  ... to put in a JP for ...
    nop                              ; 0002     00               ;  ... development
    jp init                          ; 0003     c3 d4 18         ;  Continue startup at 18D4

l0006h:                                                         
    nop                              ; 0006     00               ;  Padding before fixed ISR address
    nop                              ; 0007     00              
isr_008h:
    push af                          ; 0008     f5               ;  Save ...
    push bc                          ; 0009     c5               ;  ...
    push de                          ; 000a     d5               ;  ...
    push hl                          ; 000b     e5               ;  ... everything
l000ch:                                                         
    jp isr_08_continues              ; 000c     c3 8c 00         ;  Continue ISR at 8C

    nop                              ; 000f     00               ;  Padding before fixed ISR address
l0010h:                                                         
isr_010h:                                                         
    push af                          ; 0010     f5               ;  Save ...
    push bc                          ; 0011     c5               ;  ...
    push de                          ; 0012     d5               ;  ...
    push hl                          ; 0013     e5               ;  ... everything
    ld a,080h                        ; 0014     3e 80            ;  Flag that tells objects ...
    ld (vblank_status),a             ; 0016     32 72 20         ;  ... on the lower half of the screen to draw/move
    ld hl,isr_delay                  ; 0019     21 c0 20         ;  Decrement ...
    dec (hl)                         ; 001c     35               ;  ... the general countdown (used for pauses)
    call check_handle_tilt           ; 001d     cd cd 17         ;  Check and handle TILT
l0020h:                                                         
    in a,(001h)                      ; 0020     db 01            ;  Read coin switch
    rrca                             ; 0022     0f               ;  Has a coin been deposited (bit 0)?
    jp c,l0067h                      ; 0023     da 67 00         ;  Yes ... note that switch is closed and continue at 3F with A=1
    ld a,(coin_switch)               ; 0026     3a ea 20         ;  Switch is now open. Was it ...
    and a                            ; 0029     a7               ;  ... closed last time?
    jp z,l0042h                      ; 002a     ca 42 00         ;  No ... skip registering the credit
    ld a,(num_coins)                 ; 002d     3a eb 20         ;  Number of credits in BCD
l0030h:                                                         
    cp 099h                          ; 0030     fe 99            ;  99 credits already?
    jp z,l003eh                      ; 0032     ca 3e 00         ;  Yes ... ignore this (better than rolling over to 00)
    add a,001h                       ; 0035     c6 01            ;  Bump number of credits
    daa                              ; 0037     27               ;  Make it binary coded decimal
    ld (num_coins),a                 ; 0038     32 eb 20         ;  New number of credits
    call draw_num_credits            ; 003b     cd 47 19         ;  Draw credits on screen
l003eh:                                                         
    xor a                            ; 003e     af               ;  Credit switch ...
l003fh:                                                         
    ld (coin_switch),a               ; 003f     32 ea 20         ;  ... has opened
l0042h:                                                         
    ld a,(suspend_play)              ; 0042     3a e9 20         ;  Are we moving ...
    and a                            ; 0045     a7               ;  ... game objects?
    jp z,isr_restore_regs_exit       ; 0046     ca 82 00         ;  No ... restore registers and out
    ld a,(game_mode)                 ; 0049     3a ef 20         ;  Are we in ...
    and a                            ; 004c     a7               ;  ... game mode?
    jp nz,l006fh                     ; 004d     c2 6f 00         ;  Yes ... go process game-play things and out
    ld a,(num_coins)                 ; 0050     3a eb 20         ;  Number of credits
    and a                            ; 0053     a7               ;  Are there any credits (player standing there)?
    jp nz,l005dh                     ; 0054     c2 5d 00         ;  Yes ... skip any ISR animations for the splash screens
    call isrspl_tasks                ; 0057     cd bf 0a         ;  Process ISR tasks for splash screens
    jp isr_restore_regs_exit         ; 005a     c3 82 00         ;  Restore registers and out

l005dh:                                                         
    ld a,(wait_start_loop)           ; 005d     3a 93 20         ;  Are we in the ...
    and a                            ; 0060     a7               ;  ... "press start" loop?
    jp nz,isr_restore_regs_exit      ; 0061     c2 82 00         ;  Yes ... restore registers and out
    jp wait_for_start                ; 0064     c3 65 07         ;  Start the "press start" loop

l0067h:                                                         
    ld a,001h                        ; 0067     3e 01            ;  Remember switch ...
    ld (coin_switch),a               ; 0069     32 ea 20         ;  ... state for debounce
    jp l003fh                        ; 006c     c3 3f 00         ;  Continue

l006fh:                                                         
    call time_fleet_sound            ; 006f     cd 40 17         ;  Time down fleet sound and sets flag if needs new delay value
l0072h:                                                         
    ld a,(obj2timer_extra)           ; 0072     3a 32 20         ;  Use rolling shot's timer to sync ...
    ld (shot_sync),a                 ; 0075     32 80 20         ;  ... other two shots
    call draw_alien                  ; 0078     cd 00 01         ;  Draw the current alien (or exploding alien)
    call run_game_objs               ; 007b     cd 48 02         ;  Process game objects (including player object)
    call time_to_saucer              ; 007e     cd 13 09         ;  Count down time to saucer
    nop                              ; 0081     00               ;  ** Why are we waiting?
isr_restore_regs_exit:                                                         
    pop hl                           ; 0082     e1               ;  Restore ...
    pop de                           ; 0083     d1               ;  ...
    pop bc                           ; 0084     c1               ;  ...
    pop af                           ; 0085     f1               ;  ... everything
    ei                               ; 0086     fb               ;  Enable interrupts
    ret                              ; 0087     c9               ;  Return from interrupt

    nop                              ; 0088     00               ;  ** Why waste the space?
    nop                              ; 0089     00              
    nop                              ; 008a     00              
    nop                              ; 008b     00              
isr_08_continues:                                                         
    xor a                            ; 008c     af               ;  Flag that tells ...
    ld (vblank_status),a             ; 008d     32 72 20         ;  ... objects on the upper half of screen to draw/move
    ld a,(suspend_play)              ; 0090     3a e9 20         ;  Are we moving ...
    and a                            ; 0093     a7               ;  ... game objects?
    jp z,isr_restore_regs_exit       ; 0094     ca 82 00         ;  No ... restore and return
    ld a,(game_mode)                 ; 0097     3a ef 20         ;  Are we in ...
    and a                            ; 009a     a7               ;  ... game mode?
    jp nz,l00a5h                     ; 009b     c2 a5 00         ;  Yes .... process game objects and out
    ld a,(isr_splash_task)           ; 009e     3a c1 20         ;  Splash-animation tasks
    rrca                             ; 00a1     0f               ;  If we are in demo-mode then we'll process the tasks anyway
    jp nc,isr_restore_regs_exit      ; 00a2     d2 82 00         ;  Not in demo mode ... done
l00a5h:                                                         
    ld hl,02020h                     ; 00a5     21 20 20         ;  Game object table (skip player-object at 2010)
    call keep_processing_game_objs   ; 00a8     cd 4b 02         ;  Process all game objects (except player object)
    call cursor_next_alien           ; 00ab     cd 41 01         ;  Advance cursor to next alien (move the alien if it is last one)
    jp isr_restore_regs_exit         ; 00ae     c3 82 00         ;  Restore and return

init_rack:                                                      
    call get_alien_reference_ptr     ; 00b1     cd 86 08         ;  2xFC Get current player's ref-alien position pointer
    push hl                          ; 00b4     e5               ;  Hold pointer
    ld a,(hl)                        ; 00b5     7e               ;  Get player's ...
    inc hl                           ; 00b6     23               ;  ... ref-alien ...
    ld h,(hl)                        ; 00b7     66               ;  ...
    ld l,a                           ; 00b8     6f               ;  ... coordinates
    ld (ref_alien_yr),hl             ; 00b9     22 09 20         ;  Set game's reference alien's X,Y
    ld (alien_pos_lsb),hl            ; 00bc     22 0b 20         ;  Set game's alien cursor bit position
    pop hl                           ; 00bf     e1               ;  Restore pointer
    dec hl                           ; 00c0     2b               ;  21FB or 22FB ref alien's delta (left or right)
    ld a,(hl)                        ; 00c1     7e               ;  Get ref alien's delta X
    cp 003h                          ; 00c2     fe 03            ;  If there is one alien it will move right at 3
    jp nz,l00c8h                     ; 00c4     c2 c8 00         ;  Not 3 ... keep it
    dec a                            ; 00c7     3d               ;  If it is 3, back it down to 2 until it switches again
l00c8h:                                                         
    ld (ref_alien_dxr),a             ; 00c8     32 08 20         ;  Store alien deltaY
    cp 0feh                          ; 00cb     fe fe            ;  Moving left?
    ld a,000h                        ; 00cd     3e 00            ;  Value of 0 for rack-moving-right (not XOR so flags are unaffected)
    jp nz,l00d3h                     ; 00cf     c2 d3 00         ;  Not FE ... keep the value 0 for right
    inc a                            ; 00d2     3c               ;  It IS FE ... use 1 for left
l00d3h:                                                         
    ld (rack_direction),a            ; 00d3     32 0d 20         ;  Store rack direction
    ret                              ; 00d6     c9               ;  Done

init_racks_direction:                                                      
    ld a,002h                        ; 00d7     3e 02            ;  Set ...
    ld (p1ref_alien_dx),a            ; 00d9     32 fb 21         ;  ... player 1 and 2 ...
    ld (p2ref_alien_dx),a            ; 00dc     32 fb 22         ;  ... alien delta to 2 (right 2 pixels)
    jp l08e4h                        ; 00df     c3 e4 08        

    nop                              ; 00e2     00              
    nop                              ; 00e3     00              
    nop                              ; 00e4     00              
    nop                              ; 00e5     00              
    nop                              ; 00e6     00              
    nop                              ; 00e7     00              
    nop                              ; 00e8     00              
    nop                              ; 00e9     00              
    nop                              ; 00ea     00              
    nop                              ; 00eb     00              
    nop                              ; 00ec     00              
    nop                              ; 00ed     00              
    nop                              ; 00ee     00              
    nop                              ; 00ef     00              
    nop                              ; 00f0     00              
    nop                              ; 00f1     00              
    nop                              ; 00f2     00              
    nop                              ; 00f3     00              
    nop                              ; 00f4     00              
    nop                              ; 00f5     00              
    nop                              ; 00f6     00              
    nop                              ; 00f7     00              
    nop                              ; 00f8     00              
    nop                              ; 00f9     00              
    nop                              ; 00fa     00              
    nop                              ; 00fb     00              
    nop                              ; 00fc     00              
    nop                              ; 00fd     00              
    nop                              ; 00fe     00              
    nop                              ; 00ff     00              
draw_alien:                                                     
    ld hl,alien_is_exploding         ; 0100     21 02 20         ;  Is there an ...
    ld a,(hl)                        ; 0103     7e               ;  ... alien ...
    and a                            ; 0104     a7               ;  ... exploding?
    jp nz,aexplode_time              ; 0105     c2 38 15         ;  Yes ... go time it down and out
    push hl                          ; 0108     e5               ;  2002 on the stack
    ld a,(alien_cur_index)           ; 0109     3a 06 20         ;  Get alien index ...
    ld l,a                           ; 010c     6f               ;  ... for the 21xx or 22xx pointer
    ld a,(player_data_msb)           ; 010d     3a 67 20         ;  Get MSB ...
    ld h,a                           ; 0110     67               ;  ... of data area (21xx or 22xx)
    ld a,(hl)                        ; 0111     7e               ;  Get alien status flag
    and a                            ; 0112     a7               ;  Is the alien alive?
    pop hl                           ; 0113     e1               ;  HL=2002
    jp z,l0136h                      ; 0114     ca 36 01         ;  No alien ... skip drawing alien sprite (but flag done)
    inc hl                           ; 0117     23               ;  HL=2003 Bump descriptor
    inc hl                           ; 0118     23               ;  HL=2004 Point to alien's row
    ld a,(hl)                        ; 0119     7e               ;  alien_row
    inc hl                           ; 011a     23               ;  HL=2005 Bump descriptor
    ld b,(hl)                        ; 011b     46               ;  read alien_ani_frame_number
    and 0feh                         ; 011c     e6 fe            ;  Translate row to type offset as follows: ...
    rlca                             ; 011e     07               ;  ... 0,1 -> 32 (type 1) ...
    rlca                             ; 011f     07               ;  ... 2,3 -> 16 (type 2) ...
    rlca                             ; 0120     07               ;  ...   4 -> 32 (type 3) on top row
    ld e,a                           ; 0121     5f               ;  Sprite offset LSB
    ld d,000h                        ; 0122     16 00            ;  MSB is 0
    ld hl,sprite_aliens_start_a      ; 0124     21 00 1c         ;  Position 0 alien sprites
    add hl,de                        ; 0127     19               ;  Offset to sprite type
    ex de,hl                         ; 0128     eb               ;  Sprite offset to DE
    ld a,b                           ; 0129     78               ;  Animation frame number
    and a                            ; 012a     a7               ;  Is it position 0?
    call nz,alt_alien_sprites        ; 012b     c4 3b 01         ;  No ... add 30 and use position 1 alien sprites
    ld hl,(alien_pos_lsb)            ; 012e     2a 0b 20         ;  Pixel position
    ld b,010h                        ; 0131     06 10            ;  16 rows in alien sprites
    call draw_sprite                 ; 0133     cd d3 15         ;  Draw shifted sprite
l0136h:                                                         
    xor a                            ; 0136     af               ;  Let the ISR routine ...
    ld (wait_on_draw),a              ; 0137     32 00 20         ;  ... advance the cursor to the next alien
    ret                              ; 013a     c9               ;  Out

alt_alien_sprites:                                                      
    ld hl,l0030h                     ; 013b     21 30 00         ;  Offset sprite pointer ...
    add hl,de                        ; 013e     19               ;  ... to animation frame 1 sprites
    ex de,hl                         ; 013f     eb               ;  Back to DE
    ret                              ; 0140     c9               ;  Out

cursor_next_alien:                                              
    ld a,(player_ok)                 ; 0141     3a 68 20         ;  Is the player ...
    and a                            ; 0144     a7               ;  ... blowing up?
    ret z                            ; 0145     c8               ;  Yes ... ignore the aliens
    ld a,(wait_on_draw)              ; 0146     3a 00 20         ;  Still waiting on ...
    and a                            ; 0149     a7               ;  ... this alien to be drawn?
    ret nz                           ; 014a     c0               ;  Yes ... leave cursor in place
    ld a,(player_data_msb)           ; 014b     3a 67 20         ;  Load alien-data ...
    ld h,a                           ; 014e     67               ;  ... MSB (either 21xx or 22xx)
    ld a,(alien_cur_index)           ; 014f     3a 06 20         ;  Load the xx part of the alien flag pointer
    ld d,002h                        ; 0152     16 02            ;  When all are gone this triggers 1A1 to return from this stack frame
l0154h:                                                         
    inc a                            ; 0154     3c               ;  Have we drawn all aliens ...
    cp 037h                          ; 0155     fe 37            ;  ... at last position?
    call z,move_ref_alien            ; 0157     cc a1 01         ;  Yes ... move the bottom/right alien and reset index to 0
    ld l,a                           ; 015a     6f               ;  HL now points to alien flag
    ld b,(hl)                        ; 015b     46               ;  Is alien ...
    dec b                            ; 015c     05               ;  ... alive?
    jp nz,l0154h                     ; 015d     c2 54 01         ;  No ... skip to next alien
    ld (alien_cur_index),a           ; 0160     32 06 20         ;  New alien index
    call get_alien_coords            ; 0163     cd 7a 01         ;  Calculate bit position and type for index
    ld h,c                           ; 0166     61               ;  The calculation returns the MSB in C
    ld (alien_pos_lsb),hl            ; 0167     22 0b 20         ;  Store new bit position
    ld a,l                           ; 016a     7d               ;  Has this alien ...
    cp 028h                          ; 016b     fe 28            ;  ... reached the end of screen?
    jp c,l1971h                      ; 016d     da 71 19         ;  Yes ... kill the player
    ld a,d                           ; 0170     7a               ;  This alien's ...
    ld (alien_row),a                 ; 0171     32 04 20         ;  ... row index
    ld a,001h                        ; 0174     3e 01            ;  Set the wait-flag for the ...
    ld (wait_on_draw),a              ; 0176     32 00 20         ;  ... draw-alien routine to clear
    ret                              ; 0179     c9               ;  Done

get_alien_coords:                                               
    ld d,000h                        ; 017a     16 00            ;  Row 0
    ld a,l                           ; 017c     7d               ;  Hold onto alien index
    ld hl,ref_alien_yr               ; 017d     21 09 20         ;  Get alien x ...
    ld b,(hl)                        ; 0180     46               ;  ... to B
    inc hl                           ; 0181     23               ;  Get alien y ...
    ld c,(hl)                        ; 0182     4e               ;  ... to C
l0183h:                                                         
    cp 00bh                          ; 0183     fe 0b            ;  Can we take a full row off of index?
    jp m,l0194h                      ; 0185     fa 94 01         ;  No ... we have the row
    sbc a,00bh                       ; 0188     de 0b            ;  Subtract off 11 (one whole row)
    ld e,a                           ; 018a     5f               ;  Hold the new index
    ld a,b                           ; 018b     78               ;  Add ...
    add a,010h                       ; 018c     c6 10            ;  ... 16 to bit ...
    ld b,a                           ; 018e     47               ;  ... position Y (1 row in rack)
    ld a,e                           ; 018f     7b               ;  Restore tallied index
    inc d                            ; 0190     14               ;  Next row
    jp l0183h                        ; 0191     c3 83 01         ;  Keep skipping whole rows

l0194h:                                                         
    ld l,b                           ; 0194     68               ;  We have the LSB (the row)
l0195h:                                                         
    and a                            ; 0195     a7               ;  Are we in the right column?
    ret z                            ; 0196     c8               ;  Yes ... X and Y are right
    ld e,a                           ; 0197     5f               ;  Hold index
    ld a,c                           ; 0198     79               ;  Add ...
    add a,010h                       ; 0199     c6 10            ;  ... 16 to bit ...
    ld c,a                           ; 019b     4f               ;  ... position X (1 column in rack)
    ld a,e                           ; 019c     7b               ;  Restore index
    dec a                            ; 019d     3d               ;  We adjusted for 1 column
    jp l0195h                        ; 019e     c3 95 01         ;  Keep moving over column

move_ref_alien:                                                 
    dec d                            ; 01a1     15               ;  This decrements with each call to move
    jp z,return_two                  ; 01a2     ca cd 01         ;  Return out of TWO call frames (only used if no aliens left)
    ld hl,alien_cur_index            ; 01a5     21 06 20         ;  Set current alien ...
    ld (hl),000h                     ; 01a8     36 00            ;  ... index to 0
    inc hl                           ; 01aa     23               ;  Point to delta-x
    ld c,(hl)                        ; 01ab     4e               ;  Load delta-x into C
    ld (hl),000h                     ; 01ac     36 00            ;  Set delta-x to 0, reset delta-x to zero
    call add_delta                   ; 01ae     cd d9 01         ;  Move alien
    ld hl,alien_ani_frame_number     ; 01b1     21 05 20         ;  Alien animation frame number
    ld a,(hl)                        ; 01b4     7e               ;  Toggle ...
    inc a                            ; 01b5     3c               ;  ... animation ...
    and 001h                         ; 01b6     e6 01            ;  ... number between ...
    ld (hl),a                        ; 01b8     77               ;  ... 0 and 1
    xor a                            ; 01b9     af               ;  Alien index in A is now 0
    ld hl,player_data_msb            ; 01ba     21 67 20         ;  Restore H ...
    ld h,(hl)                        ; 01bd     66               ;  ... to player data MSB (21 or 22)
    ret                              ; 01be     c9               ;  Done

    nop                              ; 01bf     00               ;  ** Why?

init_aliens_player_one:                                                    
    ld hl,02100h                     ; 01c0     21 00 21         ;  Start of alien structures (this is the last alien)
l01c3h:                                                         
    ld b,037h                        ; 01c3     06 37            ;  Count to 55 (that's five rows of 11 aliens)
l01c5h:                                                         
    ld (hl),001h                     ; 01c5     36 01            ;  Bring alien to live
    inc hl                           ; 01c7     23               ;  Next alien
    dec b                            ; 01c8     05               ;  All done?
    jp nz,l01c5h                     ; 01c9     c2 c5 01         ;  No ... keep looping
    ret                              ; 01cc     c9               ;  Done

return_two:                                                     
    pop hl                           ; 01cd     e1               ;  Drop return to caller
    ret                              ; 01ce     c9               ;  Return to caller's caller

draw_bottom_line:                                               
    ld a,001h                        ; 01cf     3e 01            ;  Bit 1 set ... going to draw a 1-pixel stripe down left side
    ld b,0e0h                        ; 01d1     06 e0            ;  All the way down the screen
    ld hl,02402h                     ; 01d3     21 02 24         ;  Screen coordinates (3rd byte from upper left)
    jp fill_screen_row               ; 01d6     c3 cc 14         ;  Draw line down left side

add_delta:                                                       ;  C contains delta-x
    inc hl                           ; 01d9     23               ;  We loaded delta-x already ... skip over it
    ld b,(hl)                        ; 01da     46               ;  Get delta-y, B contains delta-y
    inc hl                           ; 01db     23               ;  Skip over it
    ld a,c                           ; 01dc     79               ;  Add delta-x ...
    add a,(hl)                       ; 01dd     86               ;  ... to x, so add delta-x to x
    ld (hl),a                        ; 01de     77               ;  Store new x
    inc hl                           ; 01df     23               ;  Skip to y
    ld a,b                           ; 01e0     78               ;  Add delta-y ...
    add a,(hl)                       ; 01e1     86               ;  ... to y
    ld (hl),a                        ; 01e2     77               ;  Store new y
    ret                              ; 01e3     c9               ;  Done

copy_ram_mirror:                                                 
    ld b,0c0h                        ; 01e4     06 c0            ;  Number of bytes

copy_rom_to_ram:                                                      
    ld de,ram_mirror                 ; 01e6     11 00 1b         ;  RAM mirror in ROM
    ld hl,ram_start                  ; 01e9     21 00 20         ;  Start of RAM
    jp block_copy                    ; 01ec     c3 32 1a         ;  Copy [DE]->[HL] and return

draw_shield_pl1:                                                
    ld hl,player_one_shield_buf      ; 01ef     21 42 21         ;  Player 1 shield buffer (remember between games in multi-player)
    jp l01f8h                        ; 01f2     c3 f8 01         ;  Common draw point

draw_shield_pl2:                                                
    ld hl,player_two_shield_buf      ; 01f5     21 42 22         ;  Player 2 shield buffer (remember between games in multi-player)
l01f8h:                                                         
    ld c,004h                        ; 01f8     0e 04            ;  Going to draw 4 shields
    ld de,image_shield               ; 01fa     11 20 1d         ;  Shield pixel pattern
l01fdh:                                                         
    push de                          ; 01fd     d5               ;  Hold the start for the next shield
    ld b,02ch                        ; 01fe     06 2c            ;  44 bytes to copy
    call block_copy                  ; 0200     cd 32 1a         ;  Block copy DE to HL (B bytes)
    pop de                           ; 0203     d1               ;  Restore start of shield pattern
    dec c                            ; 0204     0d               ;  Drawn all shields?
    jp nz,l01fdh                     ; 0205     c2 fd 01         ;  No ... go draw them all
    ret                              ; 0208     c9               ;  Done

remember_shields1:                                              
    ld a,001h                        ; 0209     3e 01            ;  Not zero means remember
    jp l021bh                        ; 020b     c3 1b 02         ;  Shuffle-shields player 1

remember_shields2:                                              
    ld a,001h                        ; 020e     3e 01            ;  Not zero means remember
    jp l0214h                        ; 0210     c3 14 02         ;  Shuffle-shields player 2

restore_shields2:                                               
    xor a                            ; 0213     af               ;  Zero means restore
l0214h:                                                         
    ld de,player_two_shield_buf      ; 0214     11 42 22         ;  Player 2 shield buffer (remember between games in multi-player)
    jp copy_shields                  ; 0217     c3 1e 02         ;  Shuffle-shields player 2

restore_shields1:                                               
    xor a                            ; 021a     af               ;  Zero means restore
l021bh:                                                         
    ld de,player_one_shield_buf      ; 021b     11 42 21         ;  Player 1 shield buffer (remember between games in multi-player)
l021eh:                                                         
copy_shields:                                                   
    ld (tmp2081),a                   ; 021e     32 81 20         ;  Remember copy/restore flag
    ld bc,01602h                     ; 0221     01 02 16         ;  22 rows, 2 bytes/row (for 1 shield pattern)
    ld hl,02806h                     ; 0224     21 06 28         ;  Screen coordinates
    ld a,004h                        ; 0227     3e 04            ;  Four shields to move
l0229h:                                                         
    push af                          ; 0229     f5               ;  Hold shield count
    push bc                          ; 022a     c5               ;  Hold sprite-size
    ld a,(tmp2081)                   ; 022b     3a 81 20         ;  Get back copy/restore flag
    and a                            ; 022e     a7               ;  Not zero ...
    jp nz,l0242h                     ; 022f     c2 42 02         ;  ... means remember shields
    call restore_shields             ; 0232     cd 69 1a         ;  Restore player's shields
l0235h:                                                         
    pop bc                           ; 0235     c1               ;  Get back sprite-size
    pop af                           ; 0236     f1               ;  Get back shield count
    dec a                            ; 0237     3d               ;  Have we moved all shields?
    ret z                            ; 0238     c8               ;  Yes ... out
    push de                          ; 0239     d5               ;  Hold sprite buffer
    ld de,002e0h                     ; 023a     11 e0 02         ;  Add 2E0 (23 rows) to get to ...
    add hl,de                        ; 023d     19               ;  ... next shield on screen
    pop de                           ; 023e     d1               ;  restore sprite buffer
    jp l0229h                        ; 023f     c3 29 02         ;  Go back and do all

l0242h:                                                         
    call remember_shields            ; 0242     cd 7c 14         ;  Remember player's shields
    jp l0235h                        ; 0245     c3 35 02         ;  Continue with next shield

run_game_objs:                                                  
    ld hl,game_object_0              ; 0248     21 10 20         ;  First game object (active player)
keep_processing_game_objs:                                                      
    ld a,(hl)                        ; 024b     7e               ;  Have we reached the ...
    cp 0ffh                          ; 024c     fe ff            ;  ... end of the object list?
    ret z                            ; 024e     c8               ;  Yes ... done
    cp 0feh                          ; 024f     fe fe            ;  Is object active?
    jp z,l0281h                      ; 0251     ca 81 02         ;  No ... skip it
    inc hl                           ; 0254     23               ;  xx01
    ld b,(hl)                        ; 0255     46               ;  First byte to B
    ld c,a                           ; 0256     4f               ;  Hold 1st byte
    or b                             ; 0257     b0               ;  OR 1st and 2nd byte
    ld a,c                           ; 0258     79               ;  Restore 1st byte
    jp nz,l0277h                     ; 0259     c2 77 02         ;  If word at xx00,xx02 is non zero then decrement it
    inc hl                           ; 025c     23               ;  xx02
    ld a,(hl)                        ; 025d     7e               ;  Get byte counter
    and a                            ; 025e     a7               ;  Is it 0?
    jp nz,l0288h                     ; 025f     c2 88 02         ;  No ... decrement byte counter at xx02
    inc hl                           ; 0262     23               ;  xx03
    ld e,(hl)                        ; 0263     5e               ;  Get handler address LSB
    inc hl                           ; 0264     23               ;  xx04
    ld d,(hl)                        ; 0265     56               ;  Get handler address MSB
    push hl                          ; 0266     e5               ;  Remember pointer to MSB
    ex de,hl                         ; 0267     eb               ;  Handler address to HL
    push hl                          ; 0268     e5               ;  Now to stack (making room for indirect call)
    ld hl,l026fh                     ; 0269     21 6f 02         ;  Return address to 026F
    ex (sp),hl                       ; 026c     e3               ;  Return address (026F) now on stack. Handler in HL.
    push de                          ; 026d     d5               ;  Push pointer to data struct (xx04) for handler to use
    jp (hl)                          ; 026e     e9               ;  Run object's code (will return to next line)

l026fh:                                                         
    pop hl                           ; 026f     e1               ;  Restore pointer to xx04
    ld de,l000ch                     ; 0270     11 0c 00         ;  Offset to next ...
    add hl,de                        ; 0273     19               ;  ... game task (C+4=10)
    jp keep_processing_game_objs     ; 0274     c3 4b 02         ;  Do next game task

l0277h:                                                         
    dec b                            ; 0277     05               ;  Decrement ...
    inc b                            ; 0278     04               ;  ... two ...
    jp nz,l027dh                     ; 0279     c2 7d 02         ;  ... byte ...
    dec a                            ; 027c     3d               ;  ... value ...
l027dh:                                                         
    dec b                            ; 027d     05               ;  ... at ...
    ld (hl),b                        ; 027e     70               ;  ... xx00 ...
    dec hl                           ; 027f     2b               ;  ... and ...
    ld (hl),a                        ; 0280     77               ;  ... xx01
l0281h:                                                         
    ld de,l0010h                     ; 0281     11 10 00         ;  Next ...
    add hl,de                        ; 0284     19               ;  ... object descriptor
    jp keep_processing_game_objs     ; 0285     c3 4b 02         ;  Keep processing game objects

l0288h:                                                         
    dec (hl)                         ; 0288     35               ;  Decrement the xx02 counter
    dec hl                           ; 0289     2b               ;  Back up to ...
    dec hl                           ; 028a     2b               ;  ... start of game task
    jp l0281h                        ; 028b     c3 81 02         ;  Next game task



                                                                 ;  Game object 0: Move/draw the player
                                                                 ;
                                                                 ;  This task is only called at the mid-screen ISR. It ALWAYS does its work here, even though
                                                                 ;  the player can be on the top or bottom of the screen (not rotated).
                                                                 ;
game_object_0_handler:
    pop hl                           ; 028e     e1               ;  Get player object structure 02014h
    inc hl                           ; 028f     23               ;  Point to blow-up status
    ld a,(hl)                        ; 0290     7e               ;  Get player blow-up status
    cp 0ffh                          ; 0291     fe ff            ;  Player is blowing up?
    jp z,l033bh                      ; 0293     ca 3b 03         ;  No ... go do normal movement
    inc hl                           ; 0296     23               ;  Point to blow-up delay count
    dec (hl)                         ; 0297     35               ;  Decrement the blow-up delay
    ret nz                           ; 0298     c0               ;  Not time for a new blow-up sprite ... out
    ld b,a                           ; 0299     47               ;  Hold sprite image number
    xor a                            ; 029a     af               ;  0
    ld (player_ok),a                 ; 029b     32 68 20         ;  Player is NOT OK ... player is blowing up
    ld (enable_alien_fire),a         ; 029e     32 69 20         ;  Alien fire is disabled
    ld a,030h                        ; 02a1     3e 30            ;  Reset count ...
    ld (alien_fire_delay),a          ; 02a3     32 6a 20         ;  ... till alien shots are enabled
    ld a,b                           ; 02a6     78               ;  Restore sprite image number (used if we go to 39B)
    ld (hl),005h                     ; 02a7     36 05            ;  Reload time between blow-up changes
    inc hl                           ; 02a9     23               ;  Point to number of blow-up changes
    dec (hl)                         ; 02aa     35               ;  Count down blow-up changes
    jp nz,draw_player_die            ; 02ab     c2 9b 03         ;  Still blowing up ... go draw next sprite
    ld hl,(player_yr)                ; 02ae     2a 1a 20         ;  Player's coordinates
    ld b,010h                        ; 02b1     06 10            ;  16 Bytes
    call erase_simple_sprite         ; 02b3     cd 24 14         ;  Erase simple sprite (the player)
    ld hl,02010h                     ; 02b6     21 10 20         ;  Restore player ...
    ld de,game_object_0_init         ; 02b9     11 10 1b         ;  ... structure ...
    ld b,010h                        ; 02bc     06 10            ;  ... from ...
    call block_copy                  ; 02be     cd 32 1a         ;  ... ROM mirror
    ld b,000h                        ; 02c1     06 00            ;  Turn off ...
    call sound_bits3off              ; 02c3     cd dc 19         ;  ... all sounds
    ld a,(invaded)                   ; 02c6     3a 6d 20         ;  Has rack reached ...
    and a                            ; 02c9     a7               ;  ... the bottom of the screen?
    ret nz                           ; 02ca     c0               ;  Yes ... done here
    ld a,(game_mode)                 ; 02cb     3a ef 20         ;  Are we in ...
    and a                            ; 02ce     a7               ;  ... game mode?
    ret z                            ; 02cf     c8               ;  No ... return to splash screens
    ld sp,02400h                     ; 02d0     31 00 24         ;  We aren't going to return
    ei                               ; 02d3     fb               ;  Enable interrupts (we just dropped the ISR context)
    call dsable_game_tasks           ; 02d4     cd d7 19         ;  Disable game tasks
    call get_num_ships_active_player ; 02d7     cd 2e 09         ;  Get number of ships for active player
    and a                            ; 02da     a7               ;  Any left?
    jp z,l166dh                      ; 02db     ca 6d 16         ;  No ... handle game over for player
    call get_player_alive_ptr        ; 02de     cd e7 18         ;  Get player-alive status pointer
    ld a,(hl)                        ; 02e1     7e               ;  Is player ...
    and a                            ; 02e2     a7               ;  ... alive?
    jp z,l032ch                      ; 02e3     ca 2c 03         ;  Yes ... remove a ship from player's stash and reenter game loop
    ld a,(two_players)               ; 02e6     3a ce 20         ;  Multi-player game
    and a                            ; 02e9     a7               ;  Only one player?
    jp z,l032ch                      ; 02ea     ca 2c 03         ;  Yes ... remove a ship from player's stash and reenter game loop
l02edh:                                                         
    ld a,(player_data_msb)           ; 02ed     3a 67 20         ;  Player data MSB
    push af                          ; 02f0     f5               ;  Hold the MSB
    rrca                             ; 02f1     0f               ;  Player 1 is active player?
    jp c,l0332h                      ; 02f2     da 32 03         ;  Yes ... go store player 1 shields and come back to 02F8
    call remember_shields2           ; 02f5     cd 0e 02         ;  No ... go store player 2 shields
l02f8h:                                                         
    call get_alien_ptr_etc           ; 02f8     cd 78 08         ;  Get ref-alien info and pointer to storage
    ld (hl),e                        ; 02fb     73               ;  Hold the ...
    inc hl                           ; 02fc     23               ;  ... ref-alien ...
    ld (hl),d                        ; 02fd     72               ;  ... screen coordinates
    dec hl                           ; 02fe     2b               ;  Back up ...
    dec hl                           ; 02ff     2b               ;  .. to delta storage
    ld (hl),b                        ; 0300     70               ;  Store ref-alien's delta (direction)
    nop                              ; 0301     00               ;  ** Why?
    call copy_ram_mirror             ; 0302     cd e4 01         ;  Copy RAM mirror (getting ready to switch players)
    pop af                           ; 0305     f1               ;  Restore active player MSB
    rrca                             ; 0306     0f               ;  Player 1?
    ld a,021h                        ; 0307     3e 21            ;  Player 1 data pointer
    ld b,000h                        ; 0309     06 00            ;  Cocktail bit=0 (player 1)
    jp nc,l0312h                     ; 030b     d2 12 03         ;  It was player one ... keep data for player 2
    ld b,020h                        ; 030e     06 20            ;  Cocktail bit=1 (player 2)
    ld a,022h                        ; 0310     3e 22            ;  Player 2 data pointer
l0312h:                                                         
    ld (player_data_msb),a           ; 0312     32 67 20         ;  Change players
    call two_sec_delay               ; 0315     cd b6 0a         ;  Two second delay
    xor a                            ; 0318     af               ;  Clear the player-object ...
    ld (obj0timer_lsb),a             ; 0319     32 11 20         ;  ... timer (player can move instantly after switching players)
    ld a,b                           ; 031c     78               ;  Cocktail bit to A
    out (005h),a                     ; 031d     d3 05            ;  Set the cocktail mode
    inc a                            ; 031f     3c               ;  Fleet sound 1 (first tone)
    ld (sound_port5),a               ; 0320     32 98 20         ;  Set the port 5 hold
    call clear_play_field            ; 0323     cd d6 09         ;  Clear center window
    call remove_ship                 ; 0326     cd 7f 1a         ;  Remove a ship and update indicators
    jp l07f9h                        ; 0329     c3 f9 07         ;  Tell the players that the switch has been made

l032ch:                                                         
    call remove_ship                 ; 032c     cd 7f 1a         ;  Remove a ship and update indicators
    jp l0817h                        ; 032f     c3 17 08         ;  Continue into game loop

l0332h:                                                         
    call remember_shields1           ; 0332     cd 09 02         ;  Remember the shields for player 1
    jp l02f8h                        ; 0335     c3 f8 02         ;  Back to switching-players above

    nop                              ; 0338     00               ;  ** Why
    nop                              ; 0339     00              
    nop                              ; 033a     00              
l033bh:                                                         
    ld hl,player_ok                  ; 033b     21 68 20         ;  Player OK flag
    ld (hl),001h                     ; 033e     36 01            ;  Flag 1 ... player is OK
    inc hl                           ; 0340     23               ;  2069
    ld a,(hl)                        ; 0341     7e               ;  Alien shots enabled?
    and a                            ; 0342     a7               ;  Set flags
    jp l03b0h                        ; 0343     c3 b0 03         ;  Continue

l0346h:                                                         
    nop                              ; 0346     00               ;  ** Why?
    dec hl                           ; 0347     2b               ;  2069
    ld (hl),001h                     ; 0348     36 01            ;  Enable alien fire
l034ah:                                                         
    ld a,(player_xr)                 ; 034a     3a 1b 20         ;  Current player coordinates
    ld b,a                           ; 034d     47               ;  Hold it
    ld a,(game_mode)                 ; 034e     3a ef 20         ;  Are we in ...
    and a                            ; 0351     a7               ;  ... game mode?
    jp nz,l0363h                     ; 0352     c2 63 03         ;  Yes ... use switches as player controls
    ld a,(next_demo_cmd)             ; 0355     3a 1d 20         ;  Get demo command
    rrca                             ; 0358     0f               ;  Is it right?
    jp c,move_player_right           ; 0359     da 81 03         ;  Yes ... do right
    rrca                             ; 035c     0f               ;  Is it left?
    jp c,move_player_left            ; 035d     da 8e 03         ;  Yes ... do left
    jp draw_player_and_out           ; 0360     c3 6f 03         ;  Skip over movement (draw player and out)

l0363h:                                                         
    call read_inputs                 ; 0363     cd c0 17         ;  Read active player controls
    rlca                             ; 0366     07               ;  Test for ...
    rlca                             ; 0367     07               ;  ... right button
    jp c,move_player_right           ; 0368     da 81 03         ;  Yes ... handle move right
    rlca                             ; 036b     07               ;  Test for left button
    jp c,move_player_left            ; 036c     da 8e 03         ;  Yes ... handle move left
draw_player_and_out:                                                         
    ld hl,plyr_spr_pic_l             ; 036f     21 18 20         ;  Active player descriptor
    call read_desc                   ; 0372     cd 3b 1a         ;  Load 5 byte sprite descriptor in order: EDLHB
    call conv_to_scr                 ; 0375     cd 47 1a         ;  Convert HL to screen coordinates
    call draw_simp_sprite            ; 0378     cd 39 14         ;  Draw player
    ld a,000h                        ; 037b     3e 00            ;  Clear the task timer. Nobody changes this but it could have ...
    ld (obj0timer_extra),a           ; 037d     32 12 20         ;  ... been speed set for the player with a value other than 0 (not XORA)
    ret                              ; 0380     c9               ;  Out

move_player_right:                                              
    ld a,b                           ; 0381     78               ;  Player coordinate
    cp 0d9h                          ; 0382     fe d9            ;  At right edge?
    jp z,draw_player_and_out         ; 0384     ca 6f 03         ;  Yes ... ignore this
    inc a                            ; 0387     3c               ;  Bump X coordinate
    ld (player_xr),a                 ; 0388     32 1b 20         ;  New X coordinate
    jp draw_player_and_out           ; 038b     c3 6f 03         ;  Draw player and out

move_player_left:                                               
    ld a,b                           ; 038e     78               ;  Player coordinate
    cp 030h                          ; 038f     fe 30            ;  At left edge
    jp z,draw_player_and_out         ; 0391     ca 6f 03         ;  Yes ... ignore this
    dec a                            ; 0394     3d               ;  Bump X coordinate
    ld (player_xr),a                 ; 0395     32 1b 20         ;  New X coordinate
    jp draw_player_and_out           ; 0398     c3 6f 03         ;  Draw player and out

draw_player_die:                                                
    inc a                            ; 039b     3c               ;  Toggle blowing-up ...
    and 001h                         ; 039c     e6 01            ;  ... player sprite (0,1,0,1)
    ld (player_alive),a              ; 039e     32 15 20         ;  Hold current state
    rlca                             ; 03a1     07               ;  *2
    rlca                             ; 03a2     07               ;  *4
    rlca                             ; 03a3     07               ;  *8
    rlca                             ; 03a4     07               ;  *16
    ld hl,sprite_base_blowup         ; 03a5     21 70 1c         ;  Base blow-up sprite location
    add a,l                          ; 03a8     85               ;  Offset sprite ...
    ld l,a                           ; 03a9     6f               ;  ... pointer
    ld (plyr_spr_pic_l),hl           ; 03aa     22 18 20         ;  New blow-up sprite picture
    jp draw_player_and_out           ; 03ad     c3 6f 03         ;  Draw new blow-up sprite and out

l03b0h:                                                         
    jp nz,l034ah                     ; 03b0     c2 4a 03         ;  Alien shots enabled ... move player's ship, draw it, and out
    inc hl                           ; 03b3     23               ;  To 206A
    dec (hl)                         ; 03b4     35               ;  Time until aliens can fire
    jp nz,l034ah                     ; 03b5     c2 4a 03         ;  Not time to enable ... move player's ship, draw it, and out
    jp l0346h                        ; 03b8     c3 46 03         ;  Enable alien fire ... move player's ship, draw it, and out



                                                                 ;  Game object 1: Move/draw the player shot
                                                                 ;  
                                                                 ;  This task executes at either mid-screen ISR (if it is on the top half of the non-rotated screen) or
                                                                 ;  at the end-screen ISR (if it is on the bottom half of the screen).
game_object_1_handler:                                           ;
    ld de,obj1coor_xr                ; 03bb     11 2a 20         ;  Object's Yn coordiante vec rom at 1b23 ram at 02023h
    call comp_yto_beam               ; 03be     cd 06 1a         ;  Compare to screen-update location
    pop hl                           ; 03c1     e1               ;  Pointer to task data
    ret nc                           ; 03c2     d0               ;  Make sure we are in the right ISR
    inc hl                           ; 03c3     23               ;  Point to 2025 ... the shot status
    ld a,(hl)                        ; 03c4     7e               ;  Get shot status
    and a                            ; 03c5     a7               ;  Return if ...
    ret z                            ; 03c6     c8               ;  ... no shot is active
    cp 001h                          ; 03c7     fe 01            ;  Shot just starting (requested elsewhere)?
    jp z,init_ply_shot               ; 03c9     ca fa 03         ;  Yes ... go initiate shot
    cp 002h                          ; 03cc     fe 02            ;  Progressing normally?
    jp z,move_ply_shot               ; 03ce     ca 0a 04         ;  Yes ... go move it
    inc hl                           ; 03d1     23               ;  2026
    cp 003h                          ; 03d2     fe 03            ;  Shot blowing up (not because of alien)?
    jp nz,l042ah                     ; 03d4     c2 2a 04         ;  No ... try other options
    dec (hl)                         ; 03d7     35               ;  Decrement the timer
    jp z,end_of_blowup               ; 03d8     ca 36 04         ;  If done then
    ld a,(hl)                        ; 03db     7e               ;  Get timer value
    cp 00fh                          ; 03dc     fe 0f            ;  Starts at 10 ... first decrement brings us here
    ret nz                           ; 03de     c0               ;  Not the first time ... explosion has been drawn
    push hl                          ; 03df     e5               ;  Hold pointer to data
    call read_ply_shot               ; 03e0     cd 30 04         ;  Read shot descriptor
    call erase_shifted               ; 03e3     cd 52 14         ;  Erase the sprite
    pop hl                           ; 03e6     e1               ;  2026 (timer flag)
    inc hl                           ; 03e7     23               ;  2027 point to sprite LSB
    inc (hl)                         ; 03e8     34               ;  Change 1C90 to 1C91
    inc hl                           ; 03e9     23               ;  2028
    inc hl                           ; 03ea     23               ;  2029
    dec (hl)                         ; 03eb     35               ;  Drop X coordinate ...
    dec (hl)                         ; 03ec     35               ;  ... by 2
    inc hl                           ; 03ed     23               ;  202A
    dec (hl)                         ; 03ee     35               ;  Drop Y ...
    dec (hl)                         ; 03ef     35               ;  ... coordinate ...
    dec (hl)                         ; 03f0     35               ;  ... by ...
    inc hl                           ; 03f1     23               ;  ... 3
    ld (hl),008h                     ; 03f2     36 08            ;  202B 8 bytes in size of sprite
    call read_ply_shot               ; 03f4     cd 30 04         ;  Read player shot structure
    jp draw_shifted_sprite           ; 03f7     c3 00 14         ;  Draw sprite and out

init_ply_shot:                                                  
    inc a                            ; 03fa     3c               ;  Type is now ...
    ld (hl),a                        ; 03fb     77               ;  ... 2 (in progress)
    ld a,(player_xr)                 ; 03fc     3a 1b 20         ;  Players Y coordinate
    add a,008h                       ; 03ff     c6 08            ;  To center of player
    ld (obj1coor_xr),a               ; 0401     32 2a 20         ;  Shot's Y coordinate
    call read_ply_shot               ; 0404     cd 30 04         ;  Read 5 byte structure
    jp draw_shifted_sprite           ; 0407     c3 00 14         ;  Draw sprite and out

move_ply_shot:                                                  
    call read_ply_shot               ; 040a     cd 30 04         ;  Read the shot structure
    push de                          ; 040d     d5               ;  Hold pointer to sprite image
    push hl                          ; 040e     e5               ;  Hold sprite coordinates
    push bc                          ; 040f     c5               ;  Hold sprite size (in B)
    call erase_shifted               ; 0410     cd 52 14         ;  Erase the sprite from the screen
    pop bc                           ; 0413     c1               ;  Restore size
    pop hl                           ; 0414     e1               ;  Restore coords
    pop de                           ; 0415     d1               ;  Restore pointer to sprite image
    ld a,(shot_delta_x)              ; 0416     3a 2c 20         ;  delta-x for shot
    add a,l                          ; 0419     85               ;  Move the shot ...
    ld l,a                           ; 041a     6f               ;  ... up the screen
    ld (obj1coor_yr),a               ; 041b     32 29 20         ;  Store shot's new X coordinate
    call draw_spr_collision          ; 041e     cd 91 14         ;  Draw sprite with collision detection
    ld a,(collision)                 ; 0421     3a 61 20         ;  Test for ...
    and a                            ; 0424     a7               ;  ... collision
    ret z                            ; 0425     c8               ;  No collision ... out
    ld (alien_is_exploding),a        ; 0426     32 02 20         ;  Set to not-0 indicating ...
    ret                              ; 0429     c9               ;  ... an alien is blowing up

l042ah:                                                         
    cp 005h                          ; 042a     fe 05            ;  Alien explosion in progress?
    ret z                            ; 042c     c8               ;  Yes ... nothing to do
    jp end_of_blowup                 ; 042d     c3 36 04         ;  Anything else erases the shot and removes it from duty

read_ply_shot:                                                  
    ld hl,player_shot_desc           ; 0430     21 27 20         ;  Read 5 byte sprite structure for ...
    jp read_desc                     ; 0433     c3 3b 1a         ;  ... player shot

end_of_blowup:                                                  
    call read_ply_shot               ; 0436     cd 30 04         ;  Read the shot structure
    call erase_shifted               ; 0439     cd 52 14         ;  Erase the player's shot
    ld hl,plyr_shot_status           ; 043c     21 25 20         ;  Reinit ...
    ld de,shot_struct                ; 043f     11 25 1b         ;  ... shot structure ...
    ld b,007h                        ; 0442     06 07            ;  ... from ...
    call block_copy                  ; 0444     cd 32 1a         ;  ... ROM mirror
    ld hl,(sau_score_lsb)            ; 0447     2a 8d 20         ;  Get pointer to saucer-score table
    inc l                            ; 044a     2c               ;  Every shot explosion advances it one
    ld a,l                           ; 044b     7d               ;  Have we passed ...
    cp 063h                          ; 044c     fe 63            ;  ... the end at 1D63 (bug! this should be $64 to cover all 16 values)
    jp c,l0453h                      ; 044e     da 53 04         ;  No .... keep it
    ld l,054h                        ; 0451     2e 54            ;  Wrap back around to 1D54
l0453h:                                                         
    ld (sau_score_lsb),hl            ; 0453     22 8d 20         ;  New score pointer
    ld hl,(shot_count_lsb)           ; 0456     2a 8f 20         ;  Increments with every shot ...
    inc l                            ; 0459     2c               ;  ... but only LSB ** ...
    ld (shot_count_lsb),hl           ; 045a     22 8f 20         ;  ... used for saucer direction
    ld a,(saucer_active)             ; 045d     3a 84 20         ;  Is saucer ...
    and a                            ; 0460     a7               ;  ... on screen?
    ret nz                           ; 0461     c0               ;  Yes ... don't reset it
    ld a,(hl)                        ; 0462     7e               ;  Shot counter
    and 001h                         ; 0463     e6 01            ;  Lowest bit set?
    ld bc,00229h                     ; 0465     01 29 02         ;  Xr delta of 2 starting at Xr=29
    jp nz,l046eh                     ; 0468     c2 6e 04         ;  Yes ... use 2/29
    ld bc,0fee0h                     ; 046b     01 e0 fe         ;  No ... Xr delta of -2 starting at Xr=E0
l046eh:                                                         
    ld hl,saucer_pri_pic_msb         ; 046e     21 8a 20         ;  Saucer descriptor
    ld (hl),c                        ; 0471     71               ;  Store Xr coordinate
    inc hl                           ; 0472     23               ;  Point to ...
    inc hl                           ; 0473     23               ;  ... delta Xr
    ld (hl),b                        ; 0474     70               ;  Store delta Xr
    ret                              ; 0475     c9               ;  Done


                                                                 ; Game object 2: Alien rolling-shot (targets player specifically)
                                                                 ;
                                                                 ; The 2-byte value at 2038 is where the firing-column-table-pointer would be (see other
                                                                 ; shots ... next game objects). This shot doesn't use that table. It targets the player
                                                                 ; specifically. Instead the value is used as a flag to have the shot skip its first
                                                                 ; attempt at firing every time it is reinitialized (when it blows up).
                                                                 ;
                                                                 ; The task-timer at 2032 is copied to 2080 in the game loop. The flag is used as a
                                                                 ; synchronization flag to keep all the shots processed on separate interrupt ticks. This
                                                                 ; has the main effect of slowing the shots down.
                                                                 ;
                                                                 ; When the timer is 2 the squiggly-shot/saucer (object 4 ) runs.
                                                                 ; When the timer is 1 the plunger-shot (object 3) runs.
                                                                 ; When the timer is 0 this object, the rolling-shot, runs.
game_object_2_handler:
    pop hl                           ; 0476     e1               ;  Game object data vec rom at 1b33 ram at 02033h
    ld a,(game_object_2_init_timer)  ; 0477     3a 32 1b         ;  Restore delay from ...
    ld (obj2timer_extra),a           ; 047a     32 32 20         ;  ... ROM mirror (value 2)
    ld hl,(rol_shot_cfir_lsb)        ; 047d     2a 38 20         ;  Get pointer to ...
    ld a,l                           ; 0480     7d               ;  ... column-firing table.
    or h                             ; 0481     b4               ;  All zeros?
    jp nz,l048ah                     ; 0482     c2 8a 04         ;  No ... must be a valid column. Go fire.
    dec hl                           ; 0485     2b               ;  Decrement the counter
    ld (rol_shot_cfir_lsb),hl        ; 0486     22 38 20         ;  Store new counter value (run the shot next time)
    ret                              ; 0489     c9               ;  And out

l048ah:                                                         
    ld de,rol_shot_struct            ; 048a     11 35 20         ;  Rolling-shot data structure
    ld a,0f9h                        ; 048d     3e f9            ;  Last picture of "rolling" alien shot
    call to_shot_struct              ; 048f     cd 50 05         ;  Set code to handle rolling-shot
    ld a,(plu_shot_step_cnt)         ; 0492     3a 46 20         ;  Get the plunger-shot step count
    ld (other_shot1),a               ; 0495     32 70 20         ;  Hold it
    ld a,(squ_shot_step_cnt)         ; 0498     3a 56 20         ;  Get the squiggly-shot step count
    ld (other_shot2),a               ; 049b     32 71 20         ;  Hold it
    call handle_alien_shot           ; 049e     cd 63 05         ;  Handle active shot structure
    ld a,(a_shot_blow_cnt)           ; 04a1     3a 78 20         ;  Blow up counter
    and a                            ; 04a4     a7               ;  Test if shot has cycled through blowing up
    ld hl,rol_shot_struct            ; 04a5     21 35 20         ;  Rolling-shot data structure
    jp nz,from_shot_struct           ; 04a8     c2 5b 05         ;  If shot is still running, copy the updated data and out
    ld de,game_object_2_init         ; 04ab     11 30 1b         ;  Reload ...
    ld hl,game_object_2              ; 04ae     21 30 20         ;  ... object ...
    ld b,010h                        ; 04b1     06 10            ;  ... structure ...
    jp block_copy                    ; 04b3     c3 32 1a         ;  ... from ROM mirror and out


                                                                 ;  Game object 3: Alien plunger-shot
                                                                 ;  This is skipped if there is only one alien left on the screen.
                                                                 ;
game_object_3_handler:
    pop hl                           ; 04b6     e1               ;  Game object data vec rom at 1b43 ram at 02043h 
    ld a,(skip_plunger)              ; 04b7     3a 6e 20         ;  One alien left? Skip plunger shot?
    and a                            ; 04ba     a7               ;  Check
    ret nz                           ; 04bb     c0               ;  Yes. Only one alien. Skip this shot.
    ld a,(shot_sync)                 ; 04bc     3a 80 20         ;  Sync flag (copied from GO-2's timer value)
    cp 001h                          ; 04bf     fe 01            ;  GO-2 and GO-4 are idle?
    ret nz                           ; 04c1     c0               ;  No ... only one shot at a time
    ld de,plu_shot_struct            ; 04c2     11 45 20         ;  Plunger alien shot data structure
    ld a,0edh                        ; 04c5     3e ed            ;  Last picture of "plunger" alien shot
    call to_shot_struct              ; 04c7     cd 50 05         ;  Copy the plunger alien to the active structure
    ld a,(rol_shot_step_cnt)         ; 04ca     3a 36 20         ;  Step count from rolling-shot
    ld (other_shot1),a               ; 04cd     32 70 20         ;  Hold it
    ld a,(squ_shot_step_cnt)         ; 04d0     3a 56 20         ;  Step count from squiggly shot
    ld (other_shot2),a               ; 04d3     32 71 20         ;  Hold it
    call handle_alien_shot           ; 04d6     cd 63 05         ;  Handle active shot structure
    ld a,(a_shot_cfir_lsb)           ; 04d9     3a 76 20         ;  LSB of column-firing table
    cp 010h                          ; 04dc     fe 10            ;  Been through all entries in the table?
    jp c,l04e7h                      ; 04de     da e7 04         ;  Not yet ... table is OK
    ld a,(l1b48h)                    ; 04e1     3a 48 1b         ;  Been through all ..
    ld (a_shot_cfir_lsb),a           ; 04e4     32 76 20         ;  ... so reset pointer into firing-column table
l04e7h:                                                         
    ld a,(a_shot_blow_cnt)           ; 04e7     3a 78 20         ;  Get the blow up timer
    and a                            ; 04ea     a7               ;  Zero means shot is done
    ld hl,plu_shot_struct            ; 04eb     21 45 20         ;  Plunger shot data
    jp nz,from_shot_struct           ; 04ee     c2 5b 05         ;  If shot is still running, go copy the updated data and out
    ld de,game_object_3_init         ; 04f1     11 40 1b         ;  Reload ...
    ld hl,game_object_3              ; 04f4     21 40 20         ;  ... object ...
    ld b,010h                        ; 04f7     06 10            ;  ... structure ...
    call block_copy                  ; 04f9     cd 32 1a         ;  ... from mirror
    ld a,(num_aliens)                ; 04fc     3a 82 20         ;  Number of aliens on screen
    dec a                            ; 04ff     3d               ;  Is there only one left?
    jp nz,l0508h                     ; 0500     c2 08 05         ;  No ... move on
    ld a,001h                        ; 0503     3e 01            ;  Disable plunger shot ...
    ld (skip_plunger),a              ; 0505     32 6e 20         ;  ... when only one alien remains
l0508h:                                                         
    ld hl,(a_shot_cfir_lsb)          ; 0508     2a 76 20         ;  Set the plunger shot's ...
    jp l067eh                        ; 050b     c3 7e 06         ;  ... column-firing pointer data

                                                                 ;  Game object 4 when splash screen alien is shooting extra "C" with a squiggly shot
                                                                 ;  Ignore the task data pointer passed on stack                                                                                                      
game_object_4_handler:                                                   
    pop hl                           ; 050e     e1               
l050fh:                                                         
    ld de,squ_shot_status            ; 050f     11 55 20         ;  Squiggly shot data structure
    ld a,0dbh                        ; 0512     3e db            ;  LSB of last byte of picture
    call to_shot_struct              ; 0514     cd 50 05         ;  Copy squiggly shot to
    ld a,(plu_shot_step_cnt)         ; 0517     3a 46 20         ;  Get plunger ...
    ld (other_shot1),a               ; 051a     32 70 20         ;  ... step count
    ld a,(rol_shot_step_cnt)         ; 051d     3a 36 20         ;  Get rolling ...
    ld (other_shot2),a               ; 0520     32 71 20         ;  ... step count
    call handle_alien_shot           ; 0523     cd 63 05         ;  Handle active shot structure
    ld a,(a_shot_cfir_lsb)           ; 0526     3a 76 20         ;  LSB of column-firing table pointer
    cp 015h                          ; 0529     fe 15            ;  Have we processed all entries?
    jp c,l0534h                      ; 052b     da 34 05         ;  No ... don't reset it
    ld a,(l1b58h)                    ; 052e     3a 58 1b         ;  Reset the pointer ...
    ld (a_shot_cfir_lsb),a           ; 0531     32 76 20         ;  ... back to the start of the table
l0534h:                                                         
    ld a,(a_shot_blow_cnt)           ; 0534     3a 78 20         ;  Check to see if squiggly shot is done
    and a                            ; 0537     a7               ;  0 means blow-up timer expired
    ld hl,squ_shot_status            ; 0538     21 55 20         ;  Squiggly shot data structure
    jp nz,from_shot_struct           ; 053b     c2 5b 05         ;  If shot is still running, go copy the updated data and out
    ld de,game_object_4_init         ; 053e     11 50 1b         ;  Reload
    ld hl,game_object_4              ; 0541     21 50 20         ;  ... object ...
    ld b,010h                        ; 0544     06 10            ;  ... structure ...
    call block_copy                  ; 0546     cd 32 1a         ;  ... from mirror
    ld hl,(a_shot_cfir_lsb)          ; 0549     2a 76 20         ;  Copy pointer to column-firing table ...
    ld (squ_shot_cfir_lsb),hl        ; 054c     22 58 20         ;  ... back to data structure (for next shot)
    ret                              ; 054f     c9               ;  Done

to_shot_struct:                                                      
    ld (shot_pic_end),a              ; 0550     32 7f 20         ;  LSB of last byte of last picture in sprite
    ld hl,a_shot_status              ; 0553     21 73 20         ;  Destination is the shot-structure
    ld b,00bh                        ; 0556     06 0b            ;  11 bytes
    jp block_copy                    ; 0558     c3 32 1a         ;  Block copy and out

from_shot_struct:                                               
    ld de,a_shot_status              ; 055b     11 73 20         ;  Source is the shot-structure
    ld b,00bh                        ; 055e     06 0b            ;  11 bytes
    jp block_copy                    ; 0560     c3 32 1a         ;  Block copy and out

handle_alien_shot:                                              
    ld hl,a_shot_status              ; 0563     21 73 20         ;  Start of active shot structure
    ld a,(hl)                        ; 0566     7e               ;  Get the shot status
    and 080h                         ; 0567     e6 80            ;  Is the shot active?
    jp nz,move_alien_shot            ; 0569     c2 c1 05         ;  Yes ... go move it
    ld a,(isr_splash_task)           ; 056c     3a c1 20         ;  ISR splash task
    cp 004h                          ; 056f     fe 04            ;  Shooting the "C" ?
    ld a,(enable_alien_fire)         ; 0571     3a 69 20         ;  Alien fire enabled flag
    jp z,l05b7h                      ; 0574     ca b7 05         ;  We are shooting the extra "C" ... just flag it active and out
    and a                            ; 0577     a7               ;  Is alien fire enabled?
    ret z                            ; 0578     c8               ;  No ... don't start a new shot
    inc hl                           ; 0579     23               ;  2074 step count of current shot
    ld (hl),000h                     ; 057a     36 00            ;  clear the step count
    ld a,(other_shot1)               ; 057c     3a 70 20         ;  Get the step count of the 1st "other shot"
    and a                            ; 057f     a7               ;  Any steps made?
    jp z,l0589h                      ; 0580     ca 89 05         ;  No ... ignore this count
    ld b,a                           ; 0583     47               ;  Shuffle off step count
    ld a,(a_shot_reload_rate)        ; 0584     3a cf 20         ;  Get the reload rate (based on MSB of score)
    cp b                             ; 0587     b8               ;  Too soon to fire again?
    ret nc                           ; 0588     d0               ;  Yes ... don't fire
l0589h:                                                         
    ld a,(other_shot2)               ; 0589     3a 71 20         ;  Get the step count of the 2nd "other shot"
    and a                            ; 058c     a7               ;  Any steps made?
    jp z,l0596h                      ; 058d     ca 96 05         ;  No steps on any shot ... we are clear to fire
    ld b,a                           ; 0590     47               ;  Shuffle off step count
    ld a,(a_shot_reload_rate)        ; 0591     3a cf 20         ;  Get the reload rate (based on MSB of score)
    cp b                             ; 0594     b8               ;  Too soon to fire again?
    ret nc                           ; 0595     d0               ;  Yes ... don't fire
l0596h:                                                         
    inc hl                           ; 0596     23               ;  2075
    ld a,(hl)                        ; 0597     7e               ;  Get tracking flag
    and a                            ; 0598     a7               ;  Does this shot track the player?
    jp z,l061bh                      ; 0599     ca 1b 06        
    ld hl,(a_shot_cfir_lsb)          ; 059c     2a 76 20         ;  Column-firing table
    ld c,(hl)                        ; 059f     4e               ;  Get next column to fire from
    inc hl                           ; 05a0     23               ;  Bump the ...
    nop                              ; 05a1     00               ;  % WHY?
    ld (a_shot_cfir_lsb),hl          ; 05a2     22 76 20         ;  ... pointer into column table
l05a5h:                                                         
    call find_in_column              ; 05a5     cd 2f 06         ;  Find alien in target column
    ret nc                           ; 05a8     d0               ;  No alien is alive in target column ... out
    call get_alien_coords            ; 05a9     cd 7a 01         ;  Get coordinates of alien (lowest alien in firing column)
    ld a,c                           ; 05ac     79               ;  Offset ...
    add a,007h                       ; 05ad     c6 07            ;  ... Y by 7
    ld h,a                           ; 05af     67               ;  To H
    ld a,l                           ; 05b0     7d               ;  Offset ...
    sub 00ah                         ; 05b1     d6 0a            ;  ... X down 10
    ld l,a                           ; 05b3     6f               ;  To L
    ld (alien_shot_yr),hl            ; 05b4     22 7b 20         ;  Set shot coordinates below alien
l05b7h:                                                         
    ld hl,a_shot_status              ; 05b7     21 73 20         ;  Alien shot status
    ld a,(hl)                        ; 05ba     7e               ;  Get the status
    or 080h                          ; 05bb     f6 80            ;  Mark this shot ...
    ld (hl),a                        ; 05bd     77               ;  ... as actively running
    inc hl                           ; 05be     23               ;  2074 step count
    inc (hl)                         ; 05bf     34               ;  Give this shot 1 step (it just started)
    ret                              ; 05c0     c9               ;  Out

move_alien_shot:                                                         
    ld de,0207ch                     ; 05c1     11 7c 20         ;  Alien-shot Y coordinate
    call comp_yto_beam               ; 05c4     cd 06 1a         ;  Compare to beam position
    ret nc                           ; 05c7     d0               ;  Not the right ISR for this shot
    inc hl                           ; 05c8     23               ;  2073 status
    ld a,(hl)                        ; 05c9     7e               ;  Get shot status
    and 001h                         ; 05ca     e6 01            ;  Bit 0 is 1 if blowing up
    jp nz,shot_blowing_up            ; 05cc     c2 44 06         ;  Go do shot-is-blowing-up sequence
    inc hl                           ; 05cf     23               ;  2074 step count
    inc (hl)                         ; 05d0     34               ;  Count the steps (used for fire rate)
    call erase_alien_shot_explosion  ; 05d1     cd 75 06         ;  Erase shot
    ld a,(a_shot_image_lsb)          ; 05d4     3a 79 20         ;  Get LSB of the image pointer
    add a,003h                       ; 05d7     c6 03            ;  Next set of images
    ld hl,shot_pic_end               ; 05d9     21 7f 20         ;  End of image
    cp (hl)                          ; 05dc     be               ;  Have we reached the end of the set?
    jp c,l05e2h                      ; 05dd     da e2 05         ;  No ... keep it
    sub 00ch                         ; 05e0     d6 0c            ;  Back up to the 1st image in the set
l05e2h:                                                         
    ld (a_shot_image_lsb),a          ; 05e2     32 79 20         ;  New LSB image pointer
    ld a,(alien_shot_yr)             ; 05e5     3a 7b 20         ;  Get shot's Y coordinate
    ld b,a                           ; 05e8     47               ;  Hold it
    ld a,(alien_shot_delta)          ; 05e9     3a 7e 20         ;  Get alien shot delta
    add a,b                          ; 05ec     80               ;  Add to shots coordinate
    ld (alien_shot_yr),a             ; 05ed     32 7b 20         ;  New shot Y coordinate
    call draw_alien_shot             ; 05f0     cd 6c 06         ;  Draw the alien shot
    ld a,(alien_shot_yr)             ; 05f3     3a 7b 20         ;  Shot's Y coordinate
    cp 015h                          ; 05f6     fe 15            ;  Still in the active playfield?
    jp c,l0612h                      ; 05f8     da 12 06         ;  No ... end it
    ld a,(collision)                 ; 05fb     3a 61 20         ;  Did shot collide ...
    and a                            ; 05fe     a7               ;  ... with something?
    ret z                            ; 05ff     c8               ;  No ... we are done here
l0600h:                                                         
    ld a,(alien_shot_yr)             ; 0600     3a 7b 20         ;  Shot's Y coordinate
    cp 01eh                          ; 0603     fe 1e            ;  Is it below player's area?
    jp c,l0612h                      ; 0605     da 12 06         ;  Yes ... end it
    cp 027h                          ; 0608     fe 27            ;  Is it above player's area?
    nop                              ; 060a     00               ;  ** WHY?
    jp nc,l0612h                     ; 060b     d2 12 06         ;  Yes ... end it
    sub a                            ; 060e     97               ;  Flag that player ...
    ld (player_alive),a              ; 060f     32 15 20         ;  ... has been struck
l0612h:                                                         
    ld a,(a_shot_status)             ; 0612     3a 73 20         ;  Flag to ...
    or 001h                          ; 0615     f6 01            ;  ... start shot ...
    ld (a_shot_status),a             ; 0617     32 73 20         ;  ... blowing up
    ret                              ; 061a     c9               ;  Out

l061bh:                                                         
    ld a,(player_xr)                 ; 061b     3a 1b 20         ;  Player's X coordinate
    add a,008h                       ; 061e     c6 08            ;  Center of player
    ld h,a                           ; 0620     67               ;  To H for routine
    call find_column                 ; 0621     cd 6f 15         ;  Find the column
    ld a,c                           ; 0624     79               ;  Get the column right over player
    cp 00ch                          ; 0625     fe 0c            ;  Is it a valid column?
    jp c,l05a5h                      ; 0627     da a5 05         ;  Yes ... use what we found
    ld c,00bh                        ; 062a     0e 0b            ;  Else use ...
    jp l05a5h                        ; 062c     c3 a5 05         ;  ... as far over as we can

find_in_column:                                                 
    dec c                            ; 062f     0d               ;  Column that is firing
    ld a,(player_data_msb)           ; 0630     3a 67 20         ;  Player's MSB (21xx or 22xx)
    ld h,a                           ; 0633     67               ;  To MSB of HL
    ld l,c                           ; 0634     69               ;  Column to L
    ld d,005h                        ; 0635     16 05            ;  5 rows of aliens
l0637h:                                                         
    ld a,(hl)                        ; 0637     7e               ;  Get alien's status
    and a                            ; 0638     a7               ;  0 means dead
    scf                              ; 0639     37               ;  In case not 0
    ret nz                           ; 063a     c0               ;  Alien is alive? Yes ... return
    ld a,l                           ; 063b     7d               ;  Get the flag pointer LSB
    add a,00bh                       ; 063c     c6 0b            ;  Jump to same column on next row of rack (+11 aliens per row)
    ld l,a                           ; 063e     6f               ;  New alien index
    dec d                            ; 063f     15               ;  Tested all rows?
    jp nz,l0637h                     ; 0640     c2 37 06         ;  No ... keep looking for a live alien up the rack
    ret                              ; 0643     c9               ;  Didn't find a live alien. Return with C=0.

shot_blowing_up:                                                
    ld hl,a_shot_blow_cnt            ; 0644     21 78 20         ;  Blow up timer
    dec (hl)                         ; 0647     35               ;  Decrement the value
    ld a,(hl)                        ; 0648     7e               ;  Get the value
    cp 003h                          ; 0649     fe 03            ;  First tick, 4, we draw the explosion
    jp nz,l0667h                     ; 064b     c2 67 06         ;  After that just wait
    call erase_alien_shot_explosion  ; 064e     cd 75 06         ;  Erase the shot
    ld hl,sprite_ashot_explode       ; 0651     21 dc 1c         ;  Alien shot ...
    ld (a_shot_image_lsb),hl         ; 0654     22 79 20         ;  ... explosion sprite
    ld hl,0207ch                     ; 0657     21 7c 20         ;  Alien shot Y
    dec (hl)                         ; 065a     35               ;  Left two for ...
    dec (hl)                         ; 065b     35               ;  ... explosion
    dec hl                           ; 065c     2b               ;  Point slien shot X
    dec (hl)                         ; 065d     35               ;  Up two for ...
    dec (hl)                         ; 065e     35               ;  ... explosion
    ld a,006h                        ; 065f     3e 06            ;  Alien shot descriptor ...
    ld (alien_shot_size),a           ; 0661     32 7d 20         ;  ... size 6
    jp draw_alien_shot               ; 0664     c3 6c 06         ;  Draw alien shot explosion

l0667h:                                                         
    and a                            ; 0667     a7               ;  Have we reached 0?
    ret nz                           ; 0668     c0               ;  No ... keep waiting
    jp erase_alien_shot_explosion    ; 0669     c3 75 06         ;  Erase the explosion and out

draw_alien_shot:                                                      
    ld hl,a_shot_image_lsb           ; 066c     21 79 20         ;  Alien shot descriptor
    call read_desc                   ; 066f     cd 3b 1a         ;  Read 5 byte structure
    jp draw_spr_collision            ; 0672     c3 91 14         ;  Draw shot and out

erase_alien_shot_explosion:                                                      
    ld hl,a_shot_image_lsb           ; 0675     21 79 20         ;  Alien shot descriptor
    call read_desc                   ; 0678     cd 3b 1a         ;  Read 5 byte structure
    jp erase_shifted                 ; 067b     c3 52 14         ;  Erase the shot and out

l067eh:                                                         
    ld (plu_shot_cfir_lsb),hl        ; 067e     22 48 20         ;  From 50B, update ...
    ret                              ; 0681     c9               ;  ... column-firing table pointer and out


                                                                 ;  Game object 4: Flying Saucer OR squiggly shot
                                                                 ;
                                                                 ;  This task is shared by the squiggly-shot and the flying saucer. The saucer waits until the
                                                                 ;  squiggly-shot is over before it begins.
                                                                 ;
    pop hl                           ; 0682     e1               ;  Pull data pointer from the stack (not going to use it)
    ld a,(shot_sync)                 ; 0683     3a 80 20         ;  Sync flag (copied from GO-2's timer value)
    cp 002h                          ; 0686     fe 02            ;  Are GO-2 and GO-3 idle?
    ret nz                           ; 0688     c0               ;  No ... only one at a time
    ld hl,saucer_start               ; 0689     21 83 20         ;  Time-till-saucer flag
    ld a,(hl)                        ; 068c     7e               ;  Is it time ...
    and a                            ; 068d     a7               ;  ... for a saucer?
    jp z,l050fh                      ; 068e     ca 0f 05         ;  No ... go process squiggly shot
    ld a,(squ_shot_step_cnt)         ; 0691     3a 56 20         ;  Is there a ...
    and a                            ; 0694     a7               ;  ... squiggly shot going?
    jp nz,l050fh                     ; 0695     c2 0f 05         ;  Yes ... go handle squiggly shot
    inc hl                           ; 0698     23               ;  Saucer on screen flag
    ld a,(hl)                        ; 0699     7e               ;  (2084) Is the saucer ...
    and a                            ; 069a     a7               ;  ... already on the screen?
    jp nz,l06abh                     ; 069b     c2 ab 06         ;  Yes ... go handle it
    ld a,(num_aliens)                ; 069e     3a 82 20         ;  Number of aliens remaining
    cp 008h                          ; 06a1     fe 08            ;  Less than ...
    jp c,l050fh                      ; 06a3     da 0f 05         ;  ... 8 ... no saucer
    ld (hl),001h                     ; 06a6     36 01            ;  (2084) The saucer is on the screen
    call draw_saucer                 ; 06a8     cd 3c 07         ;  Draw the flying saucer
l06abh:                                                         
    ld de,saucer_pri_pic_msb         ; 06ab     11 8a 20         ;  Saucer's Y coordinate
    call comp_yto_beam               ; 06ae     cd 06 1a         ;  Compare to beam position
    ret nc                           ; 06b1     d0               ;  Not the right ISR for moving saucer
    ld hl,saucer_hit                 ; 06b2     21 85 20         ;  Saucer hit flag
    ld a,(hl)                        ; 06b5     7e               ;  Has saucer ...
    and a                            ; 06b6     a7               ;  ... been hit?
    jp nz,l06d6h                     ; 06b7     c2 d6 06         ;  Yes ... don't move it
    ld hl,saucer_pri_pic_msb         ; 06ba     21 8a 20         ;  Saucer's structure
    ld a,(hl)                        ; 06bd     7e               ;  Get saucer's Y coordinate
    inc hl                           ; 06be     23               ;  Bump to ...
    inc hl                           ; 06bf     23               ;  ... delta Y
    add a,(hl)                       ; 06c0     86               ;  Move saucer
    ld (saucer_pri_pic_msb),a        ; 06c1     32 8a 20         ;  New coordinate
    call draw_saucer                 ; 06c4     cd 3c 07         ;  Draw the flying saucer
    ld hl,saucer_pri_pic_msb         ; 06c7     21 8a 20         ;  Saucer's structure
    ld a,(hl)                        ; 06ca     7e               ;  Y coordinate
    cp 028h                          ; 06cb     fe 28            ;  Too low? End of screen?
    jp c,l06f9h                      ; 06cd     da f9 06         ;  Yes ... remove from play
    cp 0e1h                          ; 06d0     fe e1            ;  Too high? End of screen?
    jp nc,l06f9h                     ; 06d2     d2 f9 06         ;  Yes ... remove from play
    ret                              ; 06d5     c9               ;  Done
l06d6h:                                                         
    ld b,0feh                        ; 06d6     06 fe            ;  Turn off ...
    call sound_bits3off              ; 06d8     cd dc 19         ;  ... flying saucer sound
    inc hl                           ; 06db     23               ;  (2086) show-hit timer
    dec (hl)                         ; 06dc     35               ;  Count down show-hit timer
    ld a,(hl)                        ; 06dd     7e               ;  Get current value
    cp 01fh                          ; 06de     fe 1f            ;  Starts at 20 ... is this the first tick of show-hit timer?
    jp z,l074bh                      ; 06e0     ca 4b 07         ;  Yes ... go show the explosion
    cp 018h                          ; 06e3     fe 18            ;  A little later ...
    jp z,l070ch                      ; 06e5     ca 0c 07         ;  ... show the score besides the saucer and add it
    and a                            ; 06e8     a7               ;  Has timer expired?
    ret nz                           ; 06e9     c0               ;  No ... let it run
    ld b,0efh                        ; 06ea     06 ef            ;  1110_1111 (mask off saucer hit sound)
    ld hl,sound_port5                ; 06ec     21 98 20         ;  Get current ...
    ld a,(hl)                        ; 06ef     7e               ;  ... value of port 5 sound
    and b                            ; 06f0     a0               ;  Mask off the saucer-hit sound
    ld (hl),a                        ; 06f1     77               ;  Set the new value
    and 020h                         ; 06f2     e6 20            ;  All sound off but ...
    out (005h),a                     ; 06f4     d3 05            ;  ... cocktail cabinet bit
    nop                              ; 06f6     00               ;  ** Why
    nop                              ; 06f7     00               ;  **
    nop                              ; 06f8     00               ;  **
l06f9h:                                                         
    call get_saucer_descriptor       ; 06f9     cd 42 07         ;  Covert pixel pos from descriptor to HL screen and shift
    call clear_small_sprite          ; 06fc     cd cb 14         ;  Clear a one byte sprite at HL
    ld hl,saucer_start               ; 06ff     21 83 20         ;  Saucer structure
    ld b,00ah                        ; 0702     06 0a            ;  10 bytes in saucer structure
    call reinit_saucer               ; 0704     cd 5f 07         ;  Re-initialize saucer structure
l0707h:                                                         
    ld b,0feh                        ; 0707     06 fe            ;  Turn off UFO ...
    jp sound_bits3off                ; 0709     c3 dc 19         ;  ... sound and out

l070ch:                                                         
    ld a,001h                        ; 070c     3e 01            ;  Flag the score ...
    ld (adjust_score_data),a         ; 070e     32 f1 20         ;  ... needs updating
    ld hl,(sau_score_lsb)            ; 0711     2a 8d 20         ;  Saucer score table
    ld b,(hl)                        ; 0714     46               ;  Get score for this saucer
    ld c,004h                        ; 0715     0e 04            ;  There are only 4 possibilities
    ld hl,l1d50h                     ; 0717     21 50 1d         ;  Possible scores table
    ld de,l1d4ch                     ; 071a     11 4c 1d         ;  Print strings for each score
l071dh:                                                         
    ld a,(de)                        ; 071d     1a               ;  Find ...
    cp b                             ; 071e     b8               ;  ... the ...
    jp z,l0728h                      ; 071f     ca 28 07         ;  ... print ...
    inc hl                           ; 0722     23               ;  ... string ...
    inc de                           ; 0723     13               ;  ... for ...
    dec c                            ; 0724     0d               ;  ... the ...
    jp nz,l071dh                     ; 0725     c2 1d 07         ;  ... score
l0728h:                                                         
    ld a,(hl)                        ; 0728     7e               ;  Get LSB of message (MSB is 2088 which is 1D)
    ld (saucer_pri_loc_lsb),a        ; 0729     32 87 20         ;  Message's LSB (_50=1D94 100=1D97 150=1D9A 300=1D9D)
    ld h,000h                        ; 072c     26 00            ;  MSB = 0 ...
    ld l,b                           ; 072e     68               ;  HL = B
    add hl,hl                        ; 072f     29               ;  *2
    add hl,hl                        ; 0730     29               ;  *4
    add hl,hl                        ; 0731     29               ;  *8
    add hl,hl                        ; 0732     29               ;  *16
    ld (score_delta_lsb),hl          ; 0733     22 f2 20         ;  Add score for hitting saucer (015 becomes 150 in BCD).
    call get_saucer_descriptor       ; 0736     cd 42 07         ;  Get the flying saucer score descriptor
    jp l08f1h                        ; 0739     c3 f1 08         ;  Print the three-byte score and out

draw_saucer:                                                      
    call get_saucer_descriptor       ; 073c     cd 42 07         ;  Draw the ...
    jp draw_simp_sprite              ; 073f     c3 39 14         ;  ... flying saucer

get_saucer_descriptor:                                                      
    ld hl,saucer_pri_loc_lsb         ; 0742     21 87 20         ;  Read flying saucer ...
    call read_desc                   ; 0745     cd 3b 1a         ;  ... structure
    jp conv_to_scr                   ; 0748     c3 47 1a         ;  Convert pixel number to screen and shift and out

l074bh:                                                         
    ld b,010h                        ; 074b     06 10            ;  Saucer hit sound bit
    ld hl,sound_port5                ; 074d     21 98 20         ;  Current state of sounds
    ld a,(hl)                        ; 0750     7e               ;  OR ...
    or b                             ; 0751     b0               ;  ... in ...
    ld (hl),a                        ; 0752     77               ;  ... saucer-hit sound
    call fleet_sound_off             ; 0753     cd 70 17         ;  Turn off fleet sound and start saucer-hit
    ld hl,sprite_saucer_blowup       ; 0756     21 7c 1d         ;  Sprite for saucer blowing up
    ld (saucer_pri_loc_lsb),hl       ; 0759     22 87 20         ;  Store it in structure
    jp draw_saucer                   ; 075c     c3 3c 07         ;  Draw the flying saucer

reinit_saucer:                                                      
    ld de,data_for_saucer            ; 075f     11 83 1b         ;  Data for saucer (702 sets count to 0A)
    jp block_copy                    ; 0762     c3 32 1a         ;  Reset saucer object data

wait_for_start:                                                 
    ld a,001h                        ; 0765     3e 01            ;  Tell ISR that we ...
    ld (wait_start_loop),a           ; 0767     32 93 20         ;  ... have started to wait
    ld sp,02400h                     ; 076a     31 00 24         ;  Reset stack
    ei                               ; 076d     fb               ;  Enable interrupts
    call suspend_game_tasks          ; 076e     cd 79 19         ;  Suspend game tasks
    call clear_play_field            ; 0771     cd d6 09         ;  Clear center window
    ld hl,03013h                     ; 0774     21 13 30         ;  Screen coordinates
    ld de,msg_push                   ; 0777     11 f3 1f         ;  "PRESS" or maybe "PUSH "
    ld c,004h                        ; 077a     0e 04            ;  Message length
    call print_message               ; 077c     cd f3 08         ;  Print it
l077fh:                                                         
    ld a,(num_coins)                 ; 077f     3a eb 20         ;  Number of credits
    dec a                            ; 0782     3d               ;  Set flags
    ld hl,02810h                     ; 0783     21 10 28         ;  Screen coordinates
    ld c,014h                        ; 0786     0e 14            ;  Message length
    jp nz,l0857h                     ; 0788     c2 57 08         ;  Take 1 or 2 player start
    ld de,only_one_player_btn        ; 078b     11 cf 1a         ;  "ONLY 1PLAYER BUTTON "
    call print_message               ; 078e     cd f3 08         ;  Print message
    in a,(001h)                      ; 0791     db 01            ;  Read player controls
    and 004h                         ; 0793     e6 04            ;  1Player start button?
    jp z,l077fh                      ; 0795     ca 7f 07         ;  No ... wait for button or credit
new_one_player_game:                                                       
    ld b,099h                        ; 0798     06 99            ;  Essentially a -1 for DAA
    xor a                            ; 079a     af               ;  Clear two player flag
new_game:                                                         
    ld (two_players),a               ; 079b     32 ce 20         ;  Set flag for 1 or 2 players
    ld a,(num_coins)                 ; 079e     3a eb 20         ;  Number of credits
    add a,b                          ; 07a1     80               ;  Take away credits
    daa                              ; 07a2     27               ;  Convert back to DAA
    ld (num_coins),a                 ; 07a3     32 eb 20         ;  New credit count
    call draw_num_credits            ; 07a6     cd 47 19         ;  Display number of credits
    ld hl,00000h                     ; 07a9     21 00 00         ;  Score of 0000
    ld (p1scor_l),hl                 ; 07ac     22 f8 20         ;  Clear player-1 score
    ld (p2scor_l),hl                 ; 07af     22 fc 20         ;  Clear player-2 score
    call print_player_one_score      ; 07b2     cd 25 19         ;  Print player-1 score
    call print_player_two_score      ; 07b5     cd 2b 19         ;  Print player-2 score
    call dsable_game_tasks           ; 07b8     cd d7 19         ;  Disable game tasks
    ld hl,00101h                     ; 07bb     21 01 01         ;  Two bytes 1, 1
    ld a,h                           ; 07be     7c               ;  1 to A
    ld (game_mode),a                 ; 07bf     32 ef 20         ;  20EF=1 ... game mode
    ld (player1alive),hl             ; 07c2     22 e7 20         ;  20E7 and 20E8 both one ... players 1 and 2 are alive
    ld (player1ex),hl                ; 07c5     22 e5 20         ;  Extra-ship is available for player-1 and player-2
    call draw_status                 ; 07c8     cd 56 19         ;  Print scores and credits
    call draw_shield_pl1             ; 07cb     cd ef 01         ;  Draw shields for player-1
    call draw_shield_pl2             ; 07ce     cd f5 01         ;  Draw shields for player-2
    call get_ships_per_cred          ; 07d1     cd d1 08         ;  Get number of ships from DIP settings
    ld (p1ships_rem),a               ; 07d4     32 ff 21         ;  Player-1 ships
    ld (p2ships_rem),a               ; 07d7     32 ff 22         ;  Player-2 ships
    call init_racks_direction        ; 07da     cd d7 00         ;  Set player-1 and player-2 alien racks going right
    xor a                            ; 07dd     af               ;  Make a 0
    ld (p1rack_cnt),a                ; 07de     32 fe 21         ;  Player 1 is on first rack of aliens
    ld (p2rack_cnt),a                ; 07e1     32 fe 22         ;  Player 2 is on first rack of aliens
    call init_aliens_player_one      ; 07e4     cd c0 01         ;  Initialize 55 aliens for player 1
    call init_aliens_player_two      ; 07e7     cd 04 19         ;  Initialize 55 aliens for player 2
    ld hl,03878h                     ; 07ea     21 78 38         ;  Screen coordinates for lower-left alien
    ld (p1ref_alien_y),hl            ; 07ed     22 fc 21         ;  Initialize reference alien for player 1
    ld (p2ref_alien_yr),hl           ; 07f0     22 fc 22         ;  Initialize reference alien for player 2
    call copy_ram_mirror             ; 07f3     cd e4 01         ;  Copy ROM mirror to RAM (2000 - 20C0)
    call remove_ship                 ; 07f6     cd 7f 1a         ;  Initialize ship hold indicator
l07f9h:                                                         
    call prompt_player               ; 07f9     cd 8d 08         ;  Prompt with "PLAY PLAYER "
    call clear_play_field            ; 07fc     cd d6 09         ;  Clear the playfield
    nop                              ; 07ff     00               ;  % Why?
    xor a                            ; 0800     af               ;  Make a 0
    ld (isr_splash_task),a           ; 0801     32 c1 20         ;  Disable isr splash-task animation
top_of_game_loop:                                                         
    call draw_bottom_line            ; 0804     cd cf 01         ;  Draw line across screen under player
    ld a,(player_data_msb)           ; 0807     3a 67 20         ;  Current player
    rrca                             ; 080a     0f               ;  Right bit tells all
    jp c,l0872h                      ; 080b     da 72 08         ;  Go do player 1
    call restore_shields2            ; 080e     cd 13 02         ;  Restore shields for player 2
    call draw_bottom_line            ; 0811     cd cf 01         ;  Draw line across screen under player
l0814h:                                                         
    call init_rack                   ; 0814     cd b1 00         ;  Initialize alien rack for current player
l0817h:                                                         
    call enable_game_tasks           ; 0817     cd d1 19         ;  Enable game tasks in ISR
    ld b,020h                        ; 081a     06 20            ;  Enable ...
    call sound_bits3on               ; 081c     cd fa 18         ;  ... sound amplifier
l081fh:                                                         
    call plr_fire_or_demo            ; 081f     cd 18 16         ;  Initiate player shot if button pressed
    call plyr_shot_and_bump          ; 0822     cd 0a 19         ;  Collision detect player's shot and rack-bump
    call count_aliens                ; 0825     cd f3 15         ;  Count aliens (count to 2082)
    call adjust_score_code           ; 0828     cd 88 09         ;  Adjust score (and print) if there is an adjustment
    ld a,(num_aliens)                ; 082b     3a 82 20         ;  Number of live aliens
    and a                            ; 082e     a7               ;  All aliens gone?
    jp z,l09efh                      ; 082f     ca ef 09         ;  Yes ... end of turn
    call ashot_reload_rate           ; 0832     cd 0e 17         ;  Update alien-shot-rate based on player's score
    call do_extra_ship_awards        ; 0835     cd 35 09         ;  Check (and handle) extra ship award
    call speed_shots                 ; 0838     cd d8 08         ;  Adjust alien shot speed
    call shot_sound                  ; 083b     cd 2c 17         ;  Shot sound on or off with 2025
    call flag_player_hit             ; 083e     cd 59 0a         ;  Check if player is hit
    jp z,l0849h                      ; 0841     ca 49 08         ;  No hit ... jump handler
    ld b,004h                        ; 0844     06 04            ;  Player hit sound
    call sound_bits3on               ; 0846     cd fa 18         ;  Make explosion sound
l0849h:                                                         
    call fleet_delay_ex_ship         ; 0849     cd 75 17         ;  Extra-ship sound timer, set fleet-delay, play fleet movement sound
    out (006h),a                     ; 084c     d3 06            ;  Feed the watchdog
    call ctrl_saucer_sound           ; 084e     cd 04 18         ;  Control saucer sound
    jp l081fh                        ; 0851     c3 1f 08         ;  Continue game loop

    nop                              ; 0854     00               ;  ** Why?
    nop                              ; 0855     00              
    nop                              ; 0856     00              
l0857h:                                                         
    ld de,msg_one_or_two_players_btn ; 0857     11 ba 1a         ;  "1 OR 2PLAYERS BUTTON"
    call print_message               ; 085a     cd f3 08         ;  Print message
    ld b,098h                        ; 085d     06 98            ;  -2 (take away 2 credits)
    in a,(001h)                      ; 085f     db 01            ;  Read player controls
    rrca                             ; 0861     0f               ;  Test ...
    rrca                             ; 0862     0f               ;  ... bit 2
    jp c,new_two_player_game         ; 0863     da 6d 08         ;  2 player button pressed ... do it
    rrca                             ; 0866     0f               ;  Test bit 3
    jp c,new_one_player_game         ; 0867     da 98 07         ;  One player start ... do it
    jp l077fh                        ; 086a     c3 7f 07         ;  Keep waiting on credit or button

new_two_player_game:                                                         
    ld a,001h                        ; 086d     3e 01            ;  Flag 2 player game
    jp new_game                      ; 086f     c3 9b 07         ;  Continue normal startup

l0872h:                                                         
    call restore_shields1            ; 0872     cd 1a 02         ;  Restore shields for player 1
    jp l0814h                        ; 0875     c3 14 08         ;  Continue in game loop

get_alien_ptr_etc:                                                      
    ld a,(ref_alien_dxr)             ; 0878     3a 08 20         ;  Alien deltaY
    ld b,a                           ; 087b     47               ;  Hold it
    ld hl,(ref_alien_yr)             ; 087c     2a 09 20         ;  Alien coordinates
    ex de,hl                         ; 087f     eb               ;  Coordinates to DE
    jp get_alien_reference_ptr       ; 0880     c3 86 08         ;  HL is 21FC or 22FC and out

    nop                              ; 0883     00               ;  ** Why?
    nop                              ; 0884     00              
    nop                              ; 0885     00              

get_alien_reference_ptr:                                                 
    ld a,(player_data_msb)           ; 0886     3a 67 20         ;  Player data MSB (21 or 22)
    ld h,a                           ; 0889     67               ;  To H
    ld l,0fch                        ; 088a     2e fc            ;  21FC or 22FC ... alien coordinates
    ret                              ; 088c     c9               ;  Done

prompt_player:                                                  
    ld hl,02b11h                     ; 088d     21 11 2b         ;  Screen coordinates
    ld de,msg_play_player_one        ; 0890     11 70 1b         ;  Message "PLAY PLAYER<1>"
    ld c,00eh                        ; 0893     0e 0e            ;  14 bytes in message
    call print_message               ; 0895     cd f3 08         ;  Print the message
    ld a,(player_data_msb)           ; 0898     3a 67 20         ;  Get the player number
    rrca                             ; 089b     0f               ;  C will be set for player 1
    ld a,01ch                        ; 089c     3e 1c            ;  The "2" character
    ld hl,03711h                     ; 089e     21 11 37         ;  Replace the "<1>" with "<2">
    call nc,draw_char                ; 08a1     d4 ff 08         ;  If player 2 ... change the message
    ld a,0b0h                        ; 08a4     3e b0            ;  Delay of 176 (roughly 2 seconds)
    ld (isr_delay),a                 ; 08a6     32 c0 20         ;  Set the ISR delay value
l08a9h:                                                         
    ld a,(isr_delay)                 ; 08a9     3a c0 20         ;  Get the ISR delay value
    and a                            ; 08ac     a7               ;  Has the 2 second delay expired?
    ret z                            ; 08ad     c8               ;  Yes ... done
    and 004h                         ; 08ae     e6 04            ;  Every 4 ISRs ...
    jp nz,l08bch                     ; 08b0     c2 bc 08         ;  ... flash the player's score
    call get_player_score_descriptor ; 08b3     cd ca 09         ;  Get the score descriptor for the active player
    call draw_score                  ; 08b6     cd 31 19         ;  Draw the score
    jp l08a9h                        ; 08b9     c3 a9 08         ;  Back to the top of the wait loop

l08bch:                                                         
    ld b,020h                        ; 08bc     06 20            ;  32 rows (4 characters * 8 bytes each)
    ld hl,0271ch                     ; 08be     21 1c 27         ;  Player-1 score on the screen
    ld a,(player_data_msb)           ; 08c1     3a 67 20         ;  Get the player number
    rrca                             ; 08c4     0f               ;  C will be set for player 1
    jp c,l08cbh                      ; 08c5     da cb 08         ;  We have the right score coordinates
    ld hl,0391ch                     ; 08c8     21 1c 39         ;  Use coordinates for player-2's score
l08cbh:                                                         
    call clear_small_sprite          ; 08cb     cd cb 14         ;  Clear a one byte sprite at HL
    jp l08a9h                        ; 08ce     c3 a9 08         ;  Back to the top of the wait loop

get_ships_per_cred:                                             
    in a,(002h)                      ; 08d1     db 02            ;  DIP settings
    and 003h                         ; 08d3     e6 03            ;  Get number of ships
    add a,003h                       ; 08d5     c6 03            ;  From 3-6
    ret                              ; 08d7     c9               ;  Out

speed_shots:                                                    
    ld a,(num_aliens)                ; 08d8     3a 82 20         ;  Number of aliens on screen
    cp 009h                          ; 08db     fe 09            ;  More than 8?
    ret nc                           ; 08dd     d0               ;  Yes ... leave shot speed alone
    ld a,0fbh                        ; 08de     3e fb            ;  Normally FF (-4) ... now FB (-5)
    ld (alien_shot_delta),a          ; 08e0     32 7e 20         ;  Speed up alien shots
    ret                              ; 08e3     c9               ;  Done

l08e4h:                                                         
    ld a,(two_players)               ; 08e4     3a ce 20         ;  Number of players
    and a                            ; 08e7     a7               ;  Skip if ...
    ret nz                           ; 08e8     c0               ;  ... two player
    ld hl,0391ch                     ; 08e9     21 1c 39         ;  Player 2's score
    ld b,020h                        ; 08ec     06 20            ;  32 rows is 4 digits * 8 rows each
    jp clear_small_sprite            ; 08ee     c3 cb 14         ;  Clear a one byte sprite (32 rows long) at HL

l08f1h:                                                         
    ld c,003h                        ; 08f1     0e 03            ;  Length of saucer-score message ... fall into print
print_message:                                                  
    ld a,(de)                        ; 08f3     1a               ;  Get character
    push de                          ; 08f4     d5               ;  Preserve
    call draw_char                   ; 08f5     cd ff 08         ;  Print character
    pop de                           ; 08f8     d1               ;  Restore
    inc de                           ; 08f9     13               ;  Next character
    dec c                            ; 08fa     0d               ;  All done?
    jp nz,print_message              ; 08fb     c2 f3 08         ;  Print all of message
    ret                              ; 08fe     c9               ;  Out

draw_char:                                                      
    ld de,character_set              ; 08ff     11 00 1e         ;  Character set
    push hl                          ; 0902     e5               ;  Preserve
    ld h,000h                        ; 0903     26 00            ;  MSB=0
    ld l,a                           ; 0905     6f               ;  Character number to L
    add hl,hl                        ; 0906     29               ;  HL = HL *2
    add hl,hl                        ; 0907     29               ;  *4
    add hl,hl                        ; 0908     29               ;  *8 (8 bytes each)
    add hl,de                        ; 0909     19               ;  Get pointer to sprite
    ex de,hl                         ; 090a     eb               ;  Now into DE
    pop hl                           ; 090b     e1               ;  Restore HL
    ld b,008h                        ; 090c     06 08            ;  8 bytes each
    out (006h),a                     ; 090e     d3 06            ;  Feed watchdog
    jp draw_simp_sprite              ; 0910     c3 39 14         ;  To screen

time_to_saucer:                                                 
    ld a,(ref_alien_yr)              ; 0913     3a 09 20         ;  Reference alien's X coordinate
    cp 078h                          ; 0916     fe 78            ;  Don't process saucer timer ... ($78 is 1st rack Yr)
    ret nc                           ; 0918     d0               ;  ... unless aliens are closer to bottom
    ld hl,(till_saucer_lsb)          ; 0919     2a 91 20         ;  Time to saucer
    ld a,l                           ; 091c     7d               ;  Is it time ...
    or h                             ; 091d     b4               ;  ... for a saucer
    jp nz,l0929h                     ; 091e     c2 29 09         ;  No ... skip flagging
    ld hl,l0600h                     ; 0921     21 00 06         ;  Reset timer to 600 game loops
    ld a,001h                        ; 0924     3e 01            ;  Flag a ...
    ld (saucer_start),a              ; 0926     32 83 20         ;  ... saucer sequence
l0929h:                                                         
    dec hl                           ; 0929     2b               ;  Decrement the ...
    ld (till_saucer_lsb),hl          ; 092a     22 91 20         ;  ... time-to-saucer
    ret                              ; 092d     c9               ;  Done

get_num_ships_active_player:                                                      
    call get_player_data_ptr         ; 092e     cd 11 16         ;  HL points to player data
    ld l,0ffh                        ; 0931     2e ff            ;  Last byte = numbe of ships
    ld a,(hl)                        ; 0933     7e               ;  Get number of ships
    ret                              ; 0934     c9               ;  Done

do_extra_ship_awards:                                                      
    call cur_ply_alive               ; 0935     cd 10 19         ;  Get descriptor of sorts
    dec hl                           ; 0938     2b               ;  Back up ...
    dec hl                           ; 0939     2b               ;  ... two bytes
    ld a,(hl)                        ; 093a     7e               ;  Has extra ship ...
    and a                            ; 093b     a7               ;  already been awarded?
    ret z                            ; 093c     c8               ;  Yes ... ignore
    ld b,015h                        ; 093d     06 15            ;  Default 1500
    in a,(002h)                      ; 093f     db 02            ;  Read DIP settings
    and 008h                         ; 0941     e6 08            ;  Extra ship at 1000 or 1500
    jp z,l0948h                      ; 0943     ca 48 09         ;  0=1500
    ld b,010h                        ; 0946     06 10            ;  Awarded at 1000
l0948h:                                                         
    call get_player_score_descriptor ; 0948     cd ca 09         ;  Get score descriptor for active player
    inc hl                           ; 094b     23               ;  MSB of score ...
    ld a,(hl)                        ; 094c     7e               ;  ... to accumulator
    cp b                             ; 094d     b8               ;  Time for an extra ship?
    ret c                            ; 094e     d8               ;  No ... out
    call get_num_ships_active_player ; 094f     cd 2e 09         ;  Get pointer to number of ships
    inc (hl)                         ; 0952     34               ;  Bump number of ships
    ld a,(hl)                        ; 0953     7e               ;  Get the new total
    push af                          ; 0954     f5               ;  Hang onto it for a bit
    ld hl,02501h                     ; 0955     21 01 25         ;  Screen coords for ship hold
l0958h:                                                         
    inc h                            ; 0958     24               ;  Bump to ...
    inc h                            ; 0959     24               ;  ... next
    dec a                            ; 095a     3d               ;  ... spot
    jp nz,l0958h                     ; 095b     c2 58 09         ;  Find spot for new ship
    ld b,010h                        ; 095e     06 10            ;  16 byte sprite
    ld de,sprite_player              ; 0960     11 60 1c         ;  Player sprite
    call draw_simp_sprite            ; 0963     cd 39 14         ;  Draw the sprite
    pop af                           ; 0966     f1               ;  Restore the count
    inc a                            ; 0967     3c               ;  +1
    call print_num_ships_in_acc      ; 0968     cd 8b 1a         ;  Print the number of ships
    call cur_ply_alive               ; 096b     cd 10 19         ;  Get descriptor for active player of some sort
    dec hl                           ; 096e     2b               ;  Back up ...
    dec hl                           ; 096f     2b               ;  ... two bytes
    ld (hl),000h                     ; 0970     36 00            ;  Flag extra ship has been awarded
    ld a,0ffh                        ; 0972     3e ff            ;  Set timer ...
    ld (extra_hold),a                ; 0974     32 99 20         ;  ... for extra-ship sound
    ld b,010h                        ; 0977     06 10            ;  Make sound ...
    jp sound_bits3on                 ; 0979     c3 fa 18         ;  ... for extra man

alien_score_value:                                              
    ld hl,table_alien_score_val      ; 097c     21 a0 1d         ;  Table for scores for hitting alien
    cp 002h                          ; 097f     fe 02            ;  0 or 1 (lower two rows) ...
    ret c                            ; 0981     d8               ;  ... return HL points to value 10
    inc hl                           ; 0982     23               ;  next value
    cp 004h                          ; 0983     fe 04            ;  2 or 3 (middle two rows) ...
    ret c                            ; 0985     d8               ;  ... return HL points to value 20
    inc hl                           ; 0986     23               ;  Top row ...
    ret                              ; 0987     c9               ;  ... return HL points to value 30

adjust_score_code:                                              
    call get_player_score_descriptor ; 0988     cd ca 09         ;  Get score structure for active player
    ld a,(adjust_score_data)         ; 098b     3a f1 20         ;  Does the score ...
    and a                            ; 098e     a7               ;  ... need increasing?
    ret z                            ; 098f     c8               ;  No ... done
    xor a                            ; 0990     af               ;  Mark score ...
    ld (adjust_score_data),a         ; 0991     32 f1 20         ;  ... as adjusted
    push hl                          ; 0994     e5               ;  Hold the pointer to the structure
    ld hl,(score_delta_lsb)          ; 0995     2a f2 20         ;  Get requested adjustment
    ex de,hl                         ; 0998     eb               ;  Adjustment to DE
    pop hl                           ; 0999     e1               ;  Get back pointer to structure
    ld a,(hl)                        ; 099a     7e               ;  Add adjustment ...
    add a,e                          ; 099b     83               ;  ... first byte
    daa                              ; 099c     27               ;  Adjust it for BCD
    ld (hl),a                        ; 099d     77               ;  Store new LSB
    ld e,a                           ; 099e     5f               ;  Add adjustment ...
    inc hl                           ; 099f     23               ;  ... to ...
    ld a,(hl)                        ; 09a0     7e               ;  ... second ...
    adc a,d                          ; 09a1     8a               ;  ... byte
    daa                              ; 09a2     27               ;  Adjust for BCD (cary gets dropped)
    ld (hl),a                        ; 09a3     77               ;  Store second byte
    ld d,a                           ; 09a4     57               ;  Second byte to D (first byte still in E)
    inc hl                           ; 09a5     23               ;  Load ...
    ld a,(hl)                        ; 09a6     7e               ;  ... the ...
    inc hl                           ; 09a7     23               ;  ... screen ...
    ld h,(hl)                        ; 09a8     66               ;  ... coordinates ...
    ld l,a                           ; 09a9     6f               ;  ... to HL
    jp draw_hex_word                 ; 09aa     c3 ad 09         ;  ** Usually a good idea, but wasted here

draw_hex_word:                                                   
    ld a,d                           ; 09ad     7a               ;  Get first 2 digits of BCD or hex
    call draw_hex_byte               ; 09ae     cd b2 09         ;  Print them
    ld a,e                           ; 09b1     7b               ;  Get second 2 digits of BCD or hex (fall into print)
draw_hex_byte:                                                  
    push de                          ; 09b2     d5               ;  Preserve
    push af                          ; 09b3     f5               ;  Save for later
    rrca                             ; 09b4     0f               ;  Get ...
    rrca                             ; 09b5     0f               ;  ...
    rrca                             ; 09b6     0f               ;  ...
    rrca                             ; 09b7     0f               ;  ... left digit
    and 00fh                         ; 09b8     e6 0f            ;  Mask out lower digit's bits
    call draw_digit_in_acc           ; 09ba     cd c5 09         ;  To screen at HL
    pop af                           ; 09bd     f1               ;  Restore digit
    and 00fh                         ; 09be     e6 0f            ;  Mask out upper digit
    call draw_digit_in_acc           ; 09c0     cd c5 09         ;  To screen
    pop de                           ; 09c3     d1               ;  Restore
    ret                              ; 09c4     c9               ;  Done

draw_digit_in_acc:                                                      
    add a,01ah                       ; 09c5     c6 1a            ;  Bump to number characters
    jp draw_char                     ; 09c7     c3 ff 08         ;  Continue ...

get_player_score_descriptor:                                                      
    ld a,(player_data_msb)           ; 09ca     3a 67 20         ;  Get active player
    rrca                             ; 09cd     0f               ;  Test for player
    ld hl,p1scor_l                   ; 09ce     21 f8 20         ;  Player 1 score descriptor
    ret c                            ; 09d1     d8               ;  Keep it if player 1 is active
    ld hl,p2scor_l                   ; 09d2     21 fc 20         ;  Else get player 2 descriptor
    ret                              ; 09d5     c9               ;  Out

clear_play_field:                                               
    ld hl,02402h                     ; 09d6     21 02 24         ;  Third from left, top of screen
l09d9h:                                                         
    ld (hl),000h                     ; 09d9     36 00            ;  Clear screen byte
    inc hl                           ; 09db     23               ;  Next in row
    ld a,l                           ; 09dc     7d               ;  Get X ...
    and 01fh                         ; 09dd     e6 1f            ;  ... coordinate
    cp 01ch                          ; 09df     fe 1c            ;  Edge minus a buffer?
    jp c,l09e8h                      ; 09e1     da e8 09         ;  No ... keep going
    ld de,l0006h                     ; 09e4     11 06 00         ;  Else ... bump to
    add hl,de                        ; 09e7     19               ;  ... next edge + buffer
l09e8h:                                                         
    ld a,h                           ; 09e8     7c               ;  Get Y coordinate
    cp 040h                          ; 09e9     fe 40            ;  Reached bottom?
    jp c,l09d9h                      ; 09eb     da d9 09         ;  No ... keep going
    ret                              ; 09ee     c9               ;  Done

l09efh:                                                         
    call check_player_collision      ; 09ef     cd 3c 0a        
    xor a                            ; 09f2     af               ;  Suspend ...
    ld (suspend_play),a              ; 09f3     32 e9 20         ;  ... ISR game tasks
    call clear_play_field            ; 09f6     cd d6 09         ;  Clear playfield
    ld a,(player_data_msb)           ; 09f9     3a 67 20         ;  Hold current player number ...
    push af                          ; 09fc     f5               ;  ... on stack
    call copy_ram_mirror             ; 09fd     cd e4 01         ;  Block copy RAM mirror from ROM
    pop af                           ; 0a00     f1               ;  Restore ...
    ld (player_data_msb),a           ; 0a01     32 67 20         ;  ... current player number
    ld a,(player_data_msb)           ; 0a04     3a 67 20         ;  ** Why load this again? Nobody ever jumps to 0A04?
    ld h,a                           ; 0a07     67               ;  To H
    push hl                          ; 0a08     e5               ;  Hold player-data pointer
    ld l,0feh                        ; 0a09     2e fe            ;  2xFE ... rack count
    ld a,(hl)                        ; 0a0b     7e               ;  Get the number of racks the player has beaten
    and 007h                         ; 0a0c     e6 07            ;  0-7
    inc a                            ; 0a0e     3c               ;  Now 1-8
    ld (hl),a                        ; 0a0f     77               ;  Update count since player just beat a rack
    ld hl,coord_start_alien_table    ; 0a10     21 a2 1d         ;  Starting coordinate of alien table
l0a13h:                                                         
    inc hl                           ; 0a13     23               ;  Find the ...
    dec a                            ; 0a14     3d               ;  ... right entry ...
    jp nz,l0a13h                     ; 0a15     c2 13 0a         ;  ... in the table
    ld a,(hl)                        ; 0a18     7e               ;  Get the starting Y coordiante
    pop hl                           ; 0a19     e1               ;  Restore player's pointer
    ld l,0fch                        ; 0a1a     2e fc            ;  2xFC ...
    ld (hl),a                        ; 0a1c     77               ;  Set rack's starting Y coordinate
    inc hl                           ; 0a1d     23               ;  Point to X
    ld (hl),038h                     ; 0a1e     36 38            ;  Set rack's starting X coordinate to 38
    ld a,h                           ; 0a20     7c               ;  Player ...
    rrca                             ; 0a21     0f               ;  ... number to carry
    jp c,l0a33h                      ; 0a22     da 33 0a         ;  2nd player stuff
    ld a,021h                        ; 0a25     3e 21            ;  Start fleet with ...
    ld (sound_port5),a               ; 0a27     32 98 20         ;  ... first sound
    call draw_shield_pl2             ; 0a2a     cd f5 01         ;  Draw shields for player 2
    call init_aliens_player_two      ; 0a2d     cd 04 19         ;  Initalize aliens for player 2
    jp top_of_game_loop              ; 0a30     c3 04 08         ;  Continue at top of game loop

l0a33h:                                                         
    call draw_shield_pl1             ; 0a33     cd ef 01         ;  Draw shields for player 1
    call init_aliens_player_one      ; 0a36     cd c0 01         ;  Initialize aliens for player 1
    jp top_of_game_loop              ; 0a39     c3 04 08         ;  Continue at top of game loop

check_player_collision:                                                      
    call flag_player_hit             ; 0a3c     cd 59 0a         ;  Check player collision
    jp nz,l0a52h                     ; 0a3f     c2 52 0a         ;  Player is not alive ... skip delay
    ld a,030h                        ; 0a42     3e 30            ;  Half second delay
    ld (isr_delay),a                 ; 0a44     32 c0 20         ;  Set ISR timer
l0a47h:                                                         
    ld a,(isr_delay)                 ; 0a47     3a c0 20         ;  Has timer expired?
    and a                            ; 0a4a     a7               ;  Check exipre
    ret z                            ; 0a4b     c8               ;  Out if done
    call flag_player_hit             ; 0a4c     cd 59 0a         ;  Check player collision
    jp z,l0a47h                      ; 0a4f     ca 47 0a         ;  No collision ... wait on timer
l0a52h:                                                         
    call flag_player_hit             ; 0a52     cd 59 0a         ;  Wait for ...
    jp nz,l0a52h                     ; 0a55     c2 52 0a         ;  ... collision to end
    ret                              ; 0a58     c9               ;  Done

flag_player_hit:                                                      
    ld a,(player_alive)              ; 0a59     3a 15 20         ;  Active player hit flag
    cp 0ffh                          ; 0a5c     fe ff            ;  All FFs means player is OK
    ret                              ; 0a5e     c9               ;  Out - zero flag is not hit because cmp is a subtract

score_for_alien:                                                
    ld a,(game_mode)                 ; 0a5f     3a ef 20         ;  Are we in ...
    and a                            ; 0a62     a7               ;  ... game mode?
    jp z,l0a7ch                      ; 0a63     ca 7c 0a         ;  No ... skip scoring in demo
    ld c,b                           ; 0a66     48               ;  Hold row number
    ld b,008h                        ; 0a67     06 08            ;  Alien hit sound
    call sound_bits3on               ; 0a69     cd fa 18         ;  Enable sound
    ld b,c                           ; 0a6c     41               ;  Restore row number
    ld a,b                           ; 0a6d     78               ;  Into A
    call alien_score_value           ; 0a6e     cd 7c 09         ;  Look up the score for the alien
    ld a,(hl)                        ; 0a71     7e               ;  Get the score value
    ld hl,020f3h                     ; 0a72     21 f3 20         ;  Pointer to score delta
    ld (hl),000h                     ; 0a75     36 00            ;  Upper byte of score delta is "00"
    dec hl                           ; 0a77     2b               ;  Point to score delta LSB
    ld (hl),a                        ; 0a78     77               ;  Set score for hitting alien
    dec hl                           ; 0a79     2b               ;  Point to adjust-score-flag
    ld (hl),001h                     ; 0a7a     36 01            ;  The score will get changed elsewhere
l0a7ch:                                                         
    ld hl,02062h                     ; 0a7c     21 62 20         ;  Return exploding-alien descriptor
    ret                              ; 0a7f     c9               ;  Out

animate:                                                        
    ld a,002h                        ; 0a80     3e 02            ;  Start simple linear ...
    ld (isr_splash_task),a           ; 0a82     32 c1 20         ;  ... sprite animation (splash)
l0a85h:                                                         
    out (006h),a                     ; 0a85     d3 06            ;  Feed watchdog
    ld a,(splash_reached)            ; 0a87     3a cb 20         ;  Has the ...
    and a                            ; 0a8a     a7               ;  ... sprite reached target?
    jp z,l0a85h                      ; 0a8b     ca 85 0a         ;  No ... wait
    xor a                            ; 0a8e     af               ;  Stop ...
    ld (isr_splash_task),a           ; 0a8f     32 c1 20         ;  ... ISR animation
    ret                              ; 0a92     c9               ;  Done

print_message_del:                                              
    push de                          ; 0a93     d5               ;  Preserve
    ld a,(de)                        ; 0a94     1a               ;  Get character
    call draw_char                   ; 0a95     cd ff 08         ;  Draw character on screen
    pop de                           ; 0a98     d1               ;  Preserve
    ld a,007h                        ; 0a99     3e 07            ;  Delay between letters
    ld (isr_delay),a                 ; 0a9b     32 c0 20         ;  Set counter
l0a9eh:                                                         
    ld a,(isr_delay)                 ; 0a9e     3a c0 20         ;  Get counter
    dec a                            ; 0aa1     3d               ;  Is it 1?
    jp nz,l0a9eh                     ; 0aa2     c2 9e 0a         ;  No ... wait on it
    inc de                           ; 0aa5     13               ;  Next in message
    dec c                            ; 0aa6     0d               ;  All done?
    jp nz,print_message_del          ; 0aa7     c2 93 0a         ;  No ... do all
    ret                              ; 0aaa     c9               ;  Out

splash_squiggly:                                                
    ld hl,game_object_4              ; 0aab     21 50 20         ;  Pointer to game-object 4 timer
    jp keep_processing_game_objs     ; 0aae     c3 4b 02         ;  Process squiggly-shot in demo mode

one_sec_delay:                                                  
    ld a,040h                        ; 0ab1     3e 40            ;  Delay of 64 (tad over 1 sec)
    jp wait_on_delay                 ; 0ab3     c3 d7 0a         ;  Do delay

two_sec_delay:                                                  
    ld a,080h                        ; 0ab6     3e 80            ;  Delay of 80 (tad over 2 sec)
    jp wait_on_delay                 ; 0ab8     c3 d7 0a         ;  Do delay

splash_demo:                                                    
    pop hl                           ; 0abb     e1               ;  Drop the call to ABF and ...
    jp l0072h                        ; 0abc     c3 72 00         ;  ... do a demo game loop without sound

isrspl_tasks:                                                   
    ld a,(isr_splash_task)           ; 0abf     3a c1 20         ;  Get the ISR task number
    rrca                             ; 0ac2     0f               ;  In demo play mode?
    jp c,splash_demo                 ; 0ac3     da bb 0a         ;  1: Yes ... go do game play (without sound)
    rrca                             ; 0ac6     0f               ;  Moving little alien from point A to B?
    jp c,splash_sprite               ; 0ac7     da 68 18         ;  2: Yes ... go move little alien from point A to B
    rrca                             ; 0aca     0f               ;  Shooting extra "C" with squiggly shot?
    jp c,splash_squiggly             ; 0acb     da ab 0a         ;  4: Yes ... go shoot extra "C" in splash
    ret                              ; 0ace     c9               ;  No task to do

print_to_mid_screen:                                                      
    ld hl,02b14h                     ; 0acf     21 14 2b         ;  Near center of screen
    ld c,00fh                        ; 0ad2     0e 0f            ;  15 bytes in message
    jp print_message_del             ; 0ad4     c3 93 0a         ;  Print and out

wait_on_delay:                                                  
    ld (isr_delay),a                 ; 0ad7     32 c0 20         ;  Delay counter
l0adah:                                                         
    ld a,(isr_delay)                 ; 0ada     3a c0 20         ;  Get current delay
    and a                            ; 0add     a7               ;  Zero yet?
    jp nz,l0adah                     ; 0ade     c2 da 0a         ;  No ... wait on it
    ret                              ; 0ae1     c9               ;  Out

ini_splash_ani:                                                 
    ld hl,splash_an_form             ; 0ae2     21 c2 20         ;  The splash-animation descriptor
    ld b,00ch                        ; 0ae5     06 0c            ;  C bytes
    jp block_copy                    ; 0ae7     c3 32 1a         ;  Block copy DE to descriptor

l0aeah:                                                         
    xor a                            ; 0aea     af               ;  Make a 0
    out (003h),a                     ; 0aeb     d3 03            ;  Turn off sound
    out (005h),a                     ; 0aed     d3 05            ;  Turn off sound
    call control_isr_splash_from_acc ; 0aef     cd 82 19         ;  Turn off ISR splash-task
    ei                               ; 0af2     fb               ;  Enable interrupts (using them for delays)
    call one_sec_delay               ; 0af3     cd b1 0a         ;  One second delay
    ld a,(splash_animate)            ; 0af6     3a ec 20         ;  Splash screen type
    and a                            ; 0af9     a7               ;  Set flags based on type
    ld hl,03017h                     ; 0afa     21 17 30         ;  Screen coordinates (middle near top)
    ld c,004h                        ; 0afd     0e 04            ;  4 characters in "PLAY"
    jp nz,l0be8h                     ; 0aff     c2 e8 0b         ;  Not 0 ... do "normal" PLAY
    ld de,msg_play_upside_down       ; 0b02     11 fa 1c         ;  The "PLAy" with an upside down 'Y'
    call print_message_del           ; 0b05     cd 93 0a         ;  Print the "PLAy"
    ld de,msg_space_invaders         ; 0b08     11 af 1d         ;  "SPACE  INVADERS" message
l0b0bh:                                                         
    call print_to_mid_screen         ; 0b0b     cd cf 0a         ;  Print to middle-ish of screen
    call one_sec_delay               ; 0b0e     cd b1 0a         ;  One second delay
    call draw_adv_table              ; 0b11     cd 15 18         ;  Draw "SCORE ADVANCE TABLE" with print delay
    call two_sec_delay               ; 0b14     cd b6 0a         ;  Two second delay
    ld a,(splash_animate)            ; 0b17     3a ec 20         ;  Do splash ...
    and a                            ; 0b1a     a7               ;  ... animations?
    jp nz,l0b4ah                     ; 0b1b     c2 4a 0b         ;  Not 0 ... no animations
    ld de,splash_animation_struct_1  ; 0b1e     11 95 1a         ;  Animate sprite from Y=FE to Y=9E step -1
    call ini_splash_ani              ; 0b21     cd e2 0a         ;  Copy to splash-animate structure
    call animate                     ; 0b24     cd 80 0a         ;  Wait for ISR to move sprite (small alien)
    ld de,l1bb0h                     ; 0b27     11 b0 1b         ;  Animate sprite from Y=98 to Y=FF step 1
    call ini_splash_ani              ; 0b2a     cd e2 0a         ;  Copy to splash-animate structure
    call animate                     ; 0b2d     cd 80 0a         ;  Wait for ISR to move sprite (alien pulling upside down Y)
    call one_sec_delay               ; 0b30     cd b1 0a         ;  One second delay
    ld de,splash_animation_struct_3  ; 0b33     11 c9 1f         ;  Animate sprite from Y=FF to Y=97 step 1
    call ini_splash_ani              ; 0b36     cd e2 0a         ;  Copy to splash-animate structure
    call animate                     ; 0b39     cd 80 0a         ;  Wait for ISR to move sprite (alien pushing Y)
    call one_sec_delay               ; 0b3c     cd b1 0a         ;  One second delay
    ld hl,033b7h                     ; 0b3f     21 b7 33         ;  Where the splash alien ends up
    ld b,00ah                        ; 0b42     06 0a            ;  10 rows
    call clear_small_sprite          ; 0b44     cd cb 14         ;  Clear a one byte sprite at HL
    call two_sec_delay               ; 0b47     cd b6 0a         ;  Two second delay
l0b4ah:                                                         
    call clear_play_field            ; 0b4a     cd d6 09         ;  Clear playfield
    ld a,(p1ships_rem)               ; 0b4d     3a ff 21         ;  Number of ships for player-1
    and a                            ; 0b50     a7               ;  If non zero ...
    jp nz,l0b5dh                     ; 0b51     c2 5d 0b         ;  ... keep it (counts down between demos)
    call get_ships_per_cred          ; 0b54     cd d1 08         ;  Get number of ships from DIP settings
    ld (p1ships_rem),a               ; 0b57     32 ff 21         ;  Reset number of ships for player-1
    call remove_ship                 ; 0b5a     cd 7f 1a         ;  Remove a ship from stash and update indicators
l0b5dh:                                                         
    call copy_ram_mirror             ; 0b5d     cd e4 01         ;  Block copy ROM mirror to initialize RAM
    call init_aliens_player_one      ; 0b60     cd c0 01         ;  Initialize all player 1 aliens
    call draw_shield_pl1             ; 0b63     cd ef 01         ;  Draw shields for player 1 (to buffer)
    call restore_shields1            ; 0b66     cd 1a 02         ;  Restore shields for player 1 (to screen)
    ld a,001h                        ; 0b69     3e 01            ;  ISR splash-task ...
    ld (isr_splash_task),a           ; 0b6b     32 c1 20         ;  ... playing demo
    call draw_bottom_line            ; 0b6e     cd cf 01         ;  Draw playfield line
l0b71h:                                                         
    call plr_fire_or_demo            ; 0b71     cd 18 16         ;  In demo ... process demo movement and always fire
    call check_player_shot_bump_hid  ; 0b74     cd f1 0b         ;  Check player shot and aliens bumping edges of screen and hidden message
    out (006h),a                     ; 0b77     d3 06            ;  Feed watchdog
    call flag_player_hit             ; 0b79     cd 59 0a         ;  Has demo player been hit?
    jp z,l0b71h                      ; 0b7c     ca 71 0b         ;  No ... continue game
    xor a                            ; 0b7f     af               ;  Remove player shot ...
    ld (plyr_shot_status),a          ; 0b80     32 25 20         ;  ... from activity
l0b83h:                                                         
    call flag_player_hit             ; 0b83     cd 59 0a         ;  Wait for demo player ...
    jp nz,l0b83h                     ; 0b86     c2 83 0b         ;  ... to stop exploding
l0b89h:                                                         
    xor a                            ; 0b89     af               ;  Turn off ...
    ld (isr_splash_task),a           ; 0b8a     32 c1 20         ;  ... splash animation
    call one_sec_delay               ; 0b8d     cd b1 0a         ;  One second delay
    call clear_playfield_taito_msg   ; 0b90     cd 88 19         ;  ** Something else at one time? Jump straight to clear-play-field
    ld c,00ch                        ; 0b93     0e 0c            ;  Message size
    ld hl,02c11h                     ; 0b95     21 11 2c         ;  Screen coordinates
    ld de,msg_insert_coin            ; 0b98     11 90 1f         ;  "INSERT  COIN"
    call print_message               ; 0b9b     cd f3 08         ;  Print message
    ld a,(splash_animate)            ; 0b9e     3a ec 20         ;  Do splash ...
    cp 000h                          ; 0ba1     fe 00            ;  ... animations?
    jp nz,l0baeh                     ; 0ba3     c2 ae 0b         ;  Not 0 ... not on this screen
    ld hl,03311h                     ; 0ba6     21 11 33         ;  Screen coordinates
    ld a,002h                        ; 0ba9     3e 02            ;  Character "C"
    call draw_char                   ; 0bab     cd ff 08         ;  Put an extra "C" for "CCOIN" on the screen
l0baeh:                                                         
    ld bc,coord_msg_one_or_two_play  ; 0bae     01 9c 1f         ;  "<1 OR 2 PLAYERS>  "
    call read_print_struct           ; 0bb1     cd 56 18         ;  Load the screen,pointer
    call print_msg_slow              ; 0bb4     cd 4c 18         ;  Print the message
    in a,(002h)                      ; 0bb7     db 02            ;  Display coin info (bit 7) ...
    rlca                             ; 0bb9     07               ;  ... on demo screen?
    jp c,l0bc3h                      ; 0bba     da c3 0b         ;  1 means no ... skip it
    ld bc,coord_msg_one_play_one_coi ; 0bbd     01 a0 1f         ;  "*1 PLAYER  1 COIN "
    call slow_print_descrs           ; 0bc0     cd 3a 18         ;  Load the descriptor
l0bc3h:                                                         
    call two_sec_delay               ; 0bc3     cd b6 0a         ;  Print TWO descriptors worth
    ld a,(splash_animate)            ; 0bc6     3a ec 20         ;  Doing splash ...
    cp 000h                          ; 0bc9     fe 00            ;  ... animation?
    jp nz,l0bdah                     ; 0bcb     c2 da 0b         ;  Not 0 ... not on this screen
    ld de,splash_animation_struct_4  ; 0bce     11 d5 1f         ;  Animation for small alien to line up with extra "C"
    call ini_splash_ani              ; 0bd1     cd e2 0a         ;  Copy the animation block
    call animate                     ; 0bd4     cd 80 0a         ;  Wait for the animation to complete
    call sub_189eh                   ; 0bd7     cd 9e 18         ;  Animate alien shot to extra "C"
l0bdah:                                                         
    ld hl,splash_animate             ; 0bda     21 ec 20         ;  Toggle ...
    ld a,(hl)                        ; 0bdd     7e               ;  ... the ...
    inc a                            ; 0bde     3c               ;  ... splash screen ...
    and 001h                         ; 0bdf     e6 01            ;  ... animation for ...
    ld (hl),a                        ; 0be1     77               ;  ... next time
    call clear_play_field            ; 0be2     cd d6 09         ;  Clear play field
    jp l18dfh                        ; 0be5     c3 df 18         ;  Keep splashing

l0be8h:                                                         
    ld de,msg_play_normal            ; 0be8     11 ab 1d         ;  "PLAY" with normal 'Y'
    call print_message_del           ; 0beb     cd 93 0a         ;  Print it
    jp l0b0bh                        ; 0bee     c3 0b 0b         ;  Continue with splash (HL will be pointing to next message)

check_player_shot_bump_hid:                                                      
    call plyr_shot_and_bump          ; 0bf1     cd 0a 19         ;  Check if player is shot and aliens bumping the edge of screen
    jp check_hidden_mes              ; 0bf4     c3 9a 19         ;  Check for hidden-message display sequence
a_end:                                                          
                                                                
; BLOCK 'j' (start 0x0bf7 end 0x0c00)                           
msg_taito_cop:                                                        
    defb 013h                        ; 0bf7     13              
    defb 000h                        ; 0bf8     00              
    defb 008h                        ; 0bf9     08              
    defb 013h                        ; 0bfa     13              
    defb 00eh                        ; 0bfb     0e              
    defb 026h                        ; 0bfc     26              
    defb 002h                        ; 0bfd     02              
    defb 00eh                        ; 0bfe     0e              
    defb 00fh                        ; 0bff     0f              
j_end:                                                          
                                                                
; BLOCK 'b' (start 0x0c00 end 0x1000)                           
b_first:                                                        
    defb 000h                        ; 0c00     00              
    defb 000h                        ; 0c01     00              
    defb 000h                        ; 0c02     00              
    defb 000h                        ; 0c03     00              
    defb 000h                        ; 0c04     00              
    defb 000h                        ; 0c05     00              
    defb 000h                        ; 0c06     00              
    defb 000h                        ; 0c07     00              
    defb 000h                        ; 0c08     00              
    defb 000h                        ; 0c09     00              
    defb 000h                        ; 0c0a     00              
    defb 000h                        ; 0c0b     00              
    defb 000h                        ; 0c0c     00              
    defb 000h                        ; 0c0d     00              
    defb 000h                        ; 0c0e     00              
    defb 000h                        ; 0c0f     00              
    defb 000h                        ; 0c10     00              
    defb 000h                        ; 0c11     00              
    defb 000h                        ; 0c12     00              
    defb 000h                        ; 0c13     00              
    defb 000h                        ; 0c14     00              
    defb 000h                        ; 0c15     00              
    defb 000h                        ; 0c16     00              
    defb 000h                        ; 0c17     00              
    defb 000h                        ; 0c18     00              
    defb 000h                        ; 0c19     00              
    defb 000h                        ; 0c1a     00              
    defb 000h                        ; 0c1b     00              
    defb 000h                        ; 0c1c     00              
    defb 000h                        ; 0c1d     00              
    defb 000h                        ; 0c1e     00              
    defb 000h                        ; 0c1f     00              
    defb 000h                        ; 0c20     00              
    defb 000h                        ; 0c21     00              
    defb 000h                        ; 0c22     00              
    defb 000h                        ; 0c23     00              
    defb 000h                        ; 0c24     00              
    defb 000h                        ; 0c25     00              
    defb 000h                        ; 0c26     00              
    defb 000h                        ; 0c27     00              
    defb 000h                        ; 0c28     00              
    defb 000h                        ; 0c29     00              
    defb 000h                        ; 0c2a     00              
    defb 000h                        ; 0c2b     00              
    defb 000h                        ; 0c2c     00              
    defb 000h                        ; 0c2d     00              
    defb 000h                        ; 0c2e     00              
    defb 000h                        ; 0c2f     00              
    defb 000h                        ; 0c30     00              
    defb 000h                        ; 0c31     00              
    defb 000h                        ; 0c32     00              
    defb 000h                        ; 0c33     00              
    defb 000h                        ; 0c34     00              
    defb 000h                        ; 0c35     00              
    defb 000h                        ; 0c36     00              
    defb 000h                        ; 0c37     00              
    defb 000h                        ; 0c38     00              
    defb 000h                        ; 0c39     00              
    defb 000h                        ; 0c3a     00              
    defb 000h                        ; 0c3b     00              
    defb 000h                        ; 0c3c     00              
    defb 000h                        ; 0c3d     00              
    defb 000h                        ; 0c3e     00              
    defb 000h                        ; 0c3f     00              
    defb 000h                        ; 0c40     00              
    defb 000h                        ; 0c41     00              
    defb 000h                        ; 0c42     00              
    defb 000h                        ; 0c43     00              
    defb 000h                        ; 0c44     00              
    defb 000h                        ; 0c45     00              
    defb 000h                        ; 0c46     00              
    defb 000h                        ; 0c47     00              
    defb 000h                        ; 0c48     00              
    defb 000h                        ; 0c49     00              
    defb 000h                        ; 0c4a     00              
    defb 000h                        ; 0c4b     00              
    defb 000h                        ; 0c4c     00              
    defb 000h                        ; 0c4d     00              
    defb 000h                        ; 0c4e     00              
    defb 000h                        ; 0c4f     00              
    defb 000h                        ; 0c50     00              
    defb 000h                        ; 0c51     00              
    defb 000h                        ; 0c52     00              
    defb 000h                        ; 0c53     00              
    defb 000h                        ; 0c54     00              
    defb 000h                        ; 0c55     00              
    defb 000h                        ; 0c56     00              
    defb 000h                        ; 0c57     00              
    defb 000h                        ; 0c58     00              
    defb 000h                        ; 0c59     00              
    defb 000h                        ; 0c5a     00              
    defb 000h                        ; 0c5b     00              
    defb 000h                        ; 0c5c     00              
    defb 000h                        ; 0c5d     00              
    defb 000h                        ; 0c5e     00              
    defb 000h                        ; 0c5f     00              
    defb 000h                        ; 0c60     00              
    defb 000h                        ; 0c61     00              
    defb 000h                        ; 0c62     00              
    defb 000h                        ; 0c63     00              
    defb 000h                        ; 0c64     00              
    defb 000h                        ; 0c65     00              
    defb 000h                        ; 0c66     00              
    defb 000h                        ; 0c67     00              
    defb 000h                        ; 0c68     00              
    defb 000h                        ; 0c69     00              
    defb 000h                        ; 0c6a     00              
    defb 000h                        ; 0c6b     00              
    defb 000h                        ; 0c6c     00              
    defb 000h                        ; 0c6d     00              
    defb 000h                        ; 0c6e     00              
    defb 000h                        ; 0c6f     00              
    defb 000h                        ; 0c70     00              
    defb 000h                        ; 0c71     00              
    defb 000h                        ; 0c72     00              
    defb 000h                        ; 0c73     00              
    defb 000h                        ; 0c74     00              
    defb 000h                        ; 0c75     00              
    defb 000h                        ; 0c76     00              
    defb 000h                        ; 0c77     00              
    defb 000h                        ; 0c78     00              
    defb 000h                        ; 0c79     00              
    defb 000h                        ; 0c7a     00              
    defb 000h                        ; 0c7b     00              
    defb 000h                        ; 0c7c     00              
    defb 000h                        ; 0c7d     00              
    defb 000h                        ; 0c7e     00              
    defb 000h                        ; 0c7f     00              
    defb 000h                        ; 0c80     00              
    defb 000h                        ; 0c81     00              
    defb 000h                        ; 0c82     00              
    defb 000h                        ; 0c83     00              
    defb 000h                        ; 0c84     00              
    defb 000h                        ; 0c85     00              
    defb 000h                        ; 0c86     00              
    defb 000h                        ; 0c87     00              
    defb 000h                        ; 0c88     00              
    defb 000h                        ; 0c89     00              
    defb 000h                        ; 0c8a     00              
    defb 000h                        ; 0c8b     00              
    defb 000h                        ; 0c8c     00              
    defb 000h                        ; 0c8d     00              
    defb 000h                        ; 0c8e     00              
    defb 000h                        ; 0c8f     00              
    defb 000h                        ; 0c90     00              
    defb 000h                        ; 0c91     00              
    defb 000h                        ; 0c92     00              
    defb 000h                        ; 0c93     00              
    defb 000h                        ; 0c94     00              
    defb 000h                        ; 0c95     00              
    defb 000h                        ; 0c96     00              
    defb 000h                        ; 0c97     00              
    defb 000h                        ; 0c98     00              
    defb 000h                        ; 0c99     00              
    defb 000h                        ; 0c9a     00              
    defb 000h                        ; 0c9b     00              
    defb 000h                        ; 0c9c     00              
    defb 000h                        ; 0c9d     00              
    defb 000h                        ; 0c9e     00              
    defb 000h                        ; 0c9f     00              
    defb 000h                        ; 0ca0     00              
    defb 000h                        ; 0ca1     00              
    defb 000h                        ; 0ca2     00              
    defb 000h                        ; 0ca3     00              
    defb 000h                        ; 0ca4     00              
    defb 000h                        ; 0ca5     00              
    defb 000h                        ; 0ca6     00              
    defb 000h                        ; 0ca7     00              
    defb 000h                        ; 0ca8     00              
    defb 000h                        ; 0ca9     00              
    defb 000h                        ; 0caa     00              
    defb 000h                        ; 0cab     00              
    defb 000h                        ; 0cac     00              
    defb 000h                        ; 0cad     00              
    defb 000h                        ; 0cae     00              
    defb 000h                        ; 0caf     00              
    defb 000h                        ; 0cb0     00              
    defb 000h                        ; 0cb1     00              
    defb 000h                        ; 0cb2     00              
    defb 000h                        ; 0cb3     00              
    defb 000h                        ; 0cb4     00              
    defb 000h                        ; 0cb5     00              
    defb 000h                        ; 0cb6     00              
    defb 000h                        ; 0cb7     00              
    defb 000h                        ; 0cb8     00              
    defb 000h                        ; 0cb9     00              
    defb 000h                        ; 0cba     00              
    defb 000h                        ; 0cbb     00              
    defb 000h                        ; 0cbc     00              
    defb 000h                        ; 0cbd     00              
    defb 000h                        ; 0cbe     00              
    defb 000h                        ; 0cbf     00              
    defb 000h                        ; 0cc0     00              
    defb 000h                        ; 0cc1     00              
    defb 000h                        ; 0cc2     00              
    defb 000h                        ; 0cc3     00              
    defb 000h                        ; 0cc4     00              
    defb 000h                        ; 0cc5     00              
    defb 000h                        ; 0cc6     00              
    defb 000h                        ; 0cc7     00              
    defb 000h                        ; 0cc8     00              
    defb 000h                        ; 0cc9     00              
    defb 000h                        ; 0cca     00              
    defb 000h                        ; 0ccb     00              
    defb 000h                        ; 0ccc     00              
    defb 000h                        ; 0ccd     00              
    defb 000h                        ; 0cce     00              
    defb 000h                        ; 0ccf     00              
    defb 000h                        ; 0cd0     00              
    defb 000h                        ; 0cd1     00              
    defb 000h                        ; 0cd2     00              
    defb 000h                        ; 0cd3     00              
    defb 000h                        ; 0cd4     00              
    defb 000h                        ; 0cd5     00              
    defb 000h                        ; 0cd6     00              
    defb 000h                        ; 0cd7     00              
    defb 000h                        ; 0cd8     00              
    defb 000h                        ; 0cd9     00              
    defb 000h                        ; 0cda     00              
    defb 000h                        ; 0cdb     00              
    defb 000h                        ; 0cdc     00              
    defb 000h                        ; 0cdd     00              
    defb 000h                        ; 0cde     00              
    defb 000h                        ; 0cdf     00              
    defb 000h                        ; 0ce0     00              
    defb 000h                        ; 0ce1     00              
    defb 000h                        ; 0ce2     00              
    defb 000h                        ; 0ce3     00              
    defb 000h                        ; 0ce4     00              
    defb 000h                        ; 0ce5     00              
    defb 000h                        ; 0ce6     00              
    defb 000h                        ; 0ce7     00              
    defb 000h                        ; 0ce8     00              
    defb 000h                        ; 0ce9     00              
    defb 000h                        ; 0cea     00              
    defb 000h                        ; 0ceb     00              
    defb 000h                        ; 0cec     00              
    defb 000h                        ; 0ced     00              
    defb 000h                        ; 0cee     00              
    defb 000h                        ; 0cef     00              
    defb 000h                        ; 0cf0     00              
    defb 000h                        ; 0cf1     00              
    defb 000h                        ; 0cf2     00              
    defb 000h                        ; 0cf3     00              
    defb 000h                        ; 0cf4     00              
    defb 000h                        ; 0cf5     00              
    defb 000h                        ; 0cf6     00              
    defb 000h                        ; 0cf7     00              
    defb 000h                        ; 0cf8     00              
    defb 000h                        ; 0cf9     00              
    defb 000h                        ; 0cfa     00              
    defb 000h                        ; 0cfb     00              
    defb 000h                        ; 0cfc     00              
    defb 000h                        ; 0cfd     00              
    defb 000h                        ; 0cfe     00              
    defb 000h                        ; 0cff     00              
    defb 000h                        ; 0d00     00              
    defb 000h                        ; 0d01     00              
    defb 000h                        ; 0d02     00              
    defb 000h                        ; 0d03     00              
    defb 000h                        ; 0d04     00              
    defb 000h                        ; 0d05     00              
    defb 000h                        ; 0d06     00              
    defb 000h                        ; 0d07     00              
    defb 000h                        ; 0d08     00              
    defb 000h                        ; 0d09     00              
    defb 000h                        ; 0d0a     00              
    defb 000h                        ; 0d0b     00              
    defb 000h                        ; 0d0c     00              
    defb 000h                        ; 0d0d     00              
    defb 000h                        ; 0d0e     00              
    defb 000h                        ; 0d0f     00              
    defb 000h                        ; 0d10     00              
    defb 000h                        ; 0d11     00              
    defb 000h                        ; 0d12     00              
    defb 000h                        ; 0d13     00              
    defb 000h                        ; 0d14     00              
    defb 000h                        ; 0d15     00              
    defb 000h                        ; 0d16     00              
    defb 000h                        ; 0d17     00              
    defb 000h                        ; 0d18     00              
    defb 000h                        ; 0d19     00              
    defb 000h                        ; 0d1a     00              
    defb 000h                        ; 0d1b     00              
    defb 000h                        ; 0d1c     00              
    defb 000h                        ; 0d1d     00              
    defb 000h                        ; 0d1e     00              
    defb 000h                        ; 0d1f     00              
    defb 000h                        ; 0d20     00              
    defb 000h                        ; 0d21     00              
    defb 000h                        ; 0d22     00              
    defb 000h                        ; 0d23     00              
    defb 000h                        ; 0d24     00              
    defb 000h                        ; 0d25     00              
    defb 000h                        ; 0d26     00              
    defb 000h                        ; 0d27     00              
    defb 000h                        ; 0d28     00              
    defb 000h                        ; 0d29     00              
    defb 000h                        ; 0d2a     00              
    defb 000h                        ; 0d2b     00              
    defb 000h                        ; 0d2c     00              
    defb 000h                        ; 0d2d     00              
    defb 000h                        ; 0d2e     00              
    defb 000h                        ; 0d2f     00              
    defb 000h                        ; 0d30     00              
    defb 000h                        ; 0d31     00              
    defb 000h                        ; 0d32     00              
    defb 000h                        ; 0d33     00              
    defb 000h                        ; 0d34     00              
    defb 000h                        ; 0d35     00              
    defb 000h                        ; 0d36     00              
    defb 000h                        ; 0d37     00              
    defb 000h                        ; 0d38     00              
    defb 000h                        ; 0d39     00              
    defb 000h                        ; 0d3a     00              
    defb 000h                        ; 0d3b     00              
    defb 000h                        ; 0d3c     00              
    defb 000h                        ; 0d3d     00              
    defb 000h                        ; 0d3e     00              
    defb 000h                        ; 0d3f     00              
    defb 000h                        ; 0d40     00              
    defb 000h                        ; 0d41     00              
    defb 000h                        ; 0d42     00              
    defb 000h                        ; 0d43     00              
    defb 000h                        ; 0d44     00              
    defb 000h                        ; 0d45     00              
    defb 000h                        ; 0d46     00              
    defb 000h                        ; 0d47     00              
    defb 000h                        ; 0d48     00              
    defb 000h                        ; 0d49     00              
    defb 000h                        ; 0d4a     00              
    defb 000h                        ; 0d4b     00              
    defb 000h                        ; 0d4c     00              
    defb 000h                        ; 0d4d     00              
    defb 000h                        ; 0d4e     00              
    defb 000h                        ; 0d4f     00              
    defb 000h                        ; 0d50     00              
    defb 000h                        ; 0d51     00              
    defb 000h                        ; 0d52     00              
    defb 000h                        ; 0d53     00              
    defb 000h                        ; 0d54     00              
    defb 000h                        ; 0d55     00              
    defb 000h                        ; 0d56     00              
    defb 000h                        ; 0d57     00              
    defb 000h                        ; 0d58     00              
    defb 000h                        ; 0d59     00              
    defb 000h                        ; 0d5a     00              
    defb 000h                        ; 0d5b     00              
    defb 000h                        ; 0d5c     00              
    defb 000h                        ; 0d5d     00              
    defb 000h                        ; 0d5e     00              
    defb 000h                        ; 0d5f     00              
    defb 000h                        ; 0d60     00              
    defb 000h                        ; 0d61     00              
    defb 000h                        ; 0d62     00              
    defb 000h                        ; 0d63     00              
    defb 000h                        ; 0d64     00              
    defb 000h                        ; 0d65     00              
    defb 000h                        ; 0d66     00              
    defb 000h                        ; 0d67     00              
    defb 000h                        ; 0d68     00              
    defb 000h                        ; 0d69     00              
    defb 000h                        ; 0d6a     00              
    defb 000h                        ; 0d6b     00              
    defb 000h                        ; 0d6c     00              
    defb 000h                        ; 0d6d     00              
    defb 000h                        ; 0d6e     00              
    defb 000h                        ; 0d6f     00              
    defb 000h                        ; 0d70     00              
    defb 000h                        ; 0d71     00              
    defb 000h                        ; 0d72     00              
    defb 000h                        ; 0d73     00              
    defb 000h                        ; 0d74     00              
    defb 000h                        ; 0d75     00              
    defb 000h                        ; 0d76     00              
    defb 000h                        ; 0d77     00              
    defb 000h                        ; 0d78     00              
    defb 000h                        ; 0d79     00              
    defb 000h                        ; 0d7a     00              
    defb 000h                        ; 0d7b     00              
    defb 000h                        ; 0d7c     00              
    defb 000h                        ; 0d7d     00              
    defb 000h                        ; 0d7e     00              
    defb 000h                        ; 0d7f     00              
    defb 000h                        ; 0d80     00              
    defb 000h                        ; 0d81     00              
    defb 000h                        ; 0d82     00              
    defb 000h                        ; 0d83     00              
    defb 000h                        ; 0d84     00              
    defb 000h                        ; 0d85     00              
    defb 000h                        ; 0d86     00              
    defb 000h                        ; 0d87     00              
    defb 000h                        ; 0d88     00              
    defb 000h                        ; 0d89     00              
    defb 000h                        ; 0d8a     00              
    defb 000h                        ; 0d8b     00              
    defb 000h                        ; 0d8c     00              
    defb 000h                        ; 0d8d     00              
    defb 000h                        ; 0d8e     00              
    defb 000h                        ; 0d8f     00              
    defb 000h                        ; 0d90     00              
    defb 000h                        ; 0d91     00              
    defb 000h                        ; 0d92     00              
    defb 000h                        ; 0d93     00              
    defb 000h                        ; 0d94     00              
    defb 000h                        ; 0d95     00              
    defb 000h                        ; 0d96     00              
    defb 000h                        ; 0d97     00              
    defb 000h                        ; 0d98     00              
    defb 000h                        ; 0d99     00              
    defb 000h                        ; 0d9a     00              
    defb 000h                        ; 0d9b     00              
    defb 000h                        ; 0d9c     00              
    defb 000h                        ; 0d9d     00              
    defb 000h                        ; 0d9e     00              
    defb 000h                        ; 0d9f     00              
    defb 000h                        ; 0da0     00              
    defb 000h                        ; 0da1     00              
    defb 000h                        ; 0da2     00              
    defb 000h                        ; 0da3     00              
    defb 000h                        ; 0da4     00              
    defb 000h                        ; 0da5     00              
    defb 000h                        ; 0da6     00              
    defb 000h                        ; 0da7     00              
    defb 000h                        ; 0da8     00              
    defb 000h                        ; 0da9     00              
    defb 000h                        ; 0daa     00              
    defb 000h                        ; 0dab     00              
    defb 000h                        ; 0dac     00              
    defb 000h                        ; 0dad     00              
    defb 000h                        ; 0dae     00              
    defb 000h                        ; 0daf     00              
    defb 000h                        ; 0db0     00              
    defb 000h                        ; 0db1     00              
    defb 000h                        ; 0db2     00              
    defb 000h                        ; 0db3     00              
    defb 000h                        ; 0db4     00              
    defb 000h                        ; 0db5     00              
    defb 000h                        ; 0db6     00              
    defb 000h                        ; 0db7     00              
    defb 000h                        ; 0db8     00              
    defb 000h                        ; 0db9     00              
    defb 000h                        ; 0dba     00              
    defb 000h                        ; 0dbb     00              
    defb 000h                        ; 0dbc     00              
    defb 000h                        ; 0dbd     00              
    defb 000h                        ; 0dbe     00              
    defb 000h                        ; 0dbf     00              
    defb 000h                        ; 0dc0     00              
    defb 000h                        ; 0dc1     00              
    defb 000h                        ; 0dc2     00              
    defb 000h                        ; 0dc3     00              
    defb 000h                        ; 0dc4     00              
    defb 000h                        ; 0dc5     00              
    defb 000h                        ; 0dc6     00              
    defb 000h                        ; 0dc7     00              
    defb 000h                        ; 0dc8     00              
    defb 000h                        ; 0dc9     00              
    defb 000h                        ; 0dca     00              
    defb 000h                        ; 0dcb     00              
    defb 000h                        ; 0dcc     00              
    defb 000h                        ; 0dcd     00              
    defb 000h                        ; 0dce     00              
    defb 000h                        ; 0dcf     00              
    defb 000h                        ; 0dd0     00              
    defb 000h                        ; 0dd1     00              
    defb 000h                        ; 0dd2     00              
    defb 000h                        ; 0dd3     00              
    defb 000h                        ; 0dd4     00              
    defb 000h                        ; 0dd5     00              
    defb 000h                        ; 0dd6     00              
    defb 000h                        ; 0dd7     00              
    defb 000h                        ; 0dd8     00              
    defb 000h                        ; 0dd9     00              
    defb 000h                        ; 0dda     00              
    defb 000h                        ; 0ddb     00              
    defb 000h                        ; 0ddc     00              
    defb 000h                        ; 0ddd     00              
    defb 000h                        ; 0dde     00              
    defb 000h                        ; 0ddf     00              
    defb 000h                        ; 0de0     00              
    defb 000h                        ; 0de1     00              
    defb 000h                        ; 0de2     00              
    defb 000h                        ; 0de3     00              
    defb 000h                        ; 0de4     00              
    defb 000h                        ; 0de5     00              
    defb 000h                        ; 0de6     00              
    defb 000h                        ; 0de7     00              
    defb 000h                        ; 0de8     00              
    defb 000h                        ; 0de9     00              
    defb 000h                        ; 0dea     00              
    defb 000h                        ; 0deb     00              
    defb 000h                        ; 0dec     00              
    defb 000h                        ; 0ded     00              
    defb 000h                        ; 0dee     00              
    defb 000h                        ; 0def     00              
    defb 000h                        ; 0df0     00              
    defb 000h                        ; 0df1     00              
    defb 000h                        ; 0df2     00              
    defb 000h                        ; 0df3     00              
    defb 000h                        ; 0df4     00              
    defb 000h                        ; 0df5     00              
    defb 000h                        ; 0df6     00              
    defb 000h                        ; 0df7     00              
    defb 000h                        ; 0df8     00              
    defb 000h                        ; 0df9     00              
    defb 000h                        ; 0dfa     00              
    defb 000h                        ; 0dfb     00              
    defb 000h                        ; 0dfc     00              
    defb 000h                        ; 0dfd     00              
    defb 000h                        ; 0dfe     00              
    defb 000h                        ; 0dff     00              
    defb 000h                        ; 0e00     00              
    defb 000h                        ; 0e01     00              
    defb 000h                        ; 0e02     00              
    defb 000h                        ; 0e03     00              
    defb 000h                        ; 0e04     00              
    defb 000h                        ; 0e05     00              
    defb 000h                        ; 0e06     00              
    defb 000h                        ; 0e07     00              
    defb 000h                        ; 0e08     00              
    defb 000h                        ; 0e09     00              
    defb 000h                        ; 0e0a     00              
    defb 000h                        ; 0e0b     00              
    defb 000h                        ; 0e0c     00              
    defb 000h                        ; 0e0d     00              
    defb 000h                        ; 0e0e     00              
    defb 000h                        ; 0e0f     00              
    defb 000h                        ; 0e10     00              
    defb 000h                        ; 0e11     00              
    defb 000h                        ; 0e12     00              
    defb 000h                        ; 0e13     00              
    defb 000h                        ; 0e14     00              
    defb 000h                        ; 0e15     00              
    defb 000h                        ; 0e16     00              
    defb 000h                        ; 0e17     00              
    defb 000h                        ; 0e18     00              
    defb 000h                        ; 0e19     00              
    defb 000h                        ; 0e1a     00              
    defb 000h                        ; 0e1b     00              
    defb 000h                        ; 0e1c     00              
    defb 000h                        ; 0e1d     00              
    defb 000h                        ; 0e1e     00              
    defb 000h                        ; 0e1f     00              
    defb 000h                        ; 0e20     00              
    defb 000h                        ; 0e21     00              
    defb 000h                        ; 0e22     00              
    defb 000h                        ; 0e23     00              
    defb 000h                        ; 0e24     00              
    defb 000h                        ; 0e25     00              
    defb 000h                        ; 0e26     00              
    defb 000h                        ; 0e27     00              
    defb 000h                        ; 0e28     00              
    defb 000h                        ; 0e29     00              
    defb 000h                        ; 0e2a     00              
    defb 000h                        ; 0e2b     00              
    defb 000h                        ; 0e2c     00              
    defb 000h                        ; 0e2d     00              
    defb 000h                        ; 0e2e     00              
    defb 000h                        ; 0e2f     00              
    defb 000h                        ; 0e30     00              
    defb 000h                        ; 0e31     00              
    defb 000h                        ; 0e32     00              
    defb 000h                        ; 0e33     00              
    defb 000h                        ; 0e34     00              
    defb 000h                        ; 0e35     00              
    defb 000h                        ; 0e36     00              
    defb 000h                        ; 0e37     00              
    defb 000h                        ; 0e38     00              
    defb 000h                        ; 0e39     00              
    defb 000h                        ; 0e3a     00              
    defb 000h                        ; 0e3b     00              
    defb 000h                        ; 0e3c     00              
    defb 000h                        ; 0e3d     00              
    defb 000h                        ; 0e3e     00              
    defb 000h                        ; 0e3f     00              
    defb 000h                        ; 0e40     00              
    defb 000h                        ; 0e41     00              
    defb 000h                        ; 0e42     00              
    defb 000h                        ; 0e43     00              
    defb 000h                        ; 0e44     00              
    defb 000h                        ; 0e45     00              
    defb 000h                        ; 0e46     00              
    defb 000h                        ; 0e47     00              
    defb 000h                        ; 0e48     00              
    defb 000h                        ; 0e49     00              
    defb 000h                        ; 0e4a     00              
    defb 000h                        ; 0e4b     00              
    defb 000h                        ; 0e4c     00              
    defb 000h                        ; 0e4d     00              
    defb 000h                        ; 0e4e     00              
    defb 000h                        ; 0e4f     00              
    defb 000h                        ; 0e50     00              
    defb 000h                        ; 0e51     00              
    defb 000h                        ; 0e52     00              
    defb 000h                        ; 0e53     00              
    defb 000h                        ; 0e54     00              
    defb 000h                        ; 0e55     00              
    defb 000h                        ; 0e56     00              
    defb 000h                        ; 0e57     00              
    defb 000h                        ; 0e58     00              
    defb 000h                        ; 0e59     00              
    defb 000h                        ; 0e5a     00              
    defb 000h                        ; 0e5b     00              
    defb 000h                        ; 0e5c     00              
    defb 000h                        ; 0e5d     00              
    defb 000h                        ; 0e5e     00              
    defb 000h                        ; 0e5f     00              
    defb 000h                        ; 0e60     00              
    defb 000h                        ; 0e61     00              
    defb 000h                        ; 0e62     00              
    defb 000h                        ; 0e63     00              
    defb 000h                        ; 0e64     00              
    defb 000h                        ; 0e65     00              
    defb 000h                        ; 0e66     00              
    defb 000h                        ; 0e67     00              
    defb 000h                        ; 0e68     00              
    defb 000h                        ; 0e69     00              
    defb 000h                        ; 0e6a     00              
    defb 000h                        ; 0e6b     00              
    defb 000h                        ; 0e6c     00              
    defb 000h                        ; 0e6d     00              
    defb 000h                        ; 0e6e     00              
    defb 000h                        ; 0e6f     00              
    defb 000h                        ; 0e70     00              
    defb 000h                        ; 0e71     00              
    defb 000h                        ; 0e72     00              
    defb 000h                        ; 0e73     00              
    defb 000h                        ; 0e74     00              
    defb 000h                        ; 0e75     00              
    defb 000h                        ; 0e76     00              
    defb 000h                        ; 0e77     00              
    defb 000h                        ; 0e78     00              
    defb 000h                        ; 0e79     00              
    defb 000h                        ; 0e7a     00              
    defb 000h                        ; 0e7b     00              
    defb 000h                        ; 0e7c     00              
    defb 000h                        ; 0e7d     00              
    defb 000h                        ; 0e7e     00              
    defb 000h                        ; 0e7f     00              
    defb 000h                        ; 0e80     00              
    defb 000h                        ; 0e81     00              
    defb 000h                        ; 0e82     00              
    defb 000h                        ; 0e83     00              
    defb 000h                        ; 0e84     00              
    defb 000h                        ; 0e85     00              
    defb 000h                        ; 0e86     00              
    defb 000h                        ; 0e87     00              
    defb 000h                        ; 0e88     00              
    defb 000h                        ; 0e89     00              
    defb 000h                        ; 0e8a     00              
    defb 000h                        ; 0e8b     00              
    defb 000h                        ; 0e8c     00              
    defb 000h                        ; 0e8d     00              
    defb 000h                        ; 0e8e     00              
    defb 000h                        ; 0e8f     00              
    defb 000h                        ; 0e90     00              
    defb 000h                        ; 0e91     00              
    defb 000h                        ; 0e92     00              
    defb 000h                        ; 0e93     00              
    defb 000h                        ; 0e94     00              
    defb 000h                        ; 0e95     00              
    defb 000h                        ; 0e96     00              
    defb 000h                        ; 0e97     00              
    defb 000h                        ; 0e98     00              
    defb 000h                        ; 0e99     00              
    defb 000h                        ; 0e9a     00              
    defb 000h                        ; 0e9b     00              
    defb 000h                        ; 0e9c     00              
    defb 000h                        ; 0e9d     00              
    defb 000h                        ; 0e9e     00              
    defb 000h                        ; 0e9f     00              
    defb 000h                        ; 0ea0     00              
    defb 000h                        ; 0ea1     00              
    defb 000h                        ; 0ea2     00              
    defb 000h                        ; 0ea3     00              
    defb 000h                        ; 0ea4     00              
    defb 000h                        ; 0ea5     00              
    defb 000h                        ; 0ea6     00              
    defb 000h                        ; 0ea7     00              
    defb 000h                        ; 0ea8     00              
    defb 000h                        ; 0ea9     00              
    defb 000h                        ; 0eaa     00              
    defb 000h                        ; 0eab     00              
    defb 000h                        ; 0eac     00              
    defb 000h                        ; 0ead     00              
    defb 000h                        ; 0eae     00              
    defb 000h                        ; 0eaf     00              
    defb 000h                        ; 0eb0     00              
    defb 000h                        ; 0eb1     00              
    defb 000h                        ; 0eb2     00              
    defb 000h                        ; 0eb3     00              
    defb 000h                        ; 0eb4     00              
    defb 000h                        ; 0eb5     00              
    defb 000h                        ; 0eb6     00              
    defb 000h                        ; 0eb7     00              
    defb 000h                        ; 0eb8     00              
    defb 000h                        ; 0eb9     00              
    defb 000h                        ; 0eba     00              
    defb 000h                        ; 0ebb     00              
    defb 000h                        ; 0ebc     00              
    defb 000h                        ; 0ebd     00              
    defb 000h                        ; 0ebe     00              
    defb 000h                        ; 0ebf     00              
    defb 000h                        ; 0ec0     00              
    defb 000h                        ; 0ec1     00              
    defb 000h                        ; 0ec2     00              
    defb 000h                        ; 0ec3     00              
    defb 000h                        ; 0ec4     00              
    defb 000h                        ; 0ec5     00              
    defb 000h                        ; 0ec6     00              
    defb 000h                        ; 0ec7     00              
    defb 000h                        ; 0ec8     00              
    defb 000h                        ; 0ec9     00              
    defb 000h                        ; 0eca     00              
    defb 000h                        ; 0ecb     00              
    defb 000h                        ; 0ecc     00              
    defb 000h                        ; 0ecd     00              
    defb 000h                        ; 0ece     00              
    defb 000h                        ; 0ecf     00              
    defb 000h                        ; 0ed0     00              
    defb 000h                        ; 0ed1     00              
    defb 000h                        ; 0ed2     00              
    defb 000h                        ; 0ed3     00              
    defb 000h                        ; 0ed4     00              
    defb 000h                        ; 0ed5     00              
    defb 000h                        ; 0ed6     00              
    defb 000h                        ; 0ed7     00              
    defb 000h                        ; 0ed8     00              
    defb 000h                        ; 0ed9     00              
    defb 000h                        ; 0eda     00              
    defb 000h                        ; 0edb     00              
    defb 000h                        ; 0edc     00              
    defb 000h                        ; 0edd     00              
    defb 000h                        ; 0ede     00              
    defb 000h                        ; 0edf     00              
    defb 000h                        ; 0ee0     00              
    defb 000h                        ; 0ee1     00              
    defb 000h                        ; 0ee2     00              
    defb 000h                        ; 0ee3     00              
    defb 000h                        ; 0ee4     00              
    defb 000h                        ; 0ee5     00              
    defb 000h                        ; 0ee6     00              
    defb 000h                        ; 0ee7     00              
    defb 000h                        ; 0ee8     00              
    defb 000h                        ; 0ee9     00              
    defb 000h                        ; 0eea     00              
    defb 000h                        ; 0eeb     00              
    defb 000h                        ; 0eec     00              
    defb 000h                        ; 0eed     00              
    defb 000h                        ; 0eee     00              
    defb 000h                        ; 0eef     00              
    defb 000h                        ; 0ef0     00              
    defb 000h                        ; 0ef1     00              
    defb 000h                        ; 0ef2     00              
    defb 000h                        ; 0ef3     00              
    defb 000h                        ; 0ef4     00              
    defb 000h                        ; 0ef5     00              
    defb 000h                        ; 0ef6     00              
    defb 000h                        ; 0ef7     00              
    defb 000h                        ; 0ef8     00              
    defb 000h                        ; 0ef9     00              
    defb 000h                        ; 0efa     00              
    defb 000h                        ; 0efb     00              
    defb 000h                        ; 0efc     00              
    defb 000h                        ; 0efd     00              
    defb 000h                        ; 0efe     00              
    defb 000h                        ; 0eff     00              
    defb 000h                        ; 0f00     00              
    defb 000h                        ; 0f01     00              
    defb 000h                        ; 0f02     00              
    defb 000h                        ; 0f03     00              
    defb 000h                        ; 0f04     00              
    defb 000h                        ; 0f05     00              
    defb 000h                        ; 0f06     00              
    defb 000h                        ; 0f07     00              
    defb 000h                        ; 0f08     00              
    defb 000h                        ; 0f09     00              
    defb 000h                        ; 0f0a     00              
    defb 000h                        ; 0f0b     00              
    defb 000h                        ; 0f0c     00              
    defb 000h                        ; 0f0d     00              
    defb 000h                        ; 0f0e     00              
    defb 000h                        ; 0f0f     00              
    defb 000h                        ; 0f10     00              
    defb 000h                        ; 0f11     00              
    defb 000h                        ; 0f12     00              
    defb 000h                        ; 0f13     00              
    defb 000h                        ; 0f14     00              
    defb 000h                        ; 0f15     00              
    defb 000h                        ; 0f16     00              
    defb 000h                        ; 0f17     00              
    defb 000h                        ; 0f18     00              
    defb 000h                        ; 0f19     00              
    defb 000h                        ; 0f1a     00              
    defb 000h                        ; 0f1b     00              
    defb 000h                        ; 0f1c     00              
    defb 000h                        ; 0f1d     00              
    defb 000h                        ; 0f1e     00              
    defb 000h                        ; 0f1f     00              
    defb 000h                        ; 0f20     00              
    defb 000h                        ; 0f21     00              
    defb 000h                        ; 0f22     00              
    defb 000h                        ; 0f23     00              
    defb 000h                        ; 0f24     00              
    defb 000h                        ; 0f25     00              
    defb 000h                        ; 0f26     00              
    defb 000h                        ; 0f27     00              
    defb 000h                        ; 0f28     00              
    defb 000h                        ; 0f29     00              
    defb 000h                        ; 0f2a     00              
    defb 000h                        ; 0f2b     00              
    defb 000h                        ; 0f2c     00              
    defb 000h                        ; 0f2d     00              
    defb 000h                        ; 0f2e     00              
    defb 000h                        ; 0f2f     00              
    defb 000h                        ; 0f30     00              
    defb 000h                        ; 0f31     00              
    defb 000h                        ; 0f32     00              
    defb 000h                        ; 0f33     00              
    defb 000h                        ; 0f34     00              
    defb 000h                        ; 0f35     00              
    defb 000h                        ; 0f36     00              
    defb 000h                        ; 0f37     00              
    defb 000h                        ; 0f38     00              
    defb 000h                        ; 0f39     00              
    defb 000h                        ; 0f3a     00              
    defb 000h                        ; 0f3b     00              
    defb 000h                        ; 0f3c     00              
    defb 000h                        ; 0f3d     00              
    defb 000h                        ; 0f3e     00              
    defb 000h                        ; 0f3f     00              
    defb 000h                        ; 0f40     00              
    defb 000h                        ; 0f41     00              
    defb 000h                        ; 0f42     00              
    defb 000h                        ; 0f43     00              
    defb 000h                        ; 0f44     00              
    defb 000h                        ; 0f45     00              
    defb 000h                        ; 0f46     00              
    defb 000h                        ; 0f47     00              
    defb 000h                        ; 0f48     00              
    defb 000h                        ; 0f49     00              
    defb 000h                        ; 0f4a     00              
    defb 000h                        ; 0f4b     00              
    defb 000h                        ; 0f4c     00              
    defb 000h                        ; 0f4d     00              
    defb 000h                        ; 0f4e     00              
    defb 000h                        ; 0f4f     00              
    defb 000h                        ; 0f50     00              
    defb 000h                        ; 0f51     00              
    defb 000h                        ; 0f52     00              
    defb 000h                        ; 0f53     00              
    defb 000h                        ; 0f54     00              
    defb 000h                        ; 0f55     00              
    defb 000h                        ; 0f56     00              
    defb 000h                        ; 0f57     00              
    defb 000h                        ; 0f58     00              
    defb 000h                        ; 0f59     00              
    defb 000h                        ; 0f5a     00              
    defb 000h                        ; 0f5b     00              
    defb 000h                        ; 0f5c     00              
    defb 000h                        ; 0f5d     00              
    defb 000h                        ; 0f5e     00              
    defb 000h                        ; 0f5f     00              
    defb 000h                        ; 0f60     00              
    defb 000h                        ; 0f61     00              
    defb 000h                        ; 0f62     00              
    defb 000h                        ; 0f63     00              
    defb 000h                        ; 0f64     00              
    defb 000h                        ; 0f65     00              
    defb 000h                        ; 0f66     00              
    defb 000h                        ; 0f67     00              
    defb 000h                        ; 0f68     00              
    defb 000h                        ; 0f69     00              
    defb 000h                        ; 0f6a     00              
    defb 000h                        ; 0f6b     00              
    defb 000h                        ; 0f6c     00              
    defb 000h                        ; 0f6d     00              
    defb 000h                        ; 0f6e     00              
    defb 000h                        ; 0f6f     00              
    defb 000h                        ; 0f70     00              
    defb 000h                        ; 0f71     00              
    defb 000h                        ; 0f72     00              
    defb 000h                        ; 0f73     00              
    defb 000h                        ; 0f74     00              
    defb 000h                        ; 0f75     00              
    defb 000h                        ; 0f76     00              
    defb 000h                        ; 0f77     00              
    defb 000h                        ; 0f78     00              
    defb 000h                        ; 0f79     00              
    defb 000h                        ; 0f7a     00              
    defb 000h                        ; 0f7b     00              
    defb 000h                        ; 0f7c     00              
    defb 000h                        ; 0f7d     00              
    defb 000h                        ; 0f7e     00              
    defb 000h                        ; 0f7f     00              
    defb 000h                        ; 0f80     00              
    defb 000h                        ; 0f81     00              
    defb 000h                        ; 0f82     00              
    defb 000h                        ; 0f83     00              
    defb 000h                        ; 0f84     00              
    defb 000h                        ; 0f85     00              
    defb 000h                        ; 0f86     00              
    defb 000h                        ; 0f87     00              
    defb 000h                        ; 0f88     00              
    defb 000h                        ; 0f89     00              
    defb 000h                        ; 0f8a     00              
    defb 000h                        ; 0f8b     00              
    defb 000h                        ; 0f8c     00              
    defb 000h                        ; 0f8d     00              
    defb 000h                        ; 0f8e     00              
    defb 000h                        ; 0f8f     00              
    defb 000h                        ; 0f90     00              
    defb 000h                        ; 0f91     00              
    defb 000h                        ; 0f92     00              
    defb 000h                        ; 0f93     00              
    defb 000h                        ; 0f94     00              
    defb 000h                        ; 0f95     00              
    defb 000h                        ; 0f96     00              
    defb 000h                        ; 0f97     00              
    defb 000h                        ; 0f98     00              
    defb 000h                        ; 0f99     00              
    defb 000h                        ; 0f9a     00              
    defb 000h                        ; 0f9b     00              
    defb 000h                        ; 0f9c     00              
    defb 000h                        ; 0f9d     00              
    defb 000h                        ; 0f9e     00              
    defb 000h                        ; 0f9f     00              
    defb 000h                        ; 0fa0     00              
    defb 000h                        ; 0fa1     00              
    defb 000h                        ; 0fa2     00              
    defb 000h                        ; 0fa3     00              
    defb 000h                        ; 0fa4     00              
    defb 000h                        ; 0fa5     00              
    defb 000h                        ; 0fa6     00              
    defb 000h                        ; 0fa7     00              
    defb 000h                        ; 0fa8     00              
    defb 000h                        ; 0fa9     00              
    defb 000h                        ; 0faa     00              
    defb 000h                        ; 0fab     00              
    defb 000h                        ; 0fac     00              
    defb 000h                        ; 0fad     00              
    defb 000h                        ; 0fae     00              
    defb 000h                        ; 0faf     00              
    defb 000h                        ; 0fb0     00              
    defb 000h                        ; 0fb1     00              
    defb 000h                        ; 0fb2     00              
    defb 000h                        ; 0fb3     00              
    defb 000h                        ; 0fb4     00              
    defb 000h                        ; 0fb5     00              
    defb 000h                        ; 0fb6     00              
    defb 000h                        ; 0fb7     00              
    defb 000h                        ; 0fb8     00              
    defb 000h                        ; 0fb9     00              
    defb 000h                        ; 0fba     00              
    defb 000h                        ; 0fbb     00              
    defb 000h                        ; 0fbc     00              
    defb 000h                        ; 0fbd     00              
    defb 000h                        ; 0fbe     00              
    defb 000h                        ; 0fbf     00              
    defb 000h                        ; 0fc0     00              
    defb 000h                        ; 0fc1     00              
    defb 000h                        ; 0fc2     00              
    defb 000h                        ; 0fc3     00              
    defb 000h                        ; 0fc4     00              
    defb 000h                        ; 0fc5     00              
    defb 000h                        ; 0fc6     00              
    defb 000h                        ; 0fc7     00              
    defb 000h                        ; 0fc8     00              
    defb 000h                        ; 0fc9     00              
    defb 000h                        ; 0fca     00              
    defb 000h                        ; 0fcb     00              
    defb 000h                        ; 0fcc     00              
    defb 000h                        ; 0fcd     00              
    defb 000h                        ; 0fce     00              
    defb 000h                        ; 0fcf     00              
    defb 000h                        ; 0fd0     00              
    defb 000h                        ; 0fd1     00              
    defb 000h                        ; 0fd2     00              
    defb 000h                        ; 0fd3     00              
    defb 000h                        ; 0fd4     00              
    defb 000h                        ; 0fd5     00              
    defb 000h                        ; 0fd6     00              
    defb 000h                        ; 0fd7     00              
    defb 000h                        ; 0fd8     00              
    defb 000h                        ; 0fd9     00              
    defb 000h                        ; 0fda     00              
    defb 000h                        ; 0fdb     00              
    defb 000h                        ; 0fdc     00              
    defb 000h                        ; 0fdd     00              
    defb 000h                        ; 0fde     00              
    defb 000h                        ; 0fdf     00              
    defb 000h                        ; 0fe0     00              
    defb 000h                        ; 0fe1     00              
    defb 000h                        ; 0fe2     00              
    defb 000h                        ; 0fe3     00              
    defb 000h                        ; 0fe4     00              
    defb 000h                        ; 0fe5     00              
    defb 000h                        ; 0fe6     00              
    defb 000h                        ; 0fe7     00              
    defb 000h                        ; 0fe8     00              
    defb 000h                        ; 0fe9     00              
    defb 000h                        ; 0fea     00              
    defb 000h                        ; 0feb     00              
    defb 000h                        ; 0fec     00              
    defb 000h                        ; 0fed     00              
    defb 000h                        ; 0fee     00              
    defb 000h                        ; 0fef     00              
    defb 000h                        ; 0ff0     00              
    defb 000h                        ; 0ff1     00              
    defb 000h                        ; 0ff2     00              
    defb 000h                        ; 0ff3     00              
    defb 000h                        ; 0ff4     00              
    defb 000h                        ; 0ff5     00              
    defb 000h                        ; 0ff6     00              
    defb 000h                        ; 0ff7     00              
    defb 000h                        ; 0ff8     00              
    defb 000h                        ; 0ff9     00              
    defb 000h                        ; 0ffa     00              
    defb 000h                        ; 0ffb     00              
    defb 000h                        ; 0ffc     00              
    defb 000h                        ; 0ffd     00              
    defb 000h                        ; 0ffe     00              
    defb 000h                        ; 0fff     00              
b_end:                                                          
                                                                
; BLOCK 'c' (start 0x1000 end 0x1400)                           
c_first:                                                        
    defb 000h                        ; 1000     00               ;  Three bytes for ...
    defb 000h                        ; 1001     00               ;  ... development code ...
    defb 000h                        ; 1002     00               ;  ... jump opcode
    defb 000h                        ; 1003     00               ;  Turn off ...
    defb 000h                        ; 1004     00               ;  ... sound effects (AMP ENABLE bit 5)
    defb 000h                        ; 1005     00              
    defb 000h                        ; 1006     00              
    defb 000h                        ; 1007     00              
    defb 000h                        ; 1008     00              
    defb 000h                        ; 1009     00              
    defb 000h                        ; 100a     00              
    defb 000h                        ; 100b     00              
    defb 000h                        ; 100c     00              
    defb 000h                        ; 100d     00              
    defb 000h                        ; 100e     00              
    defb 000h                        ; 100f     00              
    defb 000h                        ; 1010     00              
    defb 000h                        ; 1011     00              
    defb 000h                        ; 1012     00              
    defb 000h                        ; 1013     00              
    defb 000h                        ; 1014     00              
    defb 000h                        ; 1015     00              
    defb 000h                        ; 1016     00              
    defb 000h                        ; 1017     00              
    defb 000h                        ; 1018     00              
    defb 000h                        ; 1019     00              
    defb 000h                        ; 101a     00              
    defb 000h                        ; 101b     00              
    defb 000h                        ; 101c     00              
    defb 000h                        ; 101d     00              
    defb 000h                        ; 101e     00              
    defb 000h                        ; 101f     00              
    defb 000h                        ; 1020     00              
    defb 000h                        ; 1021     00              
    defb 000h                        ; 1022     00              
    defb 000h                        ; 1023     00              
    defb 000h                        ; 1024     00              
    defb 000h                        ; 1025     00              
    defb 000h                        ; 1026     00              
    defb 000h                        ; 1027     00              
    defb 000h                        ; 1028     00              
    defb 000h                        ; 1029     00              
    defb 000h                        ; 102a     00              
    defb 000h                        ; 102b     00              
    defb 000h                        ; 102c     00              
    defb 000h                        ; 102d     00              
    defb 000h                        ; 102e     00              
    defb 000h                        ; 102f     00              
    defb 000h                        ; 1030     00              
    defb 000h                        ; 1031     00              
    defb 000h                        ; 1032     00              
    defb 000h                        ; 1033     00              
    defb 000h                        ; 1034     00              
    defb 000h                        ; 1035     00              
    defb 000h                        ; 1036     00              
    defb 000h                        ; 1037     00              
    defb 000h                        ; 1038     00              
    defb 000h                        ; 1039     00              
    defb 000h                        ; 103a     00              
    defb 000h                        ; 103b     00              
    defb 000h                        ; 103c     00              
    defb 000h                        ; 103d     00              
    defb 000h                        ; 103e     00              
    defb 000h                        ; 103f     00              
    defb 000h                        ; 1040     00              
    defb 000h                        ; 1041     00              
    defb 000h                        ; 1042     00              
    defb 000h                        ; 1043     00              
    defb 000h                        ; 1044     00              
    defb 000h                        ; 1045     00              
    defb 000h                        ; 1046     00              
    defb 000h                        ; 1047     00              
    defb 000h                        ; 1048     00              
    defb 000h                        ; 1049     00              
    defb 000h                        ; 104a     00              
    defb 000h                        ; 104b     00              
    defb 000h                        ; 104c     00              
    defb 000h                        ; 104d     00              
    defb 000h                        ; 104e     00              
    defb 000h                        ; 104f     00              
    defb 000h                        ; 1050     00              
    defb 000h                        ; 1051     00              
    defb 000h                        ; 1052     00              
    defb 000h                        ; 1053     00              
    defb 000h                        ; 1054     00              
    defb 000h                        ; 1055     00              
    defb 000h                        ; 1056     00              
    defb 000h                        ; 1057     00              
    defb 000h                        ; 1058     00              
    defb 000h                        ; 1059     00              
    defb 000h                        ; 105a     00              
    defb 000h                        ; 105b     00              
    defb 000h                        ; 105c     00              
    defb 000h                        ; 105d     00              
    defb 000h                        ; 105e     00              
    defb 000h                        ; 105f     00              
    defb 000h                        ; 1060     00              
    defb 000h                        ; 1061     00              
    defb 000h                        ; 1062     00              
    defb 000h                        ; 1063     00              
    defb 000h                        ; 1064     00              
    defb 000h                        ; 1065     00              
    defb 000h                        ; 1066     00              
    defb 000h                        ; 1067     00              
    defb 000h                        ; 1068     00              
    defb 000h                        ; 1069     00              
    defb 000h                        ; 106a     00              
    defb 000h                        ; 106b     00              
    defb 000h                        ; 106c     00              
    defb 000h                        ; 106d     00              
    defb 000h                        ; 106e     00              
    defb 000h                        ; 106f     00              
    defb 000h                        ; 1070     00              
    defb 000h                        ; 1071     00              
    defb 000h                        ; 1072     00              
    defb 000h                        ; 1073     00              
    defb 000h                        ; 1074     00              
    defb 000h                        ; 1075     00              
    defb 000h                        ; 1076     00              
    defb 000h                        ; 1077     00              
    defb 000h                        ; 1078     00              
    defb 000h                        ; 1079     00              
    defb 000h                        ; 107a     00              
    defb 000h                        ; 107b     00              
    defb 000h                        ; 107c     00              
    defb 000h                        ; 107d     00              
    defb 000h                        ; 107e     00              
    defb 000h                        ; 107f     00              
    defb 000h                        ; 1080     00              
    defb 000h                        ; 1081     00              
    defb 000h                        ; 1082     00              
    defb 000h                        ; 1083     00              
    defb 000h                        ; 1084     00              
    defb 000h                        ; 1085     00              
    defb 000h                        ; 1086     00              
    defb 000h                        ; 1087     00              
    defb 000h                        ; 1088     00              
    defb 000h                        ; 1089     00              
    defb 000h                        ; 108a     00              
    defb 000h                        ; 108b     00              
    defb 000h                        ; 108c     00              
    defb 000h                        ; 108d     00              
    defb 000h                        ; 108e     00              
    defb 000h                        ; 108f     00              
    defb 000h                        ; 1090     00              
    defb 000h                        ; 1091     00              
    defb 000h                        ; 1092     00              
    defb 000h                        ; 1093     00              
    defb 000h                        ; 1094     00              
    defb 000h                        ; 1095     00              
    defb 000h                        ; 1096     00              
    defb 000h                        ; 1097     00              
    defb 000h                        ; 1098     00              
    defb 000h                        ; 1099     00              
    defb 000h                        ; 109a     00              
    defb 000h                        ; 109b     00              
    defb 000h                        ; 109c     00              
    defb 000h                        ; 109d     00              
    defb 000h                        ; 109e     00              
    defb 000h                        ; 109f     00              
    defb 000h                        ; 10a0     00              
    defb 000h                        ; 10a1     00              
    defb 000h                        ; 10a2     00              
    defb 000h                        ; 10a3     00              
    defb 000h                        ; 10a4     00              
    defb 000h                        ; 10a5     00              
    defb 000h                        ; 10a6     00              
    defb 000h                        ; 10a7     00              
    defb 000h                        ; 10a8     00              
    defb 000h                        ; 10a9     00              
    defb 000h                        ; 10aa     00              
    defb 000h                        ; 10ab     00              
    defb 000h                        ; 10ac     00              
    defb 000h                        ; 10ad     00              
    defb 000h                        ; 10ae     00              
    defb 000h                        ; 10af     00              
    defb 000h                        ; 10b0     00              
    defb 000h                        ; 10b1     00              
    defb 000h                        ; 10b2     00              
    defb 000h                        ; 10b3     00              
    defb 000h                        ; 10b4     00              
    defb 000h                        ; 10b5     00              
    defb 000h                        ; 10b6     00              
    defb 000h                        ; 10b7     00              
    defb 000h                        ; 10b8     00              
    defb 000h                        ; 10b9     00              
    defb 000h                        ; 10ba     00              
    defb 000h                        ; 10bb     00              
    defb 000h                        ; 10bc     00              
    defb 000h                        ; 10bd     00              
    defb 000h                        ; 10be     00              
    defb 000h                        ; 10bf     00              
    defb 000h                        ; 10c0     00              
    defb 000h                        ; 10c1     00              
    defb 000h                        ; 10c2     00              
    defb 000h                        ; 10c3     00              
    defb 000h                        ; 10c4     00              
    defb 000h                        ; 10c5     00              
    defb 000h                        ; 10c6     00              
    defb 000h                        ; 10c7     00              
    defb 000h                        ; 10c8     00              
    defb 000h                        ; 10c9     00              
    defb 000h                        ; 10ca     00              
    defb 000h                        ; 10cb     00              
    defb 000h                        ; 10cc     00              
    defb 000h                        ; 10cd     00              
    defb 000h                        ; 10ce     00              
    defb 000h                        ; 10cf     00              
    defb 000h                        ; 10d0     00              
    defb 000h                        ; 10d1     00              
    defb 000h                        ; 10d2     00              
    defb 000h                        ; 10d3     00              
    defb 000h                        ; 10d4     00              
    defb 000h                        ; 10d5     00              
    defb 000h                        ; 10d6     00              
    defb 000h                        ; 10d7     00              
    defb 000h                        ; 10d8     00              
    defb 000h                        ; 10d9     00              
    defb 000h                        ; 10da     00              
    defb 000h                        ; 10db     00              
    defb 000h                        ; 10dc     00              
    defb 000h                        ; 10dd     00              
    defb 000h                        ; 10de     00              
    defb 000h                        ; 10df     00              
    defb 000h                        ; 10e0     00              
    defb 000h                        ; 10e1     00              
    defb 000h                        ; 10e2     00              
    defb 000h                        ; 10e3     00              
    defb 000h                        ; 10e4     00              
    defb 000h                        ; 10e5     00              
    defb 000h                        ; 10e6     00              
    defb 000h                        ; 10e7     00              
    defb 000h                        ; 10e8     00              
    defb 000h                        ; 10e9     00              
    defb 000h                        ; 10ea     00              
    defb 000h                        ; 10eb     00              
    defb 000h                        ; 10ec     00              
    defb 000h                        ; 10ed     00              
    defb 000h                        ; 10ee     00              
    defb 000h                        ; 10ef     00              
    defb 000h                        ; 10f0     00              
    defb 000h                        ; 10f1     00              
    defb 000h                        ; 10f2     00              
    defb 000h                        ; 10f3     00              
    defb 000h                        ; 10f4     00              
    defb 000h                        ; 10f5     00              
    defb 000h                        ; 10f6     00              
    defb 000h                        ; 10f7     00              
    defb 000h                        ; 10f8     00              
    defb 000h                        ; 10f9     00              
    defb 000h                        ; 10fa     00              
    defb 000h                        ; 10fb     00              
    defb 000h                        ; 10fc     00              
    defb 000h                        ; 10fd     00              
    defb 000h                        ; 10fe     00              
    defb 000h                        ; 10ff     00              
    defb 000h                        ; 1100     00              
    defb 000h                        ; 1101     00              
    defb 000h                        ; 1102     00              
    defb 000h                        ; 1103     00              
    defb 000h                        ; 1104     00              
    defb 000h                        ; 1105     00              
    defb 000h                        ; 1106     00              
    defb 000h                        ; 1107     00              
    defb 000h                        ; 1108     00              
    defb 000h                        ; 1109     00              
    defb 000h                        ; 110a     00              
    defb 000h                        ; 110b     00              
    defb 000h                        ; 110c     00              
    defb 000h                        ; 110d     00              
    defb 000h                        ; 110e     00              
    defb 000h                        ; 110f     00              
    defb 000h                        ; 1110     00              
    defb 000h                        ; 1111     00              
    defb 000h                        ; 1112     00              
    defb 000h                        ; 1113     00              
    defb 000h                        ; 1114     00              
    defb 000h                        ; 1115     00              
    defb 000h                        ; 1116     00              
    defb 000h                        ; 1117     00              
    defb 000h                        ; 1118     00              
    defb 000h                        ; 1119     00              
    defb 000h                        ; 111a     00              
    defb 000h                        ; 111b     00              
    defb 000h                        ; 111c     00              
    defb 000h                        ; 111d     00              
    defb 000h                        ; 111e     00              
    defb 000h                        ; 111f     00              
    defb 000h                        ; 1120     00              
    defb 000h                        ; 1121     00              
    defb 000h                        ; 1122     00              
    defb 000h                        ; 1123     00              
    defb 000h                        ; 1124     00              
    defb 000h                        ; 1125     00              
    defb 000h                        ; 1126     00              
    defb 000h                        ; 1127     00              
    defb 000h                        ; 1128     00              
    defb 000h                        ; 1129     00              
    defb 000h                        ; 112a     00              
    defb 000h                        ; 112b     00              
    defb 000h                        ; 112c     00              
    defb 000h                        ; 112d     00              
    defb 000h                        ; 112e     00              
    defb 000h                        ; 112f     00              
    defb 000h                        ; 1130     00              
    defb 000h                        ; 1131     00              
    defb 000h                        ; 1132     00              
    defb 000h                        ; 1133     00              
    defb 000h                        ; 1134     00              
    defb 000h                        ; 1135     00              
    defb 000h                        ; 1136     00              
    defb 000h                        ; 1137     00              
    defb 000h                        ; 1138     00              
    defb 000h                        ; 1139     00              
    defb 000h                        ; 113a     00              
    defb 000h                        ; 113b     00              
    defb 000h                        ; 113c     00              
    defb 000h                        ; 113d     00              
    defb 000h                        ; 113e     00              
    defb 000h                        ; 113f     00              
    defb 000h                        ; 1140     00              
    defb 000h                        ; 1141     00              
    defb 000h                        ; 1142     00              
    defb 000h                        ; 1143     00              
    defb 000h                        ; 1144     00              
    defb 000h                        ; 1145     00              
    defb 000h                        ; 1146     00              
    defb 000h                        ; 1147     00              
    defb 000h                        ; 1148     00              
    defb 000h                        ; 1149     00              
    defb 000h                        ; 114a     00              
    defb 000h                        ; 114b     00              
    defb 000h                        ; 114c     00              
    defb 000h                        ; 114d     00              
    defb 000h                        ; 114e     00              
    defb 000h                        ; 114f     00              
    defb 000h                        ; 1150     00              
    defb 000h                        ; 1151     00              
    defb 000h                        ; 1152     00              
    defb 000h                        ; 1153     00              
    defb 000h                        ; 1154     00              
    defb 000h                        ; 1155     00              
    defb 000h                        ; 1156     00              
    defb 000h                        ; 1157     00              
    defb 000h                        ; 1158     00              
    defb 000h                        ; 1159     00              
    defb 000h                        ; 115a     00              
    defb 000h                        ; 115b     00              
    defb 000h                        ; 115c     00              
    defb 000h                        ; 115d     00              
    defb 000h                        ; 115e     00              
    defb 000h                        ; 115f     00              
    defb 000h                        ; 1160     00              
    defb 000h                        ; 1161     00              
    defb 000h                        ; 1162     00              
    defb 000h                        ; 1163     00              
    defb 000h                        ; 1164     00              
    defb 000h                        ; 1165     00              
    defb 000h                        ; 1166     00              
    defb 000h                        ; 1167     00              
    defb 000h                        ; 1168     00              
    defb 000h                        ; 1169     00              
    defb 000h                        ; 116a     00              
    defb 000h                        ; 116b     00              
    defb 000h                        ; 116c     00              
    defb 000h                        ; 116d     00              
    defb 000h                        ; 116e     00              
    defb 000h                        ; 116f     00              
    defb 000h                        ; 1170     00              
    defb 000h                        ; 1171     00              
    defb 000h                        ; 1172     00              
    defb 000h                        ; 1173     00              
    defb 000h                        ; 1174     00              
    defb 000h                        ; 1175     00              
    defb 000h                        ; 1176     00              
    defb 000h                        ; 1177     00              
    defb 000h                        ; 1178     00              
    defb 000h                        ; 1179     00              
    defb 000h                        ; 117a     00              
    defb 000h                        ; 117b     00              
    defb 000h                        ; 117c     00              
    defb 000h                        ; 117d     00              
    defb 000h                        ; 117e     00              
    defb 000h                        ; 117f     00              
    defb 000h                        ; 1180     00              
    defb 000h                        ; 1181     00              
    defb 000h                        ; 1182     00              
    defb 000h                        ; 1183     00              
    defb 000h                        ; 1184     00              
    defb 000h                        ; 1185     00              
    defb 000h                        ; 1186     00              
    defb 000h                        ; 1187     00              
    defb 000h                        ; 1188     00              
    defb 000h                        ; 1189     00              
    defb 000h                        ; 118a     00              
    defb 000h                        ; 118b     00              
    defb 000h                        ; 118c     00              
    defb 000h                        ; 118d     00              
    defb 000h                        ; 118e     00              
    defb 000h                        ; 118f     00              
    defb 000h                        ; 1190     00              
    defb 000h                        ; 1191     00              
    defb 000h                        ; 1192     00              
    defb 000h                        ; 1193     00              
    defb 000h                        ; 1194     00              
    defb 000h                        ; 1195     00              
    defb 000h                        ; 1196     00              
    defb 000h                        ; 1197     00              
    defb 000h                        ; 1198     00              
    defb 000h                        ; 1199     00              
    defb 000h                        ; 119a     00              
    defb 000h                        ; 119b     00              
    defb 000h                        ; 119c     00              
    defb 000h                        ; 119d     00              
    defb 000h                        ; 119e     00              
    defb 000h                        ; 119f     00              
    defb 000h                        ; 11a0     00              
    defb 000h                        ; 11a1     00              
    defb 000h                        ; 11a2     00              
    defb 000h                        ; 11a3     00              
    defb 000h                        ; 11a4     00              
    defb 000h                        ; 11a5     00              
    defb 000h                        ; 11a6     00              
    defb 000h                        ; 11a7     00              
    defb 000h                        ; 11a8     00              
    defb 000h                        ; 11a9     00              
    defb 000h                        ; 11aa     00              
    defb 000h                        ; 11ab     00              
    defb 000h                        ; 11ac     00              
    defb 000h                        ; 11ad     00              
    defb 000h                        ; 11ae     00              
    defb 000h                        ; 11af     00              
    defb 000h                        ; 11b0     00              
    defb 000h                        ; 11b1     00              
    defb 000h                        ; 11b2     00              
    defb 000h                        ; 11b3     00              
    defb 000h                        ; 11b4     00              
    defb 000h                        ; 11b5     00              
    defb 000h                        ; 11b6     00              
    defb 000h                        ; 11b7     00              
    defb 000h                        ; 11b8     00              
    defb 000h                        ; 11b9     00              
    defb 000h                        ; 11ba     00              
    defb 000h                        ; 11bb     00              
    defb 000h                        ; 11bc     00              
    defb 000h                        ; 11bd     00              
    defb 000h                        ; 11be     00              
    defb 000h                        ; 11bf     00              
    defb 000h                        ; 11c0     00              
    defb 000h                        ; 11c1     00              
    defb 000h                        ; 11c2     00              
    defb 000h                        ; 11c3     00              
    defb 000h                        ; 11c4     00              
    defb 000h                        ; 11c5     00              
    defb 000h                        ; 11c6     00              
    defb 000h                        ; 11c7     00              
    defb 000h                        ; 11c8     00              
    defb 000h                        ; 11c9     00              
    defb 000h                        ; 11ca     00              
    defb 000h                        ; 11cb     00              
    defb 000h                        ; 11cc     00              
    defb 000h                        ; 11cd     00              
    defb 000h                        ; 11ce     00              
    defb 000h                        ; 11cf     00              
    defb 000h                        ; 11d0     00              
    defb 000h                        ; 11d1     00              
    defb 000h                        ; 11d2     00              
    defb 000h                        ; 11d3     00              
    defb 000h                        ; 11d4     00              
    defb 000h                        ; 11d5     00              
    defb 000h                        ; 11d6     00              
    defb 000h                        ; 11d7     00              
    defb 000h                        ; 11d8     00              
    defb 000h                        ; 11d9     00              
    defb 000h                        ; 11da     00              
    defb 000h                        ; 11db     00              
    defb 000h                        ; 11dc     00              
    defb 000h                        ; 11dd     00              
    defb 000h                        ; 11de     00              
    defb 000h                        ; 11df     00              
    defb 000h                        ; 11e0     00              
    defb 000h                        ; 11e1     00              
    defb 000h                        ; 11e2     00              
    defb 000h                        ; 11e3     00              
    defb 000h                        ; 11e4     00              
    defb 000h                        ; 11e5     00              
    defb 000h                        ; 11e6     00              
    defb 000h                        ; 11e7     00              
    defb 000h                        ; 11e8     00              
    defb 000h                        ; 11e9     00              
    defb 000h                        ; 11ea     00              
    defb 000h                        ; 11eb     00              
    defb 000h                        ; 11ec     00              
    defb 000h                        ; 11ed     00              
    defb 000h                        ; 11ee     00              
    defb 000h                        ; 11ef     00              
    defb 000h                        ; 11f0     00              
    defb 000h                        ; 11f1     00              
    defb 000h                        ; 11f2     00              
    defb 000h                        ; 11f3     00              
    defb 000h                        ; 11f4     00              
    defb 000h                        ; 11f5     00              
    defb 000h                        ; 11f6     00              
    defb 000h                        ; 11f7     00              
    defb 000h                        ; 11f8     00              
    defb 000h                        ; 11f9     00              
    defb 000h                        ; 11fa     00              
    defb 000h                        ; 11fb     00              
    defb 000h                        ; 11fc     00              
    defb 000h                        ; 11fd     00              
    defb 000h                        ; 11fe     00              
    defb 000h                        ; 11ff     00              
    defb 000h                        ; 1200     00              
    defb 000h                        ; 1201     00              
    defb 000h                        ; 1202     00              
    defb 000h                        ; 1203     00              
    defb 000h                        ; 1204     00              
    defb 000h                        ; 1205     00              
    defb 000h                        ; 1206     00              
    defb 000h                        ; 1207     00              
    defb 000h                        ; 1208     00              
    defb 000h                        ; 1209     00              
    defb 000h                        ; 120a     00              
    defb 000h                        ; 120b     00              
    defb 000h                        ; 120c     00              
    defb 000h                        ; 120d     00              
    defb 000h                        ; 120e     00              
    defb 000h                        ; 120f     00              
    defb 000h                        ; 1210     00              
    defb 000h                        ; 1211     00              
    defb 000h                        ; 1212     00              
    defb 000h                        ; 1213     00              
    defb 000h                        ; 1214     00              
    defb 000h                        ; 1215     00              
    defb 000h                        ; 1216     00              
    defb 000h                        ; 1217     00              
    defb 000h                        ; 1218     00              
    defb 000h                        ; 1219     00              
    defb 000h                        ; 121a     00              
    defb 000h                        ; 121b     00              
    defb 000h                        ; 121c     00              
    defb 000h                        ; 121d     00              
    defb 000h                        ; 121e     00              
    defb 000h                        ; 121f     00              
    defb 000h                        ; 1220     00              
    defb 000h                        ; 1221     00              
    defb 000h                        ; 1222     00              
    defb 000h                        ; 1223     00              
    defb 000h                        ; 1224     00              
    defb 000h                        ; 1225     00              
    defb 000h                        ; 1226     00              
    defb 000h                        ; 1227     00              
    defb 000h                        ; 1228     00              
    defb 000h                        ; 1229     00              
    defb 000h                        ; 122a     00              
    defb 000h                        ; 122b     00              
    defb 000h                        ; 122c     00              
    defb 000h                        ; 122d     00              
    defb 000h                        ; 122e     00              
    defb 000h                        ; 122f     00              
    defb 000h                        ; 1230     00              
    defb 000h                        ; 1231     00              
    defb 000h                        ; 1232     00              
    defb 000h                        ; 1233     00              
    defb 000h                        ; 1234     00              
    defb 000h                        ; 1235     00              
    defb 000h                        ; 1236     00              
    defb 000h                        ; 1237     00              
    defb 000h                        ; 1238     00              
    defb 000h                        ; 1239     00              
    defb 000h                        ; 123a     00              
    defb 000h                        ; 123b     00              
    defb 000h                        ; 123c     00              
    defb 000h                        ; 123d     00              
    defb 000h                        ; 123e     00              
    defb 000h                        ; 123f     00              
    defb 000h                        ; 1240     00              
    defb 000h                        ; 1241     00              
    defb 000h                        ; 1242     00              
    defb 000h                        ; 1243     00              
    defb 000h                        ; 1244     00              
    defb 000h                        ; 1245     00              
    defb 000h                        ; 1246     00              
    defb 000h                        ; 1247     00              
    defb 000h                        ; 1248     00              
    defb 000h                        ; 1249     00              
    defb 000h                        ; 124a     00              
    defb 000h                        ; 124b     00              
    defb 000h                        ; 124c     00              
    defb 000h                        ; 124d     00              
    defb 000h                        ; 124e     00              
    defb 000h                        ; 124f     00              
    defb 000h                        ; 1250     00              
    defb 000h                        ; 1251     00              
    defb 000h                        ; 1252     00              
    defb 000h                        ; 1253     00              
    defb 000h                        ; 1254     00              
    defb 000h                        ; 1255     00              
    defb 000h                        ; 1256     00              
    defb 000h                        ; 1257     00              
    defb 000h                        ; 1258     00              
    defb 000h                        ; 1259     00              
    defb 000h                        ; 125a     00              
    defb 000h                        ; 125b     00              
    defb 000h                        ; 125c     00              
    defb 000h                        ; 125d     00              
    defb 000h                        ; 125e     00              
    defb 000h                        ; 125f     00              
    defb 000h                        ; 1260     00              
    defb 000h                        ; 1261     00              
    defb 000h                        ; 1262     00              
    defb 000h                        ; 1263     00              
    defb 000h                        ; 1264     00              
    defb 000h                        ; 1265     00              
    defb 000h                        ; 1266     00              
    defb 000h                        ; 1267     00              
    defb 000h                        ; 1268     00              
    defb 000h                        ; 1269     00              
    defb 000h                        ; 126a     00              
    defb 000h                        ; 126b     00              
    defb 000h                        ; 126c     00              
    defb 000h                        ; 126d     00              
    defb 000h                        ; 126e     00              
    defb 000h                        ; 126f     00              
    defb 000h                        ; 1270     00              
    defb 000h                        ; 1271     00              
    defb 000h                        ; 1272     00              
    defb 000h                        ; 1273     00              
    defb 000h                        ; 1274     00              
    defb 000h                        ; 1275     00              
    defb 000h                        ; 1276     00              
    defb 000h                        ; 1277     00              
    defb 000h                        ; 1278     00              
    defb 000h                        ; 1279     00              
    defb 000h                        ; 127a     00              
    defb 000h                        ; 127b     00              
    defb 000h                        ; 127c     00              
    defb 000h                        ; 127d     00              
    defb 000h                        ; 127e     00              
    defb 000h                        ; 127f     00              
    defb 000h                        ; 1280     00              
    defb 000h                        ; 1281     00              
    defb 000h                        ; 1282     00              
    defb 000h                        ; 1283     00              
    defb 000h                        ; 1284     00              
    defb 000h                        ; 1285     00              
    defb 000h                        ; 1286     00              
    defb 000h                        ; 1287     00              
    defb 000h                        ; 1288     00              
    defb 000h                        ; 1289     00              
    defb 000h                        ; 128a     00              
    defb 000h                        ; 128b     00              
    defb 000h                        ; 128c     00              
    defb 000h                        ; 128d     00              
    defb 000h                        ; 128e     00              
    defb 000h                        ; 128f     00              
    defb 000h                        ; 1290     00              
    defb 000h                        ; 1291     00              
    defb 000h                        ; 1292     00              
    defb 000h                        ; 1293     00              
    defb 000h                        ; 1294     00              
    defb 000h                        ; 1295     00              
    defb 000h                        ; 1296     00              
    defb 000h                        ; 1297     00              
    defb 000h                        ; 1298     00              
    defb 000h                        ; 1299     00              
    defb 000h                        ; 129a     00              
    defb 000h                        ; 129b     00              
    defb 000h                        ; 129c     00              
    defb 000h                        ; 129d     00              
    defb 000h                        ; 129e     00              
    defb 000h                        ; 129f     00              
    defb 000h                        ; 12a0     00              
    defb 000h                        ; 12a1     00              
    defb 000h                        ; 12a2     00              
    defb 000h                        ; 12a3     00              
    defb 000h                        ; 12a4     00              
    defb 000h                        ; 12a5     00              
    defb 000h                        ; 12a6     00              
    defb 000h                        ; 12a7     00              
    defb 000h                        ; 12a8     00              
    defb 000h                        ; 12a9     00              
    defb 000h                        ; 12aa     00              
    defb 000h                        ; 12ab     00              
    defb 000h                        ; 12ac     00              
    defb 000h                        ; 12ad     00              
    defb 000h                        ; 12ae     00              
    defb 000h                        ; 12af     00              
    defb 000h                        ; 12b0     00              
    defb 000h                        ; 12b1     00              
    defb 000h                        ; 12b2     00              
    defb 000h                        ; 12b3     00              
    defb 000h                        ; 12b4     00              
    defb 000h                        ; 12b5     00              
    defb 000h                        ; 12b6     00              
    defb 000h                        ; 12b7     00              
    defb 000h                        ; 12b8     00              
    defb 000h                        ; 12b9     00              
    defb 000h                        ; 12ba     00              
    defb 000h                        ; 12bb     00              
    defb 000h                        ; 12bc     00              
    defb 000h                        ; 12bd     00              
    defb 000h                        ; 12be     00              
    defb 000h                        ; 12bf     00              
    defb 000h                        ; 12c0     00              
    defb 000h                        ; 12c1     00              
    defb 000h                        ; 12c2     00              
    defb 000h                        ; 12c3     00              
    defb 000h                        ; 12c4     00              
    defb 000h                        ; 12c5     00              
    defb 000h                        ; 12c6     00              
    defb 000h                        ; 12c7     00              
    defb 000h                        ; 12c8     00              
    defb 000h                        ; 12c9     00              
    defb 000h                        ; 12ca     00              
    defb 000h                        ; 12cb     00              
    defb 000h                        ; 12cc     00              
    defb 000h                        ; 12cd     00              
    defb 000h                        ; 12ce     00              
    defb 000h                        ; 12cf     00              
    defb 000h                        ; 12d0     00              
    defb 000h                        ; 12d1     00              
    defb 000h                        ; 12d2     00              
    defb 000h                        ; 12d3     00              
    defb 000h                        ; 12d4     00              
    defb 000h                        ; 12d5     00              
    defb 000h                        ; 12d6     00              
    defb 000h                        ; 12d7     00              
    defb 000h                        ; 12d8     00              
    defb 000h                        ; 12d9     00              
    defb 000h                        ; 12da     00              
    defb 000h                        ; 12db     00              
    defb 000h                        ; 12dc     00              
    defb 000h                        ; 12dd     00              
    defb 000h                        ; 12de     00              
    defb 000h                        ; 12df     00              
    defb 000h                        ; 12e0     00              
    defb 000h                        ; 12e1     00              
    defb 000h                        ; 12e2     00              
    defb 000h                        ; 12e3     00              
    defb 000h                        ; 12e4     00              
    defb 000h                        ; 12e5     00              
    defb 000h                        ; 12e6     00              
    defb 000h                        ; 12e7     00              
    defb 000h                        ; 12e8     00              
    defb 000h                        ; 12e9     00              
    defb 000h                        ; 12ea     00              
    defb 000h                        ; 12eb     00              
    defb 000h                        ; 12ec     00              
    defb 000h                        ; 12ed     00              
    defb 000h                        ; 12ee     00              
    defb 000h                        ; 12ef     00              
    defb 000h                        ; 12f0     00              
    defb 000h                        ; 12f1     00              
    defb 000h                        ; 12f2     00              
    defb 000h                        ; 12f3     00              
    defb 000h                        ; 12f4     00              
    defb 000h                        ; 12f5     00              
    defb 000h                        ; 12f6     00              
    defb 000h                        ; 12f7     00              
    defb 000h                        ; 12f8     00              
    defb 000h                        ; 12f9     00              
    defb 000h                        ; 12fa     00              
    defb 000h                        ; 12fb     00              
    defb 000h                        ; 12fc     00              
    defb 000h                        ; 12fd     00              
    defb 000h                        ; 12fe     00              
    defb 000h                        ; 12ff     00              
    defb 000h                        ; 1300     00              
    defb 000h                        ; 1301     00              
    defb 000h                        ; 1302     00              
    defb 000h                        ; 1303     00              
    defb 000h                        ; 1304     00              
    defb 000h                        ; 1305     00              
    defb 000h                        ; 1306     00              
    defb 000h                        ; 1307     00              
    defb 000h                        ; 1308     00              
    defb 000h                        ; 1309     00              
    defb 000h                        ; 130a     00              
    defb 000h                        ; 130b     00              
    defb 000h                        ; 130c     00              
    defb 000h                        ; 130d     00              
    defb 000h                        ; 130e     00              
    defb 000h                        ; 130f     00              
    defb 000h                        ; 1310     00              
    defb 000h                        ; 1311     00              
    defb 000h                        ; 1312     00              
    defb 000h                        ; 1313     00              
    defb 000h                        ; 1314     00              
    defb 000h                        ; 1315     00              
    defb 000h                        ; 1316     00              
    defb 000h                        ; 1317     00              
    defb 000h                        ; 1318     00              
    defb 000h                        ; 1319     00              
    defb 000h                        ; 131a     00              
    defb 000h                        ; 131b     00              
    defb 000h                        ; 131c     00              
    defb 000h                        ; 131d     00              
    defb 000h                        ; 131e     00              
    defb 000h                        ; 131f     00              
    defb 000h                        ; 1320     00              
    defb 000h                        ; 1321     00              
    defb 000h                        ; 1322     00              
    defb 000h                        ; 1323     00              
    defb 000h                        ; 1324     00              
    defb 000h                        ; 1325     00              
    defb 000h                        ; 1326     00              
    defb 000h                        ; 1327     00              
    defb 000h                        ; 1328     00              
    defb 000h                        ; 1329     00              
    defb 000h                        ; 132a     00              
    defb 000h                        ; 132b     00              
    defb 000h                        ; 132c     00              
    defb 000h                        ; 132d     00              
    defb 000h                        ; 132e     00              
    defb 000h                        ; 132f     00              
    defb 000h                        ; 1330     00              
    defb 000h                        ; 1331     00              
    defb 000h                        ; 1332     00              
    defb 000h                        ; 1333     00              
    defb 000h                        ; 1334     00              
    defb 000h                        ; 1335     00              
    defb 000h                        ; 1336     00              
    defb 000h                        ; 1337     00              
    defb 000h                        ; 1338     00              
    defb 000h                        ; 1339     00              
    defb 000h                        ; 133a     00              
    defb 000h                        ; 133b     00              
    defb 000h                        ; 133c     00              
    defb 000h                        ; 133d     00              
    defb 000h                        ; 133e     00              
    defb 000h                        ; 133f     00              
    defb 000h                        ; 1340     00              
    defb 000h                        ; 1341     00              
    defb 000h                        ; 1342     00              
    defb 000h                        ; 1343     00              
    defb 000h                        ; 1344     00              
    defb 000h                        ; 1345     00              
    defb 000h                        ; 1346     00              
    defb 000h                        ; 1347     00              
    defb 000h                        ; 1348     00              
    defb 000h                        ; 1349     00              
    defb 000h                        ; 134a     00              
    defb 000h                        ; 134b     00              
    defb 000h                        ; 134c     00              
    defb 000h                        ; 134d     00              
    defb 000h                        ; 134e     00              
    defb 000h                        ; 134f     00              
    defb 000h                        ; 1350     00              
    defb 000h                        ; 1351     00              
    defb 000h                        ; 1352     00              
    defb 000h                        ; 1353     00              
    defb 000h                        ; 1354     00              
    defb 000h                        ; 1355     00              
    defb 000h                        ; 1356     00              
    defb 000h                        ; 1357     00              
    defb 000h                        ; 1358     00              
    defb 000h                        ; 1359     00              
    defb 000h                        ; 135a     00              
    defb 000h                        ; 135b     00              
    defb 000h                        ; 135c     00              
    defb 000h                        ; 135d     00              
    defb 000h                        ; 135e     00              
    defb 000h                        ; 135f     00              
    defb 000h                        ; 1360     00              
    defb 000h                        ; 1361     00              
    defb 000h                        ; 1362     00              
    defb 000h                        ; 1363     00              
    defb 000h                        ; 1364     00              
    defb 000h                        ; 1365     00              
    defb 000h                        ; 1366     00              
    defb 000h                        ; 1367     00              
    defb 000h                        ; 1368     00              
    defb 000h                        ; 1369     00              
    defb 000h                        ; 136a     00              
    defb 000h                        ; 136b     00              
    defb 000h                        ; 136c     00              
    defb 000h                        ; 136d     00              
    defb 000h                        ; 136e     00              
    defb 000h                        ; 136f     00              
    defb 000h                        ; 1370     00              
    defb 000h                        ; 1371     00              
    defb 000h                        ; 1372     00              
    defb 000h                        ; 1373     00              
    defb 000h                        ; 1374     00              
    defb 000h                        ; 1375     00              
    defb 000h                        ; 1376     00              
    defb 000h                        ; 1377     00              
    defb 000h                        ; 1378     00              
    defb 000h                        ; 1379     00              
    defb 000h                        ; 137a     00              
    defb 000h                        ; 137b     00              
    defb 000h                        ; 137c     00              
    defb 000h                        ; 137d     00              
    defb 000h                        ; 137e     00              
    defb 000h                        ; 137f     00              
    defb 000h                        ; 1380     00              
    defb 000h                        ; 1381     00              
    defb 000h                        ; 1382     00              
    defb 000h                        ; 1383     00              
    defb 000h                        ; 1384     00              
    defb 000h                        ; 1385     00              
    defb 000h                        ; 1386     00              
    defb 000h                        ; 1387     00              
    defb 000h                        ; 1388     00              
    defb 000h                        ; 1389     00              
    defb 000h                        ; 138a     00              
    defb 000h                        ; 138b     00              
    defb 000h                        ; 138c     00              
    defb 000h                        ; 138d     00              
    defb 000h                        ; 138e     00              
    defb 000h                        ; 138f     00              
    defb 000h                        ; 1390     00              
    defb 000h                        ; 1391     00              
    defb 000h                        ; 1392     00              
    defb 000h                        ; 1393     00              
    defb 000h                        ; 1394     00              
    defb 000h                        ; 1395     00              
    defb 000h                        ; 1396     00              
    defb 000h                        ; 1397     00              
    defb 000h                        ; 1398     00              
    defb 000h                        ; 1399     00              
    defb 000h                        ; 139a     00              
    defb 000h                        ; 139b     00              
    defb 000h                        ; 139c     00              
    defb 000h                        ; 139d     00              
    defb 000h                        ; 139e     00              
    defb 000h                        ; 139f     00              
    defb 000h                        ; 13a0     00              
    defb 000h                        ; 13a1     00              
    defb 000h                        ; 13a2     00              
    defb 000h                        ; 13a3     00              
    defb 000h                        ; 13a4     00              
    defb 000h                        ; 13a5     00              
    defb 000h                        ; 13a6     00              
    defb 000h                        ; 13a7     00              
    defb 000h                        ; 13a8     00              
    defb 000h                        ; 13a9     00              
    defb 000h                        ; 13aa     00              
    defb 000h                        ; 13ab     00              
    defb 000h                        ; 13ac     00              
    defb 000h                        ; 13ad     00              
    defb 000h                        ; 13ae     00              
    defb 000h                        ; 13af     00              
    defb 000h                        ; 13b0     00              
    defb 000h                        ; 13b1     00              
    defb 000h                        ; 13b2     00              
    defb 000h                        ; 13b3     00              
    defb 000h                        ; 13b4     00              
    defb 000h                        ; 13b5     00              
    defb 000h                        ; 13b6     00              
    defb 000h                        ; 13b7     00              
    defb 000h                        ; 13b8     00              
    defb 000h                        ; 13b9     00              
    defb 000h                        ; 13ba     00              
    defb 000h                        ; 13bb     00              
    defb 000h                        ; 13bc     00              
    defb 000h                        ; 13bd     00              
    defb 000h                        ; 13be     00              
    defb 000h                        ; 13bf     00              
    defb 000h                        ; 13c0     00              
    defb 000h                        ; 13c1     00              
    defb 000h                        ; 13c2     00              
    defb 000h                        ; 13c3     00              
    defb 000h                        ; 13c4     00              
    defb 000h                        ; 13c5     00              
    defb 000h                        ; 13c6     00              
    defb 000h                        ; 13c7     00              
    defb 000h                        ; 13c8     00              
    defb 000h                        ; 13c9     00              
    defb 000h                        ; 13ca     00              
    defb 000h                        ; 13cb     00              
    defb 000h                        ; 13cc     00              
    defb 000h                        ; 13cd     00              
    defb 000h                        ; 13ce     00              
    defb 000h                        ; 13cf     00              
    defb 000h                        ; 13d0     00              
    defb 000h                        ; 13d1     00              
    defb 000h                        ; 13d2     00              
    defb 000h                        ; 13d3     00              
    defb 000h                        ; 13d4     00              
    defb 000h                        ; 13d5     00              
    defb 000h                        ; 13d6     00              
    defb 000h                        ; 13d7     00              
    defb 000h                        ; 13d8     00              
    defb 000h                        ; 13d9     00              
    defb 000h                        ; 13da     00              
    defb 000h                        ; 13db     00              
    defb 000h                        ; 13dc     00              
    defb 000h                        ; 13dd     00              
    defb 000h                        ; 13de     00              
    defb 000h                        ; 13df     00              
    defb 000h                        ; 13e0     00              
    defb 000h                        ; 13e1     00              
    defb 000h                        ; 13e2     00              
    defb 000h                        ; 13e3     00              
    defb 000h                        ; 13e4     00              
    defb 000h                        ; 13e5     00              
    defb 000h                        ; 13e6     00              
    defb 000h                        ; 13e7     00              
    defb 000h                        ; 13e8     00              
    defb 000h                        ; 13e9     00              
    defb 000h                        ; 13ea     00              
    defb 000h                        ; 13eb     00              
    defb 000h                        ; 13ec     00              
    defb 000h                        ; 13ed     00              
    defb 000h                        ; 13ee     00              
    defb 000h                        ; 13ef     00              
    defb 000h                        ; 13f0     00              
    defb 000h                        ; 13f1     00              
    defb 000h                        ; 13f2     00              
    defb 000h                        ; 13f3     00              
    defb 000h                        ; 13f4     00              
    defb 000h                        ; 13f5     00              
    defb 000h                        ; 13f6     00              
    defb 000h                        ; 13f7     00              
    defb 000h                        ; 13f8     00              
    defb 000h                        ; 13f9     00              
    defb 000h                        ; 13fa     00              
    defb 000h                        ; 13fb     00              
    defb 000h                        ; 13fc     00              
    defb 000h                        ; 13fd     00              
    defb 000h                        ; 13fe     00              
    defb 000h                        ; 13ff     00              
c_end:                                                          
                                                                
; BLOCK 'd' (start 0x1400 end 0x19be)                           
d_first:                                                        
draw_shifted_sprite:                                            
    nop                              ; 1400     00               ;  Time/size pad to match CPL in EraseShiftedSprite
    call cnvt_pix_number             ; 1401     cd 74 14         ;  Convert pixel number to coord and shift
    nop                              ; 1404     00               ;  Time/size pad to match CPL in EraseShiftedSprite
l1405h:                                                         
    push bc                          ; 1405     c5               ;  Hold count
    push hl                          ; 1406     e5               ;  Hold start coordinate
    ld a,(de)                        ; 1407     1a               ;  Get the picture bits
    out (004h),a                     ; 1408     d3 04            ;  Store in shift register
    in a,(003h)                      ; 140a     db 03            ;  Read the shifted pixels
    or (hl)                          ; 140c     b6               ;  OR them onto the screen
    ld (hl),a                        ; 140d     77               ;  Store them back to screen
    inc hl                           ; 140e     23               ;  Next colummn on screen
    inc de                           ; 140f     13               ;  Next in picture
    xor a                            ; 1410     af               ;  Shift over ...
    out (004h),a                     ; 1411     d3 04            ;  ... to next byte in register (shift in 0)
    in a,(003h)                      ; 1413     db 03            ;  Read the shifted pixels
    or (hl)                          ; 1415     b6               ;  OR them onto the screen
    ld (hl),a                        ; 1416     77               ;  Store them back to screen
    pop hl                           ; 1417     e1               ;  Restore starting coordinate
    ld bc,l0020h                     ; 1418     01 20 00         ;  Add 32 ...
    add hl,bc                        ; 141b     09               ;  ... to coordinate (move to next row)
    pop bc                           ; 141c     c1               ;  Restore count
    dec b                            ; 141d     05               ;  All done?
    jp nz,l1405h                     ; 141e     c2 05 14         ;  No ... go do all rows
    ret                              ; 1421     c9               ;  Done

    nop                              ; 1422     00               ;  ** Why?
    nop                              ; 1423     00              
erase_simple_sprite:                                            
    call cnvt_pix_number             ; 1424     cd 74 14         ;  Convert pixel number in HL
l1427h:                                                         
    push bc                          ; 1427     c5               ;  Hold
    push hl                          ; 1428     e5               ;  Hold
    xor a                            ; 1429     af               ;  0
    ld (hl),a                        ; 142a     77               ;  Clear screen byte
    inc hl                           ; 142b     23               ;  Next byte
    ld (hl),a                        ; 142c     77               ;  Clear byte
    inc hl                           ; 142d     23               ;  ** Is this to mimic timing? We increment then pop
    pop hl                           ; 142e     e1               ;  Restore screen coordinate
    ld bc,l0020h                     ; 142f     01 20 00         ;  Add 1 row ...
    add hl,bc                        ; 1432     09               ;  ... to screen coordinate
    pop bc                           ; 1433     c1               ;  Restore counter
    dec b                            ; 1434     05               ;  All rows done?
    jp nz,l1427h                     ; 1435     c2 27 14         ;  Do all rows
    ret                              ; 1438     c9               ;  out

sub_1439h:                                                      
;   @pres c
;   @chan af
;   @exit b -> 0
;   @exit de -> end of sprite
;   @exit hl -> screen memory after sprite
draw_simp_sprite:                                               
    push bc                          ; 1439     c5               ;  Preserve counter
    ld a,(de)                        ; 143a     1a               ;  From character set ...
    ld (hl),a                        ; 143b     77               ;  ... to screen
    inc de                           ; 143c     13               ;  Next in character set
    ld bc,l0020h                     ; 143d     01 20 00         ;  Next row ...
    add hl,bc                        ; 1440     09               ;  ... on screen
    pop bc                           ; 1441     c1               ;  Restore counter
    dec b                            ; 1442     05               ;  Decrement counter
    jp nz,draw_simp_sprite           ; 1443     c2 39 14         ;  Do all
    ret                              ; 1446     c9               ;  Out

    nop                              ; 1447     00               ;  ** Why?
    nop                              ; 1448     00              
    nop                              ; 1449     00              
    nop                              ; 144a     00              
    nop                              ; 144b     00              
    nop                              ; 144c     00              
    nop                              ; 144d     00              
    nop                              ; 144e     00              
    nop                              ; 144f     00              
    nop                              ; 1450     00              
    nop                              ; 1451     00              
erase_shifted:                                                  
    call cnvt_pix_number             ; 1452     cd 74 14         ;  Convert pixel number in HL to coorinates with shift
l1455h:                                                         
    push bc                          ; 1455     c5               ;  Hold BC
    push hl                          ; 1456     e5               ;  Hold coordinate
    ld a,(de)                        ; 1457     1a               ;  Get picture value
    out (004h),a                     ; 1458     d3 04            ;  Value into shift register
    in a,(003h)                      ; 145a     db 03            ;  Read shifted sprite picture
    cpl                              ; 145c     2f               ;  Reverse it (erasing bits)
    and (hl)                         ; 145d     a6               ;  Erase the bits from the screen
    ld (hl),a                        ; 145e     77               ;  Store the erased pattern back
    inc hl                           ; 145f     23               ;  Next column on screen
    inc de                           ; 1460     13               ;  Next in image
    xor a                            ; 1461     af               ;  Shift register over ...
    out (004h),a                     ; 1462     d3 04            ;  ... 8 bits (shift in 0)
    in a,(003h)                      ; 1464     db 03            ;  Read 2nd byte of image
    cpl                              ; 1466     2f               ;  Reverse it (erasing bits)
    and (hl)                         ; 1467     a6               ;  Erase the bits from the screen
    ld (hl),a                        ; 1468     77               ;  Store the erased pattern back
    pop hl                           ; 1469     e1               ;  Restore starting coordinate
    ld bc,l0020h                     ; 146a     01 20 00         ;  Add 32 ...
    add hl,bc                        ; 146d     09               ;  ... to next row
    pop bc                           ; 146e     c1               ;  Restore BC (count)
    dec b                            ; 146f     05               ;  All rows done?
    jp nz,l1455h                     ; 1470     c2 55 14         ;  No ... erase all
    ret                              ; 1473     c9               ;  Done

cnvt_pix_number:                                                
    ld a,l                           ; 1474     7d               ;  Get X coordinate
    and 007h                         ; 1475     e6 07            ;  Shift by pixel position
    out (002h),a                     ; 1477     d3 02            ;  Write shift amount to hardware
    jp conv_to_scr                   ; 1479     c3 47 1a         ;  HL = HL/8 + 2000 (screen coordinate)

remember_shields:                                               
    push bc                          ; 147c     c5               ;  Hold counter
    push hl                          ; 147d     e5               ;  Hold start
l147eh:                                                         
    ld a,(hl)                        ; 147e     7e               ;  From sprite ... (should be DE)
    ld (de),a                        ; 147f     12               ;  ... to screen ... (should be HL)
    inc de                           ; 1480     13               ;  Next in sprite
    inc hl                           ; 1481     23               ;  Next on screen
    dec c                            ; 1482     0d               ;  All columns done?
    jp nz,l147eh                     ; 1483     c2 7e 14         ;  No ... do multi columns
    pop hl                           ; 1486     e1               ;  Restore screen start
    ld bc,l0020h                     ; 1487     01 20 00         ;  Add 32 ...
    add hl,bc                        ; 148a     09               ;  ... to get to next row
    pop bc                           ; 148b     c1               ;  Pop the counters
    dec b                            ; 148c     05               ;  All rows done?
    jp nz,remember_shields           ; 148d     c2 7c 14         ;  No ... do multi rows
    ret                              ; 1490     c9               ;  Done

draw_spr_collision:                                             
    call cnvt_pix_number             ; 1491     cd 74 14         ;  Convert pixel number to coord and shift
    xor a                            ; 1494     af               ;  Clear the ...
    ld (collision),a                 ; 1495     32 61 20         ;  ... collision-detection flag
l1498h:                                                         
    push bc                          ; 1498     c5               ;  Hold count
    push hl                          ; 1499     e5               ;  Hold screen
    ld a,(de)                        ; 149a     1a               ;  Get byte
    out (004h),a                     ; 149b     d3 04            ;  Write first byte to shift register
    in a,(003h)                      ; 149d     db 03            ;  Read shifted pattern
    push af                          ; 149f     f5               ;  Hold the pattern
    and (hl)                         ; 14a0     a6               ;  Any bits from pixel collide with bits on screen?
    jp z,l14a9h                      ; 14a1     ca a9 14         ;  No ... leave flag alone
    ld a,001h                        ; 14a4     3e 01            ;  Yes ... set ...
    ld (collision),a                 ; 14a6     32 61 20         ;  ... collision flag
l14a9h:                                                         
    pop af                           ; 14a9     f1               ;  Restore the pixel pattern
    or (hl)                          ; 14aa     b6               ;  OR it onto the screen
    ld (hl),a                        ; 14ab     77               ;  Store new screen value
    inc hl                           ; 14ac     23               ;  Next byte on screen
    inc de                           ; 14ad     13               ;  Next in pixel pattern
    xor a                            ; 14ae     af               ;  Write zero ...
    out (004h),a                     ; 14af     d3 04            ;  ... to shift register
    in a,(003h)                      ; 14b1     db 03            ;  Read 2nd half of shifted sprite
    push af                          ; 14b3     f5               ;  Hold pattern
    and (hl)                         ; 14b4     a6               ;  Any bits from pixel collide with bits on screen?
    jp z,l14bdh                      ; 14b5     ca bd 14         ;  No ... leave flag alone
    ld a,001h                        ; 14b8     3e 01            ;  Yes ... set ...
    ld (collision),a                 ; 14ba     32 61 20         ;  ... collision flag
l14bdh:                                                         
    pop af                           ; 14bd     f1               ;  Restore the pixel pattern
    or (hl)                          ; 14be     b6               ;  OR it onto the screen
    ld (hl),a                        ; 14bf     77               ;  Store new screen pattern
    pop hl                           ; 14c0     e1               ;  Starting screen coordinate
    ld bc,l0020h                     ; 14c1     01 20 00         ;  Add 32 ...
    add hl,bc                        ; 14c4     09               ;  ... to get to next row
    pop bc                           ; 14c5     c1               ;  Restore count
    dec b                            ; 14c6     05               ;  All done?
    jp nz,l1498h                     ; 14c7     c2 98 14         ;  No ... do all rows
    ret                              ; 14ca     c9               ;  Done

clear_small_sprite:                                             
    xor a                            ; 14cb     af               ;  0
fill_screen_row:                     
    push bc                          ; 14cc     c5               ;  Preserve BC
    ld (hl),a                        ; 14cd     77               ;  Clear screen byte
    ld bc,l0020h                     ; 14ce     01 20 00         ;  Bump HL ...
    add hl,bc                        ; 14d1     09               ;  ... one screen row
    pop bc                           ; 14d2     c1               ;  Restore
    dec b                            ; 14d3     05               ;  All done?
    jp nz,fill_screen_row            ; 14d4     c2 cc 14         ;  No ... clear all
    ret                              ; 14d7     c9              

player_shot_hit:                                                
    ld a,(plyr_shot_status)          ; 14d8     3a 25 20         ;  Player shot flag
    cp 005h                          ; 14db     fe 05            ;  Alien explosion in progress?
    ret z                            ; 14dd     c8               ;  Yes ... ignore this function
    cp 002h                          ; 14de     fe 02            ;  Normal movement?
    ret nz                           ; 14e0     c0               ;  No ... out
    ld a,(obj1coor_yr)               ; 14e1     3a 29 20         ;  Get Yr coordinate of player shot
    cp 0d8h                          ; 14e4     fe d8            ;  Compare to 216 (40 from Top-rotated)
    ld b,a                           ; 14e6     47               ;  Hold value for later
    jp nc,l1530h                     ; 14e7     d2 30 15         ;  Yr is within 40 from top initiate miss-explosion (shot flag 3)
    ld a,(alien_is_exploding)        ; 14ea     3a 02 20         ;  Is an alien ...
    and a                            ; 14ed     a7               ;  ... blowing up?
    ret z                            ; 14ee     c8               ;  No ... out
    ld a,b                           ; 14ef     78               ;  Get original Yr coordinate back to A
    cp 0ceh                          ; 14f0     fe ce            ;  Compare to 206 (50 from rotated top)
    jp nc,l1579h                     ; 14f2     d2 79 15         ;  Yr is within 50 from top? Yes ... saucer must be hit
    add a,006h                       ; 14f5     c6 06            ;  Offset to coordinate for wider "explosion" picture
    ld b,a                           ; 14f7     47               ;  Hold that
    ld a,(ref_alien_yr)              ; 14f8     3a 09 20         ;  Ref alien Y coordianate
    cp 090h                          ; 14fb     fe 90            ;  This is true if ...
    jp nc,code_bug1                  ; 14fd     d2 04 15         ;  ... aliens are down in the shields
    cp b                             ; 1500     b8               ;  Compare to shot's coordinate
    jp nc,l1530h                     ; 1501     d2 30 15         ;  Outside the rack-square ... do miss explosion

code_bug1:                                                      
    ld l,b                           ; 1504     68               ;  L now holds the shot coordinate (adjusted)
    call find_row                    ; 1505     cd 62 15         ;  Look up row number to B
    ld a,(obj1coor_xr)               ; 1508     3a 2a 20         ;  Player's shot's Xr coordinate ...
    ld h,a                           ; 150b     67               ;  ... to H
    call find_column                 ; 150c     cd 6f 15         ;  Get alien's coordinate
    ld (exp_alien_yr),hl             ; 150f     22 64 20         ;  Put it in the exploding-alien descriptor
    ld a,005h                        ; 1512     3e 05            ;  Flag alien explosion ...
    ld (plyr_shot_status),a          ; 1514     32 25 20         ;  ... in progress
    call get_alien_state_ptr         ; 1517     cd 81 15         ;  Get pointer to alien state
    ld a,(hl)                        ; 151a     7e               ;  Is alien ...
    and a                            ; 151b     a7               ;  ... alive
    jp z,l1530h                      ; 151c     ca 30 15         ;  No ... must have been an alien shot
    ld (hl),000h                     ; 151f     36 00            ;  Make alien invader dead
    call score_for_alien             ; 1521     cd 5f 0a         ;  Makes alien explosion sound and adjust score
    call read_desc                   ; 1524     cd 3b 1a         ;  Load 5 byte sprite descriptor
    call draw_sprite                 ; 1527     cd d3 15         ;  Draw explosion sprite on screen
    ld a,010h                        ; 152a     3e 10            ;  Initiate alien-explosion
    ld (exp_alien_timer),a           ; 152c     32 03 20         ;  ... timer to 16
    ret                              ; 152f     c9               ;  Out

l1530h:                                                         
    ld a,003h                        ; 1530     3e 03            ;  Mark ...
    ld (plyr_shot_status),a          ; 1532     32 25 20         ;  ... player shot hit something other than alien
    jp l154ah                        ; 1535     c3 4a 15         ;  Finish up

aexplode_time:                                                  
    ld hl,exp_alien_timer            ; 1538     21 03 20         ;  Decrement alien explosion ...
    dec (hl)                         ; 153b     35               ;  ... timer
    ret nz                           ; 153c     c0               ;  Not done  ... out
    ld hl,(exp_alien_yr)             ; 153d     2a 64 20         ;  Pixel pointer for exploding alien
    ld b,010h                        ; 1540     06 10            ;  16 row pixel
    call erase_simple_sprite         ; 1542     cd 24 14         ;  Clear the explosion sprite from the screen
l1545h:                                                         
    ld a,004h                        ; 1545     3e 04            ;  4 means that ...
    ld (plyr_shot_status),a          ; 1547     32 25 20         ;  ... alien has exploded (remove from active duty)
l154ah:                                                         
    xor a                            ; 154a     af               ;  Turn off ...
    ld (alien_is_exploding),a        ; 154b     32 02 20         ;  ... alien-is-blowing-up flag
    ld b,0f7h                        ; 154e     06 f7            ;  Turn off ...
    jp sound_bits3off                ; 1550     c3 dc 19         ;  ... alien exploding sound

    nop                              ; 1553     00              

cnt16s:                                                         
    ld c,000h                        ; 1554     0e 00            ;  Count of 16s
    cp h                             ; 1556     bc               ;  Compare reference coordinate to target
    call nc,wrap_ref                 ; 1557     d4 90 15         ;  If reference is greater or equal then do something questionable ... see below
l155ah:                                                         
    cp h                             ; 155a     bc               ;  Compare reference coordinate to target
    ret nc                           ; 155b     d0               ;  If reference is greater or equal then done
    add a,010h                       ; 155c     c6 10            ;  Add 16 to reference
    inc c                            ; 155e     0c               ;  Bump 16s count
    jp l155ah                        ; 155f     c3 5a 15         ;  Keep testing

find_row:                                                       
    ld a,(ref_alien_yr)              ; 1562     3a 09 20         ;  Reference alien Yr coordinate
    ld h,l                           ; 1565     65               ;  Target Yr coordinate to H
    call cnt16s                      ; 1566     cd 54 15         ;  Count 16s needed to bring ref alien to target
    ld b,c                           ; 1569     41               ;  Count to B
    dec b                            ; 156a     05               ;  Base 0
    sbc a,010h                       ; 156b     de 10            ;  The counting also adds 16 no matter what
    ld l,a                           ; 156d     6f               ;  To coordinate
    ret                              ; 156e     c9               ;  Done

find_column:                                                    
    ld a,(ref_alien_xr)              ; 156f     3a 0a 20         ;  Reference alien Yn coordinate
    call cnt16s                      ; 1572     cd 54 15         ;  Count 16s to bring Y to target Y
    sbc a,010h                       ; 1575     de 10            ;  Subtract off extra 16
    ld h,a                           ; 1577     67               ;  To H
    ret                              ; 1578     c9               ;  Done

l1579h:                                                         
    ld a,001h                        ; 1579     3e 01            ;  Mark flying ...
    ld (saucer_hit),a                ; 157b     32 85 20         ;  ... saucer has been hit
    jp l1545h                        ; 157e     c3 45 15         ;  Remove player shot

get_alien_state_ptr:                                             
    ld a,b                           ; 1581     78               ;  Hold original
    rlca                             ; 1582     07               ;  *2
    rlca                             ; 1583     07               ;  *4
    rlca                             ; 1584     07               ;  *8
    add a,b                          ; 1585     80               ;  *9
    add a,b                          ; 1586     80               ;  *10
    add a,b                          ; 1587     80               ;  *11
    add a,c                          ; 1588     81               ;  Add row offset to column offset
    dec a                            ; 1589     3d               ;  -1
    ld l,a                           ; 158a     6f               ;  Set LSB of HL
    ld a,(player_data_msb)           ; 158b     3a 67 20         ;  Set ...
    ld h,a                           ; 158e     67               ;  ... MSB of HL with active player indicator
    ret                              ; 158f     c9              

wrap_ref:                                                       
    inc c                            ; 1590     0c               ;  Increase 16s count
    add a,010h                       ; 1591     c6 10            ;  Add 16 to ref
    jp m,wrap_ref                    ; 1593     fa 90 15         ;  Keep going till result is positive
    ret                              ; 1596     c9               ;  Out

rack_bump:                                                      
    ld a,(rack_direction)            ; 1597     3a 0d 20         ;  Get rack direction
    and a                            ; 159a     a7               ;  Moving right?
    jp nz,l15b7h                     ; 159b     c2 b7 15         ;  No ... handle moving left
    ld hl,03ea4h                     ; 159e     21 a4 3e         ;  Line down the right edge of playfield
    call check_column                ; 15a1     cd c5 15         ;  Check line down the edge
    ret nc                           ; 15a4     d0               ;  Nothing is there ... return
    ld b,0feh                        ; 15a5     06 fe            ;  Delta X of -2
    ld a,001h                        ; 15a7     3e 01            ;  Rack now moving right
l15a9h:                                                         
    ld (rack_direction),a            ; 15a9     32 0d 20         ;  Set new rack direction
    ld a,b                           ; 15ac     78               ;  B has delta X
    ld (ref_alien_dxr),a             ; 15ad     32 08 20         ;  Set new delta X
    ld a,(rack_down_delta)           ; 15b0     3a 0e 20         ;  Set delta Y ...
    ld (ref_alien_dyr),a             ; 15b3     32 07 20         ;  ... to drop rack by 8
    ret                              ; 15b6     c9               ;  Done
l15b7h:                                                         
    ld hl,02524h                     ; 15b7     21 24 25         ;  Line down the left edge of playfield
    call check_column                ; 15ba     cd c5 15         ;  Check line down the edge
    ret nc                           ; 15bd     d0               ;  Nothing is there ... return
    call get_delta_x                 ; 15be     cd f1 18         ;  Get moving-right delta X value of 2 (3 if just one alien left)
    xor a                            ; 15c1     af               ;  Rack now moving left
    jp l15a9h                        ; 15c2     c3 a9 15         ;  Set rack direction

check_column:                                                      
    ld b,017h                        ; 15c5     06 17            ;  Checking 23 bytes in a line up the screen from near the bottom
l15c7h:                                                         
    ld a,(hl)                        ; 15c7     7e               ;  Get screen memory
    and a                            ; 15c8     a7               ;  Is screen memory empty?
    jp nz,l166bh                     ; 15c9     c2 6b 16         ;  No ... set carry flag and out
    inc hl                           ; 15cc     23               ;  Next byte on screen
    dec b                            ; 15cd     05               ;  All column done?
    jp nz,l15c7h                     ; 15ce     c2 c7 15         ;  No ... keep looking
    ret                              ; 15d1     c9               ;  Return with carry flag clear

    nop                              ; 15d2     00               ;  ** Why? Something optimized?

draw_sprite:                                                    
    call cnvt_pix_number             ; 15d3     cd 74 14         ;  Convert pixel number to screen/shift
    push hl                          ; 15d6     e5               ;  Preserve screen coordinate
l15d7h:                                                         
    push bc                          ; 15d7     c5               ;  Hold for a second
    push hl                          ; 15d8     e5               ;  Hold for a second
    ld a,(de)                        ; 15d9     1a               ;  From sprite data
    out (004h),a                     ; 15da     d3 04            ;  Write data to shift register
    in a,(003h)                      ; 15dc     db 03            ;  Read back shifted amount
    ld (hl),a                        ; 15de     77               ;  Shifted sprite to screen
    inc hl                           ; 15df     23               ;  Adjacent cell
    inc de                           ; 15e0     13               ;  Next in sprite data
    xor a                            ; 15e1     af               ;  0
    out (004h),a                     ; 15e2     d3 04            ;  Write 0 to shift register
    in a,(003h)                      ; 15e4     db 03            ;  Read back remainder of previous
    ld (hl),a                        ; 15e6     77               ;  Write remainder to adjacent
    pop hl                           ; 15e7     e1               ;  Old screen coordinate
    ld bc,l0020h                     ; 15e8     01 20 00         ;  Offset screen ...
    add hl,bc                        ; 15eb     09               ;  ... to next row
    pop bc                           ; 15ec     c1               ;  Restore count
    dec b                            ; 15ed     05               ;  All done?
    jp nz,l15d7h                     ; 15ee     c2 d7 15         ;  No ... do all
    pop hl                           ; 15f1     e1               ;  Restore HL
    ret                              ; 15f2     c9               ;  Done

count_aliens:                                                   
    call get_player_data_ptr         ; 15f3     cd 11 16         ;  Get active player descriptor
    ld bc,03700h                     ; 15f6     01 00 37         ;  B=55 aliens to check?
l15f9h:                                                         
    ld a,(hl)                        ; 15f9     7e               ;  Get byte
    and a                            ; 15fa     a7               ;  Is it a zero?
    jp z,l15ffh                      ; 15fb     ca ff 15         ;  Yes ... don't count it
    inc c                            ; 15fe     0c               ;  Count the live aliens
l15ffh:                                                         
    inc hl                           ; 15ff     23               ;  Next alien
    dec b                            ; 1600     05               ;  Count ...
    jp nz,l15f9h                     ; 1601     c2 f9 15         ;  ... all alien indicators
    ld a,c                           ; 1604     79               ;  Get the count
    ld (num_aliens),a                ; 1605     32 82 20         ;  Hold it
    cp 001h                          ; 1608     fe 01            ;  Just one?
    ret nz                           ; 160a     c0               ;  No keep going
    ld hl,0206bh                     ; 160b     21 6b 20         ;  Set flag if ...
    ld (hl),001h                     ; 160e     36 01            ;  ... only one alien left
    ret                              ; 1610     c9               ;  Out

get_player_data_ptr:                                            
    ld l,000h                        ; 1611     2e 00            ;  Byte boundary
    ld a,(player_data_msb)           ; 1613     3a 67 20         ;  Active player number
    ld h,a                           ; 1616     67               ;  Set HL to data
    ret                              ; 1617     c9               ;  Done

plr_fire_or_demo:                                               
    ld a,(player_alive)              ; 1618     3a 15 20         ;  Is there an active player?
    cp 0ffh                          ; 161b     fe ff            ;  FF = alive
    ret nz                           ; 161d     c0               ;  Player has been shot - no firing
    ld hl,02010h                     ; 161e     21 10 20         ;  Get player ...
    ld a,(hl)                        ; 1621     7e               ;  ... task ...
    inc hl                           ; 1622     23               ;  ... timer ...
    ld b,(hl)                        ; 1623     46               ;  ... value
    or b                             ; 1624     b0               ;  Is the timer 0 (object active)?
    ret nz                           ; 1625     c0               ;  No ... no firing till player object starts
    ld a,(plyr_shot_status)          ; 1626     3a 25 20         ;  Does the player have ...
    and a                            ; 1629     a7               ;  ... a shot on the screen?
    ret nz                           ; 162a     c0               ;  Yes ... ignore
    ld a,(game_mode)                 ; 162b     3a ef 20         ;  Are we in ...
    and a                            ; 162e     a7               ;  ... game mode?
    jp z,l1652h                      ; 162f     ca 52 16         ;  No ... in demo mode ... constant firing in demo
    ld a,(fire_bounce)               ; 1632     3a 2d 20         ;  Is fire button ...
    and a                            ; 1635     a7               ;  ... being held down?
    jp nz,l1648h                     ; 1636     c2 48 16         ;  Yes ... wait for bounce
    call read_inputs                 ; 1639     cd c0 17         ;  Read active player controls
    and 010h                         ; 163c     e6 10            ;  Fire-button pressed?
    ret z                            ; 163e     c8               ;  No ... out
    ld a,001h                        ; 163f     3e 01            ;  Flag
    ld (plyr_shot_status),a          ; 1641     32 25 20         ;  Flag shot active
    ld (fire_bounce),a               ; 1644     32 2d 20         ;  Flag that fire button is down
    ret                              ; 1647     c9               ;  Out

l1648h:                                                         
    call read_inputs                 ; 1648     cd c0 17         ;  Read active player controls
    and 010h                         ; 164b     e6 10            ;  Fire-button pressed?
    ret nz                           ; 164d     c0               ;  Yes ... ignore
    ld (fire_bounce),a               ; 164e     32 2d 20         ;  Else ... clear flag
    ret                              ; 1651     c9               ;  Out

l1652h:                                                         
    ld hl,plyr_shot_status           ; 1652     21 25 20         ;  Demo fires ...
    ld (hl),001h                     ; 1655     36 01            ;  ... constantly
    ld hl,(demo_cmd_ptr_lsb)         ; 1657     2a ed 20         ;  Demo command buffer
    inc hl                           ; 165a     23               ;  Next position
    ld a,l                           ; 165b     7d               ;  Command buffer ...
    cp 07eh                          ; 165c     fe 7e            ;  ... wraps around
    jp c,l1663h                      ; 165e     da 63 16         ;  ... Buffer from 1F74 to 1F7E
    ld l,074h                        ; 1661     2e 74            ;  ... overflow
l1663h:                                                         
    ld (demo_cmd_ptr_lsb),hl         ; 1663     22 ed 20         ;  Next demo command
    ld a,(hl)                        ; 1666     7e               ;  Get next command
    ld (next_demo_cmd),a             ; 1667     32 1d 20         ;  Set command for movement
    ret                              ; 166a     c9               ;  Done

l166bh:                                                         
    scf                              ; 166b     37               ;  Set carry flag
    ret                              ; 166c     c9               ;  Done

l166dh:                                                         
    xor a                            ; 166d     af               ;  0
    call print_num_ships_in_acc      ; 166e     cd 8b 1a         ;  Print ZERO ships remain
l1671h:                                                         
    call cur_ply_alive               ; 1671     cd 10 19         ;  Get active-flag ptr for current player
    ld (hl),000h                     ; 1674     36 00            ;  Flag player is dead
    call get_player_score_descriptor ; 1676     cd ca 09         ;  Get score descriptor for current player
    inc hl                           ; 1679     23               ;  Point to high two digits
    ld de,020f5h                     ; 167a     11 f5 20         ;  Current high score upper two digits
    ld a,(de)                        ; 167d     1a               ;  Is player score greater ...
    cp (hl)                          ; 167e     be               ;  ... than high score?
    dec de                           ; 167f     1b               ;  Point to LSB
    dec hl                           ; 1680     2b               ;  Point to LSB
    ld a,(de)                        ; 1681     1a               ;  Go ahead and fetch high score lower two digits
    jp z,l168bh                      ; 1682     ca 8b 16         ;  Upper two are the same ... have to check lower two
    jp nc,l1698h                     ; 1685     d2 98 16         ;  Player score is lower than high ... nothing to do
    jp l168fh                        ; 1688     c3 8f 16         ;  Player socre is higher ... go copy the new high score

l168bh:                                                         
    cp (hl)                          ; 168b     be               ;  Is lower digit higher? (upper was the same)
    jp nc,l1698h                     ; 168c     d2 98 16         ;  No ... high score is still greater than player's score
l168fh:                                                         
    ld a,(hl)                        ; 168f     7e               ;  Copy the new ...
    ld (de),a                        ; 1690     12               ;  ... high score lower two digits
    inc de                           ; 1691     13               ;  Point to MSB
    inc hl                           ; 1692     23               ;  Point to MSB
    ld a,(hl)                        ; 1693     7e               ;  Copy the new ...
    ld (de),a                        ; 1694     12               ;  ... high score upper two digits
    call print_hi_score              ; 1695     cd 50 19         ;  Draw the new high score
l1698h:                                                         
    ld a,(two_players)               ; 1698     3a ce 20         ;  Number of players
    and a                            ; 169b     a7               ;  Is this a single player game?
    jp z,l16c9h                      ; 169c     ca c9 16         ;  Yes ... short message
    ld hl,02803h                     ; 169f     21 03 28         ;  Screen coordinates
    ld de,msg_game_over_player_x     ; 16a2     11 a6 1a         ;  "GAME OVER PLAYER< >"
    ld c,014h                        ; 16a5     0e 14            ;  20 characters
    call print_message_del           ; 16a7     cd 93 0a         ;  Print message
    dec h                            ; 16aa     25               ;  Back up ...
    dec h                            ; 16ab     25               ;  ... to player indicator
    ld b,01bh                        ; 16ac     06 1b            ;  "1"
    ld a,(player_data_msb)           ; 16ae     3a 67 20         ;  Player number
    rrca                             ; 16b1     0f               ;  Is this player 1?
    jp c,l16b7h                      ; 16b2     da b7 16         ;  Yes ... keep the digit
    ld b,01ch                        ; 16b5     06 1c            ;  Else ... set digit 2
l16b7h:                                                         
    ld a,b                           ; 16b7     78               ;  To A
    call draw_char                   ; 16b8     cd ff 08         ;  Print player number
    call one_sec_delay               ; 16bb     cd b1 0a         ;  Short delay
    call get_player_alive_ptr        ; 16be     cd e7 18         ;  Get current player "alive" flag
    ld a,(hl)                        ; 16c1     7e               ;  Is player ...
    and a                            ; 16c2     a7               ;  ... alive?
    jp z,l16c9h                      ; 16c3     ca c9 16         ;  No ... skip to "GAME OVER" sequence
    jp l02edh                        ; 16c6     c3 ed 02         ;  Switch players and game loop

l16c9h:                                                         
    ld hl,02d18h                     ; 16c9     21 18 2d         ;  Screen coordinates
    ld de,msg_game_over_player_x     ; 16cc     11 a6 1a         ;  "GAME OVER PLAYER< >"
    ld c,00ah                        ; 16cf     0e 0a            ;  Just the "GAME OVER" part
    call print_message_del           ; 16d1     cd 93 0a         ;  Print message
    call two_sec_delay               ; 16d4     cd b6 0a         ;  Long delay
    call clear_play_field            ; 16d7     cd d6 09         ;  Clear center window
    xor a                            ; 16da     af               ;  Now in ...
    ld (game_mode),a                 ; 16db     32 ef 20         ;  ... demo mode
    out (005h),a                     ; 16de     d3 05            ;  All sound off
    call enable_game_tasks           ; 16e0     cd d1 19         ;  Enable ISR game tasks
    jp l0b89h                        ; 16e3     c3 89 0b         ;  Print credit information and do splash

l16e6h:                                                         
    ld sp,02400h                     ; 16e6     31 00 24         ;  Reset stack
    ei                               ; 16e9     fb               ;  Enable interrupts
    xor a                            ; 16ea     af               ;  Flag ...
    ld (player_alive),a              ; 16eb     32 15 20         ;  ... player is shot
l16eeh:                                                         
    call player_shot_hit             ; 16ee     cd d8 14         ;  Player's shot collision detection
    ld b,004h                        ; 16f1     06 04            ;  Player has been hit ...
    call sound_bits3on               ; 16f3     cd fa 18         ;  ... sound
    call flag_player_hit             ; 16f6     cd 59 0a         ;  Has flag been set?
    jp nz,l16eeh                     ; 16f9     c2 ee 16         ;  No ... wait for the flag
    call dsable_game_tasks           ; 16fc     cd d7 19         ;  Disable ISR game tasks
    ld hl,02701h                     ; 16ff     21 01 27         ;  Player's stash of ships
    call erase_ship_stash            ; 1702     cd fa 19         ;  Erase the stash of shps
    xor a                            ; 1705     af               ;  Print ...
    call print_num_ships_in_acc      ; 1706     cd 8b 1a         ;  ... a zero (number of ships)
    ld b,0fbh                        ; 1709     06 fb            ;  Turn off ...
    jp l196bh                        ; 170b     c3 6b 19         ;  ... player shot sound

ashot_reload_rate:                                              
    call get_player_score_descriptor ; 170e     cd ca 09         ;  Get score descriptor for active player
    inc hl                           ; 1711     23               ;  MSB value
    ld a,(hl)                        ; 1712     7e               ;  Get the MSB value
    ld de,score_msb_table            ; 1713     11 b8 1c         ;  Score MSB table
    ld hl,shot_reload_rate           ; 1716     21 a1 1a         ;  Corresponding fire reload rate table
    ld c,004h                        ; 1719     0e 04            ;  Only 4 entries (a 5th value of 7 is used after that)
    ld b,a                           ; 171b     47               ;  Hold the score value
l171ch:                                                         
    ld a,(de)                        ; 171c     1a               ;  Get lookup from table
    cp b                             ; 171d     b8               ;  Compare them
    jp nc,l1727h                     ; 171e     d2 27 17         ;  Equal or below ... use this table entry
    inc hl                           ; 1721     23               ;  Next ...
    inc de                           ; 1722     13               ;  ... entry in table
    dec c                            ; 1723     0d               ;  Do all ...
    jp nz,l171ch                     ; 1724     c2 1c 17         ;  ... 4 entries in the tables
l1727h:                                                         
    ld a,(hl)                        ; 1727     7e               ;  Load the shot reload value
    ld (a_shot_reload_rate),a        ; 1728     32 cf 20         ;  Save the value for use in shot routine
    ret                              ; 172b     c9               ;  Done

shot_sound:                                                     
    ld a,(plyr_shot_status)          ; 172c     3a 25 20         ;  Player shot flag
    cp 000h                          ; 172f     fe 00            ;  Active shot?
    jp nz,l1739h                     ; 1731     c2 39 17         ;  Yes ... go
    ld b,0fdh                        ; 1734     06 fd            ;  Sound mask
    jp sound_bits3off                ; 1736     c3 dc 19         ;  Mask off sound

l1739h:                                                         
    ld b,002h                        ; 1739     06 02            ;  Sound bit
    jp sound_bits3on                 ; 173b     c3 fa 18         ;  OR on sound

    nop                              ; 173e     00               ;  ** Why?
    nop                              ; 173f     00              

time_fleet_sound:                                               
    ld hl,fleet_snd_hold             ; 1740     21 9b 20         ;  Pointer to hold time for fleet
    dec (hl)                         ; 1743     35               ;  Decrement hold time
    call z,sub_176dh                 ; 1744     cc 6d 17         ;  If 0 turn fleet movement sound off
    ld a,(player_ok)                 ; 1747     3a 68 20         ;  Is player OK?
    and a                            ; 174a     a7               ;  1  means OK
    jp z,sub_176dh                   ; 174b     ca 6d 17         ;  Player not OK ... fleet movement sound off and out
    ld hl,02096h                     ; 174e     21 96 20         ;  Current time on fleet sound
    dec (hl)                         ; 1751     35               ;  Count down
    ret nz                           ; 1752     c0               ;  Not time to change sound ... out
    ld hl,sound_port5                ; 1753     21 98 20         ;  Current sound port 3 value
    ld a,(hl)                        ; 1756     7e               ;  Get value
    out (005h),a                     ; 1757     d3 05            ;  Set sounds
    ld a,(num_aliens)                ; 1759     3a 82 20         ;  Number of aliens on active screen
    and a                            ; 175c     a7               ;  Is it zero?
    jp z,sub_176dh                   ; 175d     ca 6d 17         ;  Yes ... turn off fleet movement sound and out
    dec hl                           ; 1760     2b               ;  (2097) Point to fleet timer reload
    ld a,(hl)                        ; 1761     7e               ;  Get fleet delay value
    dec hl                           ; 1762     2b               ;  (2096) Point to fleet timer
    ld (hl),a                        ; 1763     77               ;  Reload the timer
    dec hl                           ; 1764     2b               ;  Point to change-sound
    ld (hl),001h                     ; 1765     36 01            ;  (2095) time to change sound
    ld a,004h                        ; 1767     3e 04            ;  Set hold ...
    ld (fleet_snd_hold),a            ; 1769     32 9b 20         ;  ... time for fleet sound
    ret                              ; 176c     c9               ;  Done

sub_176dh:                                                      
    ld a,(sound_port5)               ; 176d     3a 98 20         ;  Current sound port 3 value
fleet_sound_off:                                                      
    and 030h                         ; 1770     e6 30            ;  Mask off fleet movement sounds
    out (005h),a                     ; 1772     d3 05            ;  Set sounds
    ret                              ; 1774     c9               ;  Out

fleet_delay_ex_ship:                                            
    ld a,(change_fleet_snd)          ; 1775     3a 95 20         ;  Time for new ...
    and a                            ; 1778     a7               ;  ... fleet movement sound?
    jp z,l17aah                      ; 1779     ca aa 17         ;  No ... skip to extra-man timing
    ld hl,table_number_of_aliens     ; 177c     21 11 1a         ;  Number of aliens list coupled ...
    ld de,table_associated_delay     ; 177f     11 21 1a         ;  ... with delay list
    ld a,(num_aliens)                ; 1782     3a 82 20         ;  Get the number of aliens on the screen
l1785h:                                                         
    cp (hl)                          ; 1785     be               ;  Compare it to the first list value
    jp nc,l178eh                     ; 1786     d2 8e 17         ;  Number of live aliens is higher than value ... use the delay
    inc hl                           ; 1789     23               ;  Move to ...
    inc de                           ; 178a     13               ;  ... next list value
    jp l1785h                        ; 178b     c3 85 17         ;  Find the right delay

l178eh:                                                         
    ld a,(de)                        ; 178e     1a               ;  Get the delay from the second list
    ld (fleet_snd_reload),a          ; 178f     32 97 20         ;  Store the new alien sound delay
    ld hl,sound_port5                ; 1792     21 98 20         ;  Get current state ...
    ld a,(hl)                        ; 1795     7e               ;  ... of sound port
    and 030h                         ; 1796     e6 30            ;  Mask off all fleet movement sounds
    ld b,a                           ; 1798     47               ;  Hold the value
    ld a,(hl)                        ; 1799     7e               ;  Get current state
    and 00fh                         ; 179a     e6 0f            ;  This time ONLY the fleet movement sounds
    rlca                             ; 179c     07               ;  Shift next to next sound
    cp 010h                          ; 179d     fe 10            ;  Overflow?
    jp nz,l17a4h                     ; 179f     c2 a4 17         ;  No ... keep it
    ld a,001h                        ; 17a2     3e 01            ;  Reset back to first sound
l17a4h:                                                         
    or b                             ; 17a4     b0               ;  Add fleet sounds to current sound value
    ld (hl),a                        ; 17a5     77               ;  Store new sound value
    xor a                            ; 17a6     af               ;  Restart ...
    ld (change_fleet_snd),a          ; 17a7     32 95 20         ;  ... waiting on fleet time
l17aah:                                                         
    ld hl,extra_hold                 ; 17aa     21 99 20         ;  Sound timer for award extra ship
    dec (hl)                         ; 17ad     35               ;  Time expired?
    ret nz                           ; 17ae     c0               ;  No ... leave sound playing
    ld b,0efh                        ; 17af     06 ef            ;  Turn off bit set with #$10 (award extra ship)
    jp sound_bits3off                ; 17b1     c3 dc 19         ;  Stop sound and out

    ld b,0efh                        ; 17b4     06 ef            ;  Mask off sound bit 4 (Extended play)
    ld hl,sound_port5                ; 17b6     21 98 20         ;  Current sound content
    ld a,(hl)                        ; 17b9     7e               ;  Get current sound bits
    and b                            ; 17ba     a0               ;  Turn off extended play
    ld (hl),a                        ; 17bb     77               ;  Remember settings
    out (005h),a                     ; 17bc     d3 05            ;  Turn off extended play
    ret                              ; 17be     c9               ;  Out

    nop                              ; 17bf     00               ;  ** Why?

read_inputs:                                                    
    ld a,(player_data_msb)           ; 17c0     3a 67 20         ;  Get active player
    rrca                             ; 17c3     0f               ;  Test player
    jp nc,l17cah                     ; 17c4     d2 ca 17         ;  Player 2 ... read port 2
    in a,(001h)                      ; 17c7     db 01            ;  Player 1 ... read port 1
    ret                              ; 17c9     c9               ;  Out

l17cah:                                                         
    in a,(002h)                      ; 17ca     db 02            ;  Get controls for player 2
    ret                              ; 17cc     c9               ;  Out

check_handle_tilt:                                              
    in a,(002h)                      ; 17cd     db 02            ;  Read input port
    and 004h                         ; 17cf     e6 04            ;  Tilt?
    ret z                            ; 17d1     c8               ;  No tilt ... return
    ld a,(tilt)                      ; 17d2     3a 9a 20         ;  Already in TILT handle?
    and a                            ; 17d5     a7               ;  1 = yes
    ret nz                           ; 17d6     c0               ;  Yes ... ignore it now
    ld sp,02400h                     ; 17d7     31 00 24         ;  Reset stack
    ld b,004h                        ; 17da     06 04            ;  Do this 4 times
l17dch:                                                         
    call clear_play_field            ; 17dc     cd d6 09         ;  Clear center window
    dec b                            ; 17df     05               ;  All done?
    jp nz,l17dch                     ; 17e0     c2 dc 17         ;  No ... do again
    ld a,001h                        ; 17e3     3e 01            ;  Flag ...
    ld (tilt),a                      ; 17e5     32 9a 20         ;  ... handling TILT
    call dsable_game_tasks           ; 17e8     cd d7 19         ;  Disable game tasks
    ei                               ; 17eb     fb               ;  Re-enable interrupts
    ld de,msg_tilt                   ; 17ec     11 bc 1c         ;  Message "TILT"
    ld hl,03016h                     ; 17ef     21 16 30         ;  Center of screen
    ld c,004h                        ; 17f2     0e 04            ;  Four letters
    call print_message_del           ; 17f4     cd 93 0a         ;  Print "TILT"
    call one_sec_delay               ; 17f7     cd b1 0a         ;  Short delay
    xor a                            ; 17fa     af               ;  Zero
    ld (tilt),a                      ; 17fb     32 9a 20         ;  TILT handle over
    ld (wait_start_loop),a           ; 17fe     32 93 20         ;  Back into splash screens
    jp l16c9h                        ; 1801     c3 c9 16         ;  Handle game over for player

ctrl_saucer_sound:                                              
    ld hl,saucer_active              ; 1804     21 84 20         ;  Saucer on screen flag
    ld a,(hl)                        ; 1807     7e               ;  Is the saucer ...
    and a                            ; 1808     a7               ;  ... on the screen?
    jp z,l0707h                      ; 1809     ca 07 07         ;  No ... UFO sound off
    inc hl                           ; 180c     23               ;  Saucer hit flag
    ld a,(hl)                        ; 180d     7e               ;  (2085) Get saucer hit flag
    and a                            ; 180e     a7               ;  Is saucer in "hit" sequence?
    ret nz                           ; 180f     c0               ;  Yes ... out
    ld b,001h                        ; 1810     06 01            ;  Retrigger saucer ...
    jp sound_bits3on                 ; 1812     c3 fa 18         ;  ... sound (retrigger makes it warble?)

draw_adv_table:                                                 
    ld hl,02810h                     ; 1815     21 10 28         ;  0x410 is 1040 rotCol=32, rotRow=16
    ld de,msg_score_advance_table    ; 1818     11 a3 1c         ;  "*SCORE ADVANCE TABLE*"
    ld c,015h                        ; 181b     0e 15            ;  21 bytes in message
    call print_message               ; 181d     cd f3 08         ;  Print message
    ld a,00ah                        ; 1820     3e 0a            ;  10 bytes in every "=xx POINTS" string
    ld (temp206c),a                  ; 1822     32 6c 20         ;  Hold the count
    ld bc,table_coord_sprite_score   ; 1825     01 be 1d         ;  Coordinate/sprite for drawing table
l1828h:                                                         
    call read_print_struct           ; 1828     cd 56 18         ;  Get HL=coordinate, DE=image
    jp c,l1837h                      ; 182b     da 37 18         ;  Move on if done
    call draw_wide_sprite            ; 182e     cd 44 18         ;  Draw 16-byte sprite
    jp l1828h                        ; 1831     c3 28 18         ;  Do all in table

    call one_sec_delay               ; 1834     cd b1 0a         ;  One second delay
l1837h:                                                         
    ld bc,table_coord_msg_score      ; 1837     01 cf 1d         ;  Coordinate/message for drawing table
slow_print_descrs:                                                      
    call read_print_struct           ; 183a     cd 56 18         ;  Get HL=coordinate, DE=message
    ret c                            ; 183d     d8               ;  Out if done
    call print_msg_slow              ; 183e     cd 4c 18         ;  Print message
    jp slow_print_descrs             ; 1841     c3 3a 18         ;  Do all in table

draw_wide_sprite:                                                      
    push bc                          ; 1844     c5               ;  Hold BC
    ld b,010h                        ; 1845     06 10            ;  16 bytes
    call draw_simp_sprite            ; 1847     cd 39 14         ;  Draw simple
    pop bc                           ; 184a     c1               ;  Restore BC
    ret                              ; 184b     c9               ;  Out

print_msg_slow:                                                      
    push bc                          ; 184c     c5               ;  Hold BC
    ld a,(temp206c)                  ; 184d     3a 6c 20         ;  Count of 10 ...
    ld c,a                           ; 1850     4f               ;  ... to C
    call print_message_del           ; 1851     cd 93 0a         ;  Print the message with delay between letters
    pop bc                           ; 1854     c1               ;  Restore BC
    ret                              ; 1855     c9               ;  Out

read_print_struct:                                                
    ld a,(bc)                        ; 1856     0a               ;  Get the screen LSB
    cp 0ffh                          ; 1857     fe ff            ;  Valid?
    scf                              ; 1859     37               ;  If not Carry will be Set
    ret z                            ; 185a     c8               ;  Return if 255
    ld l,a                           ; 185b     6f               ;  Screen LSB to L
    inc bc                           ; 185c     03               ;  Next
    ld a,(bc)                        ; 185d     0a               ;  Read screen MSB
    ld h,a                           ; 185e     67               ;  Screen MSB to H
    inc bc                           ; 185f     03               ;  Next
    ld a,(bc)                        ; 1860     0a               ;  Read message LSB
    ld e,a                           ; 1861     5f               ;  Message LSB to E
    inc bc                           ; 1862     03               ;  Next
    ld a,(bc)                        ; 1863     0a               ;  Read message MSB
    ld d,a                           ; 1864     57               ;  Message MSB to D
    inc bc                           ; 1865     03               ;  Next (for next print)
    and a                            ; 1866     a7               ;  Clear Carry
    ret                              ; 1867     c9               ;  Done

splash_sprite:                                                  
    ld hl,splash_an_form             ; 1868     21 c2 20         ;  Descriptor
    inc (hl)                         ; 186b     34               ;  Change image
    inc hl                           ; 186c     23               ;  Point to delta-x
    ld c,(hl)                        ; 186d     4e               ;  Get delta-x
    call add_delta                   ; 186e     cd d9 01         ;  Add delta-X and delta-Y to X and Y
    ld b,a                           ; 1871     47               ;  Current y coordinate
    ld a,(splash_target_y)           ; 1872     3a ca 20         ;  Has sprite reached ...
    cp b                             ; 1875     b8               ;  ... target coordinate?
    jp z,l1898h                      ; 1876     ca 98 18         ;  Yes ... flag and out
    ld a,(splash_an_form)            ; 1879     3a c2 20         ;  Image number
    and 004h                         ; 187c     e6 04            ;  Watching bit 3 for flip delay
    ld hl,(splash_im_rest_lsb)       ; 187e     2a cc 20         ;  Image
    jp nz,l1888h                     ; 1881     c2 88 18         ;  Did bit 3 go to 0? No ... keep current image
    ld de,l0030h                     ; 1884     11 30 00         ;  16*3 ...
    add hl,de                        ; 1887     19               ;  ...  use other image form
l1888h:                                                         
    ld (splash_image_lsb),hl         ; 1888     22 c7 20         ;  Image to descriptor structure
    ld hl,020c5h                     ; 188b     21 c5 20         ;  X,Y,Image descriptor
    call read_desc                   ; 188e     cd 3b 1a         ;  Read sprite descriptor
    ex de,hl                         ; 1891     eb               ;  Image to DE, position to HL
    jp draw_sprite                   ; 1892     c3 d3 15         ;  Draw the sprite

    nop                              ; 1895     00              
    nop                              ; 1896     00              
    nop                              ; 1897     00              
l1898h:                                                         
    ld a,001h                        ; 1898     3e 01            ;  Flag that sprite ...
    ld (splash_reached),a            ; 189a     32 cb 20         ;  ... reached location
    ret                              ; 189d     c9               ;  Out

sub_189eh:                                                      
    ld hl,game_object_4              ; 189e     21 50 20         ;  Task descriptor for game object 4 (squiggly shot)
    ld de,l1bc0h                     ; 18a1     11 c0 1b         ;  Task info for animate-shot-to-extra-C
    ld b,010h                        ; 18a4     06 10            ;  Block copy ...
    call block_copy                  ; 18a6     cd 32 1a         ;  ... 16 bytes
    ld a,002h                        ; 18a9     3e 02            ;  Set shot sync ...
    ld (shot_sync),a                 ; 18ab     32 80 20         ;  ... to run the squiggly shot
    ld a,0ffh                        ; 18ae     3e ff            ;  Shot direction (-1)
    ld (alien_shot_delta),a          ; 18b0     32 7e 20         ;  Alien shot delta
    ld a,004h                        ; 18b3     3e 04            ;  Animate ...
    ld (isr_splash_task),a           ; 18b5     32 c1 20         ;  ... shot
l18b8h:                                                         
    ld a,(squ_shot_status)           ; 18b8     3a 55 20         ;  Has shot ...
    and 001h                         ; 18bb     e6 01            ;  ... collided?
    jp z,l18b8h                      ; 18bd     ca b8 18         ;  No ... keep waiting
l18c0h:                                                         
    ld a,(squ_shot_status)           ; 18c0     3a 55 20         ;  Wait ...
    and 001h                         ; 18c3     e6 01            ;  ... for explosion ...
    jp nz,l18c0h                     ; 18c5     c2 c0 18         ;  ... to finish
    ld hl,03311h                     ; 18c8     21 11 33         ;  Here is where the extra C is
    ld a,026h                        ; 18cb     3e 26            ;  Space character
    nop                              ; 18cd     00               ;  ** Why?
    call draw_char                   ; 18ce     cd ff 08         ;  Draw character
    jp two_sec_delay                 ; 18d1     c3 b6 0a         ;  Two second delay and out

init:                                                           
    ld sp,02400h                     ; 18d4     31 00 24         ;  Set stack pointer just below screen
    ld b,000h                        ; 18d7     06 00            ;  Count 256 bytes
    call copy_rom_to_ram             ; 18d9     cd e6 01         ;  Copy ROM to RAM
    call draw_status                 ; 18dc     cd 56 19         ;  Print scores and credits
l18dfh:                                                         
    ld a,008h                        ; 18df     3e 08            ;  Set alien ...
    ld (a_shot_reload_rate),a        ; 18e1     32 cf 20         ;  ... shot reload rate
    jp l0aeah                        ; 18e4     c3 ea 0a         ;  Top of splash screen loop

get_player_alive_ptr:                                                      
    ld a,(player_data_msb)           ; 18e7     3a 67 20         ;  Player data MSB
    ld hl,player1alive               ; 18ea     21 e7 20         ;  Alive flags (player 1 and 2)
    rrca                             ; 18ed     0f               ;  Bit 1=1 for player 1
    ret nc                           ; 18ee     d0               ;  Player 2 ... we have it ... out
    inc hl                           ; 18ef     23               ;  Player 1's flag
    ret                              ; 18f0     c9               ;  Done

get_delta_x:                                                      
    ld b,002h                        ; 18f1     06 02            ;  Rack moving right delta X
    ld a,(num_aliens)                ; 18f3     3a 82 20         ;  Number of aliens on screen
    dec a                            ; 18f6     3d               ;  Just one left?
    ret nz                           ; 18f7     c0               ;  No ... use right delta X of 2
    inc b                            ; 18f8     04               ;  Just one alien ... move right at 3 instead of 2
    ret                              ; 18f9     c9               ;  Done

sound_bits3on:                                                  
    ld a,(sound_port3)               ; 18fa     3a 94 20         ;  Current value of sound port
    or b                             ; 18fd     b0               ;  Add in new sounds
    ld (sound_port3),a               ; 18fe     32 94 20         ;  New value of sound port
    out (003h),a                     ; 1901     d3 03            ;  Write new value to sound hardware
    ret                              ; 1903     c9              

init_aliens_player_two:                                                 
    ld hl,02200h                     ; 1904     21 00 22         ;  Player 2 data area
    jp l01c3h                        ; 1907     c3 c3 01         ;  Initialize player 2 aliens

plyr_shot_and_bump:                                             
    call player_shot_hit             ; 190a     cd d8 14         ;  Player's shot collision detection
    jp rack_bump                     ; 190d     c3 97 15         ;  Change alien deltaX and deltaY when rack bumps edges

cur_ply_alive:                                                  
    ld hl,player1alive               ; 1910     21 e7 20         ;  Alive flags
    ld a,(player_data_msb)           ; 1913     3a 67 20         ;  Player 1 or 2
    rrca                             ; 1916     0f               ;  Will be 1 if player 1
    ret c                            ; 1917     d8               ;  Return if player 1
    inc hl                           ; 1918     23               ;  Bump to player 2
    ret                              ; 1919     c9               ;  Return

draw_score_head:                                                
    ld c,01ch                        ; 191a     0e 1c            ;  28 bytes in message
    ld hl,0241eh                     ; 191c     21 1e 24         ;  Screen coordinates
    ld de,msg_score_header           ; 191f     11 e4 1a         ;  Score header message
    jp print_message                 ; 1922     c3 f3 08         ;  Print score header

print_player_one_score:                                                      
    ld hl,p1scor_l                   ; 1925     21 f8 20         ;  Player 1 score descriptor
    jp draw_score                    ; 1928     c3 31 19         ;  Print score

print_player_two_score:                                                      
    ld hl,p2scor_l                   ; 192b     21 fc 20         ;  Player 2 score descriptor
    jp draw_score                    ; 192e     c3 31 19         ;  Print score

draw_score:                                                     
    ld e,(hl)                        ; 1931     5e               ;  Get score LSB
    inc hl                           ; 1932     23               ;  Next
    ld d,(hl)                        ; 1933     56               ;  Get score MSB
    inc hl                           ; 1934     23               ;  Next
    ld a,(hl)                        ; 1935     7e               ;  Get coordinate LSB
    inc hl                           ; 1936     23               ;  Next
    ld h,(hl)                        ; 1937     66               ;  Get coordiante MSB
    ld l,a                           ; 1938     6f               ;  Set LSB
    jp draw_hex_word                 ; 1939     c3 ad 09         ;  Print 4 digits in DE

print_credit_label:                                                      
    ld c,007h                        ; 193c     0e 07            ;  7 bytes in message
    ld hl,03501h                     ; 193e     21 01 35         ;  Screen coordinates
    ld de,msg_credit                 ; 1941     11 a9 1f         ;  Message = "CREDIT "
    jp print_message                 ; 1944     c3 f3 08         ;  Print message

draw_num_credits:                                               
    ld a,(num_coins)                 ; 1947     3a eb 20         ;  Number of credits
    ld hl,03c01h                     ; 194a     21 01 3c         ;  Screen coordinates
    jp draw_hex_byte                 ; 194d     c3 b2 09         ;  Character to screen

print_hi_score:                                                 
    ld hl,020f4h                     ; 1950     21 f4 20         ;  Hi Score descriptor
    jp draw_score                    ; 1953     c3 31 19         ;  Print Hi-Score

draw_status:                                                    
    call clear_screen                ; 1956     cd 5c 1a         ;  Clear the screen
    call draw_score_head             ; 1959     cd 1a 19         ;  Print score header
    call print_player_one_score      ; 195c     cd 25 19         ;  Print player 1 score
    call print_player_two_score      ; 195f     cd 2b 19         ;  Print player 2 score
    call print_hi_score              ; 1962     cd 50 19         ;  Print hi score
    call print_credit_label          ; 1965     cd 3c 19         ;  Print credit lable
    jp draw_num_credits              ; 1968     c3 47 19         ;  Number of credits

l196bh:                                                         
    call sound_bits3off              ; 196b     cd dc 19         ;  From 170B with B=FB. Turn off player shot sound
    jp l1671h                        ; 196e     c3 71 16         ;  Update high-score if player's score is greater

l1971h:                                                         
    ld a,001h                        ; 1971     3e 01            ;  Set flag that ...
    ld (invaded),a                   ; 1973     32 6d 20         ;  ... aliens reached bottom of screen
    jp l16e6h                        ; 1976     c3 e6 16         ;  End of round

suspend_game_tasks:                                                      
    call dsable_game_tasks           ; 1979     cd d7 19         ;  Disable ISR game tasks
    call draw_num_credits            ; 197c     cd 47 19         ;  Display number of credits on screen
    jp print_credit_label            ; 197f     c3 3c 19         ;  Print message "CREDIT"

control_isr_splash_from_acc:                                                      
    ld (isr_splash_task),a           ; 1982     32 c1 20         ;  Set ISR splash task
    ret                              ; 1985     c9               ;  Done

    adc a,e                          ; 1986     8b               ;  Points to print TAITO CORPORATION message ... not sure why
    add hl,de                        ; 1987     19              
clear_playfield_taito_msg:                                                      
    jp clear_play_field              ; 1988     c3 d6 09         ;  Clear playfield and out

    ld hl,02803h                     ; 198b     21 03 28         ;  Screen coordinates
    ld de,msg_taito_corporation      ; 198e     11 be 19         ;  Message "*TAITO CORPORATION*"
    ld c,013h                        ; 1991     0e 13            ;  Message length
    jp print_message                 ; 1993     c3 f3 08         ;  Print message

    nop                              ; 1996     00               ;  ** Why?
    nop                              ; 1997     00              
    nop                              ; 1998     00              
    nop                              ; 1999     00              

check_hidden_mes:                                               
    ld a,(hid_mess_seq)              ; 199a     3a 1e 20         ;  Has the 1st "hidden-message" sequence ...
    and a                            ; 199d     a7               ;  ... been registered?
    jp nz,l19ach                     ; 199e     c2 ac 19         ;  Yes ... go look for the 2nd sequence
    in a,(001h)                      ; 19a1     db 01            ;  Get player inputs
    and 076h                         ; 19a3     e6 76            ;  0111_0110 Keep 2Pstart, 1Pstart, 1Pshot, 1Pleft, 1Pright
    sub 072h                         ; 19a5     d6 72            ;  0111_0010 1st sequence: 2Pstart, 1Pshot, 1Pleft, 1Pright
    ret nz                           ; 19a7     c0               ;  Not first sequence ... out
    inc a                            ; 19a8     3c               ;  Flag that 1st sequence ...
    ld (hid_mess_seq),a              ; 19a9     32 1e 20         ;  ... has been entered
l19ach:                                                         
    in a,(001h)                      ; 19ac     db 01            ;  Check inputs for 2nd sequence
    and 076h                         ; 19ae     e6 76            ;  0111_0110 Keep 2Pstart, 1Pstart, 1Pshot, 1Pleft, 1Pright
    cp 034h                          ; 19b0     fe 34            ;  0011_0100 2nd sequence: 1Pstart, 1Pshot, 1Pleft
    ret nz                           ; 19b2     c0               ;  If not second sequence ignore
    ld hl,02e1bh                     ; 19b3     21 1b 2e         ;  Screen coordinates
    ld de,msg_taito_cop              ; 19b6     11 f7 0b         ;  Message = "TAITO COP" (no R)
    ld c,009h                        ; 19b9     0e 09            ;  Message length
    jp print_message                 ; 19bb     c3 f3 08         ;  Print message and out

d_end:                                                          
                                                                
; BLOCK 'e' (start 0x19be end 0x19d1)                           
e_first:                                                        
msg_taito_corporation:
    defb 028h                        ; 19be     28              
    defb 013h                        ; 19bf     13              
    defb 000h                        ; 19c0     00              
    defb 008h                        ; 19c1     08              
    defb 013h                        ; 19c2     13              
    defb 00eh                        ; 19c3     0e              
    defb 026h                        ; 19c4     26              
    defb 002h                        ; 19c5     02              
    defb 00eh                        ; 19c6     0e              
    defb 011h                        ; 19c7     11              
    defb 00fh                        ; 19c8     0f              
    defb 00eh                        ; 19c9     0e              
    defb 011h                        ; 19ca     11              
    defb 000h                        ; 19cb     00              
    defb 013h                        ; 19cc     13              
    defb 008h                        ; 19cd     08              
    defb 00eh                        ; 19ce     0e              
    defb 00dh                        ; 19cf     0d              
    defb 028h                        ; 19d0     28              
e_end:                                                          
                                                                
; BLOCK 'f' (start 0x19d1 end 0x1a11)                           
f_first:                                                        
enable_game_tasks:                                              
    ld a,001h                        ; 19d1     3e 01            ;  Set ISR ...
l19d3h:                                                         
    ld (suspend_play),a              ; 19d3     32 e9 20         ;  ... game tasks enabled
    ret                              ; 19d6     c9               ;  Done

dsable_game_tasks:                                              
    xor a                            ; 19d7     af               ;  Clear ISR game tasks flag
    jp l19d3h                        ; 19d8     c3 d3 19         ;  Save a byte (the RET)

    nop                              ; 19db     00               ;  ** Here is the byte saved. I wonder if this was an optimizer pass.

sound_bits3off:                                                 
    ld a,(sound_port3)               ; 19dc     3a 94 20         ;  Current sound effects value
    and b                            ; 19df     a0               ;  Mask bits off
    ld (sound_port3),a               ; 19e0     32 94 20         ;  Store new hold value
    out (003h),a                     ; 19e3     d3 03            ;  Change sounds
    ret                              ; 19e5     c9               ;  Done

draw_num_ships:                                                 
    ld hl,02701h                     ; 19e6     21 01 27         ;  Screen coordinates
    jp z,erase_ship_stash            ; 19e9     ca fa 19         ;  None in reserve ... skip display
l19ech:                                                         
    ld de,sprite_player              ; 19ec     11 60 1c         ;  Player sprite
    ld b,010h                        ; 19ef     06 10            ;  16 rows
    ld c,a                           ; 19f1     4f               ;  Hold count
    call draw_simp_sprite            ; 19f2     cd 39 14         ;  Display 1byte sprite to screen
    ld a,c                           ; 19f5     79               ;  Restore remaining
    dec a                            ; 19f6     3d               ;  All done?
    jp nz,l19ech                     ; 19f7     c2 ec 19         ;  No ... keep going
erase_ship_stash:                                                      
    ld b,010h                        ; 19fa     06 10            ;  16 rows
    call clear_small_sprite          ; 19fc     cd cb 14         ;  Clear 1byte sprite at HL
    ld a,h                           ; 19ff     7c               ;  Get Y coordinate
    cp 035h                          ; 1a00     fe 35            ;  At edge?
    jp nz,erase_ship_stash           ; 1a02     c2 fa 19         ;  No ... do all
    ret                              ; 1a05     c9               ;  Out

comp_yto_beam:                                                  
    ld hl,vblank_status              ; 1a06     21 72 20         ;  Get the ...
    ld b,(hl)                        ; 1a09     46               ;  ... beam position status
    ld a,(de)                        ; 1a0a     1a               ;  Get the task structure flag
    and 080h                         ; 1a0b     e6 80            ;  Only upper bits count
    xor b                            ; 1a0d     a8               ;  XOR them together
    ret nz                           ; 1a0e     c0               ;  Not the same (CF cleared)
    scf                              ; 1a0f     37               ;  Set the CF if the same
    ret                              ; 1a10     c9               ;  Done
f_end:                                                          
                                                                
; BLOCK 'h' (start 0x1a11 end 0x1a32)                           
h_first:                                                        
table_number_of_aliens:                                          ; congruent with table_associated_delay
    defb 032h                        ; 1a11     32              
    defb 02bh                        ; 1a12     2b              
    defb 024h                        ; 1a13     24              
    defb 01ch                        ; 1a14     1c              
    defb 016h                        ; 1a15     16              
    defb 011h                        ; 1a16     11              
    defb 00dh                        ; 1a17     0d              
    defb 00ah                        ; 1a18     0a              
    defb 008h                        ; 1a19     08              
    defb 007h                        ; 1a1a     07              
    defb 006h                        ; 1a1b     06              
    defb 005h                        ; 1a1c     05              
    defb 004h                        ; 1a1d     04              
    defb 003h                        ; 1a1e     03              
    defb 002h                        ; 1a1f     02              
    defb 001h                        ; 1a20     01              
table_associated_delay:                                          ; congruent with table_number_of_aliens
    defb 034h                        ; 1a21     34              
    defb 02eh                        ; 1a22     2e              
    defb 027h                        ; 1a23     27              
    defb 022h                        ; 1a24     22              
    defb 01ch                        ; 1a25     1c              
    defb 018h                        ; 1a26     18              
    defb 015h                        ; 1a27     15              
    defb 013h                        ; 1a28     13              
    defb 010h                        ; 1a29     10              
    defb 00eh                        ; 1a2a     0e              
    defb 00dh                        ; 1a2b     0d              
    defb 00ch                        ; 1a2c     0c              
    defb 00bh                        ; 1a2d     0b              
    defb 009h                        ; 1a2e     09              
    defb 007h                        ; 1a2f     07              
    defb 005h                        ; 1a30     05              
    defb 0ffh                        ; 1a31     ff               ;  ** Needless terminator. The list value "1" catches everything.
h_end:                                                          
                                                                
; BLOCK 'i' (start 0x1a32 end 0x1a93)                           
i_first:                                                        
block_copy:                                                     
    ld a,(de)                        ; 1a32     1a               ;  Copy from [DE] to ...
    ld (hl),a                        ; 1a33     77               ;  ... [HL]
    inc hl                           ; 1a34     23               ;  Next destination
    inc de                           ; 1a35     13               ;  Next source
    dec b                            ; 1a36     05               ;  Count in B
    jp nz,block_copy                 ; 1a37     c2 32 1a         ;  Do all
    ret                              ; 1a3a     c9               ;  Done

read_desc:                                                      
    ld e,(hl)                        ; 1a3b     5e               ;  Descriptor ...
    inc hl                           ; 1a3c     23               ;  ... sprite ...
    ld d,(hl)                        ; 1a3d     56               ;  ...
    inc hl                           ; 1a3e     23               ;  ... picture
    ld a,(hl)                        ; 1a3f     7e               ;  Descriptor ...
    inc hl                           ; 1a40     23               ;  ... screen ...
    ld c,(hl)                        ; 1a41     4e               ;  ...
    inc hl                           ; 1a42     23               ;  ... location
    ld b,(hl)                        ; 1a43     46               ;  Number of bytes in sprite
    ld h,c                           ; 1a44     61               ;  From A,C to ...
    ld l,a                           ; 1a45     6f               ;  ... H,L
    ret                              ; 1a46     c9               ;  Done

conv_to_scr:                                                    
    push bc                          ; 1a47     c5               ;  Hold B (will mangle)
    ld b,003h                        ; 1a48     06 03            ;  3 shifts (divide by 8)
l1a4ah:                                                         
    ld a,h                           ; 1a4a     7c               ;  H to A
    rra                              ; 1a4b     1f               ;  Shift right (into carry, from doesn't matter)
    ld h,a                           ; 1a4c     67               ;  Back to H
    ld a,l                           ; 1a4d     7d               ;  L to A
    rra                              ; 1a4e     1f               ;  Shift right (from/to carry)
    ld l,a                           ; 1a4f     6f               ;  Back to L
    dec b                            ; 1a50     05               ;  Do all ...
    jp nz,l1a4ah                     ; 1a51     c2 4a 1a         ;  ... 3 shifts
    ld a,h                           ; 1a54     7c               ;  H to A
    and 03fh                         ; 1a55     e6 3f            ;  Mask off all but screen (less than or equal 3F)
    or 020h                          ; 1a57     f6 20            ;  Offset into RAM
    ld h,a                           ; 1a59     67               ;  Back to H
    pop bc                           ; 1a5a     c1               ;  Restore B
    ret                              ; 1a5b     c9               ;  Done

clear_screen:                                                   
    ld hl,02400h                     ; 1a5c     21 00 24         ;  Screen coordinate
l1a5fh:                                                         
    ld (hl),000h                     ; 1a5f     36 00            ;  Clear it
    inc hl                           ; 1a61     23               ;  Next byte
    ld a,h                           ; 1a62     7c               ;  Have we done ...
    cp 040h                          ; 1a63     fe 40            ;  ... all the screen?
    jp nz,l1a5fh                     ; 1a65     c2 5f 1a         ;  No ... keep going
    ret                              ; 1a68     c9               ;  Out

restore_shields:                                                
    push bc                          ; 1a69     c5               ;  Preserve BC
    push hl                          ; 1a6a     e5               ;  Hold for a bit
l1a6bh:                                                         
    ld a,(de)                        ; 1a6b     1a               ;  From sprite
    or (hl)                          ; 1a6c     b6               ;  OR with screen
    ld (hl),a                        ; 1a6d     77               ;  Back to screen
    inc de                           ; 1a6e     13               ;  Next sprite
    inc hl                           ; 1a6f     23               ;  Next on screen
    dec c                            ; 1a70     0d               ;  Row done?
    jp nz,l1a6bh                     ; 1a71     c2 6b 1a         ;  No ... do entire row
    pop hl                           ; 1a74     e1               ;  Original start
    ld bc,l0020h                     ; 1a75     01 20 00         ;  Bump HL by ...
    add hl,bc                        ; 1a78     09               ;  ... one screen row
    pop bc                           ; 1a79     c1               ;  Restore
    dec b                            ; 1a7a     05               ;  Row counter
    jp nz,restore_shields            ; 1a7b     c2 69 1a         ;  Do all rows
    ret                              ; 1a7e     c9              

remove_ship:                                                    
    call get_num_ships_active_player ; 1a7f     cd 2e 09         ;  Get last byte from player data
    and a                            ; 1a82     a7               ;  Is it 0?
    ret z                            ; 1a83     c8               ;  Skip
    push af                          ; 1a84     f5               ;  Preserve number remaining
    dec a                            ; 1a85     3d               ;  Remove a ship from the stash
    ld (hl),a                        ; 1a86     77               ;  New number of ships
    call draw_num_ships              ; 1a87     cd e6 19         ;  Draw the line of ships
    pop af                           ; 1a8a     f1               ;  Restore number
print_num_ships_in_acc:                                                      
    ld hl,02501h                     ; 1a8b     21 01 25         ;  Screen coordinates
    and 00fh                         ; 1a8e     e6 0f            ;  Make sure it is a digit
    jp draw_digit_in_acc             ; 1a90     c3 c5 09         ;  Print number remaining
i_end:                                                          
                                                                
; BLOCK 'g' (start 0x1a93 end 0x1fff)                           
g_first:                                                        
    defb 000h                        ; 1a93     00              
    defb 000h                        ; 1a94     00              

                                     ; Splash screen animation structure 1
                                     ; 00   Image form (increments each draw)
                                     ; 00   Delta X
                                     ; FF   Delta Y is -1
                                     ; B8   X coordinate
                                     ; FE   Y starting coordiante
                                     ; 1C20 Base image (small alien)
                                     ; 10   Size of image (16 bytes)
                                     ; 9E   Target Y coordiante
                                     ; 00   Reached Y flag
                                     ; 1C20 Base iamge (small alien)
splash_animation_struct_1:                                                         
    defb 000h                        ; 1a95     00              
    defb 000h                        ; 1a96     00              
    defb 0ffh                        ; 1a97     ff              
    defb 0b8h                        ; 1a98     b8              
    defb 0feh                        ; 1a99     fe              
    defb 020h                        ; 1a9a     20              
    defb 01ch                        ; 1a9b     1c              
    defb 010h                        ; 1a9c     10              
    defb 09eh                        ; 1a9d     9e              
    defb 000h                        ; 1a9e     00              
    defb 020h                        ; 1a9f     20              
    defb 01ch                        ; 1aa0     1c              

                                     ; The tables at 1cb8 AND 1aa1 control how fast shots are created. The speed is based
                                     ; on the upper byte of the player's score. For a score of less than or equal 0200 then
                                     ; the fire speed is 30. For a score less than or equal 1000 the shot speed is 10. Less
                                     ; than or equal 2000 the speed is 0B. Less than or equal 3000 is 08. And anything
                                     ; above 3000 is 07.
shot_reload_rate:                                                         
    defb 030h                        ; 1aa1     30              
    defb 010h                        ; 1aa2     10              
    defb 00bh                        ; 1aa3     0b              
    defb 008h                        ; 1aa4     08              
    defb 007h                        ; 1aa5     07              
msg_game_over_player_x:                                                         
    defb 006h                        ; 1aa6     06              
    defb 000h                        ; 1aa7     00              
    defb 00ch                        ; 1aa8     0c              
    defb 004h                        ; 1aa9     04              
    defb 026h                        ; 1aaa     26              
    defb 00eh                        ; 1aab     0e              
    defb 015h                        ; 1aac     15              
    defb 004h                        ; 1aad     04              
    defb 011h                        ; 1aae     11              
    defb 026h                        ; 1aaf     26              
    defb 026h                        ; 1ab0     26              
    defb 00fh                        ; 1ab1     0f              
    defb 00bh                        ; 1ab2     0b              
    defb 000h                        ; 1ab3     00              
    defb 018h                        ; 1ab4     18              
    defb 004h                        ; 1ab5     04              
    defb 011h                        ; 1ab6     11              
    defb 024h                        ; 1ab7     24              
    defb 026h                        ; 1ab8     26              
    defb 025h                        ; 1ab9     25              
msg_one_or_two_players_btn:                                                         
    defb 01bh                        ; 1aba     1b              
    defb 026h                        ; 1abb     26              
    defb 00eh                        ; 1abc     0e              
    defb 011h                        ; 1abd     11              
    defb 026h                        ; 1abe     26              
    defb 01ch                        ; 1abf     1c              
    defb 00fh                        ; 1ac0     0f              
    defb 00bh                        ; 1ac1     0b              
    defb 000h                        ; 1ac2     00              
    defb 018h                        ; 1ac3     18              
    defb 004h                        ; 1ac4     04              
    defb 011h                        ; 1ac5     11              
    defb 012h                        ; 1ac6     12              
    defb 026h                        ; 1ac7     26              
    defb 001h                        ; 1ac8     01              
    defb 014h                        ; 1ac9     14              
    defb 013h                        ; 1aca     13              
    defb 013h                        ; 1acb     13              
    defb 00eh                        ; 1acc     0e              
    defb 00dh                        ; 1acd     0d              
    defb 026h                        ; 1ace     26              
only_one_player_btn:                                                         
    defb 00eh                        ; 1acf     0e              
    defb 00dh                        ; 1ad0     0d              
    defb 00bh                        ; 1ad1     0b              
    defb 018h                        ; 1ad2     18              
    defb 026h                        ; 1ad3     26              
    defb 01bh                        ; 1ad4     1b              
    defb 00fh                        ; 1ad5     0f              
    defb 00bh                        ; 1ad6     0b              
    defb 000h                        ; 1ad7     00              
    defb 018h                        ; 1ad8     18              
    defb 004h                        ; 1ad9     04              
    defb 011h                        ; 1ada     11              
    defb 026h                        ; 1adb     26              
    defb 026h                        ; 1adc     26              
    defb 001h                        ; 1add     01              
    defb 014h                        ; 1ade     14              
    defb 013h                        ; 1adf     13              
    defb 013h                        ; 1ae0     13              
    defb 00eh                        ; 1ae1     0e              
    defb 00dh                        ; 1ae2     0d              
    defb 026h                        ; 1ae3     26              
msg_score_header:                                                         
    defb 026h                        ; 1ae4     26              
    defb 012h                        ; 1ae5     12              
    defb 002h                        ; 1ae6     02              
    defb 00eh                        ; 1ae7     0e              
    defb 011h                        ; 1ae8     11              
    defb 004h                        ; 1ae9     04              
    defb 024h                        ; 1aea     24              
    defb 01bh                        ; 1aeb     1b              
    defb 025h                        ; 1aec     25              
    defb 026h                        ; 1aed     26              
    defb 007h                        ; 1aee     07              
    defb 008h                        ; 1aef     08              
    defb 03fh                        ; 1af0     3f              
    defb 012h                        ; 1af1     12              
    defb 002h                        ; 1af2     02              
    defb 00eh                        ; 1af3     0e              
    defb 011h                        ; 1af4     11              
    defb 004h                        ; 1af5     04              
    defb 026h                        ; 1af6     26              
    defb 012h                        ; 1af7     12              
    defb 002h                        ; 1af8     02              
    defb 00eh                        ; 1af9     0e              
    defb 011h                        ; 1afa     11              
    defb 004h                        ; 1afb     04              
    defb 024h                        ; 1afc     24              
    defb 01ch                        ; 1afd     1c              
    defb 025h                        ; 1afe     25              
    defb 026h                        ; 1aff     26              

ram_mirror:                                                         
    defb 001h                        ; 1b00     01              
    defb 000h                        ; 1b01     00              
    defb 000h                        ; 1b02     00              
    defb 010h                        ; 1b03     10              
    defb 000h                        ; 1b04     00              
    defb 000h                        ; 1b05     00              
    defb 000h                        ; 1b06     00              
    defb 000h                        ; 1b07     00              
    defb 002h                        ; 1b08     02              
    defb 078h                        ; 1b09     78              
    defb 038h                        ; 1b0a     38              
    defb 078h                        ; 1b0b     78              
    defb 038h                        ; 1b0c     38              
    defb 000h                        ; 1b0d     00              
    defb 0f8h                        ; 1b0e     f8              
    defb 000h                        ; 1b0f     00              
game_object_0_init:                                                         
    defb 000h                        ; 1b10     00              ; timer
    defb 080h                        ; 1b11     80              ; timer
    defb 000h                        ; 1b12     00              ; timer
    defb 08eh                        ; 1b13     8e              ; vec?
    defb 002h                        ; 1b14     02              
    defb 0ffh                        ; 1b15     ff              
    defb 005h                        ; 1b16     05              
    defb 00ch                        ; 1b17     0c              
    defb 060h                        ; 1b18     60              
    defb 01ch                        ; 1b19     1c              
    defb 020h                        ; 1b1a     20              
    defb 030h                        ; 1b1b     30              
    defb 010h                        ; 1b1c     10              
    defb 001h                        ; 1b1d     01              
    defb 000h                        ; 1b1e     00              
    defb 000h                        ; 1b1f     00              
game_object_1_init:
    defb 000h                        ; 1b20     00              ; timer
    defb 000h                        ; 1b21     00              ; timer
    defb 000h                        ; 1b22     00              ; timer
    defb 0bbh                        ; 1b23     bb              ; vec game object 1
    defb 003h                        ; 1b24     03              
shot_struct:                                                         
    defb 000h                        ; 1b25     00              
    defb 010h                        ; 1b26     10              
    defb 090h                        ; 1b27     90              
    defb 01ch                        ; 1b28     1c              
    defb 028h                        ; 1b29     28              
    defb 030h                        ; 1b2a     30              
    defb 001h                        ; 1b2b     01              
    defb 004h                        ; 1b2c     04              
    defb 000h                        ; 1b2d     00              
    defb 0ffh                        ; 1b2e     ff              
    defb 0ffh                        ; 1b2f     ff              
game_object_2_init:                                                         
    defb 000h                        ; 1b30     00              ; timer
    defb 000h                        ; 1b31     00              ; tuner
game_object_2_init_timer:            
    defb 002h                        ; 1b32     02              ; timer
    defb 076h                        ; 1b33     76              ; vec game object 2
    defb 004h                        ; 1b34     04              
    defb 000h                        ; 1b35     00              
    defb 000h                        ; 1b36     00              
    defb 000h                        ; 1b37     00              
    defb 000h                        ; 1b38     00              
    defb 000h                        ; 1b39     00              
    defb 004h                        ; 1b3a     04              
    defb 0eeh                        ; 1b3b     ee              
    defb 01ch                        ; 1b3c     1c              
    defb 000h                        ; 1b3d     00              
    defb 000h                        ; 1b3e     00              
    defb 003h                        ; 1b3f     03              
game_object_3_init:                                                         
    defb 000h                        ; 1b40     00              ; timer 
    defb 000h                        ; 1b41     00              ; timer
    defb 000h                        ; 1b42     00              ; timer
    defb 0b6h                        ; 1b43     b6              ; vec game object 3
    defb 004h                        ; 1b44     04              
    defb 000h                        ; 1b45     00              
    defb 000h                        ; 1b46     00              
    defb 001h                        ; 1b47     01              
l1b48h:                                                         
    defb 000h                        ; 1b48     00              
    defb 01dh                        ; 1b49     1d              
    defb 004h                        ; 1b4a     04              
    defb 0e2h                        ; 1b4b     e2              
    defb 01ch                        ; 1b4c     1c              
    defb 000h                        ; 1b4d     00              
    defb 000h                        ; 1b4e     00              
    defb 003h                        ; 1b4f     03              
game_object_4_init:                  ; squiggly shot rom info
    defb 000h                        ; 1b50     00              ; timer
    defb 000h                        ; 1b51     00              ; timer
    defb 000h                        ; 1b52     00              ; timer
    defb 082h                        ; 1b53     82              ; vec game object 4
    defb 006h                        ; 1b54     06              
    defb 000h                        ; 1b55     00              
    defb 000h                        ; 1b56     00              
    defb 001h                        ; 1b57     01              
l1b58h:                                                         
    defb 006h                        ; 1b58     06              
    defb 01dh                        ; 1b59     1d              
    defb 004h                        ; 1b5a     04              
    defb 0d0h                        ; 1b5b     d0              
    defb 01ch                        ; 1b5c     1c              
    defb 000h                        ; 1b5d     00              
    defb 000h                        ; 1b5e     00              
    defb 003h                        ; 1b5f     03              
    defb 0ffh                        ; 1b60     ff              ; game object list end marker, see code at 024c
    defb 000h                        ; 1b61     00              
    defb 0c0h                        ; 1b62     c0              
    defb 01ch                        ; 1b63     1c              
    defb 000h                        ; 1b64     00              
    defb 000h                        ; 1b65     00              
    defb 010h                        ; 1b66     10              
    defb 021h                        ; 1b67     21              
    defb 001h                        ; 1b68     01              
    defb 000h                        ; 1b69     00              
    defb 030h                        ; 1b6a     30              
    defb 000h                        ; 1b6b     00              
    defb 012h                        ; 1b6c     12              
    defb 000h                        ; 1b6d     00              
    defb 000h                        ; 1b6e     00              
    defb 000h                        ; 1b6f     00              
msg_play_player_one:                                                         
    defb 00fh                        ; 1b70     0f              
    defb 00bh                        ; 1b71     0b              
    defb 000h                        ; 1b72     00              
    defb 018h                        ; 1b73     18              
    defb 026h                        ; 1b74     26              
    defb 00fh                        ; 1b75     0f              
    defb 00bh                        ; 1b76     0b              
    defb 000h                        ; 1b77     00              
    defb 018h                        ; 1b78     18              
    defb 004h                        ; 1b79     04              
    defb 011h                        ; 1b7a     11              
    defb 024h                        ; 1b7b     24              
    defb 01bh                        ; 1b7c     1b              
    defb 025h                        ; 1b7d     25              
    defb 0fch                        ; 1b7e     fc              
    defb 000h                        ; 1b7f     00              
    defb 001h                        ; 1b80     01              
    defb 0ffh                        ; 1b81     ff              
    defb 0ffh                        ; 1b82     ff              
data_for_saucer:                                                         
    defb 000h                        ; 1b83     00              
    defb 000h                        ; 1b84     00              
    defb 000h                        ; 1b85     00              
    defb 020h                        ; 1b86     20              
    defb 064h                        ; 1b87     64              
    defb 01dh                        ; 1b88     1d              
    defb 0d0h                        ; 1b89     d0              
    defb 029h                        ; 1b8a     29              
    defb 018h                        ; 1b8b     18              
    defb 002h                        ; 1b8c     02              
    defb 054h                        ; 1b8d     54              
    defb 01dh                        ; 1b8e     1d              
    defb 000h                        ; 1b8f     00              
    defb 008h                        ; 1b90     08              
    defb 000h                        ; 1b91     00              
    defb 006h                        ; 1b92     06              
    defb 000h                        ; 1b93     00              
    defb 000h                        ; 1b94     00              
    defb 001h                        ; 1b95     01              
    defb 040h                        ; 1b96     40              
    defb 000h                        ; 1b97     00              
    defb 001h                        ; 1b98     01              
    defb 000h                        ; 1b99     00              
    defb 000h                        ; 1b9a     00              
    defb 010h                        ; 1b9b     10              
    defb 09eh                        ; 1b9c     9e              
    defb 000h                        ; 1b9d     00              
    defb 020h                        ; 1b9e     20              
    defb 01ch                        ; 1b9f     1c              
    defb 000h                        ; 1ba0     00              
    defb 003h                        ; 1ba1     03              
    defb 004h                        ; 1ba2     04              
    defb 078h                        ; 1ba3     78              
    defb 014h                        ; 1ba4     14              
    defb 013h                        ; 1ba5     13              
    defb 008h                        ; 1ba6     08              
    defb 01ah                        ; 1ba7     1a              
    defb 03dh                        ; 1ba8     3d              
    defb 068h                        ; 1ba9     68              
    defb 0fch                        ; 1baa     fc              
    defb 0fch                        ; 1bab     fc              
    defb 068h                        ; 1bac     68              
    defb 03dh                        ; 1bad     3d              
    defb 01ah                        ; 1bae     1a              
    defb 000h                        ; 1baf     00              
l1bb0h:                                                         
    defb 000h                        ; 1bb0     00              
    defb 000h                        ; 1bb1     00              
    defb 001h                        ; 1bb2     01              
    defb 0b8h                        ; 1bb3     b8              
    defb 098h                        ; 1bb4     98              
    defb 0a0h                        ; 1bb5     a0              
    defb 01bh                        ; 1bb6     1b              
    defb 010h                        ; 1bb7     10              
    defb 0ffh                        ; 1bb8     ff              
    defb 000h                        ; 1bb9     00              
    defb 0a0h                        ; 1bba     a0              
    defb 01bh                        ; 1bbb     1b              
    defb 000h                        ; 1bbc     00              
    defb 000h                        ; 1bbd     00              
    defb 000h                        ; 1bbe     00              
    defb 000h                        ; 1bbf     00               ; last byte of ram mirror
l1bc0h:                                                         
    defb 000h                        ; 1bc0     00              
    defb 010h                        ; 1bc1     10              
    defb 000h                        ; 1bc2     00              
    defb 00eh                        ; 1bc3     0e              
    defb 005h                        ; 1bc4     05              
    defb 000h                        ; 1bc5     00              
    defb 000h                        ; 1bc6     00              
    defb 000h                        ; 1bc7     00              
    defb 000h                        ; 1bc8     00              
    defb 000h                        ; 1bc9     00              
    defb 007h                        ; 1bca     07              
    defb 0d0h                        ; 1bcb     d0              
    defb 01ch                        ; 1bcc     1c              
    defb 0c8h                        ; 1bcd     c8              
    defb 09bh                        ; 1bce     9b              
    defb 003h                        ; 1bcf     03              
    defb 000h                        ; 1bd0     00              
    defb 000h                        ; 1bd1     00              
    defb 003h                        ; 1bd2     03              
    defb 004h                        ; 1bd3     04              
    defb 078h                        ; 1bd4     78              
    defb 014h                        ; 1bd5     14              
    defb 00bh                        ; 1bd6     0b              
    defb 019h                        ; 1bd7     19              
    defb 03ah                        ; 1bd8     3a              
    defb 06dh                        ; 1bd9     6d              
    defb 0fah                        ; 1bda     fa              
    defb 0fah                        ; 1bdb     fa              
    defb 06dh                        ; 1bdc     6d              
    defb 03ah                        ; 1bdd     3a              
    defb 019h                        ; 1bde     19              
    defb 000h                        ; 1bdf     00              
    defb 000h                        ; 1be0     00              
    defb 000h                        ; 1be1     00              
    defb 000h                        ; 1be2     00              
    defb 000h                        ; 1be3     00              
    defb 000h                        ; 1be4     00              
    defb 000h                        ; 1be5     00              
    defb 000h                        ; 1be6     00              
    defb 000h                        ; 1be7     00              
    defb 000h                        ; 1be8     00              
    defb 001h                        ; 1be9     01              
    defb 000h                        ; 1bea     00              
    defb 000h                        ; 1beb     00              
    defb 001h                        ; 1bec     01              
    defb 074h                        ; 1bed     74              
    defb 01fh                        ; 1bee     1f              
    defb 000h                        ; 1bef     00              
    defb 080h                        ; 1bf0     80              
    defb 000h                        ; 1bf1     00              
    defb 000h                        ; 1bf2     00              
    defb 000h                        ; 1bf3     00              
    defb 000h                        ; 1bf4     00              
    defb 000h                        ; 1bf5     00              
    defb 01ch                        ; 1bf6     1c              
    defb 02fh                        ; 1bf7     2f              
    defb 000h                        ; 1bf8     00              
    defb 000h                        ; 1bf9     00              
    defb 01ch                        ; 1bfa     1c              
    defb 027h                        ; 1bfb     27              
    defb 000h                        ; 1bfc     00              
    defb 000h                        ; 1bfd     00              
    defb 01ch                        ; 1bfe     1c              
    defb 039h                        ; 1bff     39              
                                     ; end of ram_mirror
sprite_aliens_start_a:                                                         
    defb 000h                        ; 1c00     00              
    defb 000h                        ; 1c01     00              
    defb 039h                        ; 1c02     39              
    defb 079h                        ; 1c03     79              
    defb 07ah                        ; 1c04     7a              
    defb 06eh                        ; 1c05     6e              
    defb 0ech                        ; 1c06     ec              
    defb 0fah                        ; 1c07     fa              
    defb 0fah                        ; 1c08     fa              
    defb 0ech                        ; 1c09     ec              
    defb 06eh                        ; 1c0a     6e              
    defb 07ah                        ; 1c0b     7a              
    defb 079h                        ; 1c0c     79              
    defb 039h                        ; 1c0d     39              
    defb 000h                        ; 1c0e     00              
    defb 000h                        ; 1c0f     00              
    defb 000h                        ; 1c10     00              
    defb 000h                        ; 1c11     00              
    defb 000h                        ; 1c12     00              
    defb 078h                        ; 1c13     78              
    defb 01dh                        ; 1c14     1d              
    defb 0beh                        ; 1c15     be              
    defb 06ch                        ; 1c16     6c              
    defb 03ch                        ; 1c17     3c              
    defb 03ch                        ; 1c18     3c              
    defb 03ch                        ; 1c19     3c              
    defb 06ch                        ; 1c1a     6c              
    defb 0beh                        ; 1c1b     be              
    defb 01dh                        ; 1c1c     1d              
    defb 078h                        ; 1c1d     78              
    defb 000h                        ; 1c1e     00              
    defb 000h                        ; 1c1f     00              
sprite_alien_c_0:
    defb 000h                        ; 1c20     00              
    defb 000h                        ; 1c21     00              
    defb 000h                        ; 1c22     00              
    defb 000h                        ; 1c23     00              
    defb 019h                        ; 1c24     19              
    defb 03ah                        ; 1c25     3a              
    defb 06dh                        ; 1c26     6d              
    defb 0fah                        ; 1c27     fa              
    defb 0fah                        ; 1c28     fa              
    defb 06dh                        ; 1c29     6d              
    defb 03ah                        ; 1c2a     3a              
    defb 019h                        ; 1c2b     19              
    defb 000h                        ; 1c2c     00              
    defb 000h                        ; 1c2d     00              
    defb 000h                        ; 1c2e     00              
    defb 000h                        ; 1c2f     00              
sprite_aliens_start_b:
    defb 000h                        ; 1c30     00              
    defb 000h                        ; 1c31     00              
    defb 038h                        ; 1c32     38              
    defb 07ah                        ; 1c33     7a              
    defb 07fh                        ; 1c34     7f              
    defb 06dh                        ; 1c35     6d              
    defb 0ech                        ; 1c36     ec              
    defb 0fah                        ; 1c37     fa              
    defb 0fah                        ; 1c38     fa              
    defb 0ech                        ; 1c39     ec              
    defb 06dh                        ; 1c3a     6d              
    defb 07fh                        ; 1c3b     7f              
    defb 07ah                        ; 1c3c     7a              
    defb 038h                        ; 1c3d     38              
    defb 000h                        ; 1c3e     00              
    defb 000h                        ; 1c3f     00              
sprite_alien_b_1:
    defb 000h                        ; 1c40     00              
    defb 000h                        ; 1c41     00              
    defb 000h                        ; 1c42     00              
    defb 00eh                        ; 1c43     0e              
    defb 018h                        ; 1c44     18              
    defb 0beh                        ; 1c45     be              
    defb 06dh                        ; 1c46     6d              
    defb 03dh                        ; 1c47     3d              
    defb 03ch                        ; 1c48     3c              
    defb 03dh                        ; 1c49     3d              
    defb 06dh                        ; 1c4a     6d              
    defb 0beh                        ; 1c4b     be              
    defb 018h                        ; 1c4c     18              
    defb 00eh                        ; 1c4d     0e              
    defb 000h                        ; 1c4e     00              
    defb 000h                        ; 1c4f     00              
    defb 000h                        ; 1c50     00              
    defb 000h                        ; 1c51     00              
    defb 000h                        ; 1c52     00              
    defb 000h                        ; 1c53     00              
    defb 01ah                        ; 1c54     1a              
    defb 03dh                        ; 1c55     3d              
    defb 068h                        ; 1c56     68              
    defb 0fch                        ; 1c57     fc              
    defb 0fch                        ; 1c58     fc              
    defb 068h                        ; 1c59     68              
    defb 03dh                        ; 1c5a     3d              
    defb 01ah                        ; 1c5b     1a              
    defb 000h                        ; 1c5c     00              
    defb 000h                        ; 1c5d     00              
    defb 000h                        ; 1c5e     00              
    defb 000h                        ; 1c5f     00              
sprite_player:                                                         
    defb 000h                        ; 1c60     00              
    defb 000h                        ; 1c61     00              
    defb 00fh                        ; 1c62     0f              
    defb 01fh                        ; 1c63     1f              
    defb 01fh                        ; 1c64     1f              
    defb 01fh                        ; 1c65     1f              
    defb 01fh                        ; 1c66     1f              
    defb 07fh                        ; 1c67     7f              
    defb 0ffh                        ; 1c68     ff              
    defb 07fh                        ; 1c69     7f              
    defb 01fh                        ; 1c6a     1f              
    defb 01fh                        ; 1c6b     1f              
    defb 01fh                        ; 1c6c     1f              
    defb 01fh                        ; 1c6d     1f              
    defb 00fh                        ; 1c6e     0f              
    defb 000h                        ; 1c6f     00              
sprite_base_blowup:                                                         
    defb 000h                        ; 1c70     00              
    defb 004h                        ; 1c71     04              
    defb 001h                        ; 1c72     01              
    defb 013h                        ; 1c73     13              
    defb 003h                        ; 1c74     03              
    defb 007h                        ; 1c75     07              
    defb 0b3h                        ; 1c76     b3              
    defb 00fh                        ; 1c77     0f              
    defb 02fh                        ; 1c78     2f              
    defb 003h                        ; 1c79     03              
    defb 02fh                        ; 1c7a     2f              
    defb 049h                        ; 1c7b     49              
    defb 004h                        ; 1c7c     04              
    defb 003h                        ; 1c7d     03              
    defb 000h                        ; 1c7e     00              
    defb 001h                        ; 1c7f     01              
    defb 040h                        ; 1c80     40              
    defb 008h                        ; 1c81     08              
    defb 005h                        ; 1c82     05              
    defb 0a3h                        ; 1c83     a3              
    defb 00ah                        ; 1c84     0a              
    defb 003h                        ; 1c85     03              
    defb 05bh                        ; 1c86     5b              
    defb 00fh                        ; 1c87     0f              
    defb 027h                        ; 1c88     27              
    defb 027h                        ; 1c89     27              
    defb 00bh                        ; 1c8a     0b              
    defb 04bh                        ; 1c8b     4b              
    defb 040h                        ; 1c8c     40              
    defb 084h                        ; 1c8d     84              
    defb 011h                        ; 1c8e     11              
    defb 048h                        ; 1c8f     48              
player_shot_sprite:
    defb 00fh                        ; 1c90     0f              
    defb 099h                        ; 1c91     99              
    defb 03ch                        ; 1c92     3c              
    defb 07eh                        ; 1c93     7e              
    defb 03dh                        ; 1c94     3d              
    defb 0bch                        ; 1c95     bc              
    defb 03eh                        ; 1c96     3e              
    defb 07ch                        ; 1c97     7c              
    defb 099h                        ; 1c98     99              
    defb 027h                        ; 1c99     27              
    defb 01bh                        ; 1c9a     1b              
    defb 01ah                        ; 1c9b     1a              
    defb 026h                        ; 1c9c     26              
    defb 00fh                        ; 1c9d     0f              
    defb 00eh                        ; 1c9e     0e              
    defb 008h                        ; 1c9f     08              
    defb 00dh                        ; 1ca0     0d              
    defb 013h                        ; 1ca1     13              
    defb 012h                        ; 1ca2     12              
msg_score_advance_table:                                                         
    defb 028h                        ; 1ca3     28              
    defb 012h                        ; 1ca4     12              
    defb 002h                        ; 1ca5     02              
    defb 00eh                        ; 1ca6     0e              
    defb 011h                        ; 1ca7     11              
    defb 004h                        ; 1ca8     04              
    defb 026h                        ; 1ca9     26              
    defb 000h                        ; 1caa     00              
    defb 003h                        ; 1cab     03              
    defb 015h                        ; 1cac     15              
    defb 000h                        ; 1cad     00              
    defb 00dh                        ; 1cae     0d              
    defb 002h                        ; 1caf     02              
    defb 004h                        ; 1cb0     04              
    defb 026h                        ; 1cb1     26              
    defb 013h                        ; 1cb2     13              
    defb 000h                        ; 1cb3     00              
    defb 001h                        ; 1cb4     01              
    defb 00bh                        ; 1cb5     0b              
    defb 004h                        ; 1cb6     04              
    defb 028h                        ; 1cb7     28              
score_msb_table:                                                         
    defb 002h                        ; 1cb8     02              
    defb 010h                        ; 1cb9     10              
    defb 020h                        ; 1cba     20              
    defb 030h                        ; 1cbb     30              
msg_tilt:                                                         
    defb 013h                        ; 1cbc     13              
    defb 008h                        ; 1cbd     08              
    defb 00bh                        ; 1cbe     0b              
    defb 013h                        ; 1cbf     13              
alien_explode:
    defb 000h                        ; 1cc0     00              
    defb 008h                        ; 1cc1     08              
    defb 049h                        ; 1cc2     49              
    defb 022h                        ; 1cc3     22              
    defb 014h                        ; 1cc4     14              
    defb 081h                        ; 1cc5     81              
    defb 042h                        ; 1cc6     42              
    defb 000h                        ; 1cc7     00              
    defb 042h                        ; 1cc8     42              
    defb 081h                        ; 1cc9     81              
    defb 014h                        ; 1cca     14              
    defb 022h                        ; 1ccb     22              
    defb 049h                        ; 1ccc     49              
    defb 008h                        ; 1ccd     08              
    defb 000h                        ; 1cce     00              
    defb 000h                        ; 1ccf     00              
    defb 044h                        ; 1cd0     44              
    defb 0aah                        ; 1cd1     aa              
    defb 010h                        ; 1cd2     10              
    defb 088h                        ; 1cd3     88              
    defb 054h                        ; 1cd4     54              
    defb 022h                        ; 1cd5     22              
    defb 010h                        ; 1cd6     10              
    defb 0aah                        ; 1cd7     aa              
    defb 044h                        ; 1cd8     44              
    defb 022h                        ; 1cd9     22              
    defb 054h                        ; 1cda     54              
    defb 088h                        ; 1cdb     88              
sprite_ashot_explode:                                                         
    defb 04ah                        ; 1cdc     4a              
    defb 015h                        ; 1cdd     15              
    defb 0beh                        ; 1cde     be              
    defb 03fh                        ; 1cdf     3f              
    defb 05eh                        ; 1ce0     5e              
    defb 025h                        ; 1ce1     25              
    defb 004h                        ; 1ce2     04              
    defb 0fch                        ; 1ce3     fc              
    defb 004h                        ; 1ce4     04              
    defb 010h                        ; 1ce5     10              
    defb 0fch                        ; 1ce6     fc              
    defb 010h                        ; 1ce7     10              
    defb 020h                        ; 1ce8     20              
    defb 0fch                        ; 1ce9     fc              
    defb 020h                        ; 1cea     20              
    defb 080h                        ; 1ceb     80              
    defb 0fch                        ; 1cec     fc              
    defb 080h                        ; 1ced     80              
    defb 000h                        ; 1cee     00              
    defb 0feh                        ; 1cef     fe              
    defb 000h                        ; 1cf0     00              
    defb 024h                        ; 1cf1     24              
    defb 0feh                        ; 1cf2     fe              
    defb 012h                        ; 1cf3     12              
    defb 000h                        ; 1cf4     00              
    defb 0feh                        ; 1cf5     fe              
    defb 000h                        ; 1cf6     00              
    defb 048h                        ; 1cf7     48              
    defb 0feh                        ; 1cf8     fe              
    defb 090h                        ; 1cf9     90              
msg_play_upside_down:                                                         
    defb 00fh                        ; 1cfa     0f              
    defb 00bh                        ; 1cfb     0b              
    defb 000h                        ; 1cfc     00              
    defb 029h                        ; 1cfd     29              
    defb 000h                        ; 1cfe     00              
    defb 000h                        ; 1cff     00              
    defb 001h                        ; 1d00     01              
    defb 007h                        ; 1d01     07              
    defb 001h                        ; 1d02     01              
    defb 001h                        ; 1d03     01              
    defb 001h                        ; 1d04     01              
    defb 004h                        ; 1d05     04              
    defb 00bh                        ; 1d06     0b              
    defb 001h                        ; 1d07     01              
    defb 006h                        ; 1d08     06              
    defb 003h                        ; 1d09     03              
    defb 001h                        ; 1d0a     01              
    defb 001h                        ; 1d0b     01              
    defb 00bh                        ; 1d0c     0b              
    defb 009h                        ; 1d0d     09              
    defb 002h                        ; 1d0e     02              
    defb 008h                        ; 1d0f     08              
    defb 002h                        ; 1d10     02              
    defb 00bh                        ; 1d11     0b              
    defb 004h                        ; 1d12     04              
    defb 007h                        ; 1d13     07              
    defb 00ah                        ; 1d14     0a              
    defb 005h                        ; 1d15     05              
    defb 002h                        ; 1d16     02              
    defb 005h                        ; 1d17     05              
    defb 004h                        ; 1d18     04              
    defb 006h                        ; 1d19     06              
    defb 007h                        ; 1d1a     07              
    defb 008h                        ; 1d1b     08              
    defb 00ah                        ; 1d1c     0a              
    defb 006h                        ; 1d1d     06              
    defb 00ah                        ; 1d1e     0a              
    defb 003h                        ; 1d1f     03              
image_shield:                                                         
    defb 0ffh                        ; 1d20     ff              
    defb 00fh                        ; 1d21     0f              
    defb 0ffh                        ; 1d22     ff              
    defb 01fh                        ; 1d23     1f              
    defb 0ffh                        ; 1d24     ff              
    defb 03fh                        ; 1d25     3f              
    defb 0ffh                        ; 1d26     ff              
    defb 07fh                        ; 1d27     7f              
    defb 0ffh                        ; 1d28     ff              
    defb 0ffh                        ; 1d29     ff              
    defb 0fch                        ; 1d2a     fc              
    defb 0ffh                        ; 1d2b     ff              
    defb 0f8h                        ; 1d2c     f8              
    defb 0ffh                        ; 1d2d     ff              
    defb 0f0h                        ; 1d2e     f0              
    defb 0ffh                        ; 1d2f     ff              
    defb 0f0h                        ; 1d30     f0              
    defb 0ffh                        ; 1d31     ff              
    defb 0f0h                        ; 1d32     f0              
    defb 0ffh                        ; 1d33     ff              
    defb 0f0h                        ; 1d34     f0              
    defb 0ffh                        ; 1d35     ff              
    defb 0f0h                        ; 1d36     f0              
    defb 0ffh                        ; 1d37     ff              
    defb 0f0h                        ; 1d38     f0              
    defb 0ffh                        ; 1d39     ff              
    defb 0f0h                        ; 1d3a     f0              
    defb 0ffh                        ; 1d3b     ff              
    defb 0f8h                        ; 1d3c     f8              
    defb 0ffh                        ; 1d3d     ff              
    defb 0fch                        ; 1d3e     fc              
    defb 0ffh                        ; 1d3f     ff              
    defb 0ffh                        ; 1d40     ff              
    defb 0ffh                        ; 1d41     ff              
    defb 0ffh                        ; 1d42     ff              
    defb 0ffh                        ; 1d43     ff              
    defb 0ffh                        ; 1d44     ff              
    defb 07fh                        ; 1d45     7f              
    defb 0ffh                        ; 1d46     ff              
    defb 03fh                        ; 1d47     3f              
    defb 0ffh                        ; 1d48     ff              
    defb 01fh                        ; 1d49     1f              
    defb 0ffh                        ; 1d4a     ff              
    defb 00fh                        ; 1d4b     0f              
l1d4ch:                                                         
    defb 005h                        ; 1d4c     05              
    defb 010h                        ; 1d4d     10              
    defb 015h                        ; 1d4e     15              
    defb 030h                        ; 1d4f     30              
l1d50h:                                                         
    defb 094h                        ; 1d50     94              
    defb 097h                        ; 1d51     97              
    defb 09ah                        ; 1d52     9a              
    defb 09dh                        ; 1d53     9d              
    defb 010h                        ; 1d54     10              
    defb 005h                        ; 1d55     05              
    defb 005h                        ; 1d56     05              
    defb 010h                        ; 1d57     10              
    defb 015h                        ; 1d58     15              
    defb 010h                        ; 1d59     10              
    defb 010h                        ; 1d5a     10              
    defb 005h                        ; 1d5b     05              
    defb 030h                        ; 1d5c     30              
    defb 010h                        ; 1d5d     10              
    defb 010h                        ; 1d5e     10              
    defb 010h                        ; 1d5f     10              
    defb 005h                        ; 1d60     05              
    defb 015h                        ; 1d61     15              
    defb 010h                        ; 1d62     10              
    defb 005h                        ; 1d63     05              
    defb 000h                        ; 1d64     00              
    defb 000h                        ; 1d65     00              
    defb 000h                        ; 1d66     00              
    defb 000h                        ; 1d67     00              
sprite_flying_saucer:
    defb 004h                        ; 1d68     04              
    defb 00ch                        ; 1d69     0c              
    defb 01eh                        ; 1d6a     1e              
    defb 037h                        ; 1d6b     37              
    defb 03eh                        ; 1d6c     3e              
    defb 07ch                        ; 1d6d     7c              
    defb 074h                        ; 1d6e     74              
    defb 07eh                        ; 1d6f     7e              
    defb 07eh                        ; 1d70     7e              
    defb 074h                        ; 1d71     74              
    defb 07ch                        ; 1d72     7c              
    defb 03eh                        ; 1d73     3e              
    defb 037h                        ; 1d74     37              
    defb 01eh                        ; 1d75     1e              
    defb 00ch                        ; 1d76     0c              
    defb 004h                        ; 1d77     04              
    defb 000h                        ; 1d78     00              
    defb 000h                        ; 1d79     00              
    defb 000h                        ; 1d7a     00              
    defb 000h                        ; 1d7b     00              
sprite_saucer_blowup:                                                         
    defb 000h                        ; 1d7c     00              
    defb 022h                        ; 1d7d     22              
    defb 000h                        ; 1d7e     00              
    defb 0a5h                        ; 1d7f     a5              
    defb 040h                        ; 1d80     40              
    defb 008h                        ; 1d81     08              
    defb 098h                        ; 1d82     98              
    defb 03dh                        ; 1d83     3d              
    defb 0b6h                        ; 1d84     b6              
    defb 03ch                        ; 1d85     3c              
    defb 036h                        ; 1d86     36              
    defb 01dh                        ; 1d87     1d              
    defb 010h                        ; 1d88     10              
    defb 048h                        ; 1d89     48              
    defb 062h                        ; 1d8a     62              
    defb 0b6h                        ; 1d8b     b6              
    defb 01dh                        ; 1d8c     1d              
    defb 098h                        ; 1d8d     98              
    defb 008h                        ; 1d8e     08              
    defb 042h                        ; 1d8f     42              
    defb 090h                        ; 1d90     90              
    defb 008h                        ; 1d91     08              
    defb 000h                        ; 1d92     00              
    defb 000h                        ; 1d93     00              
    defb 026h                        ; 1d94     26              
    defb 01fh                        ; 1d95     1f              
    defb 01ah                        ; 1d96     1a              
    defb 01bh                        ; 1d97     1b              
    defb 01ah                        ; 1d98     1a              
    defb 01ah                        ; 1d99     1a              
    defb 01bh                        ; 1d9a     1b              
    defb 01fh                        ; 1d9b     1f              
    defb 01ah                        ; 1d9c     1a              
    defb 01dh                        ; 1d9d     1d              
    defb 01ah                        ; 1d9e     1a              
    defb 01ah                        ; 1d9f     1a              
table_alien_score_val:                                                         
    defb 010h                        ; 1da0     10               ; Bottom two rows
    defb 020h                        ; 1da1     20               ; Middle rows
coord_start_alien_table:                                         ; Lol, fuck me - preinc in loop                
    defb 030h                        ; 1da2     30               ; Weird overlap, this is the last of - Highest row.
    defb 060h                        ; 1da3     60              
    defb 050h                        ; 1da4     50              
    defb 048h                        ; 1da5     48              
    defb 048h                        ; 1da6     48              
    defb 048h                        ; 1da7     48              
    defb 040h                        ; 1da8     40              
    defb 040h                        ; 1da9     40              
    defb 040h                        ; 1daa     40              
msg_play_normal:                                                         
    defb 00fh                        ; 1dab     0f              
    defb 00bh                        ; 1dac     0b              
    defb 000h                        ; 1dad     00              
    defb 018h                        ; 1dae     18              
msg_space_invaders:                                                         
    defb 012h                        ; 1daf     12              
    defb 00fh                        ; 1db0     0f              
    defb 000h                        ; 1db1     00              
    defb 002h                        ; 1db2     02              
    defb 004h                        ; 1db3     04              
    defb 026h                        ; 1db4     26              
    defb 026h                        ; 1db5     26              
    defb 008h                        ; 1db6     08              
    defb 00dh                        ; 1db7     0d              
    defb 015h                        ; 1db8     15              
    defb 000h                        ; 1db9     00              
    defb 003h                        ; 1dba     03              
    defb 004h                        ; 1dbb     04              
    defb 011h                        ; 1dbc     11              
    defb 012h                        ; 1dbd     12              

table_coord_sprite_score:                                                         
    defb 00eh                        ; 1dbe     0e              
    defb 02ch                        ; 1dbf     2c              
    defb 068h                        ; 1dc0     68               ; ref 1d68
    defb 01dh                        ; 1dc1     1d              
    defb 00ch                        ; 1dc2     0c              
    defb 02ch                        ; 1dc3     2c              
    defb 020h                        ; 1dc4     20               ; ref 1c20 
    defb 01ch                        ; 1dc5     1c               
    defb 00ah                        ; 1dc6     0a              
    defb 02ch                        ; 1dc7     2c              
    defb 040h                        ; 1dc8     40               ; ref 1c40
    defb 01ch                        ; 1dc9     1c              
    defb 008h                        ; 1dca     08              
    defb 02ch                        ; 1dcb     2c              
    defb 000h                        ; 1dcc     00               ; ref 1c00
    defb 01ch                        ; 1dcd     1c              
    defb 0ffh                        ; 1dce     ff              

table_coord_msg_score:               ;                           ; references strings below
    defb 00eh                        ; 1dcf     0e              
    defb 02eh                        ; 1dd0     2e              
    defb 0e0h                        ; 1dd1     e0              
    defb 01dh                        ; 1dd2     1d              
    defb 00ch                        ; 1dd3     0c              
    defb 02eh                        ; 1dd4     2e              
    defb 0eah                        ; 1dd5     ea              
    defb 01dh                        ; 1dd6     1d              
    defb 00ah                        ; 1dd7     0a              
    defb 02eh                        ; 1dd8     2e              
    defb 0f4h                        ; 1dd9     f4              
    defb 01dh                        ; 1dda     1d              
    defb 008h                        ; 1ddb     08              
    defb 02eh                        ; 1ddc     2e              
    defb 099h                        ; 1ddd     99              
    defb 01ch                        ; 1dde     1c              
    defb 0ffh                        ; 1ddf     ff              

msg_mystery:
    defb 027h                        ; 1de0     27              
    defb 038h                        ; 1de1     38              
    defb 026h                        ; 1de2     26              
    defb 00ch                        ; 1de3     0c              
    defb 018h                        ; 1de4     18              
    defb 012h                        ; 1de5     12              
    defb 013h                        ; 1de6     13              
    defb 004h                        ; 1de7     04              
    defb 011h                        ; 1de8     11              
    defb 018h                        ; 1de9     18              

msg_thirty_points:
    defb 027h                        ; 1dea     27              
    defb 01dh                        ; 1deb     1d              
    defb 01ah                        ; 1dec     1a              
    defb 026h                        ; 1ded     26              
    defb 00fh                        ; 1dee     0f              
    defb 00eh                        ; 1def     0e              
    defb 008h                        ; 1df0     08              
    defb 00dh                        ; 1df1     0d              
    defb 013h                        ; 1df2     13              
    defb 012h                        ; 1df3     12              

msg_twenty_points:
    defb 027h                        ; 1df4     27              
    defb 01ch                        ; 1df5     1c              
    defb 01ah                        ; 1df6     1a              
    defb 026h                        ; 1df7     26              
    defb 00fh                        ; 1df8     0f              
    defb 00eh                        ; 1df9     0e              
    defb 008h                        ; 1dfa     08              
    defb 00dh                        ; 1dfb     0d              
    defb 013h                        ; 1dfc     13              
    defb 012h                        ; 1dfd     12              

padding_align_font:
    defb 000h                        ; 1dfe     00              
    defb 000h                        ; 1dff     00              

character_set:                                                         
    defb 000h                        ; 1e00     00              
    defb 01fh                        ; 1e01     1f              
    defb 024h                        ; 1e02     24              
    defb 044h                        ; 1e03     44              
    defb 024h                        ; 1e04     24              
    defb 01fh                        ; 1e05     1f              
    defb 000h                        ; 1e06     00              
    defb 000h                        ; 1e07     00              
    defb 000h                        ; 1e08     00              
    defb 07fh                        ; 1e09     7f              
    defb 049h                        ; 1e0a     49              
    defb 049h                        ; 1e0b     49              
    defb 049h                        ; 1e0c     49              
    defb 036h                        ; 1e0d     36              
    defb 000h                        ; 1e0e     00              
    defb 000h                        ; 1e0f     00              
    defb 000h                        ; 1e10     00              
    defb 03eh                        ; 1e11     3e              
    defb 041h                        ; 1e12     41              
    defb 041h                        ; 1e13     41              
    defb 041h                        ; 1e14     41              
    defb 022h                        ; 1e15     22              
    defb 000h                        ; 1e16     00              
    defb 000h                        ; 1e17     00              
    defb 000h                        ; 1e18     00              
    defb 07fh                        ; 1e19     7f              
    defb 041h                        ; 1e1a     41              
    defb 041h                        ; 1e1b     41              
    defb 041h                        ; 1e1c     41              
    defb 03eh                        ; 1e1d     3e              
    defb 000h                        ; 1e1e     00              
    defb 000h                        ; 1e1f     00              
    defb 000h                        ; 1e20     00              
    defb 07fh                        ; 1e21     7f              
    defb 049h                        ; 1e22     49              
    defb 049h                        ; 1e23     49              
    defb 049h                        ; 1e24     49              
    defb 041h                        ; 1e25     41              
    defb 000h                        ; 1e26     00              
    defb 000h                        ; 1e27     00              
    defb 000h                        ; 1e28     00              
    defb 07fh                        ; 1e29     7f              
    defb 048h                        ; 1e2a     48              
    defb 048h                        ; 1e2b     48              
    defb 048h                        ; 1e2c     48              
    defb 040h                        ; 1e2d     40              
    defb 000h                        ; 1e2e     00              
    defb 000h                        ; 1e2f     00              
    defb 000h                        ; 1e30     00              
    defb 03eh                        ; 1e31     3e              
    defb 041h                        ; 1e32     41              
    defb 041h                        ; 1e33     41              
    defb 045h                        ; 1e34     45              
    defb 047h                        ; 1e35     47              
    defb 000h                        ; 1e36     00              
    defb 000h                        ; 1e37     00              
    defb 000h                        ; 1e38     00              
    defb 07fh                        ; 1e39     7f              
    defb 008h                        ; 1e3a     08              
    defb 008h                        ; 1e3b     08              
    defb 008h                        ; 1e3c     08              
    defb 07fh                        ; 1e3d     7f              
    defb 000h                        ; 1e3e     00              
    defb 000h                        ; 1e3f     00              
    defb 000h                        ; 1e40     00              
    defb 000h                        ; 1e41     00              
    defb 041h                        ; 1e42     41              
    defb 07fh                        ; 1e43     7f              
    defb 041h                        ; 1e44     41              
    defb 000h                        ; 1e45     00              
    defb 000h                        ; 1e46     00              
    defb 000h                        ; 1e47     00              
    defb 000h                        ; 1e48     00              
    defb 002h                        ; 1e49     02              
    defb 001h                        ; 1e4a     01              
    defb 001h                        ; 1e4b     01              
    defb 001h                        ; 1e4c     01              
    defb 07eh                        ; 1e4d     7e              
    defb 000h                        ; 1e4e     00              
    defb 000h                        ; 1e4f     00              
    defb 000h                        ; 1e50     00              
    defb 07fh                        ; 1e51     7f              
    defb 008h                        ; 1e52     08              
    defb 014h                        ; 1e53     14              
    defb 022h                        ; 1e54     22              
    defb 041h                        ; 1e55     41              
    defb 000h                        ; 1e56     00              
    defb 000h                        ; 1e57     00              
    defb 000h                        ; 1e58     00              
    defb 07fh                        ; 1e59     7f              
    defb 001h                        ; 1e5a     01              
    defb 001h                        ; 1e5b     01              
    defb 001h                        ; 1e5c     01              
    defb 001h                        ; 1e5d     01              
    defb 000h                        ; 1e5e     00              
    defb 000h                        ; 1e5f     00              
    defb 000h                        ; 1e60     00              
    defb 07fh                        ; 1e61     7f              
    defb 020h                        ; 1e62     20              
    defb 018h                        ; 1e63     18              
    defb 020h                        ; 1e64     20              
    defb 07fh                        ; 1e65     7f              
    defb 000h                        ; 1e66     00              
    defb 000h                        ; 1e67     00              
    defb 000h                        ; 1e68     00              
    defb 07fh                        ; 1e69     7f              
    defb 010h                        ; 1e6a     10              
    defb 008h                        ; 1e6b     08              
    defb 004h                        ; 1e6c     04              
    defb 07fh                        ; 1e6d     7f              
    defb 000h                        ; 1e6e     00              
    defb 000h                        ; 1e6f     00              
    defb 000h                        ; 1e70     00              
    defb 03eh                        ; 1e71     3e              
    defb 041h                        ; 1e72     41              
    defb 041h                        ; 1e73     41              
    defb 041h                        ; 1e74     41              
    defb 03eh                        ; 1e75     3e              
    defb 000h                        ; 1e76     00              
    defb 000h                        ; 1e77     00              
    defb 000h                        ; 1e78     00              
    defb 07fh                        ; 1e79     7f              
    defb 048h                        ; 1e7a     48              
    defb 048h                        ; 1e7b     48              
    defb 048h                        ; 1e7c     48              
    defb 030h                        ; 1e7d     30              
    defb 000h                        ; 1e7e     00              
    defb 000h                        ; 1e7f     00              
    defb 000h                        ; 1e80     00              
    defb 03eh                        ; 1e81     3e              
    defb 041h                        ; 1e82     41              
    defb 045h                        ; 1e83     45              
    defb 042h                        ; 1e84     42              
    defb 03dh                        ; 1e85     3d              
    defb 000h                        ; 1e86     00              
    defb 000h                        ; 1e87     00              
    defb 000h                        ; 1e88     00              
    defb 07fh                        ; 1e89     7f              
    defb 048h                        ; 1e8a     48              
    defb 04ch                        ; 1e8b     4c              
    defb 04ah                        ; 1e8c     4a              
    defb 031h                        ; 1e8d     31              
    defb 000h                        ; 1e8e     00              
    defb 000h                        ; 1e8f     00              
    defb 000h                        ; 1e90     00              
    defb 032h                        ; 1e91     32              
    defb 049h                        ; 1e92     49              
    defb 049h                        ; 1e93     49              
    defb 049h                        ; 1e94     49              
    defb 026h                        ; 1e95     26              
    defb 000h                        ; 1e96     00              
    defb 000h                        ; 1e97     00              
    defb 000h                        ; 1e98     00              
    defb 040h                        ; 1e99     40              
    defb 040h                        ; 1e9a     40              
    defb 07fh                        ; 1e9b     7f              
    defb 040h                        ; 1e9c     40              
    defb 040h                        ; 1e9d     40              
    defb 000h                        ; 1e9e     00              
    defb 000h                        ; 1e9f     00              
    defb 000h                        ; 1ea0     00              
    defb 07eh                        ; 1ea1     7e              
    defb 001h                        ; 1ea2     01              
    defb 001h                        ; 1ea3     01              
    defb 001h                        ; 1ea4     01              
    defb 07eh                        ; 1ea5     7e              
    defb 000h                        ; 1ea6     00              
    defb 000h                        ; 1ea7     00              
    defb 000h                        ; 1ea8     00              
    defb 07ch                        ; 1ea9     7c              
    defb 002h                        ; 1eaa     02              
    defb 001h                        ; 1eab     01              
    defb 002h                        ; 1eac     02              
    defb 07ch                        ; 1ead     7c              
    defb 000h                        ; 1eae     00              
    defb 000h                        ; 1eaf     00              
    defb 000h                        ; 1eb0     00              
    defb 07fh                        ; 1eb1     7f              
    defb 002h                        ; 1eb2     02              
    defb 00ch                        ; 1eb3     0c              
    defb 002h                        ; 1eb4     02              
    defb 07fh                        ; 1eb5     7f              
    defb 000h                        ; 1eb6     00              
    defb 000h                        ; 1eb7     00              
    defb 000h                        ; 1eb8     00              
    defb 063h                        ; 1eb9     63              
    defb 014h                        ; 1eba     14              
    defb 008h                        ; 1ebb     08              
    defb 014h                        ; 1ebc     14              
    defb 063h                        ; 1ebd     63              
    defb 000h                        ; 1ebe     00              
    defb 000h                        ; 1ebf     00              
    defb 000h                        ; 1ec0     00              
    defb 060h                        ; 1ec1     60              
    defb 010h                        ; 1ec2     10              
    defb 00fh                        ; 1ec3     0f              
    defb 010h                        ; 1ec4     10              
    defb 060h                        ; 1ec5     60              
    defb 000h                        ; 1ec6     00              
    defb 000h                        ; 1ec7     00              
    defb 000h                        ; 1ec8     00              
    defb 043h                        ; 1ec9     43              
    defb 045h                        ; 1eca     45              
    defb 049h                        ; 1ecb     49              
    defb 051h                        ; 1ecc     51              
    defb 061h                        ; 1ecd     61              
    defb 000h                        ; 1ece     00              
    defb 000h                        ; 1ecf     00              
    defb 000h                        ; 1ed0     00              
    defb 03eh                        ; 1ed1     3e              
    defb 045h                        ; 1ed2     45              
    defb 049h                        ; 1ed3     49              
    defb 051h                        ; 1ed4     51              
    defb 03eh                        ; 1ed5     3e              
    defb 000h                        ; 1ed6     00              
    defb 000h                        ; 1ed7     00              
    defb 000h                        ; 1ed8     00              
    defb 000h                        ; 1ed9     00              
    defb 021h                        ; 1eda     21              
    defb 07fh                        ; 1edb     7f              
    defb 001h                        ; 1edc     01              
    defb 000h                        ; 1edd     00              
    defb 000h                        ; 1ede     00              
    defb 000h                        ; 1edf     00              
    defb 000h                        ; 1ee0     00              
    defb 023h                        ; 1ee1     23              
    defb 045h                        ; 1ee2     45              
    defb 049h                        ; 1ee3     49              
    defb 049h                        ; 1ee4     49              
    defb 031h                        ; 1ee5     31              
    defb 000h                        ; 1ee6     00              
    defb 000h                        ; 1ee7     00              
    defb 000h                        ; 1ee8     00              
    defb 042h                        ; 1ee9     42              
    defb 041h                        ; 1eea     41              
    defb 049h                        ; 1eeb     49              
    defb 059h                        ; 1eec     59              
    defb 066h                        ; 1eed     66              
    defb 000h                        ; 1eee     00              
    defb 000h                        ; 1eef     00              
    defb 000h                        ; 1ef0     00              
    defb 00ch                        ; 1ef1     0c              
    defb 014h                        ; 1ef2     14              
    defb 024h                        ; 1ef3     24              
    defb 07fh                        ; 1ef4     7f              
    defb 004h                        ; 1ef5     04              
    defb 000h                        ; 1ef6     00              
    defb 000h                        ; 1ef7     00              
    defb 000h                        ; 1ef8     00              
    defb 072h                        ; 1ef9     72              
    defb 051h                        ; 1efa     51              
    defb 051h                        ; 1efb     51              
    defb 051h                        ; 1efc     51              
    defb 04eh                        ; 1efd     4e              
    defb 000h                        ; 1efe     00              
    defb 000h                        ; 1eff     00              
    defb 000h                        ; 1f00     00              
    defb 01eh                        ; 1f01     1e              
    defb 029h                        ; 1f02     29              
    defb 049h                        ; 1f03     49              
    defb 049h                        ; 1f04     49              
    defb 046h                        ; 1f05     46              
    defb 000h                        ; 1f06     00              
    defb 000h                        ; 1f07     00              
    defb 000h                        ; 1f08     00              
    defb 040h                        ; 1f09     40              
    defb 047h                        ; 1f0a     47              
    defb 048h                        ; 1f0b     48              
    defb 050h                        ; 1f0c     50              
    defb 060h                        ; 1f0d     60              
    defb 000h                        ; 1f0e     00              
    defb 000h                        ; 1f0f     00              
    defb 000h                        ; 1f10     00              
    defb 036h                        ; 1f11     36              
    defb 049h                        ; 1f12     49              
    defb 049h                        ; 1f13     49              
    defb 049h                        ; 1f14     49              
    defb 036h                        ; 1f15     36              
    defb 000h                        ; 1f16     00              
    defb 000h                        ; 1f17     00              
    defb 000h                        ; 1f18     00              
    defb 031h                        ; 1f19     31              
    defb 049h                        ; 1f1a     49              
    defb 049h                        ; 1f1b     49              
    defb 04ah                        ; 1f1c     4a              
    defb 03ch                        ; 1f1d     3c              
    defb 000h                        ; 1f1e     00              
    defb 000h                        ; 1f1f     00              
    defb 000h                        ; 1f20     00              
    defb 008h                        ; 1f21     08              
    defb 014h                        ; 1f22     14              
    defb 022h                        ; 1f23     22              
    defb 041h                        ; 1f24     41              
    defb 000h                        ; 1f25     00              
    defb 000h                        ; 1f26     00              
    defb 000h                        ; 1f27     00              
    defb 000h                        ; 1f28     00              
    defb 000h                        ; 1f29     00              
    defb 041h                        ; 1f2a     41              
    defb 022h                        ; 1f2b     22              
    defb 014h                        ; 1f2c     14              
    defb 008h                        ; 1f2d     08              
    defb 000h                        ; 1f2e     00              
    defb 000h                        ; 1f2f     00              
    defb 000h                        ; 1f30     00              
    defb 000h                        ; 1f31     00              
    defb 000h                        ; 1f32     00              
    defb 000h                        ; 1f33     00              
    defb 000h                        ; 1f34     00              
    defb 000h                        ; 1f35     00              
    defb 000h                        ; 1f36     00              
    defb 000h                        ; 1f37     00              
    defb 000h                        ; 1f38     00              
    defb 014h                        ; 1f39     14              
    defb 014h                        ; 1f3a     14              
    defb 014h                        ; 1f3b     14              
    defb 014h                        ; 1f3c     14              
    defb 014h                        ; 1f3d     14              
    defb 000h                        ; 1f3e     00              
    defb 000h                        ; 1f3f     00              
    defb 000h                        ; 1f40     00              
    defb 022h                        ; 1f41     22              
    defb 014h                        ; 1f42     14              
    defb 07fh                        ; 1f43     7f              
    defb 014h                        ; 1f44     14              
    defb 022h                        ; 1f45     22              
    defb 000h                        ; 1f46     00              
    defb 000h                        ; 1f47     00              
    defb 000h                        ; 1f48     00              
    defb 003h                        ; 1f49     03              
    defb 004h                        ; 1f4a     04              
    defb 078h                        ; 1f4b     78              
    defb 004h                        ; 1f4c     04              
    defb 003h                        ; 1f4d     03              
    defb 000h                        ; 1f4e     00              
    defb 000h                        ; 1f4f     00              

    defb 024h                        ; 1f50     24              
    defb 01bh                        ; 1f51     1b              
    defb 026h                        ; 1f52     26              
    defb 00eh                        ; 1f53     0e              
    defb 011h                        ; 1f54     11              
    defb 026h                        ; 1f55     26              
    defb 01ch                        ; 1f56     1c              
    defb 026h                        ; 1f57     26              
    defb 00fh                        ; 1f58     0f              
    defb 00bh                        ; 1f59     0b              
    defb 000h                        ; 1f5a     00              
    defb 018h                        ; 1f5b     18              
    defb 004h                        ; 1f5c     04              
    defb 011h                        ; 1f5d     11              
    defb 012h                        ; 1f5e     12              
    defb 025h                        ; 1f5f     25              
    defb 026h                        ; 1f60     26              
    defb 026h                        ; 1f61     26              

    defb 028h                        ; 1f62     28              
    defb 01bh                        ; 1f63     1b              
    defb 026h                        ; 1f64     26              
    defb 00fh                        ; 1f65     0f              
    defb 00bh                        ; 1f66     0b              
    defb 000h                        ; 1f67     00              
    defb 018h                        ; 1f68     18              
    defb 004h                        ; 1f69     04              
    defb 011h                        ; 1f6a     11              
    defb 026h                        ; 1f6b     26              
    defb 026h                        ; 1f6c     26              
    defb 01bh                        ; 1f6d     1b              
    defb 026h                        ; 1f6e     26              
    defb 002h                        ; 1f6f     02              
    defb 00eh                        ; 1f70     0e              
    defb 008h                        ; 1f71     08              
    defb 00dh                        ; 1f72     0d              
    defb 026h                        ; 1f73     26              
    defb 001h                        ; 1f74     01              ; + demo command buffer starts
    defb 001h                        ; 1f75     01              ; |    
    defb 000h                        ; 1f76     00              ; |    
    defb 000h                        ; 1f77     00              ; |    
    defb 001h                        ; 1f78     01              ; |    
    defb 000h                        ; 1f79     00              ; |    
    defb 002h                        ; 1f7a     02              ; |    
    defb 001h                        ; 1f7b     01              ; |    
    defb 000h                        ; 1f7c     00              ; |    
    defb 002h                        ; 1f7d     02              ; |    
    defb 001h                        ; 1f7e     01              ; + demo command buffer ends
    defb 000h                        ; 1f7f     00              

sprite_alien_y_0:
    defb 060h                        ; 1f80     60              
    defb 010h                        ; 1f81     10              
    defb 00fh                        ; 1f82     0f              
    defb 010h                        ; 1f83     10              
    defb 060h                        ; 1f84     60              
    defb 030h                        ; 1f85     30              
    defb 018h                        ; 1f86     18              
    defb 01ah                        ; 1f87     1a              
    defb 03dh                        ; 1f88     3d              
    defb 068h                        ; 1f89     68              
    defb 0fch                        ; 1f8a     fc              
    defb 0fch                        ; 1f8b     fc              
    defb 068h                        ; 1f8c     68              
    defb 03dh                        ; 1f8d     3d              
    defb 01ah                        ; 1f8e     1a              
    defb 000h                        ; 1f8f     00              

msg_insert_coin:                                                         
    defb 008h                        ; 1f90     08              
    defb 00dh                        ; 1f91     0d              
    defb 012h                        ; 1f92     12              
    defb 004h                        ; 1f93     04              
    defb 011h                        ; 1f94     11              
    defb 013h                        ; 1f95     13              
    defb 026h                        ; 1f96     26              
    defb 026h                        ; 1f97     26              
    defb 002h                        ; 1f98     02              
    defb 00eh                        ; 1f99     0e              
    defb 008h                        ; 1f9a     08              
    defb 00dh                        ; 1f9b     0d              

coord_msg_one_or_two_play:                                                         
    defb 00dh                        ; 1f9c     0d              
    defb 02ah                        ; 1f9d     2a              
    defb 050h                        ; 1f9e     50               ; ref 1f50
    defb 01fh                        ; 1f9f     1f              

coord_msg_one_play_one_coi:                                                         
    defb 00ah                        ; 1fa0     0a              
    defb 02ah                        ; 1fa1     2a              
    defb 062h                        ; 1fa2     62               ; ref 1f62
    defb 01fh                        ; 1fa3     1f               

coord_msg_two_play_two_coi:                                                         
    defb 007h                        ; 1fa4     07              
    defb 02ah                        ; 1fa5     2a              
    defb 0e1h                        ; 1fa6     e1               ; ref 1fe1
    defb 01fh                        ; 1fa7     1f              

terminate_table:
    defb 0ffh                        ; 1fa8     ff              

msg_credit:                                                         
    defb 002h                        ; 1fa9     02              
    defb 011h                        ; 1faa     11              
    defb 004h                        ; 1fab     04              
    defb 003h                        ; 1fac     03              
    defb 008h                        ; 1fad     08              
    defb 013h                        ; 1fae     13              
    defb 026h                        ; 1faf     26              

sprite_alien_y_1:
    defb 000h                        ; 1fb0     00              
    defb 060h                        ; 1fb1     60              
    defb 010h                        ; 1fb2     10              
    defb 00fh                        ; 1fb3     0f              
    defb 010h                        ; 1fb4     10              
    defb 060h                        ; 1fb5     60              
    defb 038h                        ; 1fb6     38              
    defb 019h                        ; 1fb7     19              
    defb 03ah                        ; 1fb8     3a              
    defb 06dh                        ; 1fb9     6d              
    defb 0fah                        ; 1fba     fa              
    defb 0fah                        ; 1fbb     fa              
    defb 06dh                        ; 1fbc     6d              
    defb 03ah                        ; 1fbd     3a              
    defb 019h                        ; 1fbe     19              
    defb 000h                        ; 1fbf     00              

sprite_char_query:
    defb 000h                        ; 1fc0     00              
    defb 020h                        ; 1fc1     20              
    defb 040h                        ; 1fc2     40              
    defb 04dh                        ; 1fc3     4d              
    defb 050h                        ; 1fc4     50              
    defb 020h                        ; 1fc5     20              
    defb 000h                        ; 1fc6     00              
    defb 000h                        ; 1fc7     00              

    defb 000h                        ; 1fc8     00              

                                     ; Splash screen animation structure 3
                                     ; 00   Image form (increments each draw)
                                     ; 00   Delta X
                                     ; FF   Delta Y is -1
                                     ; B8   X coordinate
                                     ; FF   Y starting coordiante
                                     ; 1F80 Base image (small alien with Y)
                                     ; 10   Size of image (16 bytes)
                                     ; 97   Target Y coordiante
                                     ; 00   Reached Y flag
                                     ; 1F80 Base iamge (small alien with Y)
                                     ;
splash_animation_struct_3:                                                         
    defb 000h                        ; 1fc9     00              
    defb 000h                        ; 1fca     00              
    defb 0ffh                        ; 1fcb     ff              
    defb 0b8h                        ; 1fcc     b8              
    defb 0ffh                        ; 1fcd     ff              
    defb 080h                        ; 1fce     80              
    defb 01fh                        ; 1fcf     1f              
    defb 010h                        ; 1fd0     10              
    defb 097h                        ; 1fd1     97              
    defb 000h                        ; 1fd2     00              
    defb 080h                        ; 1fd3     80              
    defb 01fh                        ; 1fd4     1f              

                                     ; Splash screen animation structure 4
                                     ; 00   Image form (increments each draw)
                                     ; 00   Delta X
                                     ; 01   Delta Y is 1
                                     ; D0   X coordinate
                                     ; 22   Y starting coordiante
                                     ; 1C20 Base image (small alien)
                                     ; 10   Size of image (16 bytes)
                                     ; 94   Target Y coordiante
                                     ; 00   Reached Y flag
                                     ; 1C20 Base iamge (small alien)
                                     ;
splash_animation_struct_4:                                                         
    defb 000h                        ; 1fd5     00              
    defb 000h                        ; 1fd6     00              
    defb 001h                        ; 1fd7     01              
    defb 0d0h                        ; 1fd8     d0              
    defb 022h                        ; 1fd9     22              
    defb 020h                        ; 1fda     20              
    defb 01ch                        ; 1fdb     1c              
    defb 010h                        ; 1fdc     10              
    defb 094h                        ; 1fdd     94              
    defb 000h                        ; 1fde     00              
    defb 020h                        ; 1fdf     20              
    defb 01ch                        ; 1fe0     1c              

msg_two_players_two_coins:
    defb 028h                        ; 1fe1     28               
    defb 01ch                        ; 1fe2     1c              
    defb 026h                        ; 1fe3     26              
    defb 00fh                        ; 1fe4     0f              
    defb 00bh                        ; 1fe5     0b              
    defb 000h                        ; 1fe6     00              
    defb 018h                        ; 1fe7     18              
    defb 004h                        ; 1fe8     04              
    defb 011h                        ; 1fe9     11              
    defb 012h                        ; 1fea     12              
    defb 026h                        ; 1feb     26              
    defb 01ch                        ; 1fec     1c              
    defb 026h                        ; 1fed     26              
    defb 002h                        ; 1fee     02              
    defb 00eh                        ; 1fef     0e              
    defb 008h                        ; 1ff0     08              
    defb 00dh                        ; 1ff1     0d              
    defb 012h                        ; 1ff2     12              

msg_push:                                                         
    defb 00fh                        ; 1ff3     0f              
    defb 014h                        ; 1ff4     14              
    defb 012h                        ; 1ff5     12              
    defb 007h                        ; 1ff6     07              
    defb 026h                        ; 1ff7     26              
    defb 000h                        ; 1ff8     00              
    defb 008h                        ; 1ff9     08              
    defb 008h                        ; 1ffa     08              
    defb 008h                        ; 1ffb     08              
    defb 008h                        ; 1ffc     08              
    defb 008h                        ; 1ffd     08              
    defb 000h                        ; 1ffe     00              

g_end:                                                          
    nop                              ; 1fff     00              
                                                                
ram_start:                     equ 02000h                        ; 02000h 02000    ; from here is copied from rom at ram_mirror                 defb 001h ; 1b00 01  ram_mirror:                                                  
wait_on_draw:                  equ 02000h                        ; 02000h 02000    ; from here is copied from rom at ram_mirror                 defb 001h ; 1b00 01  ram_mirror:                                                  
                                                                 ; 02001h 02001                                                                 defb 000h ; 1b01 00  
alien_is_exploding:            equ 02002h                        ; 02002h 02002    ; read sequentially in draw_alien                            defb 000h ; 1b02 00  
exp_alien_timer:               equ 02003h                        ; 02003h 02003                                                                 defb 010h ; 1b03 10  
alien_row:                     equ 02004h                        ; 02004h 02004                                                                 defb 000h ; 1b04 00  
alien_ani_frame_number:        equ 02005h                        ; 02005h 02005    ; alien animation frame number                               defb 000h ; 1b05 00  
alien_cur_index:               equ 02006h                        ; 02006h 02006                                                                 defb 000h ; 1b06 00  
ref_alien_dyr:                 equ 02007h                        ; 02007h 02007                                                                 defb 000h ; 1b07 00  
ref_alien_dxr:                 equ 02008h                        ; 02008h 02008                                                                 defb 002h ; 1b08 02  
ref_alien_yr:                  equ 02009h                        ; 02009h 02009                                                                 defb 078h ; 1b09 78  
ref_alien_xr:                  equ 0200ah                        ; 0200ah 0200a                                                                 defb 038h ; 1b0a 38  
alien_pos_lsb:                 equ 0200bh                        ; 0200bh 0200b                                                                 defb 078h ; 1b0b 78  
                                                                 ; 0200ch 0200c                                                                 defb 038h ; 1b0c 38  
rack_direction:                equ 0200dh                        ; 0200dh 0200d                                                                 defb 000h ; 1b0d 00  
rack_down_delta:               equ 0200eh                        ; 0200eh 0200e                                                                 defb 0f8h ; 1b0e f8  
                                                                 ; 0200fh 0200f                                                                 defb 000h ; 1b0f 00  
; game object 0                                                                 
game_object_0:                 equ 02010h                        ; 02010h 02010    ; @ first game object active player                          defb 000h ; 1b10 00  game_object_0_init:                                      
obj0timer_lsb:                 equ 02011h                        ; 02011h 02011                                                                 defb 080h ; 1b11 80  
obj0timer_extra:               equ 02012h                        ; 02012h 02012                                                                 defb 000h ; 1b12 00  
                                                                 ; 02013h 02013    ; vec lo                                                     defb 08eh ; 1b13 8e  
                                                                 ; 02014h 02014    ; vec hi                                                     defb 002h ; 1b14 02  
player_alive:                  equ 02015h                        ; 02015h 02015                                                                 defb 0ffh ; 1b15 ff  
                                                                 ; 02016h 02016                                                                 defb 005h ; 1b16 05  
                                                                 ; 02017h 02017                                                                 defb 00ch ; 1b17 0c  
plyr_spr_pic_l:                equ 02018h                        ; 02018h 02018    e ; descriptor                                               defb 060h ; 1b18 60  sprite_player
                                                                 ; 02019h 02019    d                                                            defb 01ch ; 1b19 1c  
player_yr:                     equ 0201ah                        ; 0201ah 0201a    l                                                            defb 020h ; 1b1a 20  
player_xr:                     equ 0201bh                        ; 0201bh 0201b    h                                                            defb 030h ; 1b1b 30  
                                                                 ; 0201ch 0201c    b                                                            defb 010h ; 1b1c 10  
next_demo_cmd:                 equ 0201dh                        ; 0201dh 0201d                                                                 defb 001h ; 1b1d 01  
hid_mess_seq:                  equ 0201eh                        ; 0201eh 0201e                                                                 defb 000h ; 1b1e 00  
                                                                 ; 0201fh 0201f                                                                 defb 000h ; 1b1f 00  
; game object 1
                                                                 ; 02020h 02020    ; @ game object table                                        defb 000h ; 1b20 00  
                                                                 ; 02021h 02021                                                                 defb 000h ; 1b21 00  
                                                                 ; 02022h 02022                                                                 defb 000h ; 1b22 00  
                                                                 ; 02023h 02023    ; vec lo                                                     defb 0bbh ; 1b23 bb  
                                                                 ; 02024h 02024    ; vec hi                                                     defb 003h ; 1b24 03  
plyr_shot_status:              equ 02025h                        ; 02025h 02025                                                                 defb 000h ; 1b25 00  shot_struct:                                                
                                                                 ; 02026h 02026                                                                 defb 010h ; 1b26 10  
player_shot_desc:              equ 02027h                        ; 02027h 02027    e ; descriptor                                               defb 090h ; 1b27 90  player_shot_sprite
                                                                 ; 02028h 02028    d                                                            defb 01ch ; 1b28 1c  
obj1coor_yr:                   equ 02029h                        ; 02029h 02029    l                                                            defb 028h ; 1b29 28  
obj1coor_xr:                   equ 0202ah                        ; 0202ah 0202a    h                                                            defb 030h ; 1b2a 30  
                                                                 ; 0202bh 0202b    b                                                            defb 001h ; 1b2b 01  
shot_delta_x:                  equ 0202ch                        ; 0202ch 0202c                                                                 defb 004h ; 1b2c 04  
fire_bounce:                   equ 0202dh                        ; 0202dh 0202d                                                                 defb 000h ; 1b2d 00  
                                                                 ; 0202eh 0202e                                                                 defb 0ffh ; 1b2e ff  
                                                                 ; 0202fh 0202f                                                                 defb 0ffh ; 1b2f ff  
; game object 2
game_object_2:                 equ 02030h                        ; 02030h 02030    ; @ reload object structure from rom                         defb 000h ; 1b30 00  l1b30h:                                                     
                                                                 ; 02031h 02031                                                                 defb 000h ; 1b31 00  
obj2timer_extra:               equ 02032h                        ; 02032h 02032                                                                 defb 002h ; 1b32 02  l1b32h:                                                     
                                                                 ; 02033h 02033    ; vec lo                                                     defb 076h ; 1b33 76  
                                                                 ; 02034h 02034    ; vec hi                                                     defb 004h ; 1b34 04  
rol_shot_struct:               equ 02035h                        ; 02035h 02035    ; @ rolling shot data structure                              defb 000h ; 1b35 00  
rol_shot_step_cnt:             equ 02036h                        ; 02036h 02036                                                                 defb 000h ; 1b36 00  
                                                                 ; 02037h 02037                                                                 defb 000h ; 1b37 00  
rol_shot_cfir_lsb:             equ 02038h                        ; 02038h 02038                                                                 defb 000h ; 1b38 00  
                                                                 ; 02039h 02039                                                                 defb 000h ; 1b39 00  
                                                                 ; 0203ah 0203a                                                                 defb 004h ; 1b3a 04  
                                                                 ; 0203bh 0203b                                                                 defb 0eeh ; 1b3b ee  
                                                                 ; 0203ch 0203c                                                                 defb 01ch ; 1b3c 1c  
                                                                 ; 0203dh 0203d                                                                 defb 000h ; 1b3d 00  
                                                                 ; 0203eh 0203e                                                                 defb 000h ; 1b3e 00  
                                                                 ; 0203fh 0203f                                                                 defb 003h ; 1b3f 03  
; game object 3
game_object_3:                 equ 02040h                        ; 02040h 02040    ; @ reload object structure from rom                         defb 000h ; 1b40 00  l1b40h:                                                     
                                                                 ; 02041h 02041                                                                 defb 000h ; 1b41 00  
                                                                 ; 02042h 02042                                                                 defb 000h ; 1b42 00  
                                                                 ; 02043h 02043    ; vec lo                                                     defb 0b6h ; 1b43 b6  
                                                                 ; 02044h 02044    ; vec hi                                                     defb 004h ; 1b44 04  
plu_shot_struct:               equ 02045h                        ; 02045h 02045    ; @ plunger shot data structure                              defb 000h ; 1b45 00  
plu_shot_step_cnt:             equ 02046h                        ; 02046h 02046                                                                 defb 000h ; 1b46 00  
                                                                 ; 02047h 02047                                                                 defb 001h ; 1b47 01  
plu_shot_cfir_lsb:             equ 02048h                        ; 02048h 02048                                                                 defb 000h ; 1b48 00  l1b48h:                                                     
                                                                 ; 02049h 02049                                                                 defb 01dh ; 1b49 1d  
                                                                 ; 0204ah 0204a                                                                 defb 004h ; 1b4a 04  
                                                                 ; 0204bh 0204b                                                                 defb 0e2h ; 1b4b e2  
                                                                 ; 0204ch 0204c                                                                 defb 01ch ; 1b4c 1c  
                                                                 ; 0204dh 0204d                                                                 defb 000h ; 1b4d 00  
                                                                 ; 0204eh 0204e                                                                 defb 000h ; 1b4e 00  
                                                                 ; 0204fh 0204f                                                                 defb 003h ; 1b4f 03  
; game object 4
game_object_4:                 equ 02050h                        ; 02050h 02050 +  ; squiggly shot ram info                                     defb 000h ; 1b50 00  l1b50h:                                                     
                                                                 ; 02051h 02051 |                                                               defb 000h ; 1b51 00  
                                                                 ; 02052h 02052 |                                                               defb 000h ; 1b52 00  
                                                                 ; 02053h 02053 |  ; vec lo                                                     defb 082h ; 1b53 82  
                                                                 ; 02054h 02054 |  ; vec hi                                                     defb 006h ; 1b54 06  
squ_shot_status:               equ 02055h                        ; 02055h 02055 |                                                               defb 000h ; 1b55 00  
squ_shot_step_cnt:             equ 02056h                        ; 02056h 02056 |                                                               defb 000h ; 1b56 00  
                                                                 ; 02057h 02057 |                                                               defb 001h ; 1b57 01  
squ_shot_cfir_lsb:             equ 02058h                        ; 02058h 02058 |                                                               defb 006h ; 1b58 06  l1b58h:                                                     
                                                                 ; 02059h 02059 |                                                               defb 01dh ; 1b59 1d  
                                                                 ; 0205ah 0205a |                                                               defb 004h ; 1b5a 04  
                                                                 ; 0205bh 0205b |                                                               defb 0d0h ; 1b5b d0  
                                                                 ; 0205ch 0205c |                                                               defb 01ch ; 1b5c 1c  
                                                                 ; 0205dh 0205d |                                                               defb 000h ; 1b5d 00  
                                                                 ; 0205eh 0205e |                                                               defb 000h ; 1b5e 00  
                                                                 ; 0205fh 0205f +                                                               defb 003h ; 1b5f 03  
; game object table end marker is 0ffh
                                                                 ; 02060h 02060                                                                 defb 0ffh ; 1b60 ff  

collision:                     equ 02061h                        ; 02061h 02061                                                                 defb 000h ; 1b61 00  
                                                                 ; 02062h 02062    ; e ; descriptor ; exploding alien                           defb 0c0h ; 1b62 c0  alien_explode
                                                                 ; 02063h 02063    ; d                                                          defb 01ch ; 1b63 1c  
exp_alien_yr:                  equ 02064h                        ; 02064h 02064    ; l                                                          defb 000h ; 1b64 00  
                                                                 ; 02065h 02065    ; h                                                          defb 000h ; 1b65 00  
                                                                 ; 02066h 02066    ; b                                                          defb 010h ; 1b66 10  
player_data_msb:               equ 02067h                        ; 02067h 02067                                                                 defb 021h ; 1b67 21  
player_ok:                     equ 02068h                        ; 02068h 02068                                                                 defb 001h ; 1b68 01  
enable_alien_fire:             equ 02069h                        ; 02069h 02069                                                                 defb 000h ; 1b69 00  
alien_fire_delay:              equ 0206ah                        ; 0206ah 0206a                                                                 defb 030h ; 1b6a 30  
                                                                 ; 0206bh 0206b    ; flag if only one alien left                                defb 000h ; 1b6b 00  
temp206c:                      equ 0206ch                        ; 0206ch 0206c                                                                 defb 012h ; 1b6c 12  
invaded:                       equ 0206dh                        ; 0206dh 0206d                                                                 defb 000h ; 1b6d 00  
skip_plunger:                  equ 0206eh                        ; 0206eh 0206e                                                                 defb 000h ; 1b6e 00  
                                                                 ; 0206fh 0206f                                                                 defb 000h ; 1b6f 00  
other_shot1:                   equ 02070h                        ; 02070h 02070                                                                 defb 00fh ; 1b70 0f  msg_play_player_one:                                        
other_shot2:                   equ 02071h                        ; 02071h 02071                                                                 defb 00bh ; 1b71 0b  
vblank_status:                 equ 02072h                        ; 02072h 02072                                                                 defb 000h ; 1b72 00  

a_shot_status:                 equ 02073h                        ; 02073h 02073 +                                                               defb 018h ; 1b73 18  
                                                                 ; 02074h 02074 |                                                               defb 026h ; 1b74 26  
                                                                 ; 02075h 02075 |                                                               defb 00fh ; 1b75 0f  
a_shot_cfir_lsb:               equ 02076h                        ; 02076h 02076 |                                                               defb 00bh ; 1b76 0b  
                                                                 ; 02077h 02077 |                                                               defb 000h ; 1b77 00  
a_shot_blow_cnt:               equ 02078h                        ; 02078h 02078 |                                                               defb 018h ; 1b78 18  
a_shot_image_lsb:              equ 02079h                        ; 02079h 02079 |  ; e ; descriptor                                             defb 004h ; 1b79 04  
                                                                 ; 0207ah 0207a |  ; d                                                          defb 011h ; 1b7a 11  
alien_shot_yr:                 equ 0207bh                        ; 0207bh 0207b |  ; l                                                          defb 024h ; 1b7b 24  
                                                                 ; 0207ch 0207c |  ; h  ; @ alien shot y? coordinate                            defb 01bh ; 1b7c 1b  
alien_shot_size:               equ 0207dh                        ; 0207dh 0207d +  ; b                                                          defb 025h ; 1b7d 25  

alien_shot_delta:              equ 0207eh                        ; 0207eh 0207e                                                                 defb 0fch ; 1b7e fc  
shot_pic_end:                  equ 0207fh                        ; 0207fh 0207f                                                                 defb 000h ; 1b7f 00  
shot_sync:                     equ 02080h                        ; 02080h 02080                                                                 defb 001h ; 1b80 01  
tmp2081:                       equ 02081h                        ; 02081h 02081                                                                 defb 0ffh ; 1b81 ff  
num_aliens:                    equ 02082h                        ; 02082h 02082                                                                 defb 0ffh ; 1b82 ff  
saucer_start:                  equ 02083h                        ; 02083h 02083                                                                 defb 000h ; 1b83 00  data_for_saucer: +                                          
saucer_active:                 equ 02084h                        ; 02084h 02084                                                                 defb 000h ; 1b84 00                   |                 
saucer_hit:                    equ 02085h                        ; 02085h 02085                                                                 defb 000h ; 1b85 00                   |                 
                                                                 ; 02086h 02086                                                                 defb 020h ; 1b86 20                   |                 
saucer_pri_loc_lsb:            equ 02087h                        ; 02087h 02087    ; e ; descriptor                                             defb 064h ; 1b87 64                   |                 
                                                                 ; 02088h 02088    ; d                                                          defb 01dh ; 1b88 1d                   |                 
                                                                 ; 02089h 02089    ; l                                                          defb 0d0h ; 1b89 d0                   |                 
saucer_pri_pic_msb:            equ 0208ah                        ; 0208ah 0208a    ; h                                                          defb 029h ; 1b8a 29                   |                 
                                                                 ; 0208bh 0208b    ; b                                                          defb 018h ; 1b8b 18                   |                 
                                                                 ; 0208ch 0208c                                                                 defb 002h ; 1b8c 02                   +                 
sau_score_lsb:                 equ 0208dh                        ; 0208dh 0208d                                                                 defb 054h ; 1b8d 54                                     
                                                                 ; 0208eh 0208e                                                                 defb 01dh ; 1b8e 1d                                     
shot_count_lsb:                equ 0208fh                        ; 0208fh 0208f                                                                 defb 000h ; 1b8f 00                                     
                                                                 ; 02090h 02090                                                                 defb 008h ; 1b90 08                                     
till_saucer_lsb:               equ 02091h                        ; 02091h 02091                                                                 defb 000h ; 1b91 00                                     
                                                                 ; 02092h 02092                                                                 defb 006h ; 1b92 06                                     
wait_start_loop:               equ 02093h                        ; 02093h 02093                                                                 defb 000h ; 1b93 00                                     
sound_port3:                   equ 02094h                        ; 02094h 02094                                                                 defb 000h ; 1b94 00                                     
change_fleet_snd:              equ 02095h                        ; 02095h 02095                                                                 defb 001h ; 1b95 01                                     
                                                                 ; 02096h 02096    ; @ current time on fleet sound                              defb 040h ; 1b96 40                                     
fleet_snd_reload:              equ 02097h                        ; 02097h 02097                                                                 defb 000h ; 1b97 00                                     
sound_port5:                   equ 02098h                        ; 02098h 02098                                                                 defb 001h ; 1b98 01                                     
extra_hold:                    equ 02099h                        ; 02099h 02099                                                                 defb 000h ; 1b99 00                                     
tilt:                          equ 0209ah                        ; 0209ah 0209a                                                                 defb 000h ; 1b9a 00                                     
fleet_snd_hold:                equ 0209bh                        ; 0209bh 0209b                                                                 defb 010h ; 1b9b 10                                     
                                                                 ; 0209ch 0209c                                                                 defb 09eh ; 1b9c 9e  
                                                                 ; 0209dh 0209d                                                                 defb 000h ; 1b9d 00  
                                                                 ; 0209eh 0209e                                                                 defb 020h ; 1b9e 20  
                                                                 ; 0209fh 0209f                                                                 defb 01ch ; 1b9f 1c  
                                                                 ; 020a0h 020a0                                                                 defb 000h ; 1ba0 00  
                                                                 ; 020a1h 020a1                                                                 defb 003h ; 1ba1 03  
                                                                 ; 020a2h 020a2                                                                 defb 004h ; 1ba2 04  
                                                                 ; 020a3h 020a3                                                                 defb 078h ; 1ba3 78  
                                                                 ; 020a4h 020a4                                                                 defb 014h ; 1ba4 14  
                                                                 ; 020a5h 020a5                                                                 defb 013h ; 1ba5 13  
                                                                 ; 020a6h 020a6                                                                 defb 008h ; 1ba6 08  
                                                                 ; 020a7h 020a7                                                                 defb 01ah ; 1ba7 1a  
                                                                 ; 020a8h 020a8                                                                 defb 03dh ; 1ba8 3d  
                                                                 ; 020a9h 020a9                                                                 defb 068h ; 1ba9 68  
                                                                 ; 020aah 020aa                                                                 defb 0fch ; 1baa fc  
                                                                 ; 020abh 020ab                                                                 defb 0fch ; 1bab fc  
                                                                 ; 020ach 020ac                                                                 defb 068h ; 1bac 68  
                                                                 ; 020adh 020ad                                                                 defb 03dh ; 1bad 3d  
                                                                 ; 020aeh 020ae                                                                 defb 01ah ; 1bae 1a  
                                                                 ; 020afh 020af                                                                 defb 000h ; 1baf 00  
                                                                 ; 020b0h 020b0                                                                 defb 000h ; 1bb0 00  l1bb0h:                                                     
                                                                 ; 020b1h 020b1                                                                 defb 000h ; 1bb1 00  
                                                                 ; 020b2h 020b2                                                                 defb 001h ; 1bb2 01  
                                                                 ; 020b3h 020b3                                                                 defb 0b8h ; 1bb3 b8  
                                                                 ; 020b4h 020b4                                                                 defb 098h ; 1bb4 98  
                                                                 ; 020b5h 020b5                                                                 defb 0a0h ; 1bb5 a0  
                                                                 ; 020b6h 020b6                                                                 defb 01bh ; 1bb6 1b  
                                                                 ; 020b7h 020b7                                                                 defb 010h ; 1bb7 10  
                                                                 ; 020b8h 020b8                                                                 defb 0ffh ; 1bb8 ff  
                                                                 ; 020b9h 020b9                                                                 defb 000h ; 1bb9 00  
                                                                 ; 020bah 020ba                                                                 defb 0a0h ; 1bba a0  
                                                                 ; 020bbh 020bb                                                                 defb 01bh ; 1bbb 1b  
                                                                 ; 020bch 020bc                                                                 defb 000h ; 1bbc 00  
                                                                 ; 020bdh 020bd                                                                 defb 000h ; 1bbd 00  
                                                                 ; 020beh 020be                                                                 defb 000h ; 1bbe 00  
                                                                 ; 020bfh 020bf    ; up to here is copied from rom at ram_mirror                defb 000h ; 1bbf 00  ; last byte of ram mirror                                   

isr_delay:                     equ 020c0h                        ; 020c0h 020c0    
isr_splash_task:               equ 020c1h                        ; 020c1h 020c1    
splash_an_form:                equ 020c2h                        ; 020c2h 020c2 +   
                                                                 ; 020c3h 020c3 |    
                                                                 ; 020c4h 020c4 |                                 
                                                                 ; 020c5h 020c5 |    @ xy image descriptor
                                                                 ; 020c6h 020c6 |                                 
splash_image_lsb:              equ 020c7h                        ; 020c7h 020c7 |                                     
                                                                 ; 020c8h 020c8 |                                 
                                                                 ; 020c9h 020c9 |                                 
splash_target_y:               equ 020cah                        ; 020cah 020ca |                                     
splash_reached:                equ 020cbh                        ; 020cbh 020cb |                                     
splash_im_rest_lsb:            equ 020cch                        ; 020cch 020cc |                                     
                                                                 ; 020cdh 020cd +                                 
two_players:                   equ 020ceh                        ; 020ceh 020ce                                       
a_shot_reload_rate:            equ 020cfh                        ; 020cfh 020cf                                       
                                                                 ; 020d0h 020d0                                   
                                                                 ; 020d1h 020d1                                   
                                                                 ; 020d2h 020d2                                   
                                                                 ; 020d3h 020d3
                                                                 ; 020d4h 020d4
                                                                 ; 020d5h 020d5
                                                                 ; 020d6h 020d6
                                                                 ; 020d7h 020d7
                                                                 ; 020d8h 020d8
                                                                 ; 020d9h 020d9
                                                                 ; 020dah 020da
                                                                 ; 020dbh 020db
                                                                 ; 020dch 020dc
                                                                 ; 020ddh 020dd
                                                                 ; 020deh 020de
                                                                 ; 020dfh 020df
                                                                 ; 020e0h 020e0
                                                                 ; 020e1h 020e1
                                                                 ; 020e2h 020e2
                                                                 ; 620e3h 020e3
                                                                 ; 020e4h 020e4
player1ex:                     equ 020e5h                        ; 020e5h 020e5    
player2ex:                     equ 020e6h                        ; 020e6h 020e6
player1alive:                  equ 020e7h                        ; 020e7h 020e7    
player2alive:                  equ 020e8h                        ; 020e8h 020e8
suspend_play:                  equ 020e9h                        ; 020e9h 020e9    
coin_switch:                   equ 020eah                        ; 020eah 020ea    
num_coins:                     equ 020ebh                        ; 020ebh 020eb    
splash_animate:                equ 020ech                        ; 020ech 020ec    
demo_cmd_ptr_lsb:              equ 020edh                        ; 020edh 020ed    
                                                                 ; 020eeh 020ee
game_mode:                     equ 020efh                        ; 020efh 020ef    
                                                                 ; 020f0h 020f0
adjust_score_data:             equ 020f1h                        ; 020f1h 020f1    
score_delta_lsb:               equ 020f2h                        ; 020f2h 020f2    
                                                                 ; 020f3h 020f3    ; @ pointer to score delta msb
                                                                 ; 020f4h 020f4    ; @ hi score descriptor
                                                                 ; 020f5h 020f5    ; @ current hi score upper two digits
                                                                 ; 020f6h 020f6
                                                                 ; 020f7h 020f7
p1scor_l:                      equ 020f8h                        ; 020f8h 020f8    
                                                                 ; 020f9h 020f9
                                                                 ; 020fah 020fa
                                                                 ; 020fbh 020fb
p2scor_l:                      equ 020fch                        ; 020fch 020fc    
                                                                 ; 020fdh 020fd
                                                                 ; 020feh 020fe
                                                                 ; 020ffh 020ff
                                                                 ; 02100h 02100     ; @ start of alien structure this is the last alien @ player one data area start?
                                                                 ; 02101h 02101
                                                                 ; 02102h 02102
                                                                 ; 02103h 02103
                                                                 ; 02104h 02104
                                                                 ; 02105h 02105
                                                                 ; 02106h 02106
                                                                 ; 02107h 02107
                                                                 ; 02108h 02108
                                                                 ; 02109h 02109
                                                                 ; 0210ah 0210a
                                                                 ; 0210bh 0210b
                                                                 ; 0210ch 0210c
                                                                 ; 0210dh 0210d
                                                                 ; 0210eh 0210e
                                                                 ; 0210fh 0210f
                                                                 ; 02110h 02110
                                                                 ; 02111h 02111
                                                                 ; 02112h 02112
                                                                 ; 02113h 02113
                                                                 ; 02114h 02114
                                                                 ; 02115h 02115
                                                                 ; 02116h 02116
                                                                 ; 02117h 02117
                                                                 ; 02118h 02118
                                                                 ; 02119h 02119
                                                                 ; 0211ah 0211a
                                                                 ; 0211bh 0211b
                                                                 ; 0211ch 0211c
                                                                 ; 0211dh 0211d
                                                                 ; 0211eh 0211e
                                                                 ; 0211fh 0211f
                                                                 ; 02120h 02120
                                                                 ; 02121h 02121
                                                                 ; 02122h 02122
                                                                 ; 02123h 02123
                                                                 ; 02124h 02124
                                                                 ; 02125h 02125
                                                                 ; 02126h 02126
                                                                 ; 02127h 02127
                                                                 ; 02128h 02128
                                                                 ; 02129h 02129
                                                                 ; 0212ah 0212a
                                                                 ; 0212bh 0212b
                                                                 ; 0212ch 0212c
                                                                 ; 0212dh 0212d
                                                                 ; 0212eh 0212e
                                                                 ; 0212fh 0212f
                                                                 ; 02130h 02130
                                                                 ; 02131h 02131
                                                                 ; 02132h 02132
                                                                 ; 02133h 02133
                                                                 ; 02134h 02134
                                                                 ; 02135h 02135
                                                                 ; 02136h 02136
                                                                 ; 02137h 02137
                                                                 ; 02138h 02138
                                                                 ; 02139h 02139
                                                                 ; 0213ah 0213a
                                                                 ; 0213bh 0213b
                                                                 ; 0213ch 0213c
                                                                 ; 0213dh 0213d
                                                                 ; 0213eh 0213e
                                                                 ; 0213fh 0213f
                                                                 ; 02140h 02140
                                                                 ; 02141h 02141
player_one_shield_buf: equ 02142h                                ; 02142h 02142     ; @ player one shield buffer
                                                                 ; 02143h 02143
                                                                 ; 02144h 02144
                                                                 ; 02145h 02145
                                                                 ; 02146h 02146
                                                                 ; 02147h 02147
                                                                 ; 02148h 02148
                                                                 ; 02149h 02149
                                                                 ; 0214ah 0214a
                                                                 ; 0214bh 0214b
                                                                 ; 0214ch 0214c
                                                                 ; 0214dh 0214d
                                                                 ; 0214eh 0214e
                                                                 ; 0214fh 0214f
                                                                 ; 02150h 02150
                                                                 ; 02151h 02151
                                                                 ; 02152h 02152
                                                                 ; 02153h 02153
                                                                 ; 02154h 02154
                                                                 ; 02155h 02155
                                                                 ; 02156h 02156
                                                                 ; 02157h 02157
                                                                 ; 02158h 02158
                                                                 ; 02159h 02159
                                                                 ; 0215ah 0215a
                                                                 ; 0215bh 0215b
                                                                 ; 0215ch 0215c
                                                                 ; 0215dh 0215d
                                                                 ; 0215eh 0215e
                                                                 ; 0215fh 0215f
                                                                 ; 02160h 02160
                                                                 ; 02161h 02161
                                                                 ; 02162h 02162
                                                                 ; 02163h 02163
                                                                 ; 02164h 02164
                                                                 ; 02165h 02165
                                                                 ; 02166h 02166
                                                                 ; 02167h 02167
                                                                 ; 02168h 02168
                                                                 ; 02169h 02169
                                                                 ; 0216ah 0216a
                                                                 ; 0216bh 0216b
                                                                 ; 0216ch 0216c
                                                                 ; 0216dh 0216d
                                                                 ; 0216eh 0216e
                                                                 ; 0216fh 0216f
                                                                 ; 02170h 02170
                                                                 ; 02171h 02171
                                                                 ; 02172h 02172
                                                                 ; 02173h 02173
                                                                 ; 02174h 02174
                                                                 ; 02175h 02175
                                                                 ; 02176h 02176
                                                                 ; 02177h 02177
                                                                 ; 02178h 02178
                                                                 ; 02179h 02179
                                                                 ; 0217ah 0217a
                                                                 ; 0217bh 0217b
                                                                 ; 0217ch 0217c
                                                                 ; 0217dh 0217d
                                                                 ; 0217eh 0217e
                                                                 ; 0217fh 0217f
                                                                 ; 02180h 02180
                                                                 ; 02181h 02181
                                                                 ; 02182h 02182
                                                                 ; 02183h 02183
                                                                 ; 02184h 02184
                                                                 ; 02185h 02185
                                                                 ; 02186h 02186
                                                                 ; 02187h 02187
                                                                 ; 02188h 02188
                                                                 ; 02189h 02189
                                                                 ; 0218ah 0218a
                                                                 ; 0218bh 0218b
                                                                 ; 0218ch 0218c
                                                                 ; 0218dh 0218d
                                                                 ; 0218eh 0218e
                                                                 ; 0218fh 0218f
                                                                 ; 02190h 02190
                                                                 ; 02191h 02191
                                                                 ; 02192h 02192
                                                                 ; 02193h 02193
                                                                 ; 02194h 02194
                                                                 ; 02195h 02195
                                                                 ; 02196h 02196
                                                                 ; 02197h 02197
                                                                 ; 02198h 02198
                                                                 ; 02199h 02199
                                                                 ; 0219ah 0219a
                                                                 ; 0219bh 0219b
                                                                 ; 0219ch 0219c
                                                                 ; 0219dh 0219d
                                                                 ; 0219eh 0219e
                                                                 ; 0219fh 0219f
                                                                 ; 021a0h 021a0
                                                                 ; 021a1h 021a1
                                                                 ; 021a2h 021a2
                                                                 ; 021a3h 021a3
                                                                 ; 021a4h 021a4
                                                                 ; 021a5h 021a5
                                                                 ; 021a6h 021a6
                                                                 ; 021a7h 021a7
                                                                 ; 021a8h 021a8
                                                                 ; 021a9h 021a9
                                                                 ; 021aah 021aa
                                                                 ; 021abh 021ab
                                                                 ; 021ach 021ac
                                                                 ; 021adh 021ad
                                                                 ; 021aeh 021ae
                                                                 ; 021afh 021af
                                                                 ; 021b0h 021b0
                                                                 ; 021b1h 021b1
                                                                 ; 021b2h 021b2
                                                                 ; 021b3h 021b3
                                                                 ; 021b4h 021b4
                                                                 ; 021b5h 021b5
                                                                 ; 021b6h 021b6
                                                                 ; 021b7h 021b7
                                                                 ; 021b8h 021b8
                                                                 ; 021b9h 021b9
                                                                 ; 021bah 021ba
                                                                 ; 021bbh 021bb
                                                                 ; 021bch 021bc
                                                                 ; 021bdh 021bd
                                                                 ; 021beh 021be
                                                                 ; 021bfh 021bf
                                                                 ; 021c0h 021c0
                                                                 ; 021c1h 021c1
                                                                 ; 021c2h 021c2
                                                                 ; 021c3h 021c3
                                                                 ; 021c4h 021c4
                                                                 ; 021c5h 021c5
                                                                 ; 021c6h 021c6
                                                                 ; 021c7h 021c7
                                                                 ; 021c8h 021c8
                                                                 ; 021c9h 021c9
                                                                 ; 021cah 021ca
                                                                 ; 021cbh 021cb
                                                                 ; 021cch 021cc
                                                                 ; 021cdh 021cd
                                                                 ; 021ceh 021ce
                                                                 ; 021cfh 021cf
                                                                 ; 021d0h 021d0
                                                                 ; 021d1h 021d1
                                                                 ; 021d2h 021d2
                                                                 ; 021d3h 021d3
                                                                 ; 021d4h 021d4
                                                                 ; 021d5h 021d5
                                                                 ; 021d6h 021d6
                                                                 ; 021d7h 021d7
                                                                 ; 021d8h 021d8
                                                                 ; 021d9h 021d9
                                                                 ; 021dah 021da
                                                                 ; 021dbh 021db
                                                                 ; 021dch 021dc
                                                                 ; 021ddh 021dd
                                                                 ; 021deh 021de
                                                                 ; 021dfh 021df
                                                                 ; 021e0h 021e0
                                                                 ; 021e1h 021e1
                                                                 ; 021e2h 021e2
                                                                 ; 021e3h 021e3
                                                                 ; 021e4h 021e4
                                                                 ; 021e5h 021e5
                                                                 ; 021e6h 021e6
                                                                 ; 021e7h 021e7
                                                                 ; 021e8h 021e8
                                                                 ; 021e9h 021e9
                                                                 ; 021eah 021ea
                                                                 ; 021ebh 021eb
                                                                 ; 021ech 021ec
                                                                 ; 021edh 021ed
                                                                 ; 021eeh 021ee
                                                                 ; 021efh 021ef
                                                                 ; 021f0h 021f0
                                                                 ; 021f1h 021f1
                                                                 ; 021f2h 021f2
                                                                 ; 021f3h 021f3
                                                                 ; 021f4h 021f4
                                                                 ; 021f5h 021f5
                                                                 ; 021f6h 021f6
                                                                 ; 021f7h 021f7
                                                                 ; 021f8h 021f8
                                                                 ; 021f9h 021f9
                                                                 ; 021fah 021fa
p1ref_alien_dx:                equ 021fbh                        ; 021fbh 021fb    
p1ref_alien_y:                 equ 021fch                        ; 021fch 021fc    
                                                                 ; 021fdh 021fd
p1rack_cnt:                    equ 021feh                        ; 021feh 021fe    
p1ships_rem:                   equ 021ffh                        ; 021ffh 021ff    
                                                                 ; 02200h 02200     ; @ player two data area
                                                                 ; 02201h 02201
                                                                 ; 02202h 02202
                                                                 ; 02203h 02203
                                                                 ; 02204h 02204
                                                                 ; 02205h 02205
                                                                 ; 02206h 02206
                                                                 ; 02207h 02207
                                                                 ; 02208h 02208
                                                                 ; 02209h 02209
                                                                 ; 0220ah 0220a
                                                                 ; 0220bh 0220b
                                                                 ; 0220ch 0220c
                                                                 ; 0220dh 0220d
                                                                 ; 0220eh 0220e
                                                                 ; 0220fh 0220f
                                                                 ; 02210h 02210
                                                                 ; 02211h 02211
                                                                 ; 02212h 02212
                                                                 ; 02213h 02213
                                                                 ; 02214h 02214
                                                                 ; 02215h 02215
                                                                 ; 02216h 02216
                                                                 ; 02217h 02217
                                                                 ; 02218h 02218
                                                                 ; 02219h 02219
                                                                 ; 0221ah 0221a
                                                                 ; 0221bh 0221b
                                                                 ; 0221ch 0221c
                                                                 ; 0221dh 0221d
                                                                 ; 0221eh 0221e
                                                                 ; 0221fh 0221f
                                                                 ; 02220h 02220
                                                                 ; 02221h 02221
                                                                 ; 02222h 02222
                                                                 ; 02223h 02223
                                                                 ; 02224h 02224
                                                                 ; 02225h 02225
                                                                 ; 02226h 02226
                                                                 ; 02227h 02227
                                                                 ; 02228h 02228
                                                                 ; 02229h 02229
                                                                 ; 0222ah 0222a
                                                                 ; 0222bh 0222b
                                                                 ; 0222ch 0222c
                                                                 ; 0222dh 0222d
                                                                 ; 0222eh 0222e
                                                                 ; 0222fh 0222f
                                                                 ; 02230h 02230
                                                                 ; 02231h 02231
                                                                 ; 02232h 02232
                                                                 ; 02233h 02233
                                                                 ; 02234h 02234
                                                                 ; 02235h 02235
                                                                 ; 02236h 02236
                                                                 ; 02237h 02237
                                                                 ; 02238h 02238
                                                                 ; 02239h 02239
                                                                 ; 0223ah 0223a
                                                                 ; 0223bh 0223b
                                                                 ; 0223ch 0223c
                                                                 ; 0223dh 0223d
                                                                 ; 0223eh 0223e
                                                                 ; 0223fh 0223f
                                                                 ; 02240h 02240
                                                                 ; 02241h 02241
player_two_shield_buf: equ 02242h                                ; 02242h 02242     ; @ player two shield buffer
                                                                 ; 02243h 02243
                                                                 ; 02244h 02244
                                                                 ; 02245h 02245
                                                                 ; 02246h 02246
                                                                 ; 02247h 02247
                                                                 ; 02248h 02248
                                                                 ; 02249h 02249
                                                                 ; 0224ah 0224a
                                                                 ; 0224bh 0224b
                                                                 ; 0224ch 0224c
                                                                 ; 0224dh 0224d
                                                                 ; 0224eh 0224e
                                                                 ; 0224fh 0224f
                                                                 ; 02250h 02250
                                                                 ; 02251h 02251
                                                                 ; 02252h 02252
                                                                 ; 02253h 02253
                                                                 ; 02254h 02254
                                                                 ; 02255h 02255
                                                                 ; 02256h 02256
                                                                 ; 02257h 02257
                                                                 ; 02258h 02258
                                                                 ; 02259h 02259
                                                                 ; 0225ah 0225a
                                                                 ; 0225bh 0225b
                                                                 ; 0225ch 0225c
                                                                 ; 0225dh 0225d
                                                                 ; 0225eh 0225e
                                                                 ; 0225fh 0225f
                                                                 ; 02260h 02260
                                                                 ; 02261h 02261
                                                                 ; 02262h 02262
                                                                 ; 02263h 02263
                                                                 ; 02264h 02264
                                                                 ; 02265h 02265
                                                                 ; 02266h 02266
                                                                 ; 02267h 02267
                                                                 ; 02268h 02268
                                                                 ; 02269h 02269
                                                                 ; 0226ah 0226a
                                                                 ; 0226bh 0226b
                                                                 ; 0226ch 0226c
                                                                 ; 0226dh 0226d
                                                                 ; 0226eh 0226e
                                                                 ; 0226fh 0226f
                                                                 ; 02270h 02270
                                                                 ; 02271h 02271
                                                                 ; 02272h 02272
                                                                 ; 02273h 02273
                                                                 ; 02274h 02274
                                                                 ; 02275h 02275
                                                                 ; 02276h 02276
                                                                 ; 02277h 02277
                                                                 ; 02278h 02278
                                                                 ; 02279h 02279
                                                                 ; 0227ah 0227a
                                                                 ; 0227bh 0227b
                                                                 ; 0227ch 0227c
                                                                 ; 0227dh 0227d
                                                                 ; 0227eh 0227e
                                                                 ; 0227fh 0227f
                                                                 ; 02280h 02280
                                                                 ; 02281h 02281
                                                                 ; 02282h 02282
                                                                 ; 02283h 02283
                                                                 ; 02284h 02284
                                                                 ; 02285h 02285
                                                                 ; 02286h 02286
                                                                 ; 02287h 02287
                                                                 ; 02288h 02288
                                                                 ; 02289h 02289
                                                                 ; 0228ah 0228a
                                                                 ; 0228bh 0228b
                                                                 ; 0228ch 0228c
                                                                 ; 0228dh 0228d
                                                                 ; 0228eh 0228e
                                                                 ; 0228fh 0228f
                                                                 ; 02290h 02290
                                                                 ; 02291h 02291
                                                                 ; 02292h 02292
                                                                 ; 02293h 02293
                                                                 ; 02294h 02294
                                                                 ; 02295h 02295
                                                                 ; 02296h 02296
                                                                 ; 02297h 02297
                                                                 ; 02298h 02298
                                                                 ; 02299h 02299
                                                                 ; 0229ah 0229a
                                                                 ; 0229bh 0229b
                                                                 ; 0229ch 0229c
                                                                 ; 0229dh 0229d
                                                                 ; 0229eh 0229e
                                                                 ; 0229fh 0229f
                                                                 ; 022a0h 022a0
                                                                 ; 022a1h 022a1
                                                                 ; 022a2h 022a2
                                                                 ; 022a3h 022a3
                                                                 ; 022a4h 022a4
                                                                 ; 022a5h 022a5
                                                                 ; 022a6h 022a6
                                                                 ; 022a7h 022a7
                                                                 ; 022a8h 022a8
                                                                 ; 022a9h 022a9
                                                                 ; 022aah 022aa
                                                                 ; 022abh 022ab
                                                                 ; 022ach 022ac
                                                                 ; 022adh 022ad
                                                                 ; 022aeh 022ae
                                                                 ; 022afh 022af
                                                                 ; 022b0h 022b0
                                                                 ; 022b1h 022b1
                                                                 ; 022b2h 022b2
                                                                 ; 022b3h 022b3
                                                                 ; 022b4h 022b4
                                                                 ; 022b5h 022b5
                                                                 ; 022b6h 022b6
                                                                 ; 022b7h 022b7
                                                                 ; 022b8h 022b8
                                                                 ; 022b9h 022b9
                                                                 ; 022bah 022ba
                                                                 ; 022bbh 022bb
                                                                 ; 022bch 022bc
                                                                 ; 022bdh 022bd
                                                                 ; 022beh 022be
                                                                 ; 022bfh 022bf
                                                                 ; 022c0h 022c0
                                                                 ; 022c1h 022c1
                                                                 ; 022c2h 022c2
                                                                 ; 022c3h 022c3
                                                                 ; 022c4h 022c4
                                                                 ; 022c5h 022c5
                                                                 ; 022c6h 022c6
                                                                 ; 022c7h 022c7
                                                                 ; 022c8h 022c8
                                                                 ; 022c9h 022c9
                                                                 ; 022cah 022ca
                                                                 ; 022cbh 022cb
                                                                 ; 022cch 022cc
                                                                 ; 022cdh 022cd
                                                                 ; 022ceh 022ce
                                                                 ; 022cfh 022cf
                                                                 ; 022d0h 022d0
                                                                 ; 022d1h 022d1
                                                                 ; 022d2h 022d2
                                                                 ; 022d3h 022d3
                                                                 ; 022d4h 022d4
                                                                 ; 022d5h 022d5
                                                                 ; 022d6h 022d6
                                                                 ; 022d7h 022d7
                                                                 ; 022d8h 022d8
                                                                 ; 022d9h 022d9
                                                                 ; 022dah 022da
                                                                 ; 022dbh 022db
                                                                 ; 022dch 022dc
                                                                 ; 022ddh 022dd
                                                                 ; 022deh 022de
                                                                 ; 022dfh 022df
                                                                 ; 022e0h 022e0
                                                                 ; 022e1h 022e1
                                                                 ; 022e2h 022e2
                                                                 ; 022e3h 022e3
                                                                 ; 022e4h 022e4
                                                                 ; 022e5h 022e5
                                                                 ; 022e6h 022e6
                                                                 ; 022e7h 022e7
                                                                 ; 022e8h 022e8
                                                                 ; 022e9h 022e9
                                                                 ; 022eah 022ea
                                                                 ; 022ebh 022eb
                                                                 ; 022ech 022ec
                                                                 ; 022edh 022ed
                                                                 ; 022eeh 022ee
                                                                 ; 022efh 022ef
                                                                 ; 022f0h 022f0
                                                                 ; 022f1h 022f1
                                                                 ; 022f2h 022f2
                                                                 ; 022f3h 022f3
                                                                 ; 022f4h 022f4
                                                                 ; 022f5h 022f5
                                                                 ; 022f6h 022f6
                                                                 ; 022f7h 022f7
                                                                 ; 022f8h 022f8
                                                                 ; 022f9h 022f9
                                                                 ; 022fah 022fa
p2ref_alien_dx:                equ 022fbh                        ; 022fbh 022fb    
p2ref_alien_yr:                equ 022fch                        ; 022fch 022fc    
                                                                 ; 022fdh 022fd
p2rack_cnt:                    equ 022feh                        ; 022feh 022fe    
p2ships_rem:                   equ 022ffh                        ; 022ffh 022ff    
