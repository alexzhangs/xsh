#? Description:
#?     xsh is an extension of Bash. It works as a Bash library framework.
#?
#? Usage:
#?     xsh <LPUE> [UTIL_OPTIONS]
#?     xsh calls <LPUE> [...]
#?     xsh import <LPUR> [...]
#?     xsh unimport <LPUR> [...]
#?     xsh list [LPUR]
#?     xsh load [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
#?     xsh unload REPO
#?     xsh update [-b BRANCH | -t TAG] REPO
#?     xsh upgrade [-b BRANCH | -t TAG]
#?     xsh debug [-enuvx] <FUNCTION | SCRIPT>
#?     xsh version
#?     xsh versions
#?     xsh help [-t] [-c] [-d] [-s SECTION] [BUILTIN | LPUR]
#?
#?     xsh log [debug|info|warning|error|fail|fatal] <MESSAGE>
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
#?     calls                Call utilities in a batch. No options can be passed.
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
#?     list                 List loaded libraries if no options passed.
#?         [LPUR]           List matched libraries, packages and utilities.
#?                          The syntax is the same with import.
#?
#?     load                 Load library from Git repo.
#?                          Without '-b' or '-t', it will load the latest tagged
#?                          version, if there's no any tagged version, returns error.
#?
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
#?     debug                Debug the called function or script.
#?         [-enuvx]         The same with shell options.
#?                          See `help set`.
#?                          Default is `-x`.
#?
#?     version              Show current xsh version.
#?
#?     versions             Show available xsh versions.
#?
#?     help                 Show help for xsh builtin functions or utilities.
#?         [-t]             Show the title.
#?                          This option can't be used with BUILTIN.
#?         [-c]             Show code.
#?         [-d]             Show entire document.
#?         [-s SECTION]     Show specific section of the document.
#?                          The section name is case sensitive.
#?                          This option can be used multi times.
#?         [BUILTIN]        xsh builtin function name without leading `__xsh_`.
#?                          Show help for xsh builtin functions.
#?         [LPUR]           LPUR.
#?                          Show help for matched utilities.
#?                          If unset, show help for xsh itself.
#?
#?         If both BUILTIN and LPUR unset, then show help for xsh itself.
#?         The options order matters to the output.
#?
#? Debug Mode:
#?     Enable debug mode by setting environment varaible: XSH_DEBUG
#?
#?     With debug mode enabled, set shell options: `-vx`.
#?     Debug mode is available only for the command started with `xsh`.
#?
#?     Values for XSH_DEBUG:
#?         1:      Debug current called xsh utility.
#?         <LPUR>: Debug matched xsh utilities.
#?
#?     Example:
#?         $ XSH_DEBUG=1 xsh /string/upper foo
#?
#?     This is for debugging xsh libraries.
#?     For general debugging purpose, see `xsh debug`.
#?
#? Dev Mode:
#?     Enable dev mode by setting environment varaible: XSH_DEV
#?
#?     With dev mode enabled, able to call the utilities from development library.
#?
#?     Values for XSH_DEV:
#?         1:      Call current called xsh utility from dev library.
#?         <LPUR>: Call matched xsh utilities from dev library.
#?
#?     Example:
#?         $ XSH_DEV=1 xsh /string/upper foo
#?
#?     The development library path is set by environment variable: XSH_DEV_HOME.
#?     In the XSH_DEV_HOME, the symbol links pointing to the repos must exist.
#?
#?     The dev mode is for developers to developing xsh libraries.
#?
function xsh () {

    #? Description:
    #?   Get the mime type of a file.
    #?
    #? Usage:
    #?   __xsh_mime_type <FILE> [...]
    #?
    #? Example:
    #?   $ __xsh_mime_type /usr/bin/command /bin/ls ~
    #?   text/x-shellscript
    #?   application/x-mach-binary
    #?   inode/directory
    #?
    function __xsh_mime_type () {
        /usr/bin/file -b --mime-type "$@"
    }

    #? Description:
    #?   Output the given shell options state.
    #?
    #? Usage:
    #?   __xsh_shell_option [OPTION_NAME][...]
    #?
    #? Example:
    #?   $ __xsh_shell_option vxhimBH
    #?   -himBH +vx
    #?
    function __xsh_shell_option () {
        local on=${-//[^$1]/}
        [[ -n $on ]] && on=-$on || :

        local off=${1//[$-]/}
        [[ -n $off ]] && off=+$off || :

        echo $on $off
    }


    #? Description:
    #?   Call a function or a script with specific shell options turning on.
    #?   The shell options will be restored afterwards.
    #?
    #? Usage:
    #?   __xsh_call_with_shell_option <OPTION> [...] <FUNCTION | SCRIPT>
    #?
    #? Options:
    #?   <OPTION>   The same with shell options.
    #?              See `help set`.
    #?
    #? Example:
    #?   $ __xsh_call_with_shell_option -v -x echo $HOME
    #?
    function __xsh_call_with_shell_option () {
        local OPTIND OPTARG opt

        local options

        while getopts abefhkmnptuvxBCHP opt; do
            case ${opt} in
                [abefhkmnptuvxBCHP])
                    options=${options}${opt}
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))

        # save former state of options
        local exopts=$(__xsh_shell_option "${options}")
        local ret=0

        if [[ $(type -t "$1") == file &&
                  $(__xsh_mime_type "$(which "$1")" | cut -d/ -f1) == text ]]; then
            # call script with shell options enabled
            bash -${options} "$(which "$1")" "${@:2}" || ret=$?
            return ${ret}
        fi

        # enable shell options
        set -${options}

        # call function
        "$@" || ret=$?

        # restore state of shell options
        set ${exopts}  # do not double quote the parameter

        return ${ret}
    }

    #? Description:
    #?   Enable debug mode for the called function or script.
    #?
    #? Usage:
    #?   __xsh_debug [-enuvx] <FUNCTION | SCRIPT>
    #?
    #? Options:
    #?   [-enuvx]   The same with shell options.
    #?              See `help set`.
    #?
    #?   If no option given, `-x` is set as default.
    #?
    function __xsh_debug () {
        if [[ ${1:0:1} != - ]]; then
            set -- -x "$@"
        fi

        __xsh_call_with_shell_option "$@"
    }

    #? Description:
    #?   Count the number of given function name in ${FUNCNAME[@]}
    #?
    #? Usage:
    #?   __xsH_count_in_funcstack <FUNCNAME>
    #?
    function __xsh_count_in_funcstack () {
        printf '%s\n' "${FUNCNAME[@]}" \
            | grep -c "^${1}$"
    }

    #? Description:
    #?   Fire the command on the RETURN signal of function `xsh`.
    #?   The trapped command is cleared after it's fired once.
    #?
    #? Usage:
    #?   __xsh_trap_return [COMMAND]
    #?
    function __xsh_trap_return () {
        local command="
        if [[ \$FUNCNAME == xsh ]]; then
            trap - RETURN
            ${1:?}
        fi;"
        trap "$command" RETURN
    }

    # call __xsh_clean() while xsh() returns
    # clean env if reaching the final exit point of xsh
    __xsh_trap_return '
            if [[ $(__xsh_count_in_funcstack xsh) -eq 1 ]]; then
                __xsh_clean >/dev/null 2>&1
            fi;'

    #? Description:
    #?   Log message to stdout/stderr.
    #?
    #? Usage:
    #?   __xsh_log [debug|info|warning|error|fail|fatal] <MESSAGE>
    #?
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

    local xsh_home

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


    #? Description:
    #?   chmod +x all .sh regular files under the given dir.
    #?
    #? Usage:
    #?   __xsh_chmod_x_by_dir <PATH>
    #?
    function __xsh_chmod_x_by_dir () {
        local path=$1

        find "${path}" \
             -type f \
             -name "*.sh" \
             -exec chmod +x {} \;
    }

    #? Description:
    #?   chmod +x all .sh regular files under `./scripts`.
    #?
    #? Usage:
    #?   __xsh_git_chmod_x
    #?
    function __xsh_git_chmod_x () {
        if [[ -d ./scripts ]]; then
            __xsh_chmod_x_by_dir ./scripts
        fi
    }

    #? Description:
    #?   Discard all local changes and untracked files.
    #?
    #? Usage:
    #?   __xsh_git_discard_all
    #?
    function __xsh_git_discard_all () {
        git reset --hard \
            && git clean -d --force
    }

    #? Description:
    #?   Get all tags.
    #?
    #? Usage:
    #?   __xsh_git_get_all_tags
    #?
    function __xsh_git_get_all_tags () {
        git tag --list
    }

    #? Description:
    #?   Fetch remote tags to local.
    #?
    #? Usage:
    #?   __xsh_git_fetch_remote_tags
    #?
    function __xsh_git_fetch_remote_tags () {
        # remove local tags that don't exist on remote
        __xsh_git_get_all_tags | xargs git tag --delete
        git fetch --tags
    }

    #? Description:
    #?   Get the tag current on.
    #?
    #? Usage:
    #?   __xsh_git_get_current_tag
    #?
    function __xsh_git_get_current_tag () {
        git describe --tags
    }

    #? Description:
    #?   Get the latest tag
    #?
    #? Usage:
    #?   __xsh_git_get_latest_tag
    #?
    function __xsh_git_get_latest_tag () {
        __xsh_git_get_all_tags | sed -n '$p'
    }

    #? Description:
    #?   Check if the work directory is dirty.
    #?
    #? Usage:
    #?   __xsh_git_is_workdir_dirty
    #?
    function __xsh_git_is_workdir_dirty () {
        test -n "$(git status -s)"
    }

    #? Description:
    #?   Get current branch.
    #?   Output 'HEAD' if detached at a tag.
    #?
    #? Usage:
    #?   __xsh_git_get_current_branch
    #?
    function __xsh_git_get_current_branch () {
        git rev-parse --abbrev-ref HEAD
    }

    #? Description:
    #?   Clone a Git repo.
    #?
    #? Usage:
    #?   __xsh_git_clone [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
    #?
    #? Options:
    #?   [-s GIT_SERVER]  Git server URL.
    #?                    E.g. `https://github.com`
    #?   [-b BRANCH]      Clone the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Clone a specific TAG version.
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
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
                    git_options[${#git_options[@]}]=-${opt}
                    git_options[${#git_options[@]}]=${OPTARG}
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

        git clone "${git_server}/${repo}" "${repo_path}"

        # update to latest tagged version
        (cd "${repo_path}" \
             && __xsh_git_force_update "${git_options[@]}" \
             && __xsh_git_chmod_x
        )

        local ret=$?
        if [[ ${ret} -ne 0 ]]; then
            __xsh_log warning "Deleting repo ${repo_path}."
            /bin/rm -rf "${repo_path}"
            return ${ret}
        fi
    }

    #? Description:
    #?   Update current repo.
    #?   Any local changes will be DISCARDED after update.
    #?   Any untracked files will be REMOVED after update.
    #?
    #? Usage:
    #?   __xsh_git_force_update [-b BRANCH | -t TAG]
    #?
    #? Options:
    #?   [-b BRANCH]      Update to the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Update to a specific TAG version.
    #?
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

        if __xsh_git_is_workdir_dirty; then
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

        if [[ $(__xsh_git_get_current_branch) != 'HEAD' ]]; then
           git pull
        fi

        if [[ $? -ne 0 ]]; then
            __xsh_log error "Failed to update repo."
            return 255
        fi
    }

    #? Description:
    #?   Show help for xsh builtin functions or utilities.
    #?
    #? Usage:
    #?   __xsh_help [-t] [-c] [-d] [-s SECTION [...]] [BUILTIN | LPUR]
    #?
    #? Options:
    #?   [-t]             Show title.
    #?                    This option can't be used with BUILTIN.
    #?   [-c]             Show code.
    #?   [-d]             Show entire document.
    #?   [-s SECTION]     Show specific section of the document.
    #?                    The section name is case sensitive.
    #?                    This option can be used multi times.
    #?   [BUILTIN]        xsh builtin function name without leading `__xsh_`.
    #?                    Show help for xsh builtin functions.
    #?   [LPUR]           LPUR.
    #?                    Show help for matched utilities.
    #?
    #?   If both BUILTIN and LPUR unset, then show help for xsh itself.
    #?   The options order matters to the output.
    #?
    function __xsh_help () {
        local OPTIND OPTARG opt

        declare -a options
        while getopts tcds: opt; do
            case ${opt} in
                t|c|d)
                    options[${#options[@]}]=-${opt}
                    ;;
                s)
                    options[${#options[@]}]=-${opt}
                    options[${#options[@]}]=${OPTARG}
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))

        if [[ ${#options[@]} -eq 0 ]]; then
            options=-d
        fi

        local topic=$1
        if [[ -z ${topic} ]]; then
            __xsh_info "${options[@]}" "${xsh_home}/xsh/xsh.sh"
            return
        fi

        if [[ $(type -t "__xsh_${topic}") == function ]]; then
            __xsh_info -f "__xsh_${topic}" "${options[@]}" "${xsh_home}/xsh/xsh.sh"
        fi

        local ln
        while read ln; do
            if [[ -n ${ln} ]]; then
                __xsh_info "${options[@]}" "${ln}"
            fi
        done <<< "$(__xsh_get_path_by_lpur "${topic}")"
    }

    #? Description:
    #?   Show specific info for xsh builtin functions or utilities.
    #?
    #? Usage:
    #?   __xsh_info [-f NAME] [-t] [-c] [-d] [-s SECTION [...]] PATH
    #?
    #? Options:
    #?   [-f NAME]        Get info for this function name rather than the one in path.
    #?                    This option is valid only with `-d` and `-s`, else it's ignored.
    #?   [-t]             Show title.
    #?                    This option can't be used with BUILTIN.
    #?   [-c]             Show code.
    #?   [-d]             Show entire document.
    #?   [-s SECTION]     Show specific section of the document.
    #?                    The section name is case sensitive.
    #?                    This option can be used multi times.
    #?   PATH             Path to the scripts file.
    #?
    #?   The util name appearing in the doc in syntax `@<UTIL>` will be replaced
    #?   as the full util name.
    #?   The options order matters to the output.
    #?
    function __xsh_info () {
        local OPTIND OPTARG opt

        local path=${@:(-1)}

        if [[ -z ${path} || ${path:1:1} == - ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        local util lpue
        util=$(__xsh_get_util_by_path "${path}")
        lpue=$(__xsh_get_lpue_by_path "${path}")

        if [[ -z ${util} ]]; then
            __xsh_log error "util is null: %s." "${path}"
            return 255
        fi

        if [[ -z ${lpue} ]]; then
            __xsh_log error "lpue is null: %s." "${path}"
            return 255
        fi

        local funcname

        while getopts f:tcds: opt; do
            case ${opt} in
                f)
                    funcname=${OPTARG}
                    ;;
                t)
                    local type=$(__xsh_get_type_by_path "${path}")

                    if [[ -z ${type} ]]; then
                        __xsh_log error "type is null: %s." "${path}"
                        return 255
                    fi

                    printf "[%s] %s\n" "${type}" "${lpue}"
                    ;;
                d)
                    awk -v util=${util} -v fname=${funcname} \
                        '{
                            if (flag == 1 && $1 == "function" && $2 == (fname?fname:util)) {
                                for (j=0;j<=i;j++) print a[j]
                                exit
                            }
                            if ($1 == "#?") {
                                a[i++] = $0
                                flag = 1
                            } else {
                                i = flag = 0
                                delete a
                            }
                        }' "${path}" \
                            | sed -e 's/[ ]*#? //' \
                                  -e 's/[ ]*#?//' \
                                  -e "s|@${util}|xsh ${lpue}|g"
                    ;;
                c)
                    sed '/^#?/d' "${path}"
                    ;;
                s)
                    __xsh_info -f "${funcname}" -d "${path}" \
                        | sed -n "/^${OPTARG}/,/^[^ ]/p" \
                        | sed '$d'
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
    }

    #? Description:
    #?   Show a list of xsh versions.
    #?
    #? Usage:
    #?   __xsh_versions
    #?
    function __xsh_versions () {
        (cd "${xsh_home}/xsh" \
             && __xsh_git_get_all_tags
        )
    }

    #? Description:
    #?   Show current version of xsh.
    #?
    #? Usage:
    #?   __xsh_version
    #?
    function __xsh_version () {
        (cd "${xsh_home}/xsh" \
             && __xsh_git_get_current_tag
        )
    }

    #? Description:
    #?   Show a list of xsh libraries.
    #?   If the LPUR is given, show a list of matching utils.
    #?
    #? Usage:
    #?   __xsh_list [LPUR]
    #?
    function __xsh_list () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_lib_list
        else
            __xsh_help -t "${lpur}"
        fi
    }

    #? Description:
    #?   Get specific property of `xsh.lib` of a lib or repo.
    #?
    #? Usage:
    #?   __xsh_get_cfg_property <LIB | REPO> <PROPERTY>
    #?
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

    #? Description:
    #?
    #?
    #? Usage:
    #?
    #?
    function __xsh_get_lib_by_repo () {
        local repo=$1

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo is null or not set."
            return 255
        fi

        __xsh_get_cfg_property "${repo}" name
    }

    #? Description:
    #?   List loaded libraries with version.
    #?
    #? Usage:
    #?   __xsh_lib_list
    #?
    function __xsh_lib_list () {
        local lib lib_path repo version

        while read lib_path; do
            lib=${lib_path##*/}
            version=$(cd "${lib_path}" && __xsh_git_get_current_tag)
            repo=$(readlink "${lib_path}" \
                       | awk -F/ '{print $(NF-1) FS $NF}')

            printf '%s (%s) => %s\n' "${lib}" "${version:-latest}" "${repo}"
        done <<< "$(find "${xsh_lib_home}" -type l -maxdepth 1)"
    }

    #? Description:
    #?   Library manager.
    #?
    #? Usage:
    #?   __xsh_lib_manager REPO [unimport] [link] [unlink] [delete]
    #?
    #? Options:
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    #? Commands:
    #?   [unimport]       unimport all imported utilities for the REPO.
    #?   [link]           link the REPO as library.
    #?   [unlink]         unlink the linked REPO.
    #?   [delete]         delete the REPO.
    #?
    #?   The order of the commands matters.
    #?
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

    #? Description:
    #?   Load library from Git repo.
    #?   Without '-b' or '-t', it will load the latest tagged
    #?   version, if there's no any tagged version, returns error.
    #?
    #? Usage:
    #?   __xsh_load [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
    #?
    #? Options:
    #?   [-s GIT_SERVER]  Git server URL.
    #?                    E.g. `https://github.com`
    #?   [-b BRANCH]      Load the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Load a specific TAG version.
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_load () {
        # get repo from last parameter
        local repo=${@:(-1)}

        __xsh_git_clone "$@" || return
        __xsh_lib_manager "${repo}" link
        local ret=$?
        if [[ ${ret} -ne 0 ]]; then
            __xsh_log warning "Deleting repo ${repo_path}."
            rm -rf "${xsh_repo_home}/${repo}"
            return ${ret}
        fi
    }

    #? Description:
    #?   Unload a xsh library.
    #?
    #? Usage:
    #?   __xsh_unload REPO
    #?
    #? Options:
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_unload () {
        local repo=$1

        __xsh_lib_manager "${repo}" unimport unlink delete
    }

    #? Description:
    #?   Update a loaded library.
    #?
    #? Usage:
    #?   __xsh_update [-b BRANCH | -t TAG] REPO
    #?
    #? Options:
    #?   [-b BRANCH]      Update to the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Update to a specific TAG version.
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_update () {
        # get repo from last parameter
        local repo=${@:(-1)}

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        __xsh_lib_manager "${repo}" unimport unlink || return

        (cd "${xsh_repo_home}/${repo}" \
             && __xsh_git_force_update "$@" \
             && __xsh_git_chmod_x
        ) || return

        __xsh_lib_manager "${repo}" link
    }

    #? Description:
    #?   Update xsh itself.
    #?
    #? Usage:
    #?   __xsh_upgrade [-b BRANCH | -t TAG]
    #?
    #? Options:
    #?   [-b BRANCH]      Update to the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Update to a specific TAG version.
    #?
    function __xsh_upgrade () {
        local repo_path="${xsh_home}/xsh"

        (cd "${repo_path}" \
             && __xsh_git_force_update "$@" \
             && __xsh_git_chmod_x
        ) || return

        source "${repo_path}/xsh.sh"
    }

    #? Description:
    #?   Apply init files under the given library path, start from library root.
    #?   For example: `__xsh_init /home/user/.xsh/lib/x/string` will try to
    #?   apply following init files if they present.
    #?
    #?     * /home/user/.xsh/lib/x/__init__.sh
    #?     * /home/user/.xsh/lib/x/string/__init__.sh
    #?
    #?   Previously applied init files will be skipped.
    #?
    #?   A global environment variable `__XSH_INIT__` is used to track all
    #?   applied init files.
    #?
    #? Usage:
    #?   __xsh_init <DIR>
    #?
    function __xsh_init () {
        local dir=$1

        local scope=${dir#${xsh_lib_home}}  # remove xsh_lib_home path from beginning

        # remove the leading `/`
        scope=${scope%/}
        # remove the tailing `/`
        scope=${scope#/}

        if [[ -z ${scope} ]]; then
            __xsh_log ERROR "Found empty init scope for dir: ${dir}"
            return 255
        fi

        local ln init_subdir
        while read ln; do
            if [[ -z ${init_subdir} ]]; then
                init_subdir=${ln}
            else
                init_subdir="${init_subdir}/${ln}"
            fi

            local init_file="${xsh_lib_home}/${init_subdir}/__init__.sh"

            if [[ -f ${init_file} ]]; then
                # replace all `/` to `-`
                local init_expr=${init_subdir//\//-}

                if [[ -z $(xsh /array/search __XSH_INIT__ "${init_expr}") ]]; then
                    # apply the init file
                    source "${init_file}"

                    # remember the applied init file
                    __XSH_INIT__[${#__XSH_INIT__[@]}]=${init_expr}
                fi
            fi
        done <<< "$(echo "${scope//\//$'\n'}")"  # replace all `/` to newline
    }

    #? Description:
    #?   Import the matching utilities by a list of LPUR.
    #?
    #? Usage:
    #?   __xsh_imports [LPUR] [...]
    #?
    function __xsh_imports () {
        local lpur
        local ret=0

        for lpur in "$@"; do
            __xsh_import "${lpur}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    #? Description:
    #?   Import the matching utilities for LPUR.
    #?   The functions are sourced, and the scripts are linked at /usr/local/bin.
    #?
    #? Usage:
    #?   __xsh_import <LPUR>
    #?
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
            if [[ -n ${ln} ]]; then
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
            fi
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
    }

    #? Description:
    #?   Source a file like `.../<lib>/functions/<package>/<util>.sh`
    #?   as function `<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_import_function <FILE>
    #?
    function __xsh_import_function () {
        local path=$1
        local util lpuc

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        util=$(__xsh_get_util_by_path "${path}")
        lpuc=$(__xsh_get_lpuc_by_path "${path}")

        # apply init files
        __xsh_init "${path%/*}"

        # source the function
        source /dev/stdin <<< "$(sed "s/function ${util} ()/function ${lpuc} ()/g" "${path}")"
    }

    #? Description:
    #?   Link a file like `.../<lib>/scripts/<package>/<util>.sh`
    #?   as `/usr/local/bin/<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_import_script <FILE>
    #?
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

    #? Description:
    #?   Un-import the matching utilities by a list of LPUR.
    #?
    #? Usage:
    #?   __xsh_unimports [LPUR] [...]
    #?
    function __xsh_unimports () {
        local lpur
        local ret=0

        for lpur in "$@"; do
            __xsh_unimport "${lpur}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    #? Description:
    #?   Un-import the matching utilities for LPUR.
    #?   The sourced functions are unset, and the linked scripts are unlinked.
    #?
    #? Usage:
    #?   __xsh_unimport <LPUR>
    #?
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
            if [[ -n ${ln} ]]; then
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
            fi
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
    }

    #? Description:
    #?   Source a file like `.../<lib>/functions/<package>/<util>.sh`
    #?   and unset the function by name `<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_unimport_function <FILE>
    #?
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

    #? Description:
    #?   Unlink a file like `.../<lib>/scripts/<package>/<util>.sh`
    #?   at `/usr/local/bin/<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_unimport_script <FILE>
    #?
    function __xsh_unimport_script () {
        local path=$1
        local lpuc

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        rm -f "/usr/local/bin/${lpuc}"

        # forget remembered commands locations
        hash -r
    }

    #? Description:
    #?   Call utilities in a batch. No options can be passed.
    #?
    #? Usage:
    #?   __xsh_calls <LPUE> [...]
    #?
    function __xsh_calls () {
        local lpue
        local ret=0

        for lpue in "$@"; do
            __xsh_call "${lpue}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    #? Description:
    #?   Call a function or a script by LPUE.
    #?   `XSH_DEV` and `XSH_DEBUG` are being handled.
    #?
    #? Usage:
    #?   __xsh_call <LPUE> [OPTIONS]
    #?
    function __xsh_call () {
        # legal input:
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_log error "LPUE is null or not set."
            return 255
        fi

        local lpuc=$(__xsh_get_lpuc_by_lpue "${lpue}")

        if [[ -n ${XSH_DEV} ]]; then
            if [[ -z ${XSH_DEV_HOME} ]]; then
                __xsh_log error "XSH_DEV_HOME is not set properly."
                return 255
            fi

            local xsh_dev
            case ${XSH_DEV} in
                1)
                    xsh_dev=${lpuc}
                    ;;
                *)
                    xsh_dev=$(
                        # set xsh_lib_home within sub shell
                        xsh_lib_home=${XSH_DEV_HOME}
                        __xsh_get_lpuc_by_lpur "${XSH_DEV}")
                    ;;
            esac

            if grep -q "^${lpuc}$" <(echo "${xsh_dev}"); then
                # force to import and unimport dev util
                xsh_lib_home=${XSH_DEV_HOME} __xsh_exec -i -u "${lpue}" "${@:2}"
                return
            fi
        fi

        __xsh_exec "${lpue}" "${@:2}"
    }

    #? Description:
    #?   Call a function or a script by LPUE.
    #?   `XSH_DEBUG` is being handled.
    #?
    #? Usage:
    #?   __xsh_exec [-i] [-u] <LPUE>
    #?
    #? Options:
    #?   [-i]   Import the util before the execution no matter if it's available.
    #?   [-u]   Unimport the util after the execution.
    #?
    function __xsh_exec () {
        local OPTIND OPTARG opt

        local import=0 unimport=0
        while getopts iu opt; do
            case ${opt} in
                i)
                    import=1
                    ;;
                u)
                    unimport=1
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_log error "LPUE is null or not set."
            return 255
        fi

        local lpuc=$(__xsh_get_lpuc_by_lpue "${lpue}")

        if [[ ${import} -eq 1 ]]; then
            __xsh_import "${lpue}"
        elif ! type -t "${lpuc}" >/dev/null 2>&1; then
            __xsh_import "${lpue}"
        fi

        local ret=0

        if [[ -n ${XSH_DEBUG} ]]; then
            local xsh_debug

            case ${XSH_DEBUG} in
                1)
                    xsh_debug=${lpuc}
                    ;;
                *)
                    xsh_debug=$(__xsh_get_lpuc_by_lpur "${XSH_DEBUG}")
                    ;;
            esac

            if grep -q "^${lpuc}$" <(echo "${xsh_debug}"); then
                __xsh_call_with_shell_option -vx "${lpuc}" "${@:2}" || ret=$?
            else
                ${lpuc} "${@:2}" || ret=$?
            fi
        else
            ${lpuc} "${@:2}" || ret=$?
        fi

        if [[ ${unimport} -eq 1 ]]; then
            __xsh_unimport "${lpue}"
        fi

        return ${ret}
    }

    #? Description:
    #?   Complete a LPUR.
    #?
    #? Usage:
    #?   __xsh_complete_lpur <LPUR>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lib_by_lpur <LPUR>
    #?
    function __xsh_get_lib_by_lpur () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        lpur=$(__xsh_complete_lpur "${lpur}")
        echo "${lpur%%/*}"  # remove anything after first / (include the /)
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_pur_by_lpur <LPUR>
    #?
    function __xsh_get_pur_by_lpur () {
        local lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        lpur=$(__xsh_complete_lpur "${lpur}")
        echo "${lpur#*/}"  # remove lib part
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_path_by_lpur <LPUR>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpuc_by_lpur <LPUR>
    #?
    function __xsh_get_lpuc_by_lpur () {
        local lpur=$1
        local ln

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        while read ln; do
            if [[ -n ${ln} ]]; then
                __xsh_get_lpuc_by_path "${ln}"
            fi
        done <<< "$(__xsh_get_path_by_lpur "${lpur}")"
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpuc_by_lpue <LPUE>
    #?
    function __xsh_get_lpuc_by_lpue () {
        local lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_log error "LPUE is null or not set."
            return 255
        fi

        lpue=$(__xsh_complete_lpur "${lpue}")
        echo "${lpue//\//-}"  # replace each / with -
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_type_by_path <PATH>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lib_by_path <PATH>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_util_by_path <PATH>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_pue_by_path <PATH>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpue_by_path <PATH>
    #?
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

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpuc_by_path <PATH>
    #?
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

    #? Description:
    #?   List all xsh internal functions.
    #?
    #? Usage:
    #?   __xsh_get_internal_functions
    #?
    function __xsh_get_internal_functions () {
        typeset -f xsh \
            | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}'
    }

    #? Description:
    #?   Clean environment on xsh() returns.
    #?
    #? Usage:
    #?   __xsh_clean
    #?
    function __xsh_clean () {
        unset -f $(__xsh_get_internal_functions)
    }

    # Check input
    if [[ -z $1 ]]; then
        __xsh_help >&2
        return 255
    fi

    # Main
    if [[ $(type -t "__xsh_$1") == function ]]; then
        # xsh command and builtin function
        __xsh_$1 "${@:2}"
    else
        __xsh_call "$1" "${@:2}"
    fi
}
export -f xsh
