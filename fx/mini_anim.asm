; mini animation fx for grid

.fx_anim_start

.fx_anim_init
{
	STX fx_anim_ptr
	STY fx_anim_ptr+1

	LDY #0
	STY fx_anim_num_loops

	LDA (fx_anim_ptr), Y
	STA fx_anim_x
	INY

	LDA (fx_anim_ptr), Y
	STA fx_anim_y
	INY
	
	STY fx_anim_idx
	JSR fx_anim_init_step

	RTS
}

.fx_anim_init_loop
{
	\\ Next byte is number of loops
	INY

	LDA (fx_anim_ptr), Y
	BNE init_next_step

	\\ Hit end of loop

	\\ Done all loops?
	SEC
	LDA fx_anim_num_loops
	SBC #1
	BEQ init_next_step

	\\ If not reset our index
	LDY fx_anim_loop_point

	.init_next_step
	STA fx_anim_num_loops
	STY fx_anim_loop_point

	INY
	STY fx_anim_idx
}
\\ DROP THROUGH TO INITIALISE FIRST STEP OF LOOP!

.fx_anim_init_step
{
	LDY fx_anim_idx

	LDA (fx_anim_ptr), Y
	BEQ return					; end of sequence

	CMP #&FF					; special iteration = loop
	BEQ fx_anim_init_loop

	STA fx_anim_num_it			; number of times to iterate
	INY

	LDA (fx_anim_ptr), Y
	STA fx_anim_dx
	INY

	LDA (fx_anim_ptr), Y
	STA fx_anim_dy
	INY

	LDA (fx_anim_ptr), Y
	LSR A: LSR A: LSR A: LSR A
	STA fx_anim_num_px

	LDA (fx_anim_ptr), Y
	AND #&F
	STA fx_anim_frm_d
	INY

	STA fx_anim_frm_c

	STY fx_anim_idx
	.return
	RTS
}

.fx_anim_get_next_step
{
	JSR fx_anim_init_step
	BNE continue_seq

	\\ Currently just resets on end of sequence

	LDX fx_anim_ptr
	LDY fx_anim_ptr+1
	JMP fx_anim_init

	.continue_seq
	RTS
}

.fx_anim_update
{
	LDY fx_anim_frm_c
	BNE wait_count

	.do_anim

	\\ Do the anim
	LDY fx_anim_num_px			; this many pixels
	LDA fx_anim_x
	LDX fx_anim_y

	.loop

	\\ Draw pixel
	JSR grid_set_pixel

	CLC
	LDA fx_anim_y
	ADC fx_anim_dy
	STA fx_anim_y
	TAX

	CLC
	LDA fx_anim_x
	ADC fx_anim_dx
	STA fx_anim_x

	DEY
	BNE loop

	\\ Done an iteration
	DEC fx_anim_num_it

	\\ How many iterations left?
	BNE next_it

	\\ Done all iterations

	JMP fx_anim_get_next_step

	.next_it

	\\ Countdown timer

	LDY fx_anim_frm_d
	.wait_count
	DEY
	STY fx_anim_frm_c

	.return
	RTS
}

\\ anim data something like:
\\ start x,y
\\ what to do at end?  finish, loop, reverse?
\\ num iterations of step - 0=end of stream, could use flags for end if reach X/Y bounds?
\\ pixel delta x, delta y -- can be negative
\\ pixels per frame - or make this globally configured (need bounds checking?)
\\ frame delay - pack 4:4 with pixels per frame (or could be globally configured?)

\\ other ideas:
\\ could have loops in the sequence to do a series of steps
\\ could make a step terminate when reaching boundary of the grid rather than counting
\\ could start sequences from current x,y

\\ still need to figure out start / end vs iterations & delays
\\ shouldn't draw on init - only draw in update
\\ delay first then draw current pixel then update position

MACRO ANIM_START x, y
	EQUB x, y
ENDMACRO

MACRO ANIM_STEP iterations, delta_x, delta_y, pixels, delay
	EQUB iterations, delta_x, delta_y, (pixels * 16 + delay)
ENDMACRO

MACRO ANIM_STEP_1 iterations, delta_x, delta_y
	EQUB iterations, delta_x, delta_y, 17			; 1 + 1
ENDMACRO

MACRO ANIM_LOOP loops
	EQUB &FF, loops
ENDMACRO

MACRO ANIM_LOOP_END
	EQUB &FF, 0
ENDMACRO

MACRO ANIM_END
	EQUB 0
ENDMACRO

.anim_data_snake_v
{
	ANIM_START 0, 0
	{
		ANIM_LOOP 6
		{
			ANIM_STEP 6, 0, 1, 1, 1
			ANIM_STEP 1, 1, 0, 1, 1
			ANIM_STEP 6, 0, -1, 1, 1
			ANIM_STEP 1, 1, 0, 1, 1
		}
		ANIM_LOOP_END
		ANIM_STEP 7, 0, 1, 1, 1
	}
	ANIM_END
}

.anim_data_snake_h
{
	ANIM_START 0, 0
	{
		ANIM_LOOP 3
		{
			ANIM_STEP 12, 1, 0, 1, 1
			ANIM_STEP 1, 0, 1, 1, 1
			ANIM_STEP 12, -1, 0, 1, 1
			ANIM_STEP 1, 0, 1, 1, 1
		}
		ANIM_LOOP_END
		ANIM_STEP 13, 1, 0, 1, 1
	}
	ANIM_END
}

.anim_data_spiral
{
	ANIM_START 0, 0
	{
		ANIM_STEP_1 12, 1, 0
		ANIM_STEP_1 6, 0, 1
		ANIM_STEP_1 12, -1, 0
		ANIM_STEP_1 5, 0, -1
		ANIM_STEP_1 11, 1, 0
		ANIM_STEP_1 4, 0, 1
		ANIM_STEP_1 10, -1, 0
		ANIM_STEP_1 3, 0, -1
		ANIM_STEP_1 9, 1, 0
		ANIM_STEP_1 2, 0, 1
		ANIM_STEP_1 8, -1, 0
		ANIM_STEP_1 1, 0, -1
		ANIM_STEP_1 8, 1, 0
	}
	ANIM_END
}

.anim_data_scan
{
	ANIM_START 0, 0
	{
		ANIM_LOOP 6
		{
			ANIM_STEP_1 12, 1, 0
			ANIM_STEP_1 1, -12, 1
		}
		ANIM_LOOP_END
		ANIM_STEP_1 13, 1, 0
	}
	ANIM_END
}

.anim_data_lines_x
{
	ANIM_START 0, 0
	{
		ANIM_LOOP 6
		{
			ANIM_STEP 1, 1, 0, 13, 1
			ANIM_STEP_1 1, -13, 1
		}
		ANIM_LOOP_END
		ANIM_STEP 1, 1, 0, 13, 1
	}
	ANIM_END
}

.anim_data_lines_y
{
	ANIM_START 0, 0
	{
		ANIM_LOOP 12
		{
			ANIM_STEP 1, 0, 1, 7, 1
			ANIM_STEP 1, 1, -7, 1, 1
		}
		ANIM_LOOP_END
		ANIM_STEP 1, 0, 1, 7, 1
	}
	ANIM_END
}

.fx_anim_end
