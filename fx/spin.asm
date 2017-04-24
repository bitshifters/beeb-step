; Spin FX

.fx_spin_start

.fx_spin_angle 		EQUB 0

.fx_spin_init
{
}

FX_SPIN_CENTRE_X = 128+(GRID_W/2)
FX_SPIN_CENTRE_Y = 128+(GRID_H/2)

FX_SPIN_TABLE_SIZE = 64

.fx_spin_update
{
IF 1
	LDA #FX_SPIN_CENTRE_X
	STA rtw_startx
	LDA #FX_SPIN_CENTRE_Y
	STA rtw_starty

	LDX fx_spin_angle
	LDA fx_spin_sin_table, X
	CLC
	ADC #FX_SPIN_CENTRE_X
	STA rtw_endx

	LDA fx_spin_cos_table, X
	CLC
	ADC #FX_SPIN_CENTRE_Y
	STA rtw_endy

	INX
	
IF 	FX_SPIN_TABLE_SIZE < 256
	TXA
	AND #(FX_SPIN_TABLE_SIZE-1)
	STA fx_spin_angle
ELSE
	STX fx_spin_angle
ENDIF

	JSR draw_line
ELSE

	LDA #0
	STA rtw_startx
	LDA #0
	STA rtw_starty

	LDA fx_spin_angle
	STA rtw_endx
	LDA #GRID_H
	STA rtw_endy

	JSR draw_line

	LDA fx_spin_angle
	CLC
	ADC #1
	AND #&F
	STA fx_spin_angle

ENDIF

	.return
	RTS
}

.fx_spin_sin_table
FOR n,0,(FX_SPIN_TABLE_SIZE + (FX_SPIN_TABLE_SIZE/4))-1,1
EQUB GRID_W * SIN(2 * PI * n / FX_SPIN_TABLE_SIZE)
NEXT

fx_spin_cos_table = fx_spin_sin_table + (FX_SPIN_TABLE_SIZE/4)

.fx_spin_end
