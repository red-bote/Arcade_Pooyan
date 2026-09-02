# Arcade_Pooyan — Basys 3 Port

FPGA port of Konami's Pooyan (1982) to the Digilent Basys 3 board, based on
Dar's [Arcade_Pooyan](https://github.com/darfpga/Arcade_Pooyan) DE10-Lite design.

## Hardware Requirements

- Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`)
- PS/2 keyboard on JB Pmod (JB1 = data, JB3 = clock)
- Joystick on JA Pmod (active-low: JA1=right, JA2=left, JA3=down, JA4=up, JA7=fire)
- Audio via PmodAMP2 on JC Pmod (JC1=AIN, JC2=GAIN on sw15, JC4=SHUTDOWN on sw14)
- VGA monitor on the Basys 3 VGA connector
- ROMs: `pooyan.zip` from MAME, placed in `~/roms/`

## Quick Start

```bash
# Set ROM path (default: ~/roms/pooyan.zip)
export ROMZIP=~/roms/pooyan.zip

# Full build from clean upstream
make setup       # sanity-check upstream + run prep_roms
make clk_wiz     # generate MMCM IP (or open in Vivado GUI)
make synth       # synthesis (runs from /tmp)
make bitstream   # implementation + write_bitstream

# Or all at once (skips bitstream):
make all
```

## Dip Switches

| Switch | Function |
|--------|----------|
| sw(0-1) | Lives (binary) |
| sw(2) | Cocktail mode |
| sw(3) | Bonus |
| sw(4-6) | Difficulty (binary) |
| sw(7) | Sound |
| sw(8-12) | Coinage A (binary) |
| sw(13-15) | Coinage B (fixed default) |

Default (all down): Lives=3, Cocktail=Upright, Bonus=50K/80K+, Difficulty=Easy, Demo Sounds=ON.
Coinage: 1 coin / 1 credit. All-down = factory defaults.

## Controls

**Keyboard (PS/2 on JB):**
- F4 = Start 1 player
- F5 = Start 2 players
- F3 = Add coin
- SPACE = Fire
- Arrow keys = Move
- F8 = Toggle display mode (31 kHz VGA / 15 kHz TV)

**Joystick (JA Pmod):**
- Direction + Fire
- Fire+Left = Start 1 player
- Fire+Right = Start 2 players
- Fire+Up = Add coin

## Debug

- LEDs show dip switch state
- 7-segment display shows low nibble of debug CPU address

## Patches

All modifications to upstream Dar sources are captured as patches:

1. **T80 XOR width fix** — upstream `rtl_t80_350/T80.vhd` already contains the
   Vivado operand-width fix (line 738); `make setup` detects it and skips.
2. **Basys3 top-level wrapper** — DE10-Lite wrapper adapted for Basys3
   pins/clocks/scandoubler, authored directly into `sources_1/new/` by
   `make_de10_lite_to_basys3_wrapper.sh` during `make create_prj`.

See [PORTING_SPEC.md](PORTING_SPEC.md) for full details.
