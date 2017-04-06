



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

.swr_fail_text EQUS "No SWR banks found.", 13, 10, 0
.swr_bank_text EQUS "Found %b", LO(swr_ram_banks_count), HI(swr_ram_banks_count), " SWR banks.", 13, 10, 0
.swr_bank_text2 EQUS " Bank %a", 13, 10, 0

.loading_bank_text EQUS "Loading bank... ", 0
.loading_bank_text2 EQUS "OK", 13, 10, 0


SONG_ADDR = &8000


.entry
{
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




	; Let's get going.
    lda #0
    jsr swr_select_slot

	LDX #LO(SONG_ADDR)
	LDY #HI(SONG_ADDR)
	JSR	vgm_init_stream
	BNE quit

	jsr inittimer1irq


.loop
	lda #19:jsr osbyte

	lda _byte+2
	and #&f0
	lsr a:lsr a:lsr a:lsr a
	tax
	lda hex2ascii,x
	sta &7c00
	lda _byte+2
	and #&0f
	tax
	lda hex2ascii,x
	sta &7c01
	
	lda _byte+1
	and #&f0
	lsr a:lsr a:lsr a:lsr a
	tax
	lda hex2ascii,x
	sta &7c02
	lda _byte+1
	and #&0f
	tax
	lda hex2ascii,x
	sta &7c03


	lda exo_swr_bank
	and #&0f
	tax
	lda hex2ascii,x
	sta &7c05

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



PRINT "Code from ", ~start, "to", ~end