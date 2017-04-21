
; Pixel FX

.fx_pixel_start


; fn to set pixel so we can overload at runtime

.fx_pixel_plot				; (A,X) = (x,y)
{
	JMP fx_pixel_set
}

.fx_pixel_set
{
	SET_PIXEL_AX
	RTS
}

.fx_pixel_mirror_X
{
	SET_PIXEL_AX_MIRROR_X
	RTS
}

.fx_pixel_mirror_Y
{
	SET_PIXEL_AX_MIRROR_Y
	RTS
}

.fx_pixel_mirror_four
{
	SET_PIXEL_AX_MIRROR_FOUR
	RTS
}


; Lookup tables

.grid_y_lookup
FOR n,0,GRID_H-1,1
EQUB n * GRID_W
NEXT

.grid_y_lookup_inv
FOR n,0,GRID_H-1,1
EQUB ((GRID_H-1) - n) * GRID_W
NEXT

.fx_pixel_end
