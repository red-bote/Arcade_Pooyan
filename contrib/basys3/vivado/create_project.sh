#!/bin/bash
# create_project.sh — Create the initial Vivado Basys3 project directories
# and copy the tracked port assets into place.
#
# Layout: .xpr lives directly in basys3/ and the project
# sources tree is basys3/arcade_pooyan_basys3.srcs/.
#
# Vivado resolves $PSRCDIR as $PRJDIR/<project_name>.srcs, so files must
# be placed in the .srcs/ directory tree, not flat in basys3/.
#
# This is called by make create_prj (via Makefile).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CONTRIB="$ROOT/contrib/basys3"

PROJ_DIR="$ROOT/basys3"
CONSTRS_IMPORT="$PROJ_DIR/arcade_pooyan_basys3.srcs/constrs_1/imports/digilent-xdc-master"

if [ ! -f "$ROOT/rtl_dar/pooyan.vhd" ]; then
    echo "error: upstream tree not found under: $ROOT" >&2
    exit 1
fi

step() { printf '\n==> %s\n' "$1"; }

step "1/3 Creating project directories"
mkdir -p "$PROJ_DIR" "$CONSTRS_IMPORT"

step "2/3 Copying arcade_pooyan_basys3.xpr"
cp -f "$CONTRIB/vivado/arcade_pooyan_basys3.xpr" "$PROJ_DIR/arcade_pooyan_basys3.xpr"

step "3/3 Copying Basys-3-Master.xdc"
cp -f "$CONTRIB/vivado/Basys-3-Master.xdc" "$CONSTRS_IMPORT/Basys-3-Master.xdc"

echo
echo "Project files in place:"
ls -l "$PROJ_DIR/arcade_pooyan_basys3.xpr"
ls -l "$CONSTRS_IMPORT/Basys-3-Master.xdc"
