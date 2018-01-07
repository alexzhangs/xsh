function xsh () {
    local xsh_home lpue
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
        printf "  xsh call [LIB][/PACKAGE]/UTIL ...\n"
        printf "  xsh import [LIB][/PACKAGE][/UTIL] ...\n"
        printf "  xsh list\n"
        printf "  xsh load -r GIT_REPO_URL [-b BRANCH] LIB\n"
        printf "  xsh uninstal LIB\n"
        printf "  xsh help|-h|--help\n\n"

        printf "Options:\n"
        printf "  [LIB][/PACKAGE]/UTIL      Utility to call.\n"
        printf "    UTIL_OPTIONS            Will be passed to utility.\n"
        printf "                            Default LIB is 'x', point to library xsh-lib-xsh.\n"
        printf "  call                      Call utilities in a batch. No options can be passed.\n"
        printf "    [LIB][/PACKAGE]/UTIL    Utility to call.\n"
        printf "  import                    Import utilities so can be called as syntax: 'LIB-PACKAGE-UTIL'\n"
        printf "    [LIB][/PACKAGE][/UTIL]  Utilities to import or call.\n"
        printf "                            Default LIB is 'x', point to library xsh-lib-xsh.\n"
        printf "                            A single quoted asterist '*' presents all utils in all libraries.\n"
        printf "  list                      List loaded libraries, packages and utilities.\n"
        printf "  load                      Load library from Git repo.\n"
        printf "    -r GIT_REPO_URL         Git repo URL.\n"
        printf "    [-b BRANCH]             Branch to use, default is repo's default branch.\n"
        printf "    LIB                     Library name, must be unique in all loaded libraries.\n"
        printf "  unload                    Unload library.\n"
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
    function __xsh_load () {
        local repo branch branch_opt lib
        local OPTARG OPTIND

        while getopts r:b: opt; do
            case ${opt} in
                r)
                    repo=${OPTARG}
                    ;;
                b)
                    branch=${OPTARG}
                    ;;
                *)
                    usage >&2
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        lib=${1:?}

        [[ -n ${branch} ]] && branch_opt="-b ${branch}"

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            printf "ERROR: library '%s' already exists.\n" "${lib}"
            return 255
        else
            git clone ${branch_opt} "${repo:?}" "${xsh_home}/lib/${lib}"
            find "${xsh_home}/lib/${lib}/scripts" \
                 -type f \
                 -name "*.sh" \
                 -exec chmod +x {} \;
        fi
    }

    # @private
    function __xsh_unload () {
        local lib=${1:?}

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            /bin/rm -rf "${xsh_home}/lib/${lib}"
        else
            printf "ERROR: library '%s' doesn't exist.\n" "${lib}"
            return 255
        fi
    }

    # @private
    # Source a function by LPUE.
    # Link a script by LPUE.
    function __xsh_import () {
        # legal input:
        #   '*'
        #   /, x
        #   x/pkg, /pkg
        #   x/pkg/util, /pkg/util
        #   x/util, /util
        local lpue=${1:?}
        local lib_home lib pue ln type

        lib_home="${xsh_home}/lib"

        lib=$(__xsh_get_lib_by_lpue "${lpue}")
        pue=$(__xsh_get_pue_by_lpue "${lpue}")

        while read ln; do
            type=$(__xsh_get_type_by_path "${ln}")

            case ${type} in
                functions)
                    __xsh_import_function "${ln}"
                    ;;
                scripts)
                    __xsh_import_script "${ln}"
                    ;;
                *)
                    return 255
                    ;;
            esac
        done <<< "$(
             find "${lib_home}" \
                  -path "${lib_home}/${lib}/functions/${pue}.sh" \
                  -o \
                  -path "${lib_home}/${lib}/functions/${pue}/*" \
                  -name "*.sh" \
                  -o \
                  -path "${lib_home}/${lib}/scripts/${pue}.sh" \
                  -o \
                  -path "${lib_home}/${lib}/scripts/${pue}/*" \
                  -name "*.sh" \
                  2>/dev/null
                  )"
    }

    # @private
    # Source a file ".../<lib>/functions/<package>/<util>.sh"
    #   as function "<lib>-<package>-<util>"
    function __xsh_import_function () {
        local util=$(__xsh_get_util_by_path "${1:?}")
        local lpuc=$(__xsh_get_lpuc_by_path "${1:?}")
        source /dev/stdin <<<"$(sed "s/function ${util} ()/function ${lpuc} ()/g" "$1")"
    }

    # @private
    # Link a file ".../<lib>/scripts/<package>/<util>.sh"
    #   as "/usr/local/bin/<lib>-<package>-<util>"
    function __xsh_import_script () {
        local lpuc=$(__xsh_get_lpuc_by_path "${1:?}")
        ln -sf "$1" "/usr/local/bin/${lpuc}"
    }

    # @private
    # Call a function or a script by LPUE.
    function __xsh_call () {
        # legal input:
        #   x/pkg/util, /pkg/util
        #   x/util, /util
        local lpue=${1:?}
        local lpuc

        lpuc=$(__xsh_get_lpuc_by_lpue "${lpue}")

        if type ${lpuc} >/dev/null 2>&1; then
            ${lpuc} "${@:2}"
        else
            __xsh_import "${lpue}" && ${lpuc} "${@:2}"
        fi
    }

    # @private
    function __xsh_complete_lpue () {
        local lpue=${1:?}
        lpue=${lpue/#\//x\/}  # set default lib x if lpue is started with /
        lpue=${lpue/%\//\/*}  # set default pue if lpue is ended with /
        if [[ -n ${lpue##*\/*} ]]; then
            lpue="${lpue}/*"
        else
            :
        fi
        echo "${lpue}"
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
    function __xsh_get_lib_by_lpue () {
        local lpue=${1:?}
        lpue=$(__xsh_complete_lpue "${lpue}")
        echo "${lpue%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_util_by_path () {
        local path=${1:?}
        local util=${path##*/}  # get util
        echo "${util%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pue_by_path () {
        local path=${1:?}
        local pue=${path#${xsh_home}/lib/*/*/}  # strip path from begin
        echo "${pue%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pue_by_lpue () {
        local lpue=${1:?}
        lpue=$(__xsh_complete_lpue "${lpue}")
        echo "${lpue#*/}"  # remove lib part
    }

    # @private
    function __xsh_get_lpue_by_path () {
        local path=${1:?}
        local lib=$(__xsh_get_lib_by_path "${path}")
        local pue=$(__xsh_get_pue_by_path "${path}")
        echo "${lib}/${pue}"
    }

    # @private
    function __xsh_get_lpuc_by_path () {
        local path=${1:?}
        local lpue=$(__xsh_get_lpue_by_path "${path}")
        echo "${lpue//\//-}"  # replace each / with -
    }

    # @private
    function __xsh_get_lpuc_by_lpue () {
        local lpue=${1:?}
        lpue=$(__xsh_complete_lpue "${lpue}")
        echo "${lpue//\//-}"  # replace each / with -
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
                  __xsh_load \
                  __xsh_unload \
                  __xsh_import \
                  __xsh_import_function \
                  __xsh_import_script \
                  __xsh_call \
                  __xsh_complete_lpue \
                  __xsh_get_type_by_path \
                  __xsh_get_lib_by_path \
                  __xsh_get_lib_by_lpue \
                  __xsh_get_util_by_path \
                  __xsh_get_pue_by_path \
                  __xsh_get_pue_by_lpue \
                  __xsh_get_lpue_by_path \
                  __xsh_get_lpuc_by_path \
                  __xsh_get_lpuc_by_lpue \
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
        load)
            __xsh_load "${@:2}"
            ret=$?
            ;;
        unload)
            __xsh_unload "${@:2}"
            ret=$?
            ;;
        import)
            for lpue in "${@:2}"; do
                __xsh_import "${lpue}"
                ret=$((ret + $?))
            done
            ;;
        call)
            for lpue in "${@:2}"; do
                __xsh_call "${lpue}"
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

    return ${ret}
}
export -f xsh
