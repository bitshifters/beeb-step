; pixel animation fx

.fx_anim_ptr		SKIP 2
.fx_anim_idx		SKIP 1
.fx_anim_x			SKIP 1
.fx_anim_y			SKIP 1
.fx_anim_dx			SKIP 1
.fx_anim_dy			SKIP 1
.fx_anim_num_it 	SKIP 1
.fx_anim_num_px		SKIP 1
.fx_anim_frm_d		SKIP 1
.fx_anim_frm_c		SKIP 1
.fx_anim_num_loops	SKIP 1
.fx_anim_loop_point	SKIP 1

MACRO SET_ANIM_EFFECT fn
{
    LDX #LO(fn):LDY #HI(fn):JSR fx_anim_init
}
ENDMACRO