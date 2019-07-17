#!/bin/bash

set -e

XSH_HOME=~/.xsh
SCRIPT_DIR=$(dirname "$0")

function is_mac () {
    uname | grep -iq 'darwin'
}

function sed_regx () {
    if is_mac; then
        sed -E "$@"
    else
        sed -r "$@"
    fi
}

function sed_inplace () {
    if is_mac; then
       sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

function sed_regx_inplace () {
    if is_mac; then
        sed -E -i '' "$@"
    else
        sed -r -i "$@"
    fi
}

function replace_or_append () {
    local file=${1:?}
    local old=${2:?}
    local new=${3:?}
    local cnt

    if [[ ! -e ${file} ]]; then
        touch "${file}"
    fi

    cnt=$(sed_regx -n "/${old}/=" "${file}" | sed -n '$=')
    if [[ -z ${cnt} ]]; then
        echo "${new}" >> "${file}"
    elif [[ ${cnt} -eq 1 ]]; then
        sed_regx_inplace "s|${old}|${new}|" "${file}"
    elif [[ ${cnt} -gt 1 ]]; then
        printf "ERROR: more than one line matching the old '%s'\n" "${old}" >&2
        return 255
    else
        printf "ERROR: unknown error" >&2
        return 255
    fi
}

if [[ -e ~/${XSH_HOME} ]]; then
    printf "WARN: xsh home directory %s already exists\n" "${XSH_HOME}" >&2
else
    printf "creating xsh home directory %s\n" "${XSH_HOME}"
    /bin/mkdir -p "${XSH_HOME}"
fi

printf "installing: ${XSH_HOME}/xsh.sh\n"
/bin/cp -a "${SCRIPT_DIR}/xsh.sh" "${XSH_HOME}"

printf "updating: %s\n" ~/.bashrc
replace_or_append ~/.bashrc '^export XSH_HOME=.*$' "export XSH_HOME=${XSH_HOME}"
replace_or_append ~/.bashrc '^\. \$\{XSH_HOME\}\/xsh\.sh$' '. ${XSH_HOME}/xsh.sh'

printf "DONE.\n"

printf "##################################################\n"
printf "## please run 'exec bash' to apply ~/.bashrc    ##\n"
printf "##################################################\n"

exit
