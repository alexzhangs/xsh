function xsh () {
    local xsh_home name
    local ret=0

    # check environment variable
    if [[ -n ${XSH_HOME%/} ]]; then
        # remove tailing '/'
        xsh_home=${XSH_HOME%/}
    else
        printf "ERROR: XSH_HOME is not set properly: '%s'.\n" "${XSH_HOME}" >&2
        return 255
    fi

    # @private
    function __xsh_usage () {
        printf "Usage:\n"
        printf "  xsh [LIB][/PACKAGE]/UTIL [UTIL_OPTIONS]\n"
        printf "  xsh import [LIB][/PACKAGE]/UTIL ...\n"
        printf "  xsh load [LIB][/PACKAGE][/UTIL] ...\n"
        printf "  xsh list\n"
        printf "  xsh install -r GIT_REPO_URL [-b BRANCH] [-a ALIAS] LIB\n"
        printf "  xsh uninstal LIB\n"
        printf "  xsh help|-h|--help\n\n"

        printf "Options:\n"
        printf "  [LIB][/PACKAGE]/UTIL      Utility to call.\n"
        printf "    UTIL_OPTIONS            Will be passed to utility.\n"
        printf "                            Default LIB is 'core', point to library xsh-lib-core.\n"
        printf "  import                    Call utilities in a batch. No options can be passed.\n"
        printf "    [LIB][/PACKAGE]/UTIL    Utility to call.\n"
        printf "  load                      Load utilities so can be called as syntax: 'LIB-PACKAGE-UTIL'\n"
        printf "    [LIB][/PACKAGE][/UTIL]  Utilities to load or import.\n"
        printf "                            Default LIB is 'core', point to library xsh-lib-core.\n"
        printf "                            A single quoted asterist '*' presents all utils in all libraries.\n"
        printf "  list                      List installed libraries, packages and utilities.\n"
        printf "  install                   Install library from Git repo.\n"
        printf "    -r GIT_REPO_URL         Git repo URL.\n"
        printf "    [-b BRANCH]             Branch to use, default is repo's default branch.\n"
        printf "    [-a ALIAS]              Alias of library name.\n"
        printf "    LIB                     Library name, must be unique in all installed libraries.\n"
        printf "                            Default used to prefix utility name: LIB-PACKAGE-UTIL\n"
        printf "  uninstall                 Uninstall library.\n"
        printf "    LIB                     Library name.\n"
        printf "  help|-h|--help            This help.\n"
    }

    # @private
    function __xsh_list () {
        find "${xsh_home}/lib" -type f -name "*.sh" \
            | sed -e "s|^${xsh_home}/lib/||" \
                  -e 's|.sh$||' \
            | sort \
            | awk -F/ '{
                  lib=$1;
                  type=$2;
                  if (lib != last_lib) {
                     printf "Library: [%s]\n", lib;
                     last_type=""
                  };
                  last_lib=lib;
                  if (type != last_type) {
                     printf "  %s:\n", type;
                  };
                  last_type=type;
                  printf "    %s/%s\n", $3, $4;
                  }'
    }

    # @private
    function __xsh_install () {
        local repo branch name
        local OPTARG OPTIND

        while getopts r:b: opt; do
            case $opt in
                r)
                    repo=$OPTARG
                    ;;
                b)
                    branch=$OPTARG
                    ;;
                *)
                    usage >&2
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        name=${1:?}

        branch=${branch:-master}  # set default

        if [[ -e ${xsh_home}/lib/${name} ]]; then
            printf "ERROR: library '%s' already exists.\n" "${name}"
            return 255
        else
            git clone -b "${branch:?}" "${repo:?}" "${xsh_home}/lib/${name}"
        fi
    }

    # @private
    function __xsh_uninstall () {
        local name=${1:?}

        if [[ -e ${xsh_home}/lib/${name} ]]; then
            /bin/rm -rf "${xsh_home}/lib/${name}"
        else
            printf "ERROR: library '%s' doesn't exist.\n" "${name}"
            return 255
        fi
    }

    # @private
    # Source functions by relative file path and
    #   file name(without extension).
    # Link scripts by relative file path and
    #   file name(without extension).
    function __xsh_load () {
        # legal input:
        #   '*'
        #   /, core
        #   core/pkg, /pkg
        #   core/pkg/util, /pkg/util
        #   core/util, /util
        local path=${1:?}
        local lib lib_home rest ln type

        lib=${path%%/*}  # remove anything after first / (include the /)
        lib=${lib:-core}  # set default

        lib_home="${xsh_home}/lib"

        rest=${path#"${lib}"}  # remove lib part, double quote is needed for '*'
        rest=${rest#/}  # remove leading /
        rest=${rest%/}  # remove tailing /
        rest=${rest:-'*'}  # set default

        while read ln; do
            type=${ln#${lib_home}/${lib}/}  # strip path from begin
            type=${type%%/*}  # strip path from end

            case ${type} in
                functions)
                    __xsh_load_function "$ln"
                    ;;
                scripts)
                    __xsh_load_script "$ln"
                    ;;
                *)
                    return 255
                    ;;
            esac
        done <<< "$(
             find "${lib_home}" \
                  -path "${lib_home}/${lib}/functions/${rest}.sh" \
                  -o \
                  -path "${lib_home}/${lib}/functions/${rest}/*" \
                  -name "*.sh" \
                  -o \
                  -path "${lib_home}/${lib}/scripts/${rest}.sh" \
                  -o \
                  -path "${lib_home}/${lib}/scripts/${rest}/*" \
                  -name "*.sh" \
                  2>/dev/null
                  )"
    }

    # @private
    # Source a file simply
    function __xsh_load_function () {
        if [[ -n $1 ]]; then
            source "$1"
        else
            :
        fi
    }

    # @private
    # Link a file "scripts/<domain>/<foo>.sh"
    #   as "/usr/local/bin/x-<domain>-<foo>"
    function __xsh_load_script () {
        local symlink

        if [[ -n $1 ]]; then
            symlink=${1#${xsh_home}/lib/*/scripts/}  # strip path from begin
            symlink=${symlink%.sh}  #  remove file extension
            symlink=x-${symlink//\//-}  # replace each '/' with '-'
            ln -sf "$1" "/usr/local/bin/$symlink"
        else
            :
        fi
    }

    # @private
    # Call a function or a script by relative file path
    #   and file name(without extension).
    function __xsh_call () {
        # legal input:
        #   core/pkg/util, /pkg/util
        #   core/util, /util
        local command

        # check input
        if [[ -n $1 ]]; then
            command=x-${1//\//-}  # replace each '/' with '-'
        else
            return 255
        fi

        if type $command >/dev/null 2>&1; then
            $command "${@:2}"
        else
            __xsh_load "$1" && $command "${@:2}"
        fi
    }

    # @private
    # This function should only be called directly by function xsh().
    function __xsh_clean () {
        # clean env if here is the final exit point of xsh
        # FUNCNAME[0]: __xsh_clean
        # FUNCNAME[1]: xsh
        if [[ $(printf '%s\n' "${FUNCNAME[@]}" \
                    | grep -c "^${FUNCNAME[1]}$") -eq 1 ]]; then
            unset __xsh_usage \
                  __xsh_list \
                  __xsh_install \
                  __xsh_uninstall \
                  __xsh_load \
                  __xsh_load_function \
                  __xsh_load_script \
                  __xsh_call \
                  __xsh_clean
        else
            :
        fi
    }

    # check input
    if [[ -z $1 ]]; then
        __xsh_usage >&2
        __xsh_clean
        return 255
    fi

    # main
    case $1 in
        list)
            __xsh_list
            ret=$?
            ;;
        install)
            __xsh_install "${@:2}"
            ret=$?
            ;;
        uninstall)
            __xsh_uninstall "${@:2}"
            ret=$?
            ;;
        load)
            for name in "${@:2}"; do
                __xsh_load "$name"
                ret=$((ret + $?))
            done
            ;;
        import)
            for name in "${@:2}"; do
                __xsh_call "$name"
                ret=$((ret + $?))
            done
            ;;
        help|-h|--help)
            __xsh_usage
            ret=$?
            ;;
        *)
            __xsh_call "$1" "${@:2}"
            ret=$?
            ;;
    esac

    # clean
    __xsh_clean

    return $ret
}
export -f xsh
