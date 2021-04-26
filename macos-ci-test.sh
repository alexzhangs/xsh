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

    # install xsh
    #   -f: Force to uninstall xsh before to install it.
    #   -s: Skip the step to upgrade xsh to the latest stable version.
    sudo -H -u "${testuser}" bash "${SCRIPT_DIR}/install.sh" -f -s

    # run test cases with bash
    sudo -H -u "${testuser}" bash -c ". ~/.xshrc && /usr/local/lib/shellspec/shellspec -C \"${SCRIPT_DIR}\" -s /bin/bash --no-warning-as-failure spec/xsh_spec.sh"
}

declare SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

main "$@"

exit
