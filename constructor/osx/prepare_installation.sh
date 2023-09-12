#!/bin/bash
# Copyright (c) 2017 Anaconda, Inc.
# All rights reserved.

# COMMON UTILS
# If you update this block, please propagate changes to the other scripts using it
set -euo pipefail

notify() {
# shellcheck disable=SC2050
if [ "__PROGRESS_NOTIFICATIONS__" = "True" ]; then
osascript <<EOF
display notification "$1" with title "📦 Install __NAME__ __VERSION__"
EOF
fi
logger -p "install.info" "$1" || echo "$1"
}

unset DYLD_LIBRARY_PATH

PREFIX="$2/__PKG_PREFIX__"
PREFIX=$(cd "$PREFIX"; pwd)
export PREFIX
echo "PREFIX=$PREFIX"
CONDA_EXEC="$PREFIX/conda.exe"
# /COMMON UTILS

chmod +x "$CONDA_EXEC"

# We cannot package a Info.plist file, so we package the file as Info_plist
# and rename it here
if [ -f $PREFIX/Info_plist ];
then
    mv $PREFIX/Info_plist $PREFIX/Info.plist
fi

# Create a blank history file so conda thinks this is an existing env
mkdir -p "$PREFIX/conda-meta"
touch "$PREFIX/conda-meta/history"

# Extract the conda packages but avoiding the overwriting of the
# custom metadata we have already put in place
notify "Preparing packages..."
if ! "$CONDA_EXEC" constructor --prefix "$PREFIX" --extract-conda-pkgs; then
    echo "ERROR: could not extract the conda packages"
    exit 1
fi

if [ -n "__MAIN_EXE__" ];
then
    echo "#!/bin/sh
SCRIPT_DIR=\$( cd -- \"\$( dirname -- \"\${BASH_SOURCE[0]}\" )\" &> /dev/null && pwd )
mkdir -p $PREFIX/MacOS
exec \"\$SCRIPT_DIR/../__MAIN_EXE__\"" > $PREFIX/MacOS/$(basename __MAIN_EXE__ )
    chmod +x $PREFIX/MacOS/$( basename __MAIN_EXE__ )
fi

exit 0
