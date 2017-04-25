
; wibbling logo
; using sprite data from mode7-sprites cracktro wip

.fx_logowibble_start

LOGOWIBBLE_shadow_addr = &7C00

LOGOWIBBLE_char_width = 38
LOGOWIBBLE_char_height = 6
LOGOWIBBLE_sixel_height = (LOGOWIBBLE_char_height * 3)

LOGOWIBBLE_y_scr_addr = LOGOWIBBLE_shadow_addr + (1 * MODE7_char_width)
LOGOWIBBLE_table_size = 64

PLOT_PIXEL_RANGE_Y = 3*25

\ ******************************************************************
\ *	Logo Wibble FX
\ ******************************************************************

\\ Drawing complete sprite at fixed vertical position
\\ Each sixel line can have a separate X value
\\ For each sixel line
\\ Get x value
\\ Switch data block even/odd
\\ Start at x char, mask in all sprite data for that sixel line

.fx_logowibble_index
EQUB 0

.fx_logowibble_update
{
	JSR fx_logowibble_clear

	\\ Reset screen write address for this frame
	LDA #LO(LOGOWIBBLE_y_scr_addr)
	STA fx_logowibble_load_addr + 1
	STA fx_logowibble_write_addr + 1

	LDA #HI(LOGOWIBBLE_y_scr_addr)
	STA fx_logowibble_load_addr + 2
	STA fx_logowibble_write_addr + 2

	LDY #0					; sixel row

	.sixel_row_loop

	\\ Index into table for X lookup
	TYA
	ASL A
	CLC
	ADC fx_logowibble_index
	AND #(LOGOWIBBLE_table_size-1)
	TAX

	\\ Get x position
	LDA fx_logowibble_table, X			; X value for this sixel row
	STA fx_logowibble_x_pos + 1
	AND #&1
	ORA mode7_sprites_mod3_table, Y		; gives us 0-5 offset
	TAX

	LDA fx_logowibble_row_mask, X
	STA fx_logowibble_data_mask + 1

	\\ Sprite address = logo_data_XY + char_row
	\\ There's probably a quicker way to do this by toggling sprite data index depending on X parity
	CLC
	LDA fx_logowibble_sprite_table_LO, X
	ADC fx_logowibble_y_mult_table, Y
	STA fx_logowibble_data_addr + 1

	LDA fx_logowibble_sprite_table_HI, X
	ADC #0
	STA fx_logowibble_data_addr + 2
	\\ Also don't need to calc sprite address each time if using dense data - to be optimised

	\\ X char position on screen
	.fx_logowibble_x_pos
	LDA #0
	LSR A
	TAX

	\\ Save sixel row index
	STY fx_logowibble_y_row+1
	LDY #0

	.fx_logowibble_plot_loop

	.fx_logowibble_data_addr
	LDA &2000, Y

	.fx_logowibble_data_mask
	AND #0

	BEQ next_char

	.fx_logowibble_load_addr
	ORA &7800, X

	\\ Could mask out bits here to avoid having 6x copies of the sprite data

	.fx_logowibble_write_addr
	STA &7800, X

	\\ Next char
	.next_char
	INX
	INY
	CPY #LOGOWIBBLE_char_width
	BNE fx_logowibble_plot_loop

	\\ Next sixel row
	.fx_logowibble_y_row
	LDY #0
	INY
	CPY #LOGOWIBBLE_sixel_height
	BCS return

	\\ Did we move onto next character row?
	LDA mode7_sprites_mod3_table, Y
	BNE sixel_row_loop

	\\ Need to update screen pointers
	;CLC		; cleared above
	LDA fx_logowibble_load_addr + 1
	ADC #MODE7_char_width
	STA fx_logowibble_load_addr + 1
	STA fx_logowibble_write_addr + 1
	BCC sixel_row_loop

	\\ Carry
	INC fx_logowibble_load_addr + 2
	INC fx_logowibble_write_addr + 2
	BNE sixel_row_loop

	\\ Could also move to next sprite data row if dense data
	\\ Might also be able to keep sprite index in register if data small enough...

	.return
	LDX fx_logowibble_index
	INX
	AND #(LOGOWIBBLE_table_size-1)
	STX fx_logowibble_index

	RTS
}

