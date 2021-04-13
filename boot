#!/bin/bash

#? Description:
#?   Bootstrap script for xsh.
#?
#? Usage:
#?   boot [OPTION]
#?
#? Option:
#?   [-f]
#?   Force to uninstall xsh before to install it.
#?   This is default option.
#?
#?   [-s]
#?   Skip the step to upgrade xsh to the latest stable version.
#?   This lets the installation reflect the exact status of the installing files.
#?   Use this option to test the project.
#?
#?   [-b BRANCH]
#?   Upgrade xsh to the BRANCH's latest state.
#?   This option is ignored if `-s` presents.
#?   Use this option to test the project on a specific branch.
#?
#?   [-u]
#?   Uninstall xsh from your environment.
#?   All the loaded libraries will be removed along with xsh.
#?
#?   [-h]
#?   This help.
#?
#? Example:
#?   curl -s https://raw.githubusercontent.com/alexzhangs/xsh/master/boot | bash && . ~/.xshrc
#?

# exit on any error
set -e -o pipefail

declare repo='https://github.com/alexzhangs/xsh'
declare cmds=(bash install.sh -f "$@")
declare clonedir=/tmp/xsh-$RANDOM

git clone --depth=1 "$repo" "$clonedir"
cd "$clonedir"
exec "${cmds[@]}"

rm -rf "$clonedir"

exit
