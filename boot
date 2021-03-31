#!/bin/bash

#? Description:
#?   Bootstrap script for xsh.
#?
#? Usage:
#?   curl -s https://raw.githubusercontent.com/alexzhangs/xsh/master/boot | bash && . ~/.xshrc
#?

# exit on any error
set -e -o pipefail

declare repo='https://github.com/alexzhangs/xsh'
declare cmds=(bash install.sh -f)
declare clonedir=/tmp/xsh-$RANDOM

git clone --depth=1 "$repo" "$clonedir"
cd "$clonedir"
exec "${cmds[@]}"

rm -rf "$clonedir"

exit
