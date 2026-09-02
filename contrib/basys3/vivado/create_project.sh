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
# 1. Create project dirs.
# 2. Copy .xpr.
# 3. Copy XDC into constrs_1/imports/.
# 4. Author the Basys3 top-level wrapper directly into sources_1/new/
#    via make_de10_lite_to_basys3_wrapper.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CONTRIB="$ROOT/contrib/basys3"

PROJ_DIR="$ROOT/basys3"
CONSTRS_IMPORT="$PROJ_DIR/arcade_pooyan_basys3.srcs/constrs_1/imports/digilent-xdc-master"
WRAPPER_IMPORT="$PROJ_DIR/arcade_pooyan_basys3.srcs/sources_1/new"

if [ ! -f "$ROOT/rtl_dar/pooyan.vhd" ]; then
    echo "error: upstream tree not found under: $ROOT" >&2
    exit 1
fi

step() { printf '\n==> %s\n' "$1"; }

step "1/4 Creating project directories"
mkdir -p "$PROJ_DIR" "$CONSTRS_IMPORT" "$WRAPPER_IMPORT"

step "2/4 Copying arcade_pooyan_basys3.xpr"
cp -f "$CONTRIB/vivado/arcade_pooyan_basys3.xpr" "$PROJ_DIR/arcade_pooyan_basys3.xpr"

step "3/4 Copying Basys-3-Master.xdc"
cp -f "$CONTRIB/vivado/Basys-3-Master.xdc" "$CONSTRS_IMPORT/Basys-3-Master.xdc"

step "4/4 Authoring Basys3 wrapper"
bash "$CONTRIB/tools/make_de10_lite_to_basys3_wrapper.sh" "$ROOT"

echo
echo "Project files in place:"
ls -l "$PROJ_DIR/arcade_pooyan_basys3.xpr"
ls -l "$CONSTRS_IMPORT/Basys-3-Master.xdc"
ls -l "$WRAPPER_IMPORT/arcade_pooyan_basys3.vhd"
