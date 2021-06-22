IF !DEF(SERIAL)
SERIAL EQU 1

ID_PING EQU $00
ID_ACK  EQU $01
ID_REQ  EQU $02
ID_RES  EQU $03
ID_STAT EQU $04
ID_MSG  EQU $05

SECTION "Serial", ROM0[$0058]
	jp s_isr

SECTION "s_var", WRAM0
;serial status - lsb takes priority
SS_IGN_pos   EQU 0 ;Bit 0: ignore next interrupt
SS_IGN       EQU %00000001 ;Bit 0: ignore next interrupt

SS_SND_H_pos EQU 1 ;Bit 1: send header
SS_SND_H     EQU %00000010

SS_SND_pos   EQU 2 ;Bit 2: send data
SS_SND       EQU %00000100

SS_ACK_pos   EQU 3 ;Bit 3: wait for ack
SS_ACK       EQU %00001000

SS_RCV_H_pos EQU 4 ;Bit 4: rcv header
SS_RCV_H     EQU %00010000

SS_RCV_pos   EQU 5 ;Bit 5: rcv data
SS_RCV       EQU %00100000

SS_HALF_pos  EQU 6 ;Bit 6: which half of the 16 bit header is sent/received
SS_HALF      EQU %01000000

SS_MCU_pos   EQU 7 ;Bit 7: transfer has been initiated by the mcu
SS_MCU       EQU %10000000
s_state: ds 1

s_ptr: ds 2
s_len: ds 2
s_buf: ds 4096

SECTION "serial", ROM0
MACRO s_send_byte
	ld [rSB], a
	ld a, $81
	ld [rSC], a
ENDM

MACRO s_rcv_byte
    ld a, $80
    ld [rSC], a
ENDM

; 00 - ping - no args
s_send_ping: 
    ld a, SS_ACK|SS_RCV_H|SS_RCV
    ld [s_state], a

    ld a, ID_PING
    s_send_byte
    ret

; 01 - ack - no args
s_send_ack:
    ld a, SS_IGN
    ld [s_state], a

    ld a, ID_ACK
    s_send_byte
    ret

; 02 - req - a: expect response, bc: length, hl: loc
s_send_req:
    ld d, SS_SND_H|SS_SND|SS_ACK
    cp 0
    ld a, d
    jr z, :+
    or SS_RCV_H|SS_RCV
:   ld [s_state], a

    ld a, b
    ld [s_len], a
    ld a, c
    ld [s_len+1], a

    ld a, h
    ld [s_ptr], a
    ld a, l
    ld [s_ptr+1], a

    ld a, ID_REQ
    s_send_byte

    ret

;--HELPER FUNCTIONS--
s_err_ack:
    di
	lcd_WaitVRAM

    ld hl, .msg
	ld de, _SCRN0 + (SCRN_VY_B*2)
	ld bc, .msg_e-.msg
	call mem_CopyVRAM

	ld a, [rSB]
	ld [_SCRN0 + (SCRN_VY_B*3)], a

.loop:
	halt
	nop
	jp .loop

.msg:
	db "Err-No Ack"
.msg_e:

;--ISR--
s_isr:
    push af

    ld a, [Icon_Ser+OAM_Y]
    ld [OAM_Data+ICON_SER_O+OAM_Y], a

    ; check if cause of interrupt is known and branch accordingly
    ld a, [s_state]
    rra
    jp c, .ign
    rra
    jp c, .snd_h
    rra
    jp c, .snd
    rra
    jp c, .ack

    bit 3, a ;SS_MCU but rra'd 4 times left
    jp z, :+ 
    rra
    jp c, .mcu_h
    jp .mcu

:   rra
    jp c, .rcv_h
    rra
    jp c, .rcv
    ;otherwise, the mcu initiated a transfer
    jp .mcu_i

.ign:
    sla a
    ld [s_state], a

    s_rcv_byte

    pop af
    reti

.snd_h:
    ld a, [s_state]

    bit SS_HALF_pos, a
    jr nz, :+ 

    set SS_HALF_pos, a
    ld [s_state], a
    ld a, [s_len]
    jr :++

:   res SS_HALF_pos, a
    res SS_SND_H_pos, a
    ld [s_state], a
    ld a, [s_len+1]

:   s_send_byte

    pop af
    reti

.snd:
    push bc
    push hl

    ld a, [s_ptr]
	ld h, a
	ld a, [s_ptr+1]
	ld l, a

	ld a, [s_len]
	ld b, a
	ld a, [s_len+1]
	ld c, a

	ld a, b
	cp 0
	jr nz, :+
	ld a, c
	cp 0
	jr nz, :+

    ld a, [s_state]
    res SS_SND_pos, a
    ld [s_state], a

    s_rcv_byte

    jr :++

:   ld a, [hl+]
	dec bc
	s_send_byte

	ld a, h
	ld [s_ptr], a
	ld a, l
	ld [s_ptr+1], a

	ld a, b
	ld [s_len], a
	ld a, c
	ld [s_len+1], a

:   pop hl
    pop bc
    pop af
    reti

.ack:
    ld a, [s_state]
    res SS_ACK_pos, a
    ld [s_state], a

    ld a, [rSB]
    cp ID_ACK
    call nz, s_err_ack

    s_rcv_byte

    pop af
    reti

.rcv_h:
    ld a, [s_state]

    bit SS_HALF_pos, a
    jr nz, :+ 

    set SS_HALF_pos, a
    ld [s_state], a
    ld a, [rSB]
    ld [s_len], a

    jr :++

:   res SS_HALF_pos, a
    res SS_RCV_H_pos, a
    ld [s_state], a
    ld a, [rSB]
    ld [s_len+1], a

:   ld a, 0
    ld [s_ptr], a
    ld [s_ptr+1], a

    s_rcv_byte

    pop af
    reti

.rcv:
    push bc
    push de
    push hl

    ld hl, s_buf

    ld a, [s_ptr]
	ld d, a
	ld a, [s_ptr+1]
	ld e, a

    add hl, de

    ld a, [rSB]
    ld [hl+], a
	inc de

    ld a, [s_len]
    sub d
	cp 0
	jr nz, :+
	ld a, [s_len+1]
    sub e
	cp 0
	jr nz, :+

    ld a, [s_state]
    res SS_RCV_pos, a
    ld [s_state], a

    jr :++

:	ld a, d
	ld [s_ptr], a
	ld a, e
	ld [s_ptr+1], a

:   s_rcv_byte

    pop hl
    pop de
    pop bc
    pop af
    reti

;TODO: MCU Initiated transfers
.mcu_i:
    ld a, SS_MCU|SS_RCV
    ld [s_state], a
    
    ;check if header required depending on id
    pop af
    reti
.mcu_h:
    pop af
    reti
.mcu:
    pop af
    reti

ENDC