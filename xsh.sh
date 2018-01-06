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
        local repo branch branch_opt alias name
        local OPTARG OPTIND

        while getopts r:b:a: opt; do
            case $opt in
                r)
                    repo=$OPTARG
                    ;;
                b)
                    branch=$OPTARG
                    ;;
                a)
                    alias=$OPTARG
                    ;;
                *)
                    usage >&2
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        name=${1:?}

        [[ -n ${branch} ]] && branch_opt="-b ${branch}"

        if [[ -e ${xsh_home}/lib/${name} ]]; then
            printf "ERROR: library '%s' already exists.\n" "${name}"
            return 255
        else
            git clone ${branch_opt} "${repo:?}" "${xsh_home}/lib/${name}"
            find "${xsh_home}/lib/${name}/scripts" \
                 -type f \
                 -name "*.sh" \
                 -exec chmod +x {} \;
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
    # Source a function by LPU.
    # Link a script by LPU.
    function __xsh_load () {
        # legal input:
        #   '*'
        #   /, core
        #   core/pkg, /pkg
        #   core/pkg/util, /pkg/util
        #   core/util, /util
        local lpu=${1:?}
        local lib_home lib pkg_util ln type

        lib_home="${xsh_home}/lib"

        lib=$(__xsh_get_lib_by_lpu "${lpu}")
        pu=$(__xsh_get_pu_by_lpu "${lpu}")

        while read ln; do
            type=$(__xsh_get_type_by_path "${ln}")

            case ${type} in
                functions)
                    __xsh_load_function "${ln}"
                    ;;
                scripts)
                    __xsh_load_script "${ln}"
                    ;;
                *)
                    return 255
                    ;;
            esac
        done <<< "$(
             find "${lib_home}" \
                  -path "${lib_home}/${lib}/functions/${pu}.sh" \
                  -o \
                  -path "${lib_home}/${lib}/functions/${pu}/*" \
                  -name "*.sh" \
                  -o \
                  -path "${lib_home}/${lib}/scripts/${pu}.sh" \
                  -o \
                  -path "${lib_home}/${lib}/scripts/${pu}/*" \
                  -name "*.sh" \
                  2>/dev/null
                  )"
    }

    # @private
    # Source a file ".../<lib>/functions/<package>/<util>.sh"
    #   as function "<lib>-<package>-<util>"
    function __xsh_load_function () {
        local util=$(__xsh_get_util_by_path "${1:?}")
        local clpu=$(__xsh_get_clpu_by_path "${1:?}")
        source /dev/stdin <<<"$(sed "s/function ${util} ()/function ${clpu} ()/g" "$1")"
    }

    # @private
    # Link a file ".../<lib>/scripts/<package>/<util>.sh"
    #   as "/usr/local/bin/<lib>-<package>-<util>"
    function __xsh_load_script () {
        local clpu=$(__xsh_get_clpu_by_path "${1:?}")
        ln -sf "$1" "/usr/local/bin/${clpu}"
    }

    # @private
    # Call a function or a script by LPU.
    function __xsh_call () {
        # legal input:
        #   core/pkg/util, /pkg/util
        #   core/util, /util
        local lpu=${1:?}
        local clpu

        clpu=$(__xsh_get_clpu_by_lpu "${lpu}")

        if type ${clpu} >/dev/null 2>&1; then
            ${clpu} "${@:2}"
        else
            __xsh_load "${lpu}" && ${clpu} "${@:2}"
        fi
    }

    # @private
    function __xsh_complete_lpu () {
        local lpu=${1:?}
        lpu=${lpu/#\//core\/}  # set default lib if lpu is started with /
        lpu=${lpu/%\//\/*}  # set default pu if lpu is ended with /
        if [[ -n ${lpu##*\/*} ]]; then
            lpu="${lpu}/*"
        else
            :
        fi
        echo "${lpu}"
    }

    # @private
    function __xsh_get_type_by_path () {
        local path=${1:?}
        local type=${path#${xsh_home}/lib/*/}  # strip path from begin
        echo "${type%%/*}"  # strip path from end
    }

    # @private
    function __xsh_get_lib_by_path () {
        local path=${1:?}
        local lib=${path#${xsh_home}/lib/}  # strip path from begin
        echo "${lib%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_lib_by_lpu () {
        local lpu=${1:?}
        lpu=$(__xsh_complete_lpu "${lpu}")
        echo "${lpu%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_alias_by_lib () {
        :
    }

    # @private
    function __xsh_get_util_by_path () {
        local path=${1:?}
        local util=${path##*/}  # get util
        echo "${util%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pu_by_path () {
        local path=${1:?}
        local pu=${path#${xsh_home}/lib/*/*/}  # strip path from begin
        echo "${pu%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pu_by_lpu () {
        local lpu=${1:?}
        lpu=$(__xsh_complete_lpu "${lpu}")
        echo "${lpu#*/}"  # remove lib part
    }

    # @private
    function __xsh_get_lpu_by_path () {
        local path=${1:?}
        local lib=$(__xsh_get_lib_by_path "${path}")
        local pu=$(__xsh_get_pu_by_path "${path}")
        echo "${lib}/${pu}"
    }

    # @private
    function __xsh_get_clpu_by_path () {
        local path=${1:?}
        local lpu=$(__xsh_get_lpu_by_path "${path}")
        echo "${lpu//\//-}"  # replace each / with -
    }

    # @private
    function __xsh_get_clpu_by_lpu () {
        local lpu=${1:?}
        lpu=$(__xsh_complete_lpu "${lpu}")
        echo "${lpu//\//-}"  # replace each / with -
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
                  __xsh_complete_lpu \
                  __xsh_get_alias_by_lib \
                  __xsh_get_clpu_by_lpu \
                  __xsh_get_clpu_by_path \
                  __xsh_get_lib_by_lpu \
                  __xsh_get_lib_by_path \
                  __xsh_get_lpu_by_path \
                  __xsh_get_pu_by_lpu \
                  __xsh_get_pu_by_path \
                  __xsh_get_type_by_path \
                  __xsh_get_util_by_path \
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
