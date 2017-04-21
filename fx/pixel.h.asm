
; Pixel FX

MACRO SET_PIXEL_EFFECT fn
{
	LDA #LO(fn):STA fx_pixel_plot+1
	LDA #HI(fn):STA fx_pixel_plot+2
}
ENDMACRO


; Macros to set a pixel (X,Y) in the grid

MACRO SET_PIXEL_AX					; (X,Y)
{
	\\ clip
	CMP #GRID_W
	BCS clip
	CPX #GRID_H
	BCS clip
	\\ carry is clear
	ADC grid_y_lookup, X
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X
	.clip
}
ENDMACRO

MACRO SET_PIXEL_AX_MIRROR_OPP		; (X,Y)
{
	\\ clip
	CMP #GRID_W
	BCS clip
	CPX #GRID_H
	BCS clip

	\\ carry is clear
	ADC grid_y_lookup, X
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ mirror opposite corner
	TXA
	SEC
	SBC #GRID_SIZE
	EOR #&FF

	TAX
	LDA #PIXEL_FULL
	STA grid_array, X
	.clip
}
ENDMACRO

MACRO SET_PIXEL_AX_MIRROR_Y			; (X,Y)
{
	\\ clip
	CMP #GRID_W
	BCS clip
	CPX #GRID_H
	BCS clip

	\\ remember x,y
	STA load_x+1
	STX load_y+1

	\\ carry is clear
	ADC grid_y_lookup, X
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ Mirror in Y
	.load_y
	LDX #0
	.load_x		
	LDA #0

	CLC
	ADC grid_y_lookup_inv, X
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X
	.clip
}
ENDMACRO

MACRO SET_PIXEL_AX_MIRROR_X			; (X,Y)
{
	\\ clip
	CMP #GRID_W
	BCS clip
	CPX #GRID_H
	BCS clip
	\\ calc 2x
	ASL A
	STA two_x+1
	LSR A
	\\ carry is clear
	ADC grid_y_lookup, X
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ Mirror in X - not quicker to do a store & lookup!
	TXA
	ADC #(GRID_W-1)
	SEC
	.two_x
	SBC #0
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X
	.clip
}
ENDMACRO

MACRO SET_PIXEL_AX_MIRROR_FOUR			; (X,Y)
{
	CMP #GRID_W
	BCS clip
	CPX #GRID_H
	BCS clip

	\\ calc 2x
	ASL A
	STA two_x+1
	STA two_x2+1
	LSR A

	\\ carry is clear
	ADC grid_y_lookup, X
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ Mirror in X
	TXA
	ADC #(GRID_W-1)
	SEC
	.two_x
	SBC #0
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ Mirror opp corner - actually mirrors in Y
	TXA
	SEC
	SBC #GRID_SIZE
	EOR #&FF
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	\\ Mirror in X again - actually mirrors to opp corner
	TXA
	ADC #(GRID_W-1)
	SEC
	.two_x2
	SBC #0
	TAX
	LDA #PIXEL_FULL
	STA grid_array, X

	.clip
}
ENDMACRO
