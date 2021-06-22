INCLUDE "gbhw.inc" ;Hardware Definitions

;Interrupts
SECTION	"Timer_Overflow", ROM0[$0050]
	jp timer_isr
SECTION "p1thru4", ROM0[$0060]
	reti

SECTION "start", ROM0[$0100]
nop
jp start
	ROM_HEADER	ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

INCLUDE "memory.asm"
INCLUDE "serial.asm"

INCLUDE "graphics/graphics.asm"

INCLUDE "screens/keyboard.asm"
INCLUDE "screens/menu.asm"


start:
	di

	ld sp, $ffff 

	;Clear WRAM
	ld a, 0
	ld hl, _RAM
	ld bc, $DFFF-_RAM
	call mem_Set

	call g_init

	ld a, TACF_16KHZ|TACF_START
	ld [rTAC], a

	ld a, IEF_SERIAL|IEF_VBLANK|IEF_LCDC|IEF_TIMER
	ld [rIE], a
	ei 

	;ld de, s_buf
	;call get_user_input

	;ld a, 1
	;ld hl, s_buf
	;call s_send_req

	call show_menu

.wait:
	halt
	nop

	ld a, [s_state]
	cp 0
	jr nz, .wait

    ld a, [s_len]
	ld b, a
    ld a, [s_len+1]
	ld c, a

    ld hl, s_buf
	ld de, _SCRN0+(SCRN_VY_B*2)
	call mem_CopyVRAM

loop: ;Infinite wait loop
	halt 
	nop
	jr	loop

; ISR for the Timer overflow
timer_isr:
	push af
	
	ld a, 0
    ld [OAM_Data+ICON_SER_O+OAM_Y], a

	ld a, P1F_5
	ld [rP1], a
	ld a, [rP1]

	bit 2, a
	jr nz, :+
	ld a, [rSCY]
	cp -18
	jr z, :++
	dec a
	ld [rSCY], a
	jr :++

:	bit 3, a
	jr nz, :+
	ld a, [rSCY]
	cp $70
	jr z, :+
	inc a
	ld [rSCY], a

:	pop af
	reti


SECTION "data", ROM0
Msg:
	db "Hello World!"
	;db "a"
MsgE:
ErrorAck:
	db "Err-No Ack"
ErrorAckE:
Success:
	db "Success!"
SuccessE: