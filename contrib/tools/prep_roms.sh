#!/bin/bash
# Linux rom-prep for the Arcade_Pooyan Basys3 port.
#
# 1. Compile make_vhdl_prom from the in-repo Dar source tree on the host (gcc).
# 2. Convert make_pooyan_proms.bat -> make_pooyan_proms.sh (strip CRLF, translate
#    Windows commands to POSIX equivalents).
# 3. Unzip the romset (~/roms/pooyan.zip) into tools/pooyan_unzip/.
# 4. Run make_pooyan_proms.sh to generate the PROM VHDL, referenced in place
#    by arcade_pooyan_basys3.xpr ($PPRDIR/../tools/pooyan_unzip/*.vhd).
#
# Roms and the generated PROM VHDL are copyrighted MAME-derived content:
# never commit or distribute them.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROM_DIR="$ROOT/tools/pooyan_unzip"
TOOLS_SRC="$ROOT/tools/tools_prom_src/src"

ROMZIP="${ROMZIP:-$HOME/roms/pooyan.zip}"

step() { printf '\n==> %s\n' "$1"; }

if [ ! -f "$TOOLS_SRC/make_vhdl_prom.c" ]; then
    echo "error: prom tool sources not found: $TOOLS_SRC" >&2
    exit 1
fi

mkdir -p "$PROM_DIR"

step "1/4 Compiling make_vhdl_prom on the host"
gcc "$TOOLS_SRC/make_vhdl_prom.c" -lm -o "$PROM_DIR/make_vhdl_prom"

step "2/4 Converting make_pooyan_proms.bat to .sh"
if [ ! -f "$PROM_DIR/make_pooyan_proms.bat" ]; then
    echo "error: $PROM_DIR/make_pooyan_proms.bat not found" >&2
    exit 1
fi

sed -E \
    -e 's/\r$//' \
    -e 's/^copy \/B (.*) ([^ ]+)$/cat \1 > \2/' \
    -e 's/ \+ / /g' \
    -e 's/^make_vhdl_prom /.\/make_vhdl_prom /' \
    -e 's/^del /rm /' \
    "$PROM_DIR/make_pooyan_proms.bat" > "$PROM_DIR/make_pooyan_proms.sh"
chmod +x "$PROM_DIR/make_pooyan_proms.sh"

step "3/4 Unzipping romset"
if [ ! -f "$ROMZIP" ]; then
    echo "error: ROM zip not found: $ROMZIP" >&2
    echo "Set ROMZIP env var or place pooyan.zip in ~/roms/." >&2
    exit 1
fi
unzip -o "$ROMZIP" -d "$PROM_DIR"

step "4/4 Generating PROM VHDL"
( cd "$PROM_DIR" && ./make_pooyan_proms.sh )

echo
echo "Rom-prep complete. PROM VHDL generated in:"
ls -1 "$PROM_DIR"/*.vhd
