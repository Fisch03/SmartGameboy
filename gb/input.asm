IF !DEF(INPUT)
INPUT EQU 1

SECTION "input_var", WRAM0
keydown_dir: ds 1
keydown_ab:  ds 1

ENDC