.fx_logowibble_clear
{
	LDA #32
	FOR y,1,6,1
	FOR x,1,39,1
	STA &7C00 + (y*40) + x
	NEXT
	NEXT
	RTS
}

\ ******************************************************************
\ *	Look up tables
\ ******************************************************************

.fx_logowibble_table
FOR n, 0, LOGOWIBBLE_table_size-1, 1
EQUB 4 + 1.9 * SIN(2 * PI * n / LOGOWIBBLE_table_size)
NEXT

.fx_logowibble_sprite_table_LO
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)
EQUB LO(logo_data_00)
EQUB LO(logo_data_10)

.fx_logowibble_sprite_table_HI
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)
EQUB HI(logo_data_00)
EQUB HI(logo_data_10)

.fx_logowibble_y_mult_table
FOR n, 0, LOGOWIBBLE_sixel_height-1, 1
EQUB (n DIV 3) * LOGOWIBBLE_char_width
NEXT

.fx_logowibble_row_mask
EQUB 3, 3, 12, 12, 80, 80

.mode7_sprites_mod3_table
FOR n, 0, PLOT_PIXEL_RANGE_Y-1, 1
	EQUB (n MOD 3) << 1						; shift this up as bottom bit is our x offset
NEXT

\ ******************************************************************
\ *	Sprite data
\ ******************************************************************

\\ Input file 'logo.png'
\\ Image size=60x18 pixels=60x18
.logo
;EQUB 40, 6	;char width, char height
.logo_data
.logo_data_00	; x_offset=0, y_offset=0
EQUB 127,35,107,127,127,127,127,35,107,127,127,127,127,55,35,127,127,127,127,127,127,127,127,55,35,127,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 127,32,106,127,53,32,127,32,106,127,127,127,127,53,32,127,127,32,106,53,32,32,127,53,32,127,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 127,32,32,32,53,32,53,32,32,106,32,32,32,53,32,32,106,32,106,32,32,32,53,32,32,32,53,32,32,106,32,32,106,127,127,32,32,127
EQUB 127,32,106,53,53,32,127,32,106,127,32,106,127,53,32,127,106,32,106,53,32,127,127,53,32,127,53,32,127,106,32,106,127,35,35,32,32,127
EQUB 127,32,106,53,53,32,127,32,106,127,124,52,32,53,32,127,106,32,106,53,32,127,127,53,32,127,53,32,124,126,32,106,127,32,32,32,32,127
EQUB 127,32,34,33,53,32,127,32,34,107,35,33,32,53,32,127,106,32,106,53,32,127,127,53,32,35,53,32,35,107,32,106,127,32,32,127,127,127
.logo_data_10	; x_offset=1, y_offset=0
EQUB 106,55,35,127,127,127,127,55,35,127,127,127,127,127,35,107,127,127,127,127,127,127,127,127,35,107,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 106,53,32,127,127,32,106,53,32,127,127,127,127,127,32,106,127,53,32,127,32,32,106,127,32,106,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 106,53,32,32,106,32,106,32,32,32,53,32,32,106,32,32,32,53,32,53,32,32,106,32,32,32,106,32,32,32,53,32,32,127,127,53,32,106
EQUB 106,53,32,127,106,32,106,53,32,127,53,32,127,127,32,106,53,53,32,127,32,106,127,127,32,106,127,32,106,53,53,32,127,55,35,33,32,106
EQUB 106,53,32,127,106,32,106,53,32,127,125,124,32,106,32,106,53,53,32,127,32,106,127,127,32,106,127,32,104,124,53,32,127,53,32,32,32,106
EQUB 106,53,32,35,106,32,106,53,32,35,55,35,32,106,32,106,53,53,32,127,32,106,127,127,32,34,107,32,34,35,53,32,127,53,32,106,127,127

