#? Description:
#?     xsh is an extension of Bash. It works as a Bash library framework.
#?
#? Usage:
#?     xsh <LPUE> [UTIL_OPTIONS]
#?     xsh call <LPUE> [...]
#?     xsh import <LPUR> [...]
#?     xsh unimport <LPUR> [...]
#?     xsh list
#?     xsh load [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
#?     xsh unload REPO
#?     xsh update [-b BRANCH | -t TAG] REPO
#?     xsh upgrade [-b BRANCH | -t TAG]
#?     xsh version
#?     xsh versions
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
#?                          Without '-b' or '-t', it will load the latest tagged
#?                          version, if there's no any tagged version, returns error.
#?         [-s GIT_SERVER]  Git server URL.
#?                          E.g. `https://github.com`
#?         [-b BRANCH]      Load the BRANCH's latest state.
#?                          This option is for developers.
#?         [-t TAG]         Load a specific TAG version.
#?         REPO             Git repo in syntax: `USERNAME/REPO`.
#?                          E.g. `username/xsh-lib-foo`
#?
#?     unload               Unload the loaded library.
#?         REPO             Git repo in syntax: `USERNAME/REPO`.
#?
#?     update               Update the loaded library.
#?                          Without '-b' or '-t', it will update to the latest tagged
#?                          version, if there's no any tagged version, returns error.
#?         [-b BRANCH]      Update to the BRANCH's latest state.
#?                          This option is for developers.
#?         [-t TAG]         Load a specific TAG version.
#?         REPO             Git repo in syntax: `USERNAME/REPO`.
#?                          E.g. `username/xsh-lib-foo`
#?
#?     upgrade              Update xsh itself.
#?                          Without '-b' or '-t', it will update to the latest tagged
#?                          version, if there's no any tagged version, returns error.
#?         [-b BRANCH]      Update to the BRANCH's latest state.
#?                          This option is for developers.
#?         [-t TAG]         Load a specific TAG version.
#?
#?     version              Show current xsh version.
#?
#?     versions             Show available xsh versions.
#?
#?     help                 Show this help if no option followed.
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
    # Backup 'set' options to variable: orig_debug_state
    #   verbose: -v
    #   xtrace:  -x
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
    # Count the number of given function name in ${FUNCNAME[@]}
    function __xsh_count_in_funcstack () {
        printf '%s\n' "${FUNCNAME[@]}" \
            | grep -c "^${1}$"
    }

    # @private
    # Log message to stdout/stderr.
    #
    # Usage:
    #   __xsh_log [debug|info|wanning|error|fail|fatal] <MESSAGE>
    function __xsh_log () {
        local level="$(echo "$1" | tr [[:lower:]] [[:upper:]])"

        case ${level} in
            WARNING|ERROR|FAIL|FATAL)
                printf "${FUNCNAME[1]}: ${level}: %s\n" "${*:2}" >&2
                ;;
            DEBUG|INFO)
                printf "${FUNCNAME[1]}: ${level}: %s\n" "${*:2}"
                ;;
            *)
                printf "${FUNCNAME[1]}: %s\n" "$*"
                ;;
        esac
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

    local xsh_home orig_trap_return

    # call __xsh_clean() while xsh() returns
    # clean env if reaching the final exit point of xsh
    orig_trap_return=$(trap -p RETURN)
    orig_trap_return=${orig_trap_return:-trap - RETURN}
    trap 'eval "${orig_trap_return}";
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
        __xsh_log error "XSH_HOME is not set properly."
        return 255
    fi

    local xsh_repo_home="${xsh_home}/repo"
    local xsh_lib_home="${xsh_home}/lib"
    local xsh_git_server='https://github.com'

    if [[ ! -e ${xsh_lib_home} ]]; then
        mkdir -p "${xsh_lib_home}"
    fi


    # @private
    # chmod +x all files under the given dir
    function __xsh_chmod_x_by_dir () {
        local path=$1

        find "${path}" \
             -type f \
             -name "*.sh" \
             -exec chmod +x {} \;
    }

    # @private
    # Discard all local changes and untracked files
    function __xsh_git_discard_all () {
        git reset --hard \
            && git clean -d --force
    }

    # @private
    # Get all tags
    function __xsh_git_get_all_tags () {
        git tag --list
    }

    # @private
    # Fetch remote tags to local
    function __xsh_git_fetch_remote_tags () {
        # remove local tags that don't exist on remote
        __xsh_git_get_all_tags | xargs git tag --delete
        git fetch --tags
    }

    # @private
    # Get the tag current on
    function __xsh_git_get_current_tag () {
        git describe --tags
    }

    # @private
    # Get the latest tag
    function __xsh_git_get_latest_tag () {
        __xsh_git_get_all_tags | sed -n '$p'
    }

    # @private
    # Check if the work directory is clean.
    function __xsh_git_is_workdir_clean () {
        test -n "$(git status -s)"
    }

    # @private
    # Clone a Git repo.
    #
    # Usage:
    #   __xsh_git_clone [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
    #
    # Options:
    #   [-s GIT_SERVER]  Git server URL.
    #                    E.g. `https://github.com`
    #   [-b BRANCH]      Clone the BRANCH's latest state.
    #                    This option is for developers.
    #   [-t TAG]         Clone a specific TAG version.
    #   REPO             Git repo in syntax: `USERNAME/REPO`.
    #                    E.g. `username/xsh-lib-foo`
    function __xsh_git_clone () {
        local OPTARG OPTIND opt
        local git_server repo

        declare -a git_options
        git_server=${xsh_git_server}

        while getopts s:b:t: opt; do
            case ${opt} in
                s)
                    git_server=${OPTARG%/}  # remove tailing '/'
                    ;;
                b|t)
                    git_options[${#git_options[@]}]='-b'
                    git_options[${#git_options[@]}]="${OPTARG}"
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        repo=$1

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        if [[ -z ${git_server} ]]; then
            __xsh_log error "Git server is null or not set."
            return 255
        fi

        local repo_path="${xsh_repo_home}/${repo}"
        if [[ -e ${repo_path} ]]; then
            __xsh_log error "Repo already exists at ${repo_path}."
            return 255
        fi

        if [[ ${#git_options[@]} -gt 2 ]]; then
            __xsh_log error "-b and -t can't be used together."
            return 255
        fi

        git clone "${git_options[@]}" "${git_server}/${repo}" "${repo_path}"

        if [[ -z ${git_options[@]} ]]; then
            # update to latest tagged version
            (cd "${repo_path}" \
                 && __xsh_git_force_update
            )

            local ret=$?
            if [[ ${ret} -ne 0 ]]; then
                __xsh_log warning "Deleting repo ${repo_path}."
                /bin/rm -rf "${repo_path}"
                return ${ret}
            fi
        fi
    }

    # @private
    # Update current repo.
    # Any local changes will be DISCARDED after update.
    # Any untracked files will be REMOVED after update.
    #
    # Usage:
    #   __xsh_git_force_update [-b BRANCH | -t TAG]
    #
    # Options:
    #   [-b BRANCH]      Update to the BRANCH's latest state.
    #                    This option is for developers.
    #   [-t TAG]         Update to a specific TAG version.
    function __xsh_git_force_update () {
        local OPTIND OPTARG opt

        declare -a git_options

        while getopts b:t: opt; do
            case ${opt} in
                b|t)
                    git_options[${#git_options[@]}]="${OPTARG}"
                    ;;
                *)
                    return 255
                    ;;
            esac
        done

        if [[ ${#git_options[@]} -gt 1 ]]; then
            __xsh_log error "-b and -t can't be used together."
            return 255
        fi

        if __xsh_git_is_workdir_clean; then
            # discard all local changes and untracked files
            __xsh_git_discard_all
        fi

        # fetch remote tags to local
        __xsh_git_fetch_remote_tags

        if [[ -z ${git_options} ]]; then
            local git_options=$(__xsh_git_get_latest_tag)

            if [[ -z ${git_options} ]]; then
                __xsh_log error "No any available tagged version found."
                return 255
            fi
        fi

        local current=$(__xsh_git_get_current_tag)
        if [[ ${current} == ${git_options} ]]; then
            __xsh_log info "Already at the latest version: ${current}."
            return
        fi

        __xsh_log info "Updating repo to ${git_options}."
        git checkout "${git_options}"

        if [[ $? -ne 0 ]]; then
            __xsh_log error "Failed to update repo."
            return 255
        fi

        if [[ -d ./scripts ]]; then
            # chmod +x scripts if the repo is a library
            __xsh_chmod_x_by_dir "./scripts"
        fi
    }

    # @private
    function __xsh_helps () {
        local lpur title_only
        local ln
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
            __xsh_help "${XSH_HOME}/xsh/xsh.sh"
            return
        fi

        while read ln; do
            if [[ -n ${ln} ]]; then
                type=$(__xsh_get_type_by_path "${ln}" | tr [:lower:] [:upper:])
                lpue=$(__xsh_get_lpue_by_path "${ln}")
                printf "[${type}] ${lpue}\n"

                if [[ -z ${title_only} ]]; then
                    __xsh_help "${ln}"
                fi
            fi
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
    }

    # @private
    function __xsh_help () {
        local path=$1
        local util lpue

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
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
    function __xsh_versions () {
        (cd "${xsh_home}/xsh" \
             && __xsh_git_get_all_tags
        )
    }

    # @private
    function __xsh_version () {
        (cd "${xsh_home}/xsh" \
             && __xsh_git_get_current_tag
        )
    }

    # @private
    function __xsh_list () {
        __xsh_helps -t '*'
    }

    # @private
    function __xsh_get_cfg_property () {
        local name=$1
        local property=$2

        if [[ -z ${name} ]]; then
            __xsh_log error "Lib or repo name is null or not set."
            return 255
        fi

        if [[ -z ${property} ]]; then
            __xsh_log error "Property name is null or not set."
            return 255
        fi

        local cfg

        if [[ -z ${name##*/*} ]]; then
            cfg="${xsh_repo_home}/${name}/xsh.lib"
        else
            cfg="${xsh_lib_home}/${name}/xsh.lib"
        fi

        if [[ ! -f ${cfg} ]]; then
            __xsh_log error "Not found xsh.lib at: ${cfg}."
            return 255
        fi

        awk -F= -v key="${property}" '{if ($1 == key) {print $2; exit}}' "${cfg}"
    }

    # @private
    function __xsh_get_lib_by_repo () {
        local repo=$1

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo is null or not set."
            return 255
        fi

        __xsh_get_cfg_property "${repo}" name
    }

    # @private
    # Library manager.
    #
    # Usage:
    #   __xsh_lib_manager REPO [unimport] [link] [unlink] [delete]
    #
    # Options:
    #   REPO             Git repo in syntax: `USERNAME/REPO`.
    #                    E.g. `username/xsh-lib-foo`
    #
    # Commands:
    #   [unimport]       unimport all imported utilities for the REPO.
    #   [link]           link the REPO as library.
    #   [unlink]         unlink the linked REPO.
    #   [delete]         delete the REPO.
    #
    #   The order of the commands matters.
    function __xsh_lib_manager () {
        local repo=$1
        shift

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        local repo_path="${xsh_repo_home}/${repo}"
        if [[ ! -d ${repo_path} ]]; then
            __xsh_log error "Repo doesn't exist at ${repo_path}."
            return 255
        fi

        local lib=$(__xsh_get_lib_by_repo "${repo}")
        if [[ -z ${lib} ]]; then
            __xsh_log error "library name is null for the repo ${repo}."
            return 255
        fi

        local lib_path="${xsh_lib_home}/${lib}"

        local ret
        while [[ $# -gt 0 ]]; do
            case $1 in
                unimport)
                    __xsh_unimport "${lib}/*"
                    ;;
                link)
                    ln -sf "${repo_path}" "${lib_path}"
                    ;;
                unlink)
                    /bin/rm -f "${lib_path}"
                    ;;
                delete)
                    /bin/rm -rf "${repo_path}"
                    ;;
                *)
                    return 255
                    ;;
            esac

            ret=$?
            if [[ ${ret} -ne 0 ]]; then
                __xsh_log error "Command failed: $1: ${ret}."
                return ${ret}
            fi

            shift
        done
    }

    # @private
    # Load a xsh library.
    #
    # Usage:
    #   __xsh_lib_load [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
    #
    # Options:
    #   [-s GIT_SERVER]  Git server URL.
    #                    E.g. `https://github.com`
    #   [-b BRANCH]      Load the BRANCH's latest state.
    #                    This option is for developers.
    #   [-t TAG]         Load a specific TAG version.
    #   REPO             Git repo in syntax: `USERNAME/REPO`.
    #                    E.g. `username/xsh-lib-foo`
    function __xsh_lib_load () {
        # get repo from last parameter
        local repo=${@:(-1)}

        __xsh_git_clone "$@" || return
        __xsh_lib_manager "${repo}" link
    }

    # @private
    # Unload a xsh library.
    #
    # Usage:
    #   __xsh_lib_unload REPO
    #
    # Options:
    #   REPO             Git repo in syntax: `USERNAME/REPO`.
    #                    E.g. `username/xsh-lib-foo`
    function __xsh_lib_unload () {
        local repo=$1

        __xsh_lib_manager "${repo}" unimport unlink delete
    }

    # @private
    # Update a loaded library.
    #
    # Usage:
    #   __xsh_lib_update [-b BRANCH | -t TAG] REPO
    #
    # Options:
    #   [-b BRANCH]      Update to the BRANCH's latest state.
    #                    This option is for developers.
    #   [-t TAG]         Update to a specific TAG version.
    #   REPO             Git repo in syntax: `USERNAME/REPO`.
    #                    E.g. `username/xsh-lib-foo`
    function __xsh_lib_update () {
        # get repo from last parameter
        local repo=${@:(-1)}

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        __xsh_lib_manager "${repo}" unimport unlink || return

        (cd "${xsh_repo_home}/${repo}" \
             && __xsh_git_force_update "$@"
        ) || return

        __xsh_lib_manager "${repo}" link
    }

    # @private
    # Update xsh itself.
    #
    # Usage:
    #   __xsh_upgrade [-b BRANCH | -t TAG]
    #
    # Options:
    #   [-b BRANCH]      Update to the BRANCH's latest state.
    #                    This option is for developers.
    #   [-t TAG]         Update to a specific TAG version.
    function __xsh_upgrade () {
        local repo_path="${xsh_home}/xsh"

        (cd "${repo_path}" \
             && __xsh_git_force_update "$@"
        ) || return

        source "${repo_path}/xsh.sh"
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
            __xsh_log error "LPUR is null or not set."
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
            __xsh_log error "LPU path is null or not set."
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
            __xsh_log error "LPU path is null or not set."
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
            __xsh_log error "LPUR is null or not set."
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
            __xsh_log error "LPU path is null or not set."
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
            __xsh_log error "LPU path is null or not set."
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
            __xsh_log error "LPUE is null or not set."
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
            __xsh_log error "LPUR is null or not set."
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
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        lpur=$(__xsh_complete_lpur "${lpur}")
        echo "${lpur%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_pur_by_lpur () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        lpur=$(__xsh_complete_lpur "${lpur}")
        echo "${lpur#*/}"  # remove lib part
    }

    # @private
    function __xsh_get_path_by_lpur () {
        local lpur=$1
        local lib pur

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        lib=$(__xsh_get_lib_by_lpur "${lpur}")
        pur=$(__xsh_get_pur_by_lpur "${lpur}")

        find -L "${xsh_lib_home}" \
             -path "${xsh_lib_home}/${lib}/functions/${pur}.sh" \
             -o \
             -path "${xsh_lib_home}/${lib}/functions/${pur}/*" \
             -name "*.sh" \
             -o \
             -path "${xsh_lib_home}/${lib}/scripts/${pur}.sh" \
             -o \
             -path "${xsh_lib_home}/${lib}/scripts/${pur}/*" \
             -name "*.sh" \
             2>/dev/null
    }

    # @private
    function __xsh_get_lpuc_by_lpur () {
        local lpur=$1
        local ln

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        while read ln; do
            __xsh_get_lpuc_by_path "${ln}"
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
    }

    # @private
    function __xsh_get_lpuc_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_log error "LPUE is null or not set."
            return 255
        fi

        lpue=$(__xsh_complete_lpur "${lpue}")
        echo "${lpue//\//-}"  # replace each / with -
    }

    # @private
    function __xsh_get_type_by_path () {
        local path=$1
        local type

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        type=${path#${xsh_lib_home}/*/}  # strip path from begin
        echo "${type%%/*}"  # strip path from end
    }

    # @private
    function __xsh_get_lib_by_path () {
        local path=$1
        local lib

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        lib=${path#${xsh_lib_home}/}  # strip path from begin
        echo "${lib%%/*}"  # remove anything after first / (include the /)
    }

    # @private
    function __xsh_get_util_by_path () {
        local path=$1
        local util

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
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
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        pue=${path#${xsh_lib_home}/*/*/}  # strip path from begin
        echo "${pue%.sh}"  # remove file extension
    }

    # @private
    function __xsh_get_lpue_by_path () {
        local path=${1:?}
        local lib pue

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
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
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        lpue=$(__xsh_get_lpue_by_path "${path}")
        __xsh_get_lpuc_by_lpue "${lpue}"
    }

    # @private
    # List all internal functions.
    function __xsh_get_internal_functions () {
        typeset -f xsh \
            | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}'
    }

    # @private
    # Clean env on xsh() returns.
    function __xsh_clean () {
        unset -f $(__xsh_get_internal_functions)

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
            __xsh_lib_load "${@:2}"
            ;;
        unload)
            __xsh_lib_unload "${@:2}"
            ;;
        update)
            __xsh_lib_update "${@:2}"
            ;;
        upgrade)
            __xsh_upgrade "${@:2}"
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
        version)
            __xsh_version
            ;;
        versions)
            __xsh_versions
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
