# beeb-step: start here

Beeb-Step, a BBC Micro dubstep audio demo (6502, beebasm) playing the "Hundo-Hz" VGM tune authored at 392 Hz, with MODE 7 effects. Bitshifters demo, released 2019-01-12.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/beeb-step (public) |
| Local path | D:\bitshifters\beeb-step (moved from OneDrive\BEEB\Repos\beeb-step in the 2026-11 tidy) |
| Branch | disksys-osfile (checked out, 1 commit past master: "Removed DFS dependency in disksys", 2019-01-13); others: master (release), feature-kc-messing, feature-logowibble, feature-streaming, fx-letters and fx-scrolly (both deleted on GitHub, "gone") |
| Last commit | 2019-01-13: Removed DFS dependency in disksys |

## What's in here
- `beebstep.asm`: main source; `lib\`: VGM player, Exomiser, disc system (`disksys.asm`), sideways RAM, helpers; `fx\`: the effects (scrolly, letter, grid, pixel, spin, frequency); `data\`: the VGM (`BotB 24092 TMM12 - SMStep.vgm`), its Exomiser-packed 294/392 Hz versions and `page.bin`.
- `beebstep.ssd`: the built disc (tracked). `beeb-step.txt`: release text (gitignored).
- `makekc.bat` / `runkc.bat`: build and run scripts (both gitignored, so only on this machine). `bin\`: tools.

## Build and run
- `make`: runs the same beebasm command as `makekc.bat` (Makefile added 2026-11-22; it repeats the command because the bat is not in git): `..\Bin\beebasm.exe -v -i beebstep.asm -do beebstep.ssd -boot Main > compile.txt`. Works; the rebuilt `beebstep.ssd` came out identical to the tracked one.
- `make help` lists targets. `runkc.bat` launches `..\..\bin\B-em\B-em.exe beebstep.ssd`.

## Local changes
- Working tree clean apart from the new Makefile and this file. No snapshot branches.

## Status and next steps
- Released. The checked-out `disksys-osfile` change (OSFILE instead of DFS calls) was never merged to master. Other feature branches are 2017 experiments.

## See also
- README.md (edit.tf page links).
