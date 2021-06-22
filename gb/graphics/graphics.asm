IF !DEF(GRAPHICS)
GRAPHICS EQU 1

OAM_Y    EQU 0
OAM_X    EQU 1
OAM_Tile EQU 2
OAM_Flag EQU 3

SECTION "Vblank", ROM0[$0040]
	jp $FF80 ;jump VBlank ISR in HRAM
SECTION	"LCDC", ROM0[$0048]
	jp lyc_isr

SECTION "OAM_mirror", WRAM0, ALIGN[8]
OAM_Data: 
    ds 24*4
OAM_Data_Reusable: ;Sprites that can be reused with each new displayed screen
    ds 16*4

SECTION "graphics", ROM0
; Initiate graphics stuff
g_init:
    call lcd_off

    ;Copy the VBlank ISR to HRAM (because DMA can only work from there)
    ld hl, vblank_isr
    ld de, $FF80
    ld bc, vblank_isr_e-vblank_isr
    call mem_CopyVRAM

    ;Set Palette
    ld a, %11100100
	ld [rBGP], a
    ld [rOBP0], a
    ld [rOBP1], a

	;Set Scroll registers
	ld a, 0
	ld [rSCX], a
    ld a, -18
	ld [rSCY], a

    ;Let the LCDC interrupt to trigger on Line 18
    ld a, STATF_LYC
	ld [rSTAT], a

    ld a, 18
    ld [rLYC], a

    ;Load Tiles
	ld hl, TileDataMono
	ld de, _VRAM 
	ld bc, TileDataMonoE-TileDataMono
	call mem_CopyMono

	ld hl, TileData
	ld de, _VRAM + (TileDataMonoE-TileDataMono)*2
	ld bc, TileDataE-TileData
	call mem_Copy

	;Clear Screen
    ld a, 32
	ld hl, _SCRN0
	ld bc, SCRN_VX_B * SCRN_VY_B * 2
	call mem_SetVRAM

    ;Set Window
    ld a, 0
    ld [rWY], a
    ld a, 7
    ld [rWX], a

    ;Display Top Bar
    ld a, $8A
    ld hl, _SCRN1
    ld bc, SCRN_VX_B*2
    call mem_SetVRAM

    ld a, $89
    ld hl, _SCRN1+(SCRN_VY_B*2)
    ld bc, SCRN_X_B
    call mem_SetVRAM

    ;Loading Icon
    ;ld de, _SCRN1+(SCRN_VY_B*8)+4
	;ld bc, LoadingE-Loading
	;ld hl, Loading
	;call mem_CopyVRAM

    ;Load OAM Entries
    ld hl, OamEntries
    ld de, OAM_Data
    ld bc, OamEntriesE-OamEntries
    call mem_Copy

    ;Display 

    ;Turn Screen on again
	ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_WIN9C00|LCDCF_OBJ16|LCDCF_OBJON
	ld [rLCDC], a

    ret

; Turn the LCD off
lcd_off:
	ld a,[rLCDC]
	rlca
	ret nc
.wait:
	ld a,[rLY]
    cp 145
    jr nz,.wait

    ld a,[rLCDC]
    res 7,a
    ld [rLCDC],a
	ret

; Clear SCRN1 (unscrollable content)
clearSCRN1:
    ld a, 32
	ld hl, _SCRN1 + SCRN_VX_B*3
	ld bc, SCRN_VX_B * SCRN_VY_B - SCRN_VX_B*3
	call mem_SetVRAM
    ret

; Wait for VRAM accessibility
waitVBlank:
    ld   a, [rLY]
	cp   145
	jr   nz, waitVBlank
    ret


; Copy a "Metatile" into VRAM - a: starting tile index, hl: vram loc, b: width, c: height
mt_copy:
    ld e, SCRN_VY_B

    push af
    call waitVBlank
    pop af

:   ld d, b
    push hl
:   ld [hl+], a
    inc a
    dec b
    jr nz, :-

    ld  b, d
    ld d, $00
    pop hl
    add hl, de

    dec c
    jr nz, :--

    ret

    
; VBlank ISR
vblank_isr:
    push af

    ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_WIN9C00|LCDCF_WINON|LCDCF_OBJ16|LCDCF_OBJON
    ld [rLCDC], a

    ld a, HIGH(OAM_Data)
    ldh [$FF46], a  
    ld a, 40
.wait
    dec a
    jr nz, .wait

    pop af
    reti
vblank_isr_e:

; LYC ISR
lyc_isr:
    ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_WIN9C00|LCDCF_WINOFF|LCDCF_OBJ16|LCDCF_OBJON
    ld [rLCDC], a
    reti

SECTION "graphics_data",ROM0
; Tiles
TileDataMono:
	INCLUDE "graphics/ibmpc1.inc"
	chr_IBMPC1	1,4
TileDataMonoE:
TileData:
	INCBIN "graphics/icons.bin"
    INCBIN "graphics/keyboard.bin"
    INCBIN "graphics/menu.bin"
TileDataE:

; OAM Entries
OAM_OFFSET SET 0
OamEntries:
Icon_Wifi:
ICON_WIFI1_O  EQU OAM_OFFSET 
OAM_OFFSET = OAM_OFFSET + 4
    db 16,SCRN_X-(8*0+1),$80,OAMF_PAL0|OAMF_XFLIP
ICON_WIFI2_O  EQU OAM_OFFSET 
OAM_OFFSET = OAM_OFFSET + 4
    db 16,SCRN_X-(8*1+1),$80,OAMF_PAL0

Icon_MData:
ICON_MDATA1_O EQU OAM_OFFSET 
OAM_OFFSET = OAM_OFFSET + 44
    db 16,SCRN_X-(8*2+1),$82,OAMF_PAL0|OAMF_XFLIP|OAMF_YFLIP
ICON_MDATA2_O EQU OAM_OFFSET 
OAM_OFFSET = OAM_OFFSET + 4
    db 16,SCRN_X-(8*3+1),$82,OAMF_PAL0

Icon_BT:
ICON_BT_O     EQU 4*4
    db 16,SCRN_X-(8*4+3),$84,OAMF_PAL0

Icon_Ser:
ICON_SER_O    EQU OAM_OFFSET 
OAM_OFFSET = OAM_OFFSET + 4
    db 16,SCRN_X-(8*5+7),$86,OAMF_PAL0

KB_Cursor:
KB_CURSOR_O   EQU OAM_OFFSET 
OAM_OFFSET = OAM_OFFSET + 4 
    db 0, 8*3-1,        $88,OAMF_PAL0

OamEntriesE:

; Text
Loading:
    db "Loading..."
LoadingE:

ENDC