

PLAY_MUSIC = TRUE

SYS_ORB = &fe40
SYS_ORA = &fe41
SYS_DDRB = &fe42
SYS_DDRA = &fe43
SYS_T1C_L = &fe44
SYS_T1C_H = &fe45
SYS_T1L_L = &fe46
SYS_T1L_H = &fe47
SYS_T2C_L = &fe48
SYS_T2C_H = &fe49
SYS_SR = &fe4a
SYS_ACR =&fe4b
SYS_PCR = &fe4c
SYS_IFR = &fe4d
SYS_IER = &fe4e

USR_T1C_L = &fe64
USR_T1C_H = &fe65
USR_T1L_L = &fe66
USR_T1L_H = &fe67
USR_T2C_L = &fe68
USR_T2C_H = &fe69
USR_SR = &fe6a
USR_ACR = &fe6b
USR_PCR = &fe6c
USR_IFR = &fe6d
USR_IER = &fe6e

ORG 0

INCLUDE "lib/bbc.h.asm"
INCLUDE "lib/bbc_utils.h.asm"
INCLUDE "lib/exomiser.h.asm"
INCLUDE "lib/vgmplayer.h.asm"


; Define playback frequency - timed off the 1Mhz timer 
T1_HZ = 1000000
SAMP_HZ = 392 ; 294 ; 350 ;6250
RHZ = T1_HZ / SAMP_HZ



ORG &1100
GUARD &3000

.start

; Master 128 PAGE is &0E00 since MOS uses other RAM buffers for DFS workspace
SCRATCH_RAM_ADDR = &0400

INCLUDE "lib/exomiser.asm"
INCLUDE "lib/vgmplayer.asm"
INCLUDE "lib/disksys.asm"
INCLUDE "lib/swr.asm"
INCLUDE "lib/print.asm"

; disk loader uses hacky filename format (same as catalogue) 
; we use disk loader for SWR banks only
.bank_file0   EQUS "Bank0  $"
.bank_file1   EQUS "Bank1  $"
.bank_file2   EQUS "Bank2  $"
.bank_file3   EQUS "Bank3  $"

.screen_file  EQUS "LOAD Page", 13

.swr_fail_text EQUS "No SWR banks found.", 13, 10, 0
.swr_bank_text EQUS "Found %b", LO(swr_ram_banks_count), HI(swr_ram_banks_count), " SWR banks.", 13, 10, 0
.swr_bank_text2 EQUS " Bank %a", 13, 10, 0

.loading_bank_text EQUS "Loading bank... ", 0
.loading_bank_text2 EQUS "OK", 13, 10, 0


SONG_ADDR = &8000


.entry
{
	lda #200
	ldx #3
	jsr &fff4


    jsr swr_init
    bne swr_ok

    MPRINT swr_fail_text
    rts

.swr_ok


IF 1
    MPRINT    swr_bank_text
    ldx #0
.swr_print_loop
    lda swr_ram_banks,x
    MPRINT    swr_bank_text2
    inx
    cpx swr_ram_banks_count
    bne swr_print_loop
ENDIF


IF PLAY_MUSIC
	lda #0
	sta exo_swr_bank

	\\ load all SWR banks

    ; SWR 0
    MPRINT loading_bank_text  
    lda #0
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file0)
    ldy #HI(bank_file0)
    jsr disksys_load_file
    MPRINT loading_bank_text2   

    ; SWR 1
    MPRINT loading_bank_text
    lda #1
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file1)	; should be file1
    ldy #HI(bank_file1)
    jsr disksys_load_file
    MPRINT loading_bank_text2   

    ; SWR 2
    MPRINT loading_bank_text
    lda #2
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file2)
    ldy #HI(bank_file2)
    jsr disksys_load_file
    MPRINT loading_bank_text2

    ; SWR 3
    MPRINT loading_bank_text
    lda #3
    jsr swr_select_slot
    lda #&80
    ldx #LO(bank_file3)
    ldy #HI(bank_file3)
    jsr disksys_load_file
    MPRINT loading_bank_text2
ENDIF

	; Let's get going.

	lda #22
	jsr &ffee
	lda #7
	jsr &ffee

	lda #10
	sta &fe00
	lda #32
	sta &fe01	

	ldx #LO(screen_file)
	ldy #HI(screen_file)
	jsr &fff7




IF PLAY_MUSIC
    lda #0
    jsr swr_select_slot

	LDX #LO(SONG_ADDR)
	LDY #HI(SONG_ADDR)
	JSR	vgm_init_stream
	BNE quit

	jsr inittimer1irq
ENDIF


	jsr effect_init

.loop
	lda #19:jsr osbyte

	lda #135
	sta &7c22

	lda exo_swr_bank
	and #&0f
	tax
	lda hex2ascii,x
	sta &7c23

	lda _byte+2
	and #&f0
	lsr a:lsr a:lsr a:lsr a
	tax
	lda hex2ascii,x
	sta &7c24
	lda _byte+2
	and #&0f
	tax
	lda hex2ascii,x
	sta &7c25
	
	lda _byte+1
	and #&f0
	lsr a:lsr a:lsr a:lsr a
	tax
	lda hex2ascii,x
	sta &7c26
	lda _byte+1
	and #&0f
	tax
	lda hex2ascii,x
	sta &7c27


	jsr effect_update

	jmp loop

