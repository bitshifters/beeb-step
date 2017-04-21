; Frequency FX

FX_FREQUENCY_START = 13

.fx_frequency_start

.fx_frequency
{
	; triggers from frequencies played
	ldx #FX_FREQUENCY_START						; can start upto 27 entries into vgm_freq_array
	ldy #0
.floop
	lda vgm_freq_array,x
	beq nextf

	lda #PIXEL_FULL
	sta grid_array,y
;	sta grid_array+1,y
	

	lda #0
	sta vgm_freq_array,x
.nextf
	iny
;	iny

	cpy #GRID_SIZE
	bcs done_floop				; otherwise we overflow grid_array

	inx
	cpx #VGM_FX_num_freqs		; otherwise we overflow vgm_freq_array
	bcc floop
.done_floop

	RTS
}

.fx_frequency_end
