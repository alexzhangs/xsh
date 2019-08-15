#? Description:
#?     xsh is an extension of Bash. It works as a Bash library framework.
#?
#? Usage:
#?     xsh [LIB][/PACKAGE]/UTIL [UTIL_OPTIONS]
#?     xsh call [LIB][/PACKAGE]/UTIL [...]
#?     xsh import [LIB][/PACKAGE][/UTIL] [...]
#?     xsh unimport [LIB][/PACKAGE][/UTIL] [...]
#?     xsh list
#?     xsh load -r GIT_REPO_URL [-b BRANCH] LIB
#?     xsh unload LIB
#?     xsh update LIB
#?     xsh help [LIB][/PACKAGE][/UTIL]
#?
#? Options:
#?     [LIB][/PACKAGE]/UTIL        Utility to call. The library where the util belongs
#?                                 must be loaded first.
#?         [UTIL_OPTIONS]          Will be passed to utility.
#?                                 Default LIB is 'x', point to library xsh-lib-core.
#?
#?     call                        Call utilities in a batch. No options can be passed.
#?         [LIB][/PACKAGE]/UTIL    Utility to call.
#?
#?     import                      Import utilities so can be called directly without
#?                                 leading command, as syntax: 'LIB-PACKAGE-UTIL'.
#?                                 The libraries where the utilities belong must be loaded first.
#?         [LIB][/PACKAGE][/UTIL]  Utilities to import.
#?                                 Default LIB is 'x', point to library xsh-lib-core.
#?                                 A single quoted asterist '*' presents all utils in all libraries.
#?
#?     unimport                    Unimport utilities that have been sourced or linked as
#?                                 syntax: 'LIB-PACKAGE-UTIL'.
#?         [LIB][/PACKAGE][/UTIL]  Utilities to unimport.
#?                                 Default LIB is 'x', point to library xsh-lib-core.
#?                                 A single quoted asterist '*' presents all utils in all libraries.
#?
#?     list                        List loaded libraries, packages and utilities.
#?
#?     load                        Load library from Git repo.
#?         -r GIT_REPO_URL         Git repo URL.
#?         [-b BRANCH]             Branch to use, default is repo's default branch.
#?         LIB                     Library name, must be unique in all loaded libraries.
#?
#?     unload                      Unload the loaded library.
#?         LIB                     Library name.
#?
#?     update                      Update the loaded library.
#?         LIB                     Library name.
#?
#?     help                        Show this help if no option followed.
#?         [LIB][/PACKAGE][/UTIL]  Show help for utilities.
#?
function xsh () {
    # @private
    #
    function __xsh_count_in_funcstack () {
        printf '%s\n' "${FUNCNAME[@]}" \
            | grep -c "^${1}$"
    }

    local xsh_home old_trap_return

    # call __xsh_clean() while xsh() returns
    # clean env if reaching the final exit point of xsh
    old_trap_return=$(trap -p RETURN)
    old_trap_return=${old_trap_return:-trap - RETURN}
    trap 'eval "${old_trap_return}";
         if [[ ${FUNCNAME[0]} == xsh && $(__xsh_count_in_funcstack xsh ) -eq 1 ]]; then
             if type -t __xsh_clean >/dev/null 2>&1; then
                 __xsh_clean;
             fi;
         fi;' RETURN

    # check environment variable
    if [[ -n ${XSH_HOME%/} ]]; then
        # remove tailing '/'
        xsh_home=${XSH_HOME%/}
    else
        printf "$FUNCNAME: ERROR: XSH_HOME is not set properly: '%s'.\n" "${XSH_HOME}" >&2
        return 255
    fi

    # @private
    function __xsh_helps () {
        local lpue title_only
        local path ln
        local ln_type ln_lpue
        local opt OPTARG OPTIND

        while getopts t opt; do
            case ${opt} in
                t)
                    title_only=1
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_help "${XSH_HOME}/xsh.sh"
            return
        fi

        path=$(__xsh_get_path_by_lpue "${lpue}")

        while read ln; do
            if [[ -n ${ln} ]]; then
                ln_type=$(__xsh_get_type_by_path "${ln}" | tr [:lower:] [:upper:])
                ln_lpue=$(__xsh_get_lpue_by_path "${ln}")
                printf "[${ln_type}] ${ln_lpue}\n"

                if [[ -z ${title_only} ]]; then
                    __xsh_help "${ln}"
                fi
            fi
        done <<< "$(echo "${path}")"
    }

    # @private
    function __xsh_help () {
        local path=$1
        local util lpue

        if [[ -z ${path} ]]; then
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        util=$(__xsh_get_util_by_path "${path}")
        lpue=$(__xsh_get_lpue_by_path "${path}")

        # read doc-help
        sed -n '/^#?/p' "${path}" \
            | sed -e 's/^#? //' \
                  -e 's/^#?//' \
                  -e "s|@${util}|xsh ${lpue}|g"
    }

    # @private
    function __xsh_list () {
        __xsh_helps -t '*'
    }

    # @private
    function __xsh_load () {
        local repo branch branch_opt lib
        local opt OPTARG OPTIND

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
            printf "$FUNCNAME: ERROR: library name is null or not set.\n" >&2
            return 255
        fi

        if [[ -z ${repo} ]]; then
            printf "$FUNCNAME: ERROR: repository URL is null or not set.\n" >&2
            return 255
        fi

        [[ -n ${branch} ]] && branch_opt="-b ${branch}"

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            printf "$FUNCNAME: ERROR: library '%s' already exists.\n" "${lib}" >&2
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
            printf "$FUNCNAME: ERROR: library name is null or not set.\n" >&2
            return 255
        fi

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            xsh unimport "$lib/*"
            /bin/rm -rf "${xsh_home}/lib/${lib}"
        else
            printf "$FUNCNAME: ERROR: library '%s' doesn't exist.\n" "${lib}" >&2
            return 255
        fi
    }

    # @private
    function __xsh_update () {
        local lib=$1

        if [[ -z ${lib} ]]; then
            printf "$FUNCNAME: ERROR: library name is null or not set.\n" >&2
            return 255
        fi

        if [[ -e ${xsh_home}/lib/${lib} ]]; then
            xsh unimport "$lib/*"
            (cd "${xsh_home}/lib/${lib}" \
                 && git fetch origin \
                 && git reset --hard FETCH_HEAD \
                 && git clean -df \
                 && find "${xsh_home}/lib/${lib}/scripts" \
                         -type f \
                         -name "*.sh" \
                         -exec chmod +x {} \;
            )
        else
            printf "$FUNCNAME: ERROR: library '%s' doesn't exist.\n" "${lib}" >&2
            return 255
        fi
    }

    # @private
    function __xsh_imports () {
        local lpue
        local ret=0

        for lpue in "$@"; do
            __xsh_import "${lpue}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    # @private
    # Source a function by LPUE.
    # Link a script by LPUE.
    function __xsh_import () {
        # legal input:
        #   '*'
        local lpue=$1
        #   /, <lib>
        #   <lib>/<pkg>, /<pkg>
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        local ln type

        if [[ -z ${lpue} ]]; then
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        util=$(__xsh_get_util_by_path "${path}")
        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        source /dev/stdin <<< "$(sed "s/function ${util} ()/function ${lpuc} ()/g" "${path}")"
    }

    # @private
    # Link a file ".../<lib>/scripts/<package>/<util>.sh"
    #   as "/usr/local/bin/<lib>-<package>-<util>"
    function __xsh_import_script () {
        local path=$1
        local lpuc

        if [[ -z ${path} ]]; then
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        ln -sf "${path}" "/usr/local/bin/${lpuc}"
    }

    # @private
    function __xsh_unimports () {
        local lpue
        local ret=0

        for lpue in "$@"; do
            __xsh_unimport "${lpue}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    # @private
    # Unset a sourced function by LPUE.
    # Unlink a linked script by LPUE.
    function __xsh_unimport () {
        # legal input:
        #   '*'
        local lpue=$1
        #   /, <lib>
        #   <lib>/<pkg>, /<pkg>
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        local ln type

        if [[ -z ${lpue} ]]; then
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
            return 255
        fi

        while read ln; do
            type=$(__xsh_get_type_by_path "${ln}")

            case ${type} in
                functions)
                    __xsh_unimport_function "${ln}"
                    ;;
                scripts)
                    __xsh_unimport_script "${ln}"
                    ;;
                *)
                    return 255
                    ;;
            esac
        done <<< "$(__xsh_get_path_by_lpue "${lpue}")"
    }

    # @private
    # Unset
    # Source a file ".../<lib>/functions/<package>/<util>.sh"
    #   and unset function by name "<lib>-<package>-<util>"
    function __xsh_unimport_function () {
        local path=$1
        local util lpuc

        if [[ -z ${path} ]]; then
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        util=$(__xsh_get_util_by_path "${path}")
        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        source /dev/stdin <<< "$(sed -n "s/^function ${util} ().*/unset -f ${lpuc}/p" "${path}")"
    }

    # @private
    # Unlink a file ".../<lib>/scripts/<package>/<util>.sh"
    #   at "/usr/local/bin/<lib>-<package>-<util>"
    function __xsh_unimport_script () {
        local path=$1
        local lpuc

        if [[ -z ${path} ]]; then
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        rm -f "/usr/local/bin/${lpuc}"
    }

    # @private
    function __xsh_calls () {
        local lpue
        local ret=0

        for lpue in "$@"; do
            __xsh_call "${lpue}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    # @private
    # Call a function or a script by LPUE.
    function __xsh_call () {
        # legal input:
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        local lpue=$1
        local lpuc

        if [[ -z ${lpue} ]]; then
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lib=${path#${xsh_home}/lib/}  # strip path from begin
        echo "${lib%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_lib_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        util=${path%.sh}  # remove file extension
        util=$(echo "${util}" | sed 's|/[0-9]*$||')  # handle util selector
        util=${util##*/}  # get util
        echo "${util}"
    }

    # @private
    function __xsh_get_pue_by_path () {
        local path=${1:?}
        local pue

        if [[ -z ${path} ]]; then
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        pue=${path#${xsh_home}/lib/*/*/}  # strip path from begin
        echo "${pue%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_pue_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPU path is null or not set.\n" >&2
            return 255
        fi

        lpue=$(__xsh_get_lpue_by_path "${path}")
        echo "${lpue//\//-}"  # replace each / with -
    }

    # @private
    function __xsh_get_lpuc_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
            printf "$FUNCNAME: ERROR: LPUE is null or not set.\n" >&2
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
        unset -f \
              __xsh_backup_debug_state \
              __xsh_restore_debug_state \
              __xsh_enable_debug \
              __xsh_disable_debug \
              __xsh_count_in_funcstack \
              __xsh_helps \
              __xsh_help \
              __xsh_list \
              __xsh_load \
              __xsh_unload \
              __xsh_update \
              __xsh_imports \
              __xsh_import \
              __xsh_import_function \
              __xsh_import_script \
              __xsh_unimports \
              __xsh_unimport \
              __xsh_unimport_function \
              __xsh_unimport_script \
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
    }

    # Check input
    if [[ -z $1 ]]; then
        __xsh_helps >&2
        return 255
    fi

    # Main
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
        update)
            __xsh_update "${@:2}"
            ;;
        import)
            __xsh_imports "${@:2}"
            ;;
        unimport)
            __xsh_unimports "${@:2}"
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
