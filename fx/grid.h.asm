
; Grid FX

; Effect Screen Grid is 13 x 7 'pixels'
GRID_W = 13
GRID_H = 7
GRID_SIZE = GRID_W * GRID_H


; Position of top left of pixel grid
OFFS_X = 1
OFFS_Y = 10
OFFS_ADDR = &7c00+OFFS_Y*40+OFFS_X

PIXEL_W = 3	; 'pixel' width in chars
PIXEL_H = 2 ; 'pixel' height in chars

; Block designs
; [A][B]
; [C][D]


; full block
BLOCK3_A = 32+1+2+4+8+16+64
BLOCK3_B = 32+1+2+4+8+16+64
BLOCK3_C = 32+1+2
BLOCK3_D = 32+1+2

; partial block
BLOCK2_A = 32+2+4+8+16+64
BLOCK2_B = 32+1+4+8+16+64
BLOCK2_C = 32+2
BLOCK2_D = 32+1

; small block
BLOCK1_A = 32+8+64
BLOCK1_B = 32+4+16
BLOCK1_C = 32
BLOCK1_D = 32


PRECISION = 7
PIXEL_FULL = (2^PRECISION)-1

; Grid vars

screen_addr = &80 ; &81
screen_addr2 = &82
current_pixel = &88
speed = &89
tmp1 = &8A
tmp2 = &8B
index = &8C

timer = &8E ; &8F


; Macros to set Block effect on Grid

MACRO SET_BLOCK_EFFECT effect_addr
	ldx #8*4-1
.loop
	lda effect_addr,x
	sta block_table,x
	dex
	bpl loop
ENDMACRO

MACRO SET_COLOUR_EFFECT effect_addr
	ldx #7
.loop
	lda effect_addr,x
	sta block_colours,x
	dex
	bpl loop
ENDMACRO