IF 0
.logo_data_01	; x_offset=0, y_offset=1
EQUB 32,32,124,44,108,124,124,124,124,44,108,124,124,124,124,60,44,124,124,124,124,124,124,124,124,60,44,124,124,124,124,124,124,124,124,124,124,124,124,124
EQUB 32,32,127,32,106,127,55,35,127,32,106,127,127,127,127,53,32,127,127,35,107,55,35,35,127,53,32,127,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 32,32,127,32,34,35,53,32,55,32,34,107,35,35,35,53,32,35,107,32,106,33,32,32,55,33,32,35,55,35,35,107,35,35,107,127,127,35,35,127
EQUB 32,32,127,32,104,52,53,32,125,32,104,126,32,104,124,53,32,124,106,32,106,52,32,124,125,52,32,124,53,32,124,106,32,104,126,47,47,32,32,127
EQUB 32,32,127,32,106,53,53,32,127,32,106,127,112,50,35,53,32,127,106,32,106,53,32,127,127,53,32,127,53,32,115,122,32,106,127,32,32,32,32,127
EQUB 32,32,127,32,42,37,53,32,127,32,42,111,47,37,32,53,32,127,106,32,106,53,32,127,127,53,32,47,53,32,47,111,32,106,127,32,32,124,124,127
.logo_data_11	; x_offset=1, y_offset=1
EQUB 32,32,104,60,44,124,124,124,124,60,44,124,124,124,124,124,44,108,124,124,124,124,124,124,124,124,44,108,124,124,124,124,124,124,124,124,124,124,124,124
EQUB 32,32,106,53,32,127,127,35,107,53,32,127,127,127,127,127,32,106,127,55,35,127,35,35,107,127,32,106,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 32,32,106,53,32,35,107,32,106,33,32,35,55,35,35,107,32,34,35,53,32,55,32,32,106,35,32,34,107,35,35,35,55,35,35,127,127,55,35,107
EQUB 32,32,106,53,32,124,106,32,106,52,32,124,53,32,124,126,32,104,52,53,32,125,32,104,126,124,32,104,126,32,104,52,53,32,124,63,47,37,32,106
EQUB 32,32,106,53,32,127,106,32,106,53,32,127,117,112,35,107,32,106,53,53,32,127,32,106,127,127,32,106,127,32,98,113,53,32,127,53,32,32,32,106
EQUB 32,32,106,53,32,47,106,32,106,53,32,47,63,47,32,106,32,106,53,53,32,127,32,106,127,127,32,42,111,32,42,47,53,32,127,53,32,104,124,126
.logo_data_02	; x_offset=0, y_offset=2
EQUB 32,32,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112
EQUB 32,32,127,32,106,127,63,47,127,32,106,127,127,127,127,53,32,127,127,47,111,63,47,47,127,53,32,127,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 32,32,127,32,42,47,53,32,63,32,42,111,47,47,47,53,32,47,111,32,106,37,32,32,63,37,32,47,63,47,47,111,47,47,111,127,127,47,47,127
EQUB 32,32,127,32,96,48,53,32,117,32,96,122,32,96,112,53,32,112,106,32,106,48,32,112,117,48,32,112,53,32,112,106,32,96,122,127,127,32,32,127
EQUB 32,32,127,32,106,53,53,32,127,32,106,127,32,42,47,53,32,127,106,32,106,53,32,127,127,53,32,127,53,32,47,106,32,106,127,32,32,32,32,127
EQUB 32,32,127,32,106,53,53,32,127,32,106,127,127,53,32,53,32,127,106,32,106,53,32,127,127,53,32,127,53,32,127,127,32,106,127,32,32,112,112,127
.logo_data_12	; x_offset=1, y_offset=2
EQUB 32,32,96,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112,112
EQUB 32,32,106,53,32,127,127,47,111,53,32,127,127,127,127,127,32,106,127,63,47,127,47,47,111,127,32,106,127,127,127,127,127,127,127,127,127,127,127,127
EQUB 32,32,106,53,32,47,111,32,106,37,32,47,63,47,47,111,32,42,47,53,32,63,32,32,106,47,32,42,111,47,47,47,63,47,47,127,127,63,47,111
EQUB 32,32,106,53,32,112,106,32,106,48,32,112,53,32,112,122,32,96,48,53,32,117,32,96,122,112,32,96,122,32,96,48,53,32,112,127,127,53,32,106
EQUB 32,32,106,53,32,127,106,32,106,53,32,127,53,32,47,111,32,106,53,53,32,127,32,106,127,127,32,106,127,32,42,37,53,32,127,53,32,32,32,106
EQUB 32,32,106,53,32,127,106,32,106,53,32,127,127,127,32,106,32,106,53,53,32,127,32,106,127,127,32,106,127,32,106,127,53,32,127,53,32,96,112,122
ENDIF

.fx_logowibble_end
