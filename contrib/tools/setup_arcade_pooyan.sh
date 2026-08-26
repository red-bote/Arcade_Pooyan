#!/usr/bin/env bash
# setup_arcade_pooyan.sh — apply patches, stage .xpr/XDC, run prep_roms
# Called from Arcade_Pooyan root: bash contrib/tools/setup_arcade_pooyan.sh
set -euo pipefail

REPODIR="$(cd "$(dirname "$0")/../.." && pwd)"
SRCDIR="${REPODIR}"
CONTRIBDIR="${REPODIR}/contrib"
PATCHDIR="${CONTRIBDIR}/code"

# Sanity-check key files that should exist before any patching
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
  if [ ! -f "${SRCDIR}/${f}" ]; then
    echo "ERROR: Required file not found: ${f}"
    exit 1
  fi
done
echo "  All required files present."

# --- Patch 1: T80 XOR width fix (Vivado operand-length error) ---
T80="${SRCDIR}/rtl_t80_350/T80.vhd"
if grep -q "^-.*ioq := (ioq and x\"7\") xor" "${PATCHDIR}/arcade_pooyan_t80_xor_width.patch" && \
   grep -q "x\"7\"" "${T80}"; then
  echo ">>> Applying T80 XOR width patch..."
  patch -p1 --forward --directory="${SRCDIR}" < "${PATCHDIR}/arcade_pooyan_t80_xor_width.patch"
  echo "  T80 patch applied."
else
  echo ">>> T80 XOR width patch: already applied or not needed, skipping."
fi

# --- Stage .xpr and XDC into basys3/ ---
VIVADODIR="${SRCDIR}/contrib/basys3/vivado"
BASYS3DIR="${SRCDIR}/basys3"

echo ">>> Staging .xpr and XDC into basys3/ ..."
mkdir -p "${BASYS3DIR}"
cp "${VIVADODIR}/arcade_pooyan_basys3.xpr" "${BASYS3DIR}/"
cp "${VIVADODIR}/Basys-3-Master.xdc" "${BASYS3DIR}/"
echo "  .xpr and XDC staged."

# --- Generate BD-via-patch and copy it into basys3/ ---
echo ">>> Generating arcade_pooyan_basys3.vhd via embedded-patch script..."
bash "${CONTRIBDIR}/basys3/tools/make_de10_lite_to_basys3_patch.sh" "${SRCDIR}"
echo "  Wrapper generated."

# --- Copy wrapper into Vivado project directory structure ---
# Vivado resolves $PSRCDIR as $PRJDIR/<project_name>.srcs, so the wrapper
# must be at basys3/arcade_pooyan_basys3.srcs/sources_1/new/
VIVPRJDIR="${BASYS3DIR}/arcade_pooyan_basys3.srcs/sources_1/new"
mkdir -p "${VIVPRJDIR}"
cp "${BASYS3DIR}/arcade_pooyan_basys3.vhd" "${VIVPRJDIR}/"
echo "  Wrapper staged into Vivado project directory."

# --- Compile make_vhdl_prom, convert .bat, extract ROMs, generate PROM VHDL ---
echo ">>> Running prep_roms..."
bash "${CONTRIBDIR}/tools/prep_roms.sh"

echo ">>> Setup complete."
