INCLUDE "input.asm"
INCLUDE "graphics/graphics.asm"

KB_LOC_X        EQU 5
KB_LOC_Y        EQU 12

KB_LABEL_LEFT   EQU _SCRN1+(SCRN_VY_B*(KB_LOC_Y+2))+KB_LOC_X+0
KB_LABEL_TOP    EQU _SCRN1+(SCRN_VY_B*(KB_LOC_Y+0))+KB_LOC_X+3
KB_LABEL_RIGHT  EQU _SCRN1+(SCRN_VY_B*(KB_LOC_Y+2))+KB_LOC_X+6
KB_LABEL_BOTTOM EQU _SCRN1+(SCRN_VY_B*(KB_LOC_Y+4))+KB_LOC_X+3
KB_CURSOR_START EQU _SCRN1+SCRN_VY_B*4+2

KB_TEXT         EQU 0
KB_TABLE_LOC    EQU 4

KB_LEFT         EQU 5*0
KB_TOP          EQU 5*1
KB_RIGHT        EQU 5*2
KB_BOTTOM       EQU 5*3

SECTION "kb_var", WRAM0
cursor:      ds 1
dest:        ds 2


SECTION "keyboard", ROM0
;hl: current location in the table

; Get user input - de: destination of text - outputs data legth into bc
get_user_input:
    ld a, d
    ld [dest], a
    ld a, e
    ld [dest+1], a

    ;Hide normal contents completely
    ld a, [rIE]
    res 1, a 
    ld [rIE], a

    call clearSCRN1

    ;load dpad icon tiles
    ld a, $8B
    ld hl, _SCRN1+(SCRN_VY_B*(KB_LOC_Y+1))+KB_LOC_X+3
	ld bc, $0303
    call mt_copy

    ;show cursor
    ld a, 8*6
    ld [OAM_Data+KB_CURSOR_O+OAM_Y], a

    ld hl, kb_start
    call kb_load_labels

.kb_loop:
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
    jr nz, .kb_loop_dir
    ld a, 0
    ld [keydown_ab],a
    jr .kb_loop_dir

:   ld a, b
    rra
    jp nc, .btn_a
    rra
    jp nc, .btn_b

.kb_loop_dir:
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
    jr nz, .kb_loop
    ld a, 0
    ld [keydown_dir],a
    jr .kb_loop

:   ld a, b
    rra
    jp nc, .right
    rra
    jp nc, .left
    rra
    jp nc, .up
    rra
    jp nc, .down

    jp .kb_loop

.btn_a:
    ld a, [rIE]
    set 1, a 
    ld [rIE], a

    ld a, 0
    ld [OAM_Data+KB_CURSOR_O+OAM_Y], a

    ld a, [cursor]
	ld b, 0
	ld c, a
    push bc

	ld hl, KB_CURSOR_START

    ld a, [dest]
    ld d, a
    ld a, [dest+1]
    ld e, a
	ld de, s_buf
	call mem_CopyVRAM

    pop bc
    ret

.btn_b:
    ld a, 1
    ld [keydown_ab], a

    call waitVBlank

    ld a, [cursor]
    cp 0
    jp z, .kb_loop

    dec a
    ld b, 0
    ld c, a
    ld [cursor], a

    ld a, " "

    ld hl, KB_CURSOR_START
    add hl, bc
    ld [hl], a

    ld a, [OAM_Data+KB_CURSOR_O+OAM_X]
    sub 8
    ld [OAM_Data+KB_CURSOR_O+OAM_X], a

    ld hl, kb_start
    call kb_load_labels

    jp .kb_loop

.left:
    ld bc, KB_LEFT+3
    jr .switch_layer

.right:
    ld bc, KB_RIGHT+3
    jr .switch_layer

.up:
    ld bc, KB_TOP+3
    jr .switch_layer

.down:
    ld bc, KB_BOTTOM+3

