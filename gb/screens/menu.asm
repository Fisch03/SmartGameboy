INCLUDE "input.asm"
INCLUDE "graphics/graphics.asm"

M_LOC_X     EQU 1
M_LOC_Y     EQU 6

M_UP_X    EQU M_LOC_X + 2
M_UP_Y    EQU M_LOC_Y + 0

M_DOWN_X  EQU M_LOC_X + 2
M_DOWN_Y  EQU M_LOC_Y + 4

M_LEFT_X  EQU M_LOC_X + 0
M_LEFT_Y  EQU M_LOC_Y + 2

M_RIGHT_X EQU M_LOC_X + 4
M_RIGHT_Y EQU M_LOC_Y + 2

SECTION "menu", ROM0
show_menu:
    ld a, d
    ld [dest], a
    ld a, e
    ld [dest+1], a

    ;Hide normal contents completely
    ld a, [rIE]
    res 1, a 
    ld [rIE], a

    call clearSCRN1

    ;Load tiles
    ld a, $94
    ld hl, _SCRN1+(SCRN_VY_B*(M_UP_Y))+M_UP_X
	ld bc, $0202
    call mt_copy
    ld hl, _SCRN1+(SCRN_VY_B*(M_LEFT_Y))+M_LEFT_X
	ld bc, $0202
    call mt_copy
    ld hl, _SCRN1+(SCRN_VY_B*(M_RIGHT_Y))+M_RIGHT_X
	ld bc, $0202
    call mt_copy
    ld hl, _SCRN1+(SCRN_VY_B*(M_DOWN_Y))+M_DOWN_X
    ld bc, $0202
    call mt_copy

    ;Load Cursor
    ld hl, M_Cursor
    ld de, OAM_Data_Reusable
    ld bc, M_CursorE-M_Cursor
    call mem_Copy

.menu_loop:
    ;Delay between joypad reads to avoid bouncing
    halt
    nop

    ;read a+b buttons
    ld a, P1F_4
    ld [rP1], a
    REPT 6
    ld a, [rP1]
    ENDR
    ld b, a 

    ld a, [keydown_ab]
    cp 0
    jp z, :+

    ld a, b
    and $0F
    cp $0F
    jr nz, .menu_loop_dir
    ld a, 0
    ld [keydown_ab],a
    jr .menu_loop_dir

:   ld a, b
    rra
    jp nc, .btn_a
    ;rra
    ;jp nc, .btn_b

.menu_loop_dir:
    ;read directional buttons
    ld a, P1F_5
    ld [rP1], a
    REPT 6
    ld a, [rP1]
    ENDR
    ld b, a

    ld a, [keydown_dir]
    cp 0
    jp z, :+

    ld a, b
    and $0F
    cp $0F
    jr nz, .menu_loop
    ld a, 0
    ld [keydown_dir],a
    jr .menu_loop

:   ld a, b
    rra
    jp nc, .right
    rra
    jp nc, .left
    rra
    jp nc, .up
    rra
    jp nc, .down

    jr .menu_loop

.btn_a:
    jr .menu_loop


.up:
    ld a, 1
    ld b, M_UP_X*8+8
    ld c, M_UP_Y*8+16
    ld hl, M_Label_Text
    jr .update_sprites

.left:
    ld a, 2
    ld b, M_LEFT_X*8+8
    ld c, M_LEFT_Y*8+16
    ld hl, M_Label_Draw
    jr .update_sprites

.right:
    ld a, 3
    ld b, M_RIGHT_X*8+8
    ld c, M_RIGHT_Y*8+16
    ld hl, M_Label_Browse
    jr .update_sprites

.down:
    ld a, 4
    ld b, M_DOWN_X*8+8
    ld c, M_DOWN_Y*8+16
    ld hl, M_Label_Settings
    jr .update_sprites

.update_sprites:


    call waitVBlank

    ld a, b
    ld [OAM_Data_Reusable + M_CURSOR1_O + OAM_X], a
    add 8 
    ld [OAM_Data_Reusable + M_CURSOR2_O + OAM_X], a

    ld a, c
    ld [OAM_Data_Reusable + M_CURSOR1_O + OAM_Y], a
    ld [OAM_Data_Reusable + M_CURSOR2_O + OAM_Y], a

    ld de, _SCRN1+(SCRN_VY_B*(M_LOC_Y+7))+M_LOC_X-1
	ld bc, 8
	call mem_CopyVRAM

    ld a, 1
    ld [keydown_dir], a
    
    jp .menu_loop
    

SECTION "m_data", ROM0
M_Label_Text:
    db "  Text  "
M_Label_Draw:
    db "  Draw  "
M_Label_Browse:
    db " Browse "
M_Label_Settings:
    db "Settings"

OAM_OFFSET_REDEF SET 0
M_Cursor:
M_CURSOR1_O    EQU OAM_OFFSET_REDEF
OAM_OFFSET_REDEF = OAM_OFFSET_REDEF + 4
    db 0,0,$A4,OAMF_PAL0
M_CURSOR2_O    EQU OAM_OFFSET_REDEF
OAM_OFFSET_REDEF = OAM_OFFSET_REDEF + 4
    db 0,0,$A4,OAMF_PAL0|OAMF_XFLIP
M_CursorE:
PURGE OAM_OFFSET_REDEF