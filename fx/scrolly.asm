; Scroll FX

FX_SCROLLY_ADDR = &7C00 + 24 * 40 + 2
FX_SCROLLY_SPEED = 10


.fx_scrolly_start

.fx_scrolly_init
{
	LDA #LO(fx_scrolly_text)
	STA fx_scrolly_ptr
	LDA #HI(fx_scrolly_text)
	STA fx_scrolly_ptr+1

	LDA #FX_SCROLLY_SPEED
	STA fx_scrolly_delay

	RTS
}

.fx_scrolly_update
{
	DEC fx_scrolly_delay
	BNE return

	LDA #FX_SCROLLY_SPEED
	STA fx_scrolly_delay

	\\ We're gonna move everything along one char
	LDA FX_SCROLLY_ADDR
	BPL no_ctrl_code

	\\ We're going to lose a control code when we scroll

	\\ So buffer last two control codes on left columns
	LDA FX_SCROLLY_ADDR-1
	STA FX_SCROLLY_ADDR-2

	LDA FX_SCROLLY_ADDR
	STA FX_SCROLLY_ADDR-1

	.no_ctrl_code

	\\ Move all characters along one char
	LDX #0
	.loop
	LDA FX_SCROLLY_ADDR+1, X
	STA FX_SCROLLY_ADDR, X

	INX
	CPX #37
	BNE loop

	\\ Get next char from text string
	LDY #0
	LDA (fx_scrolly_ptr), Y
	BNE continue

	\\ EOS
	JSR fx_scrolly_init
	LDA (fx_scrolly_ptr), Y

	\\ Plot char
	.continue
	STA FX_SCROLLY_ADDR, X

	\\ Increment text ptr
	INC fx_scrolly_ptr
	BNE no_carry
	INC fx_scrolly_ptr+1
	.no_carry

	.return
	RTS
}

.fx_scrolly_text
{
	RED=MODE7_alpha_black+1
	GREEN=MODE7_alpha_black+2
	YELLOW=MODE7_alpha_black+3
	BLUE=MODE7_alpha_black+4
	MAGENA=MODE7_alpha_black+5
	CYAN=MODE7_alpha_black+6
	WHITE=MODE7_alpha_black+7
	FLASHING=136
	STEADY=137

	\\ Could put in wait and speed commands if desired etc.

	EQUS RED, "BITSHIFTERS",YELLOW,"presents",FLASHING,CYAN,"BEEB STEP",STEADY,WHITE,"Code by Henley and Kieran etc. etc.          ", 0
}

.fx_scrolly_end