.quit
	rts
}

.hex2ascii EQUS "0123456789ABCDEF"

.oldirq1v EQUW 0

.inittimer1irq
{
	lda &204
	ldx &205
	sta oldirq1v
	stx oldirq1v+1
	
	sei

	; Continuous interrupts for timer 1.
	lda USR_ACR
	and #&3f
	ora #&40
	sta USR_ACR
	
	; Point at IRQ handler
	lda #LO(irqhandler)
	ldx #HI(irqhandler)
	sta &204
	stx &205
	
	; Enable Usr timer1 interrupt
	lda #&c0
	sta USR_IER
	
	ldx #LO(RHZ)
	lda #HI(RHZ)

	stx USR_T1C_L
	sta USR_T1C_H
	

	; Disable system VIA interrupts
	;lda #$7f
	;sta SYS_IER
	; Enable system timer 1 and CA1 (vsync)
	;lda #$c1
	;sta SYS_IER
	
	cli
	rts
}


.exitirq
{
	pla
	sta &fc
	jmp (oldirq1v)
}

.irqhandler
{
	lda &fc
	pha
	
	lda #&c0
	bit USR_IFR
	; top bit clear - not interrupt from 6522 (user VIA).
	bpl exitirq
	; bit 6 clear - not our interrupt, process next in chain.
	bvc exitirq
	
	; Clear timer1 interrupt flag
	tya
	pha
	txa
	pha

	lda USR_T1C_L
	


	; routine

	lda reentry
	bne skip_poll
	lda #1
	sta reentry
		
	lda exo_swr_bank
	tax
	lda swr_ram_banks,X
	sta &fe30
	sta &f4


	jsr poll_player

	lda #0
	sta reentry

.skip_poll
	
	
	; we handled our interrupt: don't let anyone else see it, they'll be
	; jealous.
	pla
	tax
	pla
	tay
	pla
	sta &fc
	rti
.reentry EQUB 0
}

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



PRECISION = 7
PIXEL_FULL = (2^PRECISION)-1


screen_addr = &80 ; &81
screen_addr2 = &82
current_pixel = &88
speed = &89
tmp1 = &8A
tmp2 = &8B
index = &8C

timer = &8E ; &8F


; Each byte in the array is a 'brightness' value from 0-63 (where 0 is off and 63 is full bright)
.grid_array
	FOR n,0,GRID_SIZE
		EQUB PIXEL_FULL
	NEXT

; 

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

.grid_index_offset
EQUB 0

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

	CLC
	LDA grid_index_offset
	ADC #0
	AND #(VGM_FX_num_freqs - 1)
	STA grid_index_offset

	rts
}



ENDIF



.effect_init
{
	lda #0
	sta current_pixel
	sta timer+0
	sta timer+1

	SET_COLOUR_EFFECT effect_colour_standard
	SET_BLOCK_EFFECT effect_blocks_all_on

	rts
}

.effect_update
{
	inc timer
	lda timer
	cmp #50
	beq newsecond
	jmp carryon
.newsecond
	lda #0
	sta timer
	inc timer+1
	lda timer+1

	; do something at t=X
.fx0	cmp #10:bne fx1

	SET_COLOUR_EFFECT effect_colour_standard
	SET_BLOCK_EFFECT effect_blocks_scaled
	jmp carryon

.fx1	cmp #20:bne fx2

	SET_COLOUR_EFFECT effect_colour_inverted
	SET_BLOCK_EFFECT effect_blocks_scaled
	jmp carryon

.fx2	cmp #30:bne fx3

	SET_COLOUR_EFFECT effect_colour_inverted
	SET_BLOCK_EFFECT effect_blocks_all_on
	jmp carryon

.fx3


.carryon






	lda #10
	jsr grid_fade
	jsr grid_draw

IF 1
	; triggers from frequencies played
	ldx #13
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

	CPY #GRID_SIZE
	BCS done_floop

	inx
	cpx #VGM_FX_num_freqs		; GRID_SIZE causes a memory scribble!
	bne floop

	.done_floop


ENDIF

IF 0
	ldx current_pixel
	lda #PIXEL_FULL
	sta grid_array,x
	inc current_pixel
	lda current_pixel
	cmp #GRID_SIZE
	bne scan_ok
	lda #0
	sta current_pixel
.scan_ok
ENDIF


	rts
}




.end

SAVE "Main", start, end, entry

CLEAR 0, &FFFF
ORG 0

.song_start
INCBIN "data/smstep_392_16k.bin.exo"	; 392Hz / 16Kb exo window

;INCBIN "data/smstep_294_8k.bin.exo"		; 294Hz / 8Kb exo window

.song_end




SAVE "Bank0", song_start+0, song_start+16384, &8000, &8000
SAVE "Bank1", song_start+16384, song_start+32768, &8000, &8000
SAVE "Bank2", song_start+32768, song_start+49152, &8000, &8000
SAVE "Bank3", song_start+49152, song_start+65536, &8000, &8000

PUTFILE "data/page.bin", "Page", &7C00, &7C00

PRINT "Code from ", ~start, "to", ~end