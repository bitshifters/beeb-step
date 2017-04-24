; Letter FX

.fx_letter_start

; Plot a letter on grid
; A=ASCII char, X&Y=(x,y) 
.fx_letter_plot
{
	STX fx_letter_x
	STY fx_letter_y
	STA fx_letter_char

	\\ Ask OS for font definition (or define our own)
	LDX #LO(fx_letter_char)
	LDY #HI(fx_letter_char)
	LDA #&A
	JSR osword				; osword call

	LDY #0

	.y_loop
	\\ Clip row
	LDA fx_letter_y
	CMP #GRID_H
	BCS skip_y

	\\ Letter mask
	LDA #&80
	STA fx_letter_mask

	LDA fx_letter_x
	STA fx_letter_w

	.x_loop
	\\ Clip column
	LDA fx_letter_w
	CMP #GRID_W
	BCS skip_x

	\\ Mask font
	LDA fx_letter_def, Y
	AND fx_letter_mask
	BEQ skip_x

	\\ Calc grid index
	LDX fx_letter_y
	LDA fx_letter_w
	CLC
	ADC grid_y_lookup, X
	TAX
	
	\\ Set grid pixel
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ Next column
	.skip_x
	INC fx_letter_w
	LSR fx_letter_mask
	BNE x_loop

	\\ Next row
	.skip_y
	INC fx_letter_y
	INY
	CPY #8
	BNE y_loop

	.return
	RTS
}

.fx_letter_char			SKIP 1			; character definition required
.fx_letter_def			SKIP 8			; character definition bytes


; Probably ideally want letters to appear on the beat...

FX_LETTER_DELAY = 12

.fx_letter_update
{
	DEC fx_letter_delay
	BNE return

	LDA #FX_LETTER_DELAY
	STA fx_letter_delay

	LDX fx_letter_index
	LDA fx_letter_text, X
	BNE plot_text

	LDX #0
	STX fx_letter_index
	LDA fx_letter_text, X

	.plot_text
	LDY #0
	DEX:DEX
	JSR fx_letter_plot
	INC fx_letter_index

	.return
	RTS
}

.fx_letter_delay		EQUB FX_LETTER_DELAY
.fx_letter_index		EQUB 0
.fx_letter_text
EQUS "BITSHIFTERS", 0


.fx_letter_end
