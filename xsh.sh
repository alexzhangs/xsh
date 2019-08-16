#? Description:
#?     xsh is an extension of Bash. It works as a Bash library framework.
#?
#? Usage:
#?     xsh <LPUE> [UTIL_OPTIONS]
#?     xsh call <LPUE> [...]
#?     xsh import <LPUR> [...]
#?     xsh unimport <LPUR> [...]
#?     xsh list
#?     xsh load -r GIT_REPO_URL [-b BRANCH] LIB
#?     xsh unload LIB
#?     xsh update LIB
#?     xsh help [LPUR]
#?
#? Options:
#?     <LPUE>               Call an individual utility.
#?         [UTIL_OPTIONS]   Will be passed to utility.
#?
#?                          The library of the utility must be loaded first.
#?
#?                          LPUE stands for `Lib/Package/Util Expression`.
#?                          The LPUE syntax is: `[LIB][/PACKAGE]/UTIL`.
#?                          Example:
#?                              <lib>/<pkg>/<util>, /<pkg>/<util>
#?                              <lib>/<util>, /<util>
#?
#?     call                 Call utilities in a batch. No options can be passed.
#?         <LPUE> [...]     Utilities to call.
#?
#?     import               Import utilities.
#?         <LPUR>           Utilities to import.
#?
#?                          The imported utilities can be called directly without
#?                          leading `xsh` as syntax: 'LIB-PACKAGE-UTIL'.
#?
#?                          LPUR stands for `Lib/Package/Util Regex`.
#?                          The LPUR syntax is: `[LIB][/PACKAGE][/UTIL]`.
#?                          Example:
#?                              '*'
#?                              /, <lib>
#?                              <lib>/<pkg>, /<pkg>
#?                              <lib>/<pkg>/<util>, /<pkg>/<util>
#?                              <lib>/<util>, /<util>
#?
#?     unimport             Unimport utilities that have been sourced or linked
#?                          as syntax: 'LIB-PACKAGE-UTIL'.
#?
#?         <LPUR>           The syntax is the same with import.
#?
#?     list                 List loaded libraries, packages and utilities.
#?
#?     load                 Load library from Git repo.
#?
#?         -r GIT_REPO_URL  Git repo URL.
#?         [-b BRANCH]      Branch to use, default is repo's default branch.
#?         LIB              Library name, must be unique in all loaded libraries.
#?
#?     unload               Unload the loaded library.
#?
#?         LIB              Library name.
#?
#?     update               Update the loaded library.
#?
#?         LIB              Library name.
#?
#?     help                 Show this help if no option followed.
#?
#?         [LPUR]           Show help for matched utilities.
#?
#? Debugging:
#?     Enable debug mode by setting environment varaible: XSH_DEBUG
#?
#?     Debug mode is enabled by setting `set -vx`.
#?     Debug mode is only available with syntax: `xsh <LPUE> [UTIL_OPTIONS]`.
#?
#?     Values:
#?         xsh:    Debug xsh itself.
#?         1:      Debug current called xsh utility.
#?         <LPUR>: Debug matched xsh utilities.
#?
#?     Example:
#?         XSH_DEBUG=1 xsh /string/upper foo
#?
function xsh () {
    ### DEBUG LOGIC BEGIN ###
    set +vx  # disable debug
    ### DEBUG LOGIC ENDS  ###

    local orig_debug_state

    # @private
    #
    function __xsh_backup_debug_state () {
        case "${-//[^vx]/}" in
            v)
                orig_debug_state='-v'
                ;;
            x)
                orig_debug_state='-x'
                ;;
            vx)
                orig_debug_state='-vx'
                ;;
            *)
                orig_debug_state='+vx'
                ;;
        esac
    }

    # @private
    #
    function __xsh_count_in_funcstack () {
        printf '%s\n' "${FUNCNAME[@]}" \
            | grep -c "^${1}$"
    }

    ### DEBUG LOGIC BEGIN ###
    __xsh_backup_debug_state  # backup debug state

    case $XSH_DEBUG in
        xsh)
            unset XSH_DEBUG  # avoid further debugging
            [[ $orig_debug_state == '-vx' ]] && : || set -vx  # enable debug
            ;;
        1)
            XSH_DEBUG=$1  # set XSH_DEBUG=<lpue>
            ;;
    esac
    ### DEBUG LOGIC ENDS  ###

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
        local lpur title_only
        local path ln
        local type lpue
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
        lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_help "${XSH_HOME}/xsh.sh"
            return
        fi

        path=$(__xsh_get_path_by_lpur "${lpur}")

        while read ln; do
            if [[ -n ${ln} ]]; then
                type=$(__xsh_get_type_by_path "${ln}" | tr [:lower:] [:upper:])
                lpue=$(__xsh_get_lpue_by_path "${ln}")
                printf "[${type}] ${lpue}\n"

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
        local lpur
        local ret=0

        for lpur in "$@"; do
            __xsh_import "${lpur}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    # @private
    # Source a function by LPUR.
    # Link a script by LPUR.
    function __xsh_import () {
        # legal input:
        #   '*'
        #   /, <lib>
        #   <lib>/<pkg>, /<pkg>
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        local lpur=$1
        local ln type

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
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
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
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
        local lpur
        local ret=0

        for lpur in "$@"; do
            __xsh_unimport "${lpur}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    # @private
    # Unset a sourced function by LPUR.
    # Unlink a linked script by LPUR.
    function __xsh_unimport () {
        # legal input:
        #   '*'
        #   /, <lib>
        #   <lib>/<pkg>, /<pkg>
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        local lpur=$1
        local ln type

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
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
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
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

        if ! type -t ${lpuc} >/dev/null 2>&1; then
            __xsh_import "${lpue}"
        fi

        ### DEBUG LOGIC BEGIN ###
        if test -n "$XSH_DEBUG" && __xsh_get_lpuc_by_lpur "$XSH_DEBUG" | grep "^${lpuc}$" >/dev/null; then
            # enable debug for the utility
            [[ $orig_debug_state == '-vx' ]] && : || set -vx  # enable debug
            ${lpuc} "${@:2}"
            set +vx  # disable debug
        else
            [[ $orig_debug_state == '+vx' ]] && : || set +vx  # disable debug
            ${lpuc} "${@:2}"
        fi
        ### DEBUG LOGIC ENDS  ###
    }

    # @private
    function __xsh_complete_lpur () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
            return 255
        fi

        lpur=${lpur/#\//x\/}  # set default lib `x` if lpur is started with /
        lpur=${lpur/%\//\/*}  # set default pur `*` if lpur is ended with /
        if [[ -n ${lpur##*\/*} ]]; then
            lpur="${lpur}/*"
        else
            :
        fi
        echo "${lpur}"
    }

    # @private
    function __xsh_get_lib_by_lpur () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
            return 255
        fi

        lpur=$(__xsh_complete_lpur "${lpur}")
        echo "${lpur%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_pur_by_lpur () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
            return 255
        fi

        lpur=$(__xsh_complete_lpur "${lpur}")
        echo "${lpur#*/}"  # remove lib part
    }

    # @private
    function __xsh_get_path_by_lpur () {
        local lpur=$1
        local lib_home lib pur

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
            return 255
        fi

        lib_home="${xsh_home}/lib"

        lib=$(__xsh_get_lib_by_lpur "${lpur}")
        pur=$(__xsh_get_pur_by_lpur "${lpur}")

        find "${lib_home}" \
             -path "${lib_home}/${lib}/functions/${pur}.sh" \
             -o \
             -path "${lib_home}/${lib}/functions/${pur}/*" \
             -name "*.sh" \
             -o \
             -path "${lib_home}/${lib}/scripts/${pur}.sh" \
             -o \
             -path "${lib_home}/${lib}/scripts/${pur}/*" \
             -name "*.sh" \
             2>/dev/null
    }

    # @private
    function __xsh_get_lpuc_by_lpur () {
        local lpur=$1
        local ln

        if [[ -z ${lpur} ]]; then
            printf "$FUNCNAME: ERROR: LPUR is null or not set.\n" >&2
            return 255
        fi

        while read ln; do
            __xsh_get_lpuc_by_path "${ln}"
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
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

        lpue=$(__xsh_complete_lpur "${lpue}")
        echo "${lpue//\//-}"  # replace each / with -
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
              __xsh_complete_lpur \
              __xsh_get_lib_by_lpur \
              __xsh_get_pur_by_lpur \
              __xsh_get_path_by_lpur \
              __xsh_get_lpuc_by_lpur \
              __xsh_get_type_by_path \
              __xsh_get_lib_by_path \
              __xsh_get_util_by_path \
              __xsh_get_pue_by_path \
              __xsh_get_lpue_by_path \
              __xsh_get_lpuc_by_path \
              __xsh_get_lpuc_by_lpue \
              __xsh_clean

        ### DEBUG LOGIC BEGIN ###
        set "$orig_debug_state"  # restore debug state
        ### DEBUG LOGIC ENDS  ###
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
