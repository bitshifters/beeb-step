# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# Same command as makekc.bat (which is gitignored, so it is repeated here).
.PHONY: all build help
all: build

build:
	..\Bin\beebasm.exe -v -i beebstep.asm -do beebstep.ssd -boot Main > compile.txt

help:
	@echo make        - assemble beebstep.asm into beebstep.ssd with beebasm (listing in compile.txt)
	@echo make help   - this list
	@echo runkc.bat launches B-em on beebstep.ssd
