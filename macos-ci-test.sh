#!/bin/bash

#? Description:
#?   Test xsh project on macOS.
#?   Add this script as a `Shell Script` of PyCharm's `Run/Debug Configurations`.
#?
#? Usage:
#?   macos-ci-test.sh <TESTUSERNAME>
#?
#? Example:
#?   macos-ci-test.sh xshtestuser
#?

# exit on any error
set -e -o pipefail

function usage () {
    awk '/^#\?/ {sub("^[ ]*#\\?[ ]?", ""); print}' "$0" \
        | awk '{gsub(/^[^ ]+.*/, "\033[1m&\033[0m"); print}'
}

function insall-shellspec () {
    if ! type -t ~/.local/bin/shellspec >/dev/null; then
        curl -fsSL https://git.io/shellspec | sh -s -- -y
    fi
}

function insall-kcov () {
    if ! type -t kcov >/dev/null; then
        brew install kcov
    fi
}

function main () {
    declare testuser=$1

    if [[ -z ${testuser} ]]; then
        usage
        return 255
    fi

    # create the sandbox user if not exists yet
    if ! id ${testuser} >/dev/null 2>&1; then
        sudo sysadminctl -addUser "${testuser}" -shell /bin/bash
    fi

    # install shellspec for sandbox user if not exists yet
    declare FUNC=$(declare -f insall-shellspec)
    sudo -H -u "${testuser}" bash -c "${FUNC}; insall-shellspec"

    # install kcov for sandbox user if not exists yet
    declare FUNC=$(declare -f insall-kcov)
    sudo -H -u "${testuser}" bash -c "${FUNC}; insall-kcov"

    # install xsh
    #   -f: Force to uninstall xsh before to install it.
    #   -s: Skip the step to upgrade xsh to the latest stable version.
    sudo -H -u "${testuser}" bash "${SCRIPT_DIR}/install.sh" -f -s

    # run test cases with bash
    sudo -H -u "${testuser}" bash -c '. ~/.xshrc; cd ${XSH_HOME:?}/xsh; ~/.local/bin/shellspec --kcov --covdir ~/coverage -s /bin/bash spec/xsh_spec.sh'
}

declare SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

main "$@"

exit
