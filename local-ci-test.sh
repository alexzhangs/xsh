#!/bin/bash

#? Description:
#?   Test xsh project with coverage within a sandbox user.
#?   The shellspec and kcov are installed if they are missing.
#?
#? Usecase:
#?   Add this script as a `Shell Script` of PyCharm's `Run/Debug Configurations`.
#?
#? Usage:
#?   local-ci-test.sh <SANDBOX_USERNAME>
#?
#? Example:
#?   local-ci-test.sh xshtestuser
#?

# exit on any error
set -e -o pipefail

function usage () {
    awk '/^#\?/ {sub("^[ ]*#\\?[ ]?", ""); print}' "$0" \
        | awk '{gsub(/^[^ ]+.*/, "\033[1m&\033[0m"); print}'
}

function ci-addons () {

    function insall-kcov-dependency () {
        if type -t brew >/dev/null; then
            return
        elif type -t apt-get >/dev/null; then
            apt-get -yq --no-install-suggests --no-install-recommends install binutils-dev libcurl4-openssl-dev libdw-dev libiberty-dev
        elif type -t yum >/dev/null; then
            yum install -y cmake gcc-c++ openssl-devel elfutils-libelf-devel libcurl-devel binutils-devel elfutils-devel
        else
            return 255
        fi
    }

    insall-kcov-dependency
}

function ci-add-user () {
    if id "${LOCAL_CI_USER}" >/dev/null 2>&1; then
        return
    fi

    if type -t useradd >/dev/null; then
        # linux
        useradd -m -s /bin/bash "${LOCAL_CI_USER}"
    elif type -t sysadminctl >/dev/null; then
        # macos
        sysadminctl -addUser "${LOCAL_CI_USER}" -shell /bin/bash
    else
        return 255
    fi
}

function ci-get-code () {
    cp -a . "${LOCAL_CI_REPO_SLUG}"
    chown -R "${LOCAL_CI_USER}" "${LOCAL_CI_REPO_SLUG}"
}

function ci-before-install () {

    function insall-shellspec () {
        if type -t ~/.local/bin/shellspec >/dev/null; then
            return
        fi
        curl -fsSL https://git.io/shellspec | sh -s -- -y
    }

    function insall-kcov () {
        if type -t kcov >/dev/null; then
            return
        fi

        if type -t brew >/dev/null; then
            brew install kcov
        else
            wget https://github.com/SimonKagstrom/kcov/archive/master.tar.gz
            tar xzf master.tar.gz
            (cd kcov-master && (mkdir -p build && cd build && (cmake -DCMAKE_INSTALL_PREFIX="${HOME}"/kcov .. && make && make install)))
            rm -rf kcov-master
        fi
    }

    insall-shellspec
    insall-kcov
}

function ci-install () {
    # install xsh
    #   -f: Force to uninstall xsh before to install it.
    #   -s: Skip the step to upgrade xsh to the latest stable version.
    bash install.sh -f -s
}

function ci-after-install () {
    :
}

function ci-script () {
    # shellcheck source=/dev/null
    . ~/.xshrc
    ~/.local/bin/shellspec --kcov --covdir "${HOME:?}" -s /bin/bash spec/xsh_spec.sh spec/installer_spec.sh
}

function call () {
    declare funcname=${1:?} \
            user=${2:-$(whoami)} \
            funccode

    funccode=$(declare -f "${funcname}")
    declare repo_dir work_dir
    repo_dir=~${SANDBOX_USER:?}/$(basename "${SCRIPT_DIR:?}")

    if [[ ${user} == "${SANDBOX_USER:?}" ]]; then
        work_dir=${repo_dir}
    else
        work_dir=${SCRIPT_DIR:?}
    fi

    declare code
    IFS='' read -r -d '' code << EOF || :
LOCAL_CI=true
LOCAL_CI_USER=${SANDBOX_USER}
LOCAL_CI_REPO_SLUG=${repo_dir}
cd ${work_dir}
${funccode}
${funcname}
EOF

    sudo -H -u "${user}" bash -e -c "${code}"
}

function main () {
    declare funcname
    for funcname in "${STEPS[@]}"; do
        call "${funcname}"
    done

    for funcname in "${ROOT_STEPS[@]}"; do
        call "${funcname}" root
    done

    for funcname in "${SANDBOX_STEPS[@]}"; do
        call "${funcname}" "${SANDBOX_USER}"
    done
}

declare SANDBOX_USER=$1
if [[ -z ${SANDBOX_USER} ]]; then
    usage
    exit 255
fi

declare SCRIPT_DIR
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

declare -a STEPS=() \
        ROOT_STEPS=(ci-addons ci-add-user ci-get-code) \
        SANDBOX_STEPS=(ci-before-install ci-install ci-after-install ci-script)

main

exit