.switch_layer:
    add hl, bc

    ld b, [hl]
    inc hl
    ld c, [hl]

    ld a, b
    cp 0
    jr nz, :+
    ld a, c
    cp 0
    jr nz, :+

    REPT 3
    dec hl
    ENDR

    ld d, [hl]

    call waitVBlank

    ld a, [cursor]
    ld b, 0
    ld c, a

    ld hl, KB_CURSOR_START
    add hl, bc
    ld [hl], d

    inc a
    ld [cursor], a

    ld a, [OAM_Data+KB_CURSOR_O+OAM_X]
    add 8
    ld [OAM_Data+KB_CURSOR_O+OAM_X], a

    ld hl, kb_start
    
    jr :++
    
:   ld h, b
    ld l, c

:   call kb_load_labels

    ld a, 1
    ld [keydown_dir], a

    jp .kb_loop

    
MACRO kb_label_loop
    ld d, 3
:   ld a, [hl+]
    ld [bc], a
    inc bc
    dec d
    jr nz, :-
    inc hl
    inc hl
ENDM

; Load appropriate labels for the dpad icon
kb_load_labels:
    call waitVBlank
    push hl
    
    ld bc, KB_LABEL_LEFT
    kb_label_loop
    ld bc, KB_LABEL_TOP
    kb_label_loop
    ld bc, KB_LABEL_RIGHT
    kb_label_loop
    ld bc, KB_LABEL_BOTTOM
    kb_label_loop

    pop hl
    ret

SECTION "kb_data", ROM0

;level 1
kb_start: db "A-P",HIGH(kb_1),  LOW(kb_1),   "OTH",HIGH(kb_2),  LOW(kb_2),   "Q-Z",HIGH(kb_3),  LOW(kb_3), "\" \"",$00,         $00
;level 2
kb_1:     db "A-D",HIGH(kb_1_1),LOW(kb_1_1), "E-H",HIGH(kb_1_2),LOW(kb_1_2), "I-L",HIGH(kb_1_3),LOW(kb_1_3), "M-P",HIGH(kb_1_4),LOW(kb_1_4)
kb_2:     db "EX1",HIGH(kb_2_1),LOW(kb_2_1), "   ",HIGH(kb_2),  LOW(kb_2),   "EX2",HIGH(kb_2_3),LOW(kb_2_3), "   ",HIGH(kb_2),  LOW(kb_2)
kb_3:     db "Q-T",HIGH(kb_3_1),LOW(kb_3_1), "U-X",HIGH(kb_3_2),LOW(kb_3_2), "Y-Z",HIGH(kb_3_3),LOW(kb_3_3), "   ",HIGH(kb_3),  LOW(kb_3)

;level 3
kb_1_1:   db " A ",$00,         $00,         " B ",$00,         $00,         " C ",$00,         $00,         " D ",$00,         $00
kb_1_2:   db " E ",$00,         $00,         " F ",$00,         $00,         " G ",$00,         $00,         " H ",$00,         $00
kb_1_3:   db " I ",$00,         $00,         " J ",$00,         $00,         " K ",$00,         $00,         " L ",$00,         $00
kb_1_4:   db " M ",$00,         $00,         " N ",$00,         $00,         " O ",$00,         $00,         " P ",$00,         $00

kb_2_1:   db " . ",$00,         $00,         " , ",$00,         $00,         " ! ",$00,         $00,         " ? ",$00,         $00
kb_2_3:   db " - ",$00,         $00,         " : ",$00,         $00,         "   ",HIGH(kb_2_3),LOW(kb_2_3), "   ",HIGH(kb_2_3),LOW(kb_2_3)

kb_3_1:   db " Q ",$00,         $00,         " R ",$00,         $00,         " S ",$00,         $00,         " T ",$00,         $00
kb_3_2:   db " U ",$00,         $00,         " V ",$00,         $00,         " W ",$00,         $00,         " X ",$00,         $00
kb_3_3:   db " Y ",$00,         $00,         " Z ",$00,         $00,         "   ",HIGH(kb_3_3),LOW(kb_3_3), "   ",HIGH(kb_3_3),LOW(kb_3_3)
