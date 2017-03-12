



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
SAMP_HZ = 350 ; 350 ;6250
RHZ = T1_HZ / SAMP_HZ



ORG &1100
GUARD &7C00

.start

INCLUDE "lib/exomiser.asm"
INCLUDE "lib/vgmplayer.asm"

	
.entry
{
	LDX #LO(song_start)
	LDY #HI(song_start)
	JSR	vgm_init_stream
	BNE quit

	jsr inittimer1irq


.loop
	lda #19:jsr osbyte
	lda #65:jsr oswrch
	jmp loop

.quit
	rts
}


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
	jsr poll_player

	
	
	; we handled our interrupt: don't let anyone else see it, they'll be
	; jealous.
	pla
	tax
	pla
	tay
	pla
	sta &fc
	rti

}


.song_start
INCBIN "data/test.bin.exo"
;INCBIN "data/exception.raw.exo"
.song_end


.end

SAVE "Main", start, end, entry

PRINT "Code from ", ~start, "to", ~end