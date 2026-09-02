#!/usr/bin/env bash
# setup_arcade_pooyan.sh — sanity-check upstream, run prep_roms
# Called from Arcade_Pooyan root: bash contrib/tools/setup_arcade_pooyan.sh
#
# The upstream T80.vhd already contains the XOR-width fix (line 738:
# `"000000111"` with the broken `x"7"` line commented out).  The patch
# file is kept for reference but is not applied during setup.
set -euo pipefail

REPODIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Sanity-check key files that should exist before any build step
echo ">>> Checking required source files..."
for f in \
  rtl_t80_350/T80.vhd \
  rtl_dar/pooyan.vhd \
  rtl_dar/pooyan_de10_lite.vhd \
  rtl_dar/pooyan_sound_board.vhd \
  deca/vga_scandoubler.v \
  tools/tools_prom_src/src/make_vhdl_prom.c \
  tools/pooyan_unzip/make_pooyan_proms.bat \
; do
  if [ ! -f "${REPODIR}/${f}" ]; then
    echo "ERROR: Required file not found: ${f}"
    exit 1
  fi
done
echo "  All required files present."

# --- T80 XOR width fix: upstream already has the fix ---
T80="${REPODIR}/rtl_t80_350/T80.vhd"
if grep -q '000000111' "${T80}"; then
  echo ">>> T80 XOR width fix: upstream already contains the fix, skipping."
else
  echo ">>> T80 XOR width fix: applying patch..."
  patch -p1 --forward --directory="${REPODIR}" < "${REPODIR}/contrib/code/arcade_pooyan_t80_xor_width.patch"
  echo "  T80 patch applied."
fi

# --- Compile make_vhdl_prom, convert .bat, extract ROMs, generate PROM VHDL ---
echo ">>> Running prep_roms..."
bash "${REPODIR}/contrib/tools/prep_roms.sh"

echo ">>> Setup complete."
