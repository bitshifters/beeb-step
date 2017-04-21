
; Grid FX

.fx_grid_start

; table for each chr, indexed using same offset as colour lookup (0-7)
.block_table
.block_table_A	EQUB BLOCK1_A, BLOCK1_A, BLOCK1_A, BLOCK1_A, BLOCK2_A, BLOCK2_A, BLOCK3_A, BLOCK3_A
.block_table_B	EQUB BLOCK1_B, BLOCK1_B, BLOCK1_B, BLOCK1_B, BLOCK2_B, BLOCK2_B, BLOCK3_B, BLOCK3_B
.block_table_C	EQUB BLOCK1_C, BLOCK1_C, BLOCK1_C, BLOCK1_C, BLOCK2_C, BLOCK2_C, BLOCK3_C, BLOCK3_C
.block_table_D	EQUB BLOCK1_D, BLOCK1_D, BLOCK1_D, BLOCK1_D, BLOCK2_D, BLOCK2_D, BLOCK3_D, BLOCK3_D
	
; lookup table of colours
.block_colours	SKIP 8

; standard colour palette
.effect_colour_standard
	EQUB 144+8	; 0 - Black (Conceal)
	EQUB 144+4	; 1 - Blue
	EQUB 144+1	; 2 - Red
	EQUB 144+5  ; 3 - Magenta
	EQUB 144+2	; 4 - Green
	EQUB 144+6  ; 5 - Cyan
	EQUB 144+3	; 6 - Yellow
	EQUB 144+7	; 7 - White

; inverted colours
.effect_colour_inverted
	EQUB 144+7	; 7 - White
	EQUB 144+3	; 6 - Yellow
	EQUB 144+6  ; 5 - Cyan
	EQUB 144+2	; 4 - Green
	EQUB 144+5  ; 3 - Magenta
	EQUB 144+1	; 2 - Red
	EQUB 144+4	; 1 - Blue
	EQUB 144+8	; 0 - Black (Conceal)


; all white
.effect_colour_white
	EQUB 144+7,144+7,144+7,144+7,144+7,144+7,144+7,144+7


.effect_blocks_all_on
	EQUB BLOCK3_A, BLOCK3_A, BLOCK3_A, BLOCK3_A, BLOCK3_A, BLOCK3_A, BLOCK3_A, BLOCK3_A
	EQUB BLOCK3_B, BLOCK3_B, BLOCK3_B, BLOCK3_B, BLOCK3_B, BLOCK3_B, BLOCK3_B, BLOCK3_B
	EQUB BLOCK3_C, BLOCK3_C, BLOCK3_C, BLOCK3_C, BLOCK3_C, BLOCK3_C, BLOCK3_C, BLOCK3_C
	EQUB BLOCK3_D, BLOCK3_D, BLOCK3_D, BLOCK3_D, BLOCK3_D, BLOCK3_D, BLOCK3_D, BLOCK3_D


.effect_blocks_scaled
	EQUB BLOCK1_A, BLOCK1_A, BLOCK1_A, BLOCK1_A, BLOCK2_A, BLOCK2_A, BLOCK3_A, BLOCK3_A
	EQUB BLOCK1_B, BLOCK1_B, BLOCK1_B, BLOCK1_B, BLOCK2_B, BLOCK2_B, BLOCK3_B, BLOCK3_B
	EQUB BLOCK1_C, BLOCK1_C, BLOCK1_C, BLOCK1_C, BLOCK2_C, BLOCK2_C, BLOCK3_C, BLOCK3_C
	EQUB BLOCK1_D, BLOCK1_D, BLOCK1_D, BLOCK1_D, BLOCK2_D, BLOCK2_D, BLOCK3_D, BLOCK3_D



; Each byte in the array is a 'brightness' value from 0-63 (where 0 is off and 63 is full bright)
.grid_array
	FOR n,0,GRID_SIZE
		EQUB PIXEL_FULL
	NEXT


; on entry - A is decay rate
.grid_fade
{
	sta speed
	ldx #GRID_SIZE-1
.loop
	lda grid_array,x
	beq nextg

	sec
	sbc speed
	bpl nowrap
	lda #0
.nowrap	
	sta grid_array,x

.nextg
	dex
	bpl loop


	rts
}

IF 0
; update the colours of each 'pixel' based on current 'level'
.grid_draw
{
	lda #GRID_H
	sta tmp1

	lda #LO(OFFS_ADDR)
	sta write_colour1+1
	lda #HI(OFFS_ADDR)
	sta write_colour1+2
	
	lda #LO(OFFS_ADDR+40)
	sta write_colour2+1
	lda #HI(OFFS_ADDR+40)
	sta write_colour2+2


	ldy #0
.yloop
	ldx #0
	lda #GRID_W
	sta tmp2
.xloop
	tya
	pha

	lda grid_array,y
	FOR n,1,PRECISION-3
		lsr a
	NEXT

	tay

	lda block_colours,y
.write_colour1
	sta OFFS_ADDR,x
.write_colour2
	sta OFFS_ADDR+40,x

	inx
	inx
	inx

	pla
	tay
	iny

	dec tmp2
	bne xloop

	lda write_colour1+1:clc:adc #80:sta write_colour1+1:lda write_colour1+2:adc #0:sta write_colour1+2
	lda write_colour2+1:clc:adc #80:sta write_colour2+1:lda write_colour2+2:adc #0:sta write_colour2+2



	dec tmp1
	bne yloop

	rts
}


ELSE

.grid_draw
{
	lda #GRID_H
	sta tmp1

	lda #LO(OFFS_ADDR)
	sta screen_addr+0
	lda #HI(OFFS_ADDR)
	sta screen_addr+1

	lda #LO(OFFS_ADDR+40)
	sta screen_addr2+0
	lda #HI(OFFS_ADDR+40)
	sta screen_addr2+1

	lda #0
	sta index

.yloop
	lda #GRID_W
	sta tmp2

	ldy #0
.xloop

	ldx index
	lda grid_array,x

	FOR n,1,PRECISION-3
		lsr a
	NEXT
	tax

	lda block_colours,x
	sta (screen_addr),y
	sta (screen_addr2),y
	iny

	lda block_table_A,x
	sta (screen_addr),y
	lda block_table_C,x
	sta (screen_addr2),y
	iny

	lda block_table_B,x
	sta (screen_addr),y
	lda block_table_D,x
	sta (screen_addr2),y
	iny

	inc index
	dec tmp2
	bne xloop

	lda screen_addr+0:clc:adc #80:sta screen_addr+0:lda screen_addr+1:adc #0:sta screen_addr+1
	lda screen_addr2+0:clc:adc #80:sta screen_addr2+0:lda screen_addr2+1:adc #0:sta screen_addr2+1

	dec tmp1
	bne yloop

	rts
}

ENDIF


.fx_grid_end
