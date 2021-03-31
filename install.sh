#!/bin/bash

#? Description:
#?   Install xsh to your environment.
#?
#? Usage:
#?   install.sh [-f | -u] [-h]
#?
#? Option:
#?   [-f]  Force to uninstall xsh before to install it.
#?
#?   [-u]  Uninstall xsh from your environment.
#?         All the loaded libraries will be removed along with xsh.
#?
#?   [-h]  This help.
#?
#? Example:
#?   $ bash install.sh
#?   $ . ~/.xshrc
#?

# exit on any error
set -e -o pipefail

function usage () {
    awk '/^#\?/ {sub("^[ ]*#\\?[ ]?", ""); print}' "$0" \
        | awk '{gsub(/^[^ ]+.*/, "\033[1m&\033[0m"); print}'
}

function is-compatible () {
    "$@" >/dev/null 2>&1
}

function is-compatible-sed-E () {
    is-compatible sed -E '' /dev/null
}

function is-compatible-sed-r () {
    is-compatible sed -r '' /dev/null
}

function is-compatible-sed-i-bsd () {
    declare tmpfile=/tmp/xsh-sed-compatible-$RANDOM
    declare ret=0

    touch "$tmpfile" \
        && {
        is-compatible sed -i '' '' "$tmpfile"
        ret=$?
        /bin/rm -f "$tmpfile"
    }
    return $ret
}

function is-compatible-sed-i-gnu () {
    declare tmpfile=/tmp/xsh-sed-compatible-$RANDOM
    declare ret=0

    touch "$tmpfile" \
        && {
        is-compatible sed -i '' "$tmpfile"
        ret=$?
        /bin/rm -f "$tmpfile"
    }
    return $ret
}

function sed-regex () {
    if is-compatible-sed-r; then
        sed -r "$@"
    elif is-compatible-sed-E; then
        sed -E "$@"
    else
        return 255
    fi
}

function sed-inplace () {
    if is-compatible-sed-i-bsd; then
        sed -i '' "$@"
    elif is-compatible-sed-i-gnu; then
        sed -i "$@"
    else
        return 255
    fi
}

function sed-regex-inplace () {
    if is-compatible-sed-r && is-compatible-sed-i-bsd; then
        sed -r -i '' "$@"
    elif is-compatible-sed-r && is-compatible-sed-i-gnu; then
        sed -r -i "$@"
    elif is-compatible-sed-E && is-compatible-sed-i-bsd; then
        sed -E -i '' "$@"
    elif is-compatible-sed-E && is-compatible-sed-i-gnu; then
        sed -E -i "$@"
    else
        return 255
    fi
}

function replace-or-append () {
    declare file=${1:?} old=${2:?} new=${3:?} cnt

    if [[ ! -e ${file} ]]; then
        touch "${file}"
    fi

    cnt=$(sed-regex -n "/${old}/=" "${file}" | sed -n '$=')
    if [[ -z ${cnt} ]]; then
        echo "${new}" | tee -a "${file}"
    elif [[ ${cnt} -eq 1 ]]; then
        sed-regex-inplace "s|${old}|${new}|" "${file}"
    elif [[ ${cnt} -gt 1 ]]; then
        printf "ERROR: more than one line matching the old '%s'\n" "${old}" >&2
        return 255
    else
        printf "ERROR: unknown error" >&2
        return 255
    fi
}

function update-profile () {
    replace-or-append "${1:?}" '^\. ~\/.xshrc$' '. ~/.xshrc'
}

function clean-in-profile () {
    sed-regex-inplace -e '/. ~\/.xshrc/d' "${1:?}"
}

function uninstall-xsh () {
    printf "unsetting the xsh environments."
    unset xsh XSH_DEV XSH_DEBUG

    printf "cleaning in: %s\n" ~/.bash_profile
    clean-in-profile ~/.bash_profile

    printf "cleaning in: %s\n" ~/.bashrc
    clean-in-profile ~/.bashrc

    printf "removing: %s\n" ~/.xshrc
    /bin/rm -f ~/.xshrc

    printf "removing xsh home directory: XSH_HOME: %s\n" "${XSH_HOME}"
    /bin/rm -rf "${XSH_HOME}"

}

function install-xsh () {
    printf "creating xsh home directory: XSH_HOME: %s\n" "${XSH_HOME}"
    /bin/mkdir -p "${XSH_HOME}"

    printf "creating xsh dev home directory: XSH_DEV_HOME: %s\n" "${XSH_DEV_HOME}"
    /bin/mkdir -p "${XSH_DEV_HOME}"

    printf "installing xsh repo to: ${XSH_HOME}\n"
    /bin/cp -a "${SCRIPT_DIR}" "${XSH_HOME}/xsh"

    printf "installing: %s\n" ~/.xshrc
    /bin/cp -a "${SCRIPT_DIR}/.xshrc" ~/

    printf "updating: %s\n" ~/.bash_profile
    update-profile ~/.bash_profile

    printf "updating: %s\n" ~/.bashrc
    update-profile ~/.bashrc
}

function main () {
    declare force=0 uninstall=0 \
            OPTIND OPTARG opt

    while getopts fuh opt; do
        case ${opt} in
            f)
                force=1
                ;;
            u)
                uninstall=1
                ;;
            *)
                usage
                exit 255
                ;;
        esac
    done

    if [[ ${force} -eq 1 ]]; then
        uninstall-xsh
    elif [[ ${uninstall} -eq 1 ]]; then
        uninstall-xsh
        printf "DONE.\n"
        printf "##########################################################################\n"
        printf "## * Please execute 'unset xsh XSH_HOME XSH_DEV_HOME' or just close     ##\n"
        printf "##   all your opened terminals to remove xsh in your memory.            ##\n"
        printf "##########################################################################\n"
        exit
    fi

    if [[ -e ${XSH_HOME} ]]; then
        printf "ERROR: xsh home directory already exists: %s\n" "${XSH_HOME}" >&2
        exit 255
    fi

    install-xsh

    printf "applying xsh for current Shell.\n"
    . ~/.xshrc

    printf "updating xsh to the latest stable version.\n"
    xsh upgrade

    printf "DONE.\n"
    printf "##########################################################################\n"
    printf "## * Please execute '. ~/.xshrc' to enable the 'xsh' command.           ##\n"
    printf "##########################################################################\n"
}

declare XSH_HOME=~/.xsh
declare XSH_DEV_HOME=${XSH_HOME}/lib-dev \
        SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

main "$@"

exit
