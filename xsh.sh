function xsh () {
#? Usage:
#?   xsh [LIB][/PACKAGE]/UTIL [UTIL_OPTIONS]
#?   xsh call [LIB][/PACKAGE]/UTIL ...
#?   xsh import [LIB][/PACKAGE][/UTIL] ...
#?   xsh list
#?   xsh load -r GIT_REPO_URL [-b BRANCH] LIB
#?   xsh unload LIB
#?   xsh help [LIB][/PACKAGE][/UTIL]
#?
#? Options:
#?   [LIB][/PACKAGE]/UTIL      Utility to call.
#?     UTIL_OPTIONS            Will be passed to utility.
#?                             Default LIB is 'x', point to library xsh-lib-xsh.
#?   call                      Call utilities in a batch. No options can be passed.
#?     [LIB][/PACKAGE]/UTIL    Utility to call.
#?   import                    Import utilities so can be called as syntax: 'LIB-PACKAGE-UTIL'
#?     [LIB][/PACKAGE][/UTIL]  Utilities to import or call.
#?                             Default LIB is 'x', point to library xsh-lib-xsh.
#?                             A single quoted asterist '*' presents all utils in all libraries.
#?   list                      List loaded libraries, packages and utilities.
#?   load                      Load library from Git repo.
#?     -r GIT_REPO_URL         Git repo URL.
#?     [-b BRANCH]             Branch to use, default is repo's default branch.
#?     LIB                     Library name, must be unique in all loaded libraries.
#?   unload                    Unload library.
#?     LIB                     Library name.
#?   help                      Show this help if no option followed.
#?     [LIB][/PACKAGE][/UTIL]  Show help for utilities.

    local xsh_home old_trap_return

    # call __xsh_clean() while xsh() returns
    old_trap_return=$(trap -p RETURN)
    old_trap_return=${old_trap_return:-trap - RETURN}
    trap 'eval "${old_trap_return}";
         if [[ ${FUNCNAME[0]} == xsh ]]; then
             if type -t __xsh_clean >/dev/null 2>&1; then
                 __xsh_clean;
             fi;
         fi;' RETURN

    # check environment variable
    if [[ -n ${XSH_HOME%/} ]]; then
        # remove tailing '/'
        xsh_home=${XSH_HOME%/}
    else
        printf "ERROR: XSH_HOME is not set properly: '%s'.\n" "${XSH_HOME}" >&2
        return 255
    fi

    # @private
    function __xsh_helps () {
        local lpue=$1
        local path ln

        if [[ -z ${lpue} ]]; then
            path="${XSH_HOME}/xsh.sh"
        else
            path=$(__xsh_get_path_by_lpue "${lpue}")
        fi

        while read ln; do
            __xsh_help "${ln}"
        done <<< "$(echo "${path}")"
    }

    # @private
    function __xsh_help () {
        local path=$1

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        # read doc-help
        sed -n '/^#\? /p' "${path}" | sed 's/^#\? //' >&2
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
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        lib=$1

        if [[ -z ${lib} ]]; then
            printf "ERROR: library name is null or not set.\n" >&2
            return 255
        fi

        if [[ -z ${repo} ]]; then
            printf "ERROR: repository URL is null or not set.\n" >&2
            return 255
        fi

        [[ -n ${branch} ]] && branch_opt="-b ${branch}"

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            printf "ERROR: library '%s' already exists.\n" "${lib}" >&2
            return 255
        else
            git clone ${branch_opt} "${repo}" "${xsh_home}/lib/${lib}"
            find "${xsh_home}/lib/${lib}/scripts" \
                 -type f \
                 -name "*.sh" \
                 -exec chmod +x {} \;
        fi
    }

    # @private
    function __xsh_unload () {
        local lib=$1

        if [[ -z ${lib} ]]; then
            printf "ERROR: library name is null or not set.\n" >&2
            return 255
        fi

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            /bin/rm -rf "${xsh_home}/lib/${lib}"
        else
            printf "ERROR: library '%s' doesn't exist.\n" "${lib}" >&2
            return 255
        fi
    }

    # @private
    function __xsh_imports () {
        local lpue

        for lpue in "$@"; do
            __xsh_import "${lpue}"
            ret=$((ret + $?))
        done
        return $ret
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
        local lpue=$1
        local ln type

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

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
        done <<< "$(__xsh_get_path_by_lpue "${lpue}")"
    }

    # @private
    # Source a file ".../<lib>/functions/<package>/<util>.sh"
    #   as function "<lib>-<package>-<util>"
    function __xsh_import_function () {
        local path=$1
        local util lpuc

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        util=$(__xsh_get_util_by_path "${path}")
        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        source /dev/stdin <<<"$(sed "s/function ${util} ()/function ${lpuc} ()/g" "${path}")"
    }

    # @private
    # Link a file ".../<lib>/scripts/<package>/<util>.sh"
    #   as "/usr/local/bin/<lib>-<package>-<util>"
    function __xsh_import_script () {
        local path=$1
        local lpuc

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        ln -sf "${path}" "/usr/local/bin/${lpuc}"
    }

    # @private
    function __xsh_calls () {
        local lpue

        for lpue in "$@"; do
            __xsh_call "${lpue}"
            ret=$((ret + $?))
        done
        return $ret
    }

    # @private
    # Call a function or a script by LPUE.
    function __xsh_call () {
        # legal input:
        #   x/pkg/util, /pkg/util
        #   x/util, /util
        local lpue=$1
        local lpuc

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

        lpuc=$(__xsh_get_lpuc_by_lpue "${lpue}")

        if type -t ${lpuc} >/dev/null 2>&1; then
            ${lpuc} "${@:2}"
        else
            __xsh_import "${lpue}" && ${lpuc} "${@:2}"
        fi
    }

    # @private
    function __xsh_complete_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

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
        local path=$1
        local type

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        type=${path#${xsh_home}/lib/*/}  # strip path from begin
        echo "${type%%/*}"  # strip path from end
    }

    # @private
    function __xsh_get_lib_by_path () {
        local path=$1
        local lib

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lib=${path#${xsh_home}/lib/}  # strip path from begin
        echo "${lib%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_lib_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

        lpue=$(__xsh_complete_lpue "${lpue}")
        echo "${lpue%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_util_by_path () {
        local path=$1
        local util

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        util=${path##*/}  # get util
        echo "${util%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pue_by_path () {
        local path=${1:?}
        local pue

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        pue=${path#${xsh_home}/lib/*/*/}  # strip path from begin
        echo "${pue%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pue_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

        lpue=$(__xsh_complete_lpue "${lpue}")
        echo "${lpue#*/}"  # remove lib part
    }

    # @private
    function __xsh_get_lpue_by_path () {
        local path=${1:?}
        local lib pue

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lib=$(__xsh_get_lib_by_path "${path}")
        pue=$(__xsh_get_pue_by_path "${path}")
        echo "${lib}/${pue}"
    }

    # @private
    function __xsh_get_lpuc_by_path () {
        local path=$1
        local lpue

        if [[ -z ${path} ]]; then
            printf "ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lpue=$(__xsh_get_lpue_by_path "${path}")
        echo "${lpue//\//-}"  # replace each / with -
    }

    # @private
    function __xsh_get_lpuc_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

        lpue=$(__xsh_complete_lpue "${lpue}")
        echo "${lpue//\//-}"  # replace each / with -
    }

    # @private
    function __xsh_get_path_by_lpue () {
        local lpue=$1
        local lib_home lib pue

        if [[ -z ${lpue} ]]; then
            printf "ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

        lib_home="${xsh_home}/lib"

        lib=$(__xsh_get_lib_by_lpue "${lpue}")
        pue=$(__xsh_get_pue_by_lpue "${lpue}")

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
    }

    # @private
    # This function should only be called directly by function xsh().
    function __xsh_clean () {
        # clean env if here is the final exit point of xsh
        # FUNCNAME[0]: __xsh_clean
        # FUNCNAME[1]: xsh
        if [[ $(printf '%s\n' "${FUNCNAME[@]}" \
                    | grep -c "^${FUNCNAME[1]}$") -eq 1 ]]; then
            unset __xsh_helps \
                  __xsh_help \
                  __xsh_list \
                  __xsh_load \
                  __xsh_unload \
                  __xsh_imports \
                  __xsh_import \
                  __xsh_import_function \
                  __xsh_import_script \
                  __xsh_calls \
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
                  __xsh_get_path_by_lpue \
                  __xsh_clean
        else
            :
        fi
    }

    # check input
    if [[ -z $1 ]]; then
        __xsh_helps
        return 255
    fi

    # main
    case $1 in
        list)
            __xsh_list
            ;;
        load)
            __xsh_load "${@:2}"
            ;;
        unload)
            __xsh_unload "${@:2}"
            ;;
        import)
            __xsh_imports "${@:2}"
            ;;
        call)
            __xsh_calls "${@:2}"
            ;;
        help)
            __xsh_helps "${@:2}"
            ;;
        *)
            __xsh_call "$1" "${@:2}"
            ;;
    esac
}
export -f xsh
