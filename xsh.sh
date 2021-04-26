#? Description:
#?   xsh is an extension of Bash. It works as a Bash library framework.
#?
#? Usage:
#?   xsh <LPUE> [UTIL_OPTIONS]
#?
#? Option:
#?   <LPUE>           Call an individual utility.
#?   [UTIL_OPTIONS]   Will be passed to utility.
#?
#?   The library of the utility must be loaded first.
#?
#? Builtin:
#?   All xsh builtin functions are available without the prefix: `__xsh_`.
#?   For example, the builtin function `__xsh_lib_dev_manager` can be called as
#?   the syntax: `xsh lib_dev_manager` or `xsh lib-dev-manager`.
#?
#?   If there's naming conflict between the builtin functions and the library
#?   utilities, The builtin functions take precedence over the library utilities.
#?
#? Convention:
#?   LPUE             LPUE stands for `Lib/Package/Util Expression`.
#?                    The LPUE syntax is: `[LIB][/PACKAGE]/UTIL`.
#?                    An LPUE is also an special LPUR.
#?
#?                    Example:
#?
#?                    <lib>/<pkg>/<util>, /<pkg>/<util>
#?                    <lib>/<util>, /<util>
#?
#?   LPUR             LPUR stands for `Lib/Package/Util Regex`.
#?                    The LPUR syntax is: `[LIB][/PACKAGE][/UTIL]`.
#?
#?                    Example:
#?
#?                    '*'
#?                    /, <lib>
#?                    <lib>/<pkg>, /<pkg>
#?                    <lib>/<pkg>/<util>, /<pkg>/<util>
#?                    <lib>/<util>, /<util>
#?
#? Debug Mode:
#?   With the debug mode enabled, the shell options: `-vx` is set for the
#?   debugging utilities.
#?   The debug mode is available only for the commands started with `xsh`.
#?
#?   Enable the debug mode by setting an environment variable: `XSH_DEBUG` before
#?   the command `xsh`.
#?
#?   Values for XSH_DEBUG:
#?       1     : Enable the debug mode for whatever the LPUE input by `xsh`.
#?               e.g: XSH_DEBUG=1 xsh /string/upper foo
#?
#?       <LPUR>: Enabled the debug mode for the LPUE input by `xsh` if the
#?               LPUE equals to or matches the <LPUR> set by XSH_DEBUG.
#?               e.g: XSH_DEBUG=/string xsh /string/upper foo
#?               e.g: XSH_DEBUG=/string/pipe/upper xsh /string/upper foo
#?
#?   The debug mode applies to the following commands and internal functions:
#?       * calls
#?       * call, exec
#?
#?   The debug mode is for debugging xsh libraries.
#?   For the general debugging purpose, use `xsh debug`, see `xsh help debug`.
#?
#? Dev Mode:
#?   The dev mode is for developers to develop xsh libraries.
#?   With the dev mode enabled, the utilities from the development library will
#?   be used rather than those from the normal library.
#?   The dev mode is available only for the commands started with `xsh`.
#?
#?   Before using the dev mode, you need to create symbol links for the
#?   libraries that need to use dev mode, put the symbol links in the directory
#?   `~/.xsh/lib-dev`, and point them to your development workspaces.
#?   This can be done with the command: `xsh lib-dev-manager link ...`, and be
#?   undone with the command `xsh lib-dev-manager unlink ...`.
#?
#?   Then the dev mode is ready to use.
#?   Enable the dev mode by setting an environment variable: `XSH_DEV` before the
#?   command `xsh`.
#?
#?   Values for XSH_DEV:
#?       1     : Enable the dev mode for whatever the LPUE or LPUR input by `xsh`.
#?               e.g: XSH_DEV=1 xsh /string/upper foo
#?                    XSH_DEV=1 xsh import /string
#?                    XSH_DEV=1 xsh list
#?
#?       <LPUR>: Enabled the dev mode for the LPUE or LPUR input by `xsh` if the
#?               LPUE/LPUR equals to or matches the <LPUR> set by XSH_DEV.
#?               e.g: XSH_DEV=/string xsh import /string
#?               e.g: XSH_DEV=/string xsh help /string/upper
#?               e.g: XSH_DEV=/string/pipe/upper xsh /string/upper foo
#?               Be noted, the following usage won't work as expected:
#?               e.g: XSH_DEV=/string xsh import /
#?
#?   The dev mode applies to the following commands and internal functions:
#?       * calls, imports, unimports, list, help
#?       * call, import, unimport, lib_list, help_lib
#?
function xsh () {

    #? Description:
    #?   Get the mime type of a file.
    #?   A wrapper of `file -b --mime-type`, with enhancements:
    #?     * Only output the first line of the result.
    #?       e.g: file /bin/ls (version file-5.39)
    #?     * If the file does not exist, cannot be read, then send output to stderr.
    #?
    #? Usage:
    #?   __xsh_mime_type <FILE> [...]
    #?
    #? Option:
    #?   <FILE>          Path to the file.
    #?
    #? Example:
    #?   $ __xsh_mime_type /dev/null /bin/ls ~
    #?   inode/chardevice
    #?   application/x-mach-binary
    #?   inode/directory
    #?
    function __xsh_mime_type () {
        declare mime_type f fd

        for f in "$@"; do
            fd=1 # set default fd to stdout
            mime_type=$(/usr/bin/file -b --mime-type "${f}")

            # get the first line
            mime_type=${mime_type%%$'\n'*}
            if [[ ${mime_type} =~ 'No such file or directory' ]]; then
                # set fd to stderr
                fd=2
            fi
            printf '%s\n' "${mime_type}" >&${fd}
        done
    }

    #? Description:
    #?   Output the current state of given shell options.
    #?   Any options setter `[+-]` before the option is ignored.
    #?
    #? Usage:
    #?   __xsh_shell_option [OPTION][ ][...]
    #?
    #? Option:
    #?   [OPTION]         The syntax is `[+-]NAME`.
    #?                    See the allowed names in `help set`.
    #?
    #? Example:
    #?   $ __xsh_shell_option himBH +v -x
    #?   -himBH +vx
    #?
    function __xsh_shell_option () {
        # set IFS in local
        declare IFS=$''
        # squash all the arguments without whitespaces, `+`, and `-`
        declare testing="${*//[ +-]}"

        # remove all the shell options that are not in the testing list from the turned on shell options `$-`
        # and prefix the `-`
        declare on="-${-//[^${testing:-.}]}"

        # remove all the shell options that are turned on from the testing list
        # and prefix the `+`
        declare off="+${testing//[$-]}"

        # remove the `+` and `-` if there's no any shell option
        # do not double quote the variables
        # shellcheck disable=SC2086
        echo ${on%-} ${off%+}
    }


    #? Description:
    #?   Call a function or a script with specific shell options.
    #?   The shell options will be restored afterwards.
    #?
    #? Usage:
    #?   __xsh_call_with_shell_option [-1 OPTION] [-0 OPTION] [...] <FUNCTION | SCRIPT>
    #?
    #? Option:
    #?   [-1 OPTION]      Turn on followed options.
    #?   [-0 OPTION]      Turn off followed options.
    #?
    #?   OPTION           The same with shell options.
    #?                    See `help set`.
    #?
    #? Example:
    #?   $ __xsh_call_with_shell_option -1 vx echo $HOME
    #?
    function __xsh_call_with_shell_option () {
        declare -a options
        declare OPTIND OPTARG opt

        while getopts 1:0: opt; do
            case ${opt} in
                1)
                    options+=(-"${OPTARG}")
                    ;;
                0)
                    options+=(+"${OPTARG}")
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))

        declare mime_type ret=0
        mime_type=$(__xsh_mime_type "$(command -v "$1")" 2>/dev/null)

        if [[ $(type -t "$1" || :) == file && ${mime_type%%/*} == text ]]; then
            # call script with shell options enabled
            bash "${options[@]}" "$(command -v "$1")" "${@:2}"
            ret=$?
        else
            # save former state of options
            declare exopts
            exopts=$(__xsh_shell_option "${options[@]}")

            # enable shell options
            set "${options[@]}"

            # call function
            "$@"
            ret=$?

            # restore state of shell options
            # shellcheck disable=SC2086
            set ${exopts}  # do not double quote the parameter
        fi

        return ${ret}
    }

    #? Description:
    #?   Enable debug mode for the called function or script.
    #?
    #? Usage:
    #?   __xsh_debug [-1 OPTION] [-0 OPTION] [...] <FUNCTION | SCRIPT>
    #?
    #? Option:
    #?   [-1 OPTION]      Turn on the followed options.
    #?   [-0 OPTION]      Turn off the followed options.
    #?
    #?   OPTION           The same with shell options.
    #?                    See `help set`.
    #?
    #?   If no option given, `-1 x` is set as default.
    #?
    #? Example:
    #?   $ __xsh_debug foo_func
    #?   $ __xsh_debug bar_script.sh
    #?
    function __xsh_debug () {
        if [[ ${1:0:1} != - ]]; then
            # prepend `-1 x` to $@
            set -- -1 x "$@"
        fi

        __xsh_call_with_shell_option "$@"
    }

    #? Description:
    #?   Count the number of given function name in ${FUNCNAME[@]}
    #?
    #? Usage:
    #?   __xsh_count_in_funcstack <FUNCNAME>
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
        declare command="
        if [[ \${FUNCNAME} == xsh ]]; then
            trap - RETURN
            ${1:?}
        fi;"
        # shellcheck disable=SC2064
        trap "${command}" RETURN
    }

    #? Description:
    #?   Log message to stdout/stderr.
    #?
    #? Usage:
    #?   __xsh_log [debug|info|warning|error|fail|fatal] <MESSAGE>
    #?
    function __xsh_log () {
        declare level
        level=$(echo "$1" | tr "[:lower:]" "[:upper:]")

        declare caller
        if [[ ${FUNCNAME[1]} == xsh && ${#FUNCNAME[@]} -gt 2 ]]; then
            caller=${FUNCNAME[2]}
        else
            caller=${FUNCNAME[1]}
        fi

        case ${level} in
            WARNING|ERROR|FAIL|FATAL)
                printf "${caller}: ${level}: %s\n" "${*:2}" >&2
                ;;
            DEBUG|INFO)
                printf "${caller}: ${level}: %s\n" "${*:2}"
                ;;
            *)
                printf "${caller}: %s\n" "$*"
                ;;
        esac
    }

    #? Description:
    #?   Compare two versions.
    #?   The version format is like `X.Y.Z`.
    #?
    #? Usage:
    #?   __xsh_version_comparator <VER1> <VER2>
    #?
    #? Output:
    #?   0: VER1 == VER2
    #?   1: VER1 > VER2
    #?   2: VER1 < VER2
    #?
    function __xsh_version_comparator () {
        if [[ $1 == "$2" ]]; then
            echo 0
            return
        fi
        # don't double quote `$1` and `$2`
        # shellcheck disable=SC2206
        declare -a ver1=( ${1//./ } ) ver2=( ${2//./ } )
        declare n1=${#ver1[@]} n2=${#ver2[@]} index
        for (( index = 0; index <= $((n1 > n2 ? n1 : n2)); index++ )); do
            if [[ ${ver1[index]} -gt ${ver2[index]} ]]; then
                echo 1
                return
            elif [[ ${ver1[index]} -lt ${ver2[index]} ]]; then
                echo 2
                return
            fi
        done
        echo 0
    }

    #? Description:
    #?   chmod +x all .sh regular files under the given dir.
    #?
    #? Usage:
    #?   __xsh_chmod_x_by_dir <PATH>
    #?
    function __xsh_chmod_x_by_dir () {
        find "${1:?}" \
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
    #?   Get git version.
    #?
    #? Usage:
    #?   __xsh_git_version
    #?
    function __xsh_git_version () {
        # shellcheck disable=SC2207
        declare versions=( $(git version) )
        echo "${versions[2]}"
    }

    #? Description:
    #?   Get all tags, in ascending order of commit date.
    #?
    #? Usage:
    #?   __xsh_git_get_all_tags
    #?
    function __xsh_git_get_all_tags () {
        git tag \
            | xargs -I@ git log --format=format:"%ai @%n" -1 @ \
            | sort \
            | awk '{print $4}'
    }

    #? Description:
    #?   Fetch remote tags to local, and remove local tags no longer on remote.
    #?
    #? Usage:
    #?   __xsh_git_fetch_remote_tags
    #?
    function __xsh_git_fetch_remote_tags () {
        if [[ $(__xsh_version_comparator 1.9.0 "$(__xsh_git_version)") -eq 1 ]]; then
            # git version < 1.9.0
            git fetch --prune origin "+refs/tags/*:refs/tags/*"
        else
            # git version >= 1.9.0
            git fetch --prune --prune-tags origin
        fi
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
        [[ -n "$(git status -s)" ]]
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
    #? Option:
    #?   [-s GIT_SERVER]  Git server URL.
    #?                    E.g. `https://github.com`
    #?   [-b BRANCH]      Clone the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Clone a specific TAG version.
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    function __xsh_git_clone () {
        declare -a git_options
        declare git_server=${XSH_GIT_SERVER} \
                OPTARG OPTIND opt

        while getopts s:b:t: opt; do
            case ${opt} in
                s)
                    git_server=${OPTARG%/}  # remove tailing '/'
                    ;;
                b|t)
                    git_options+=(-"${opt}")
                    git_options+=("${OPTARG}")
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
        shift $((OPTIND - 1))
        declare repo=$1

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        if [[ -z ${git_server} ]]; then
            __xsh_log error "Git server is null or not set."
            return 255
        fi

        declare repo_path=${XSH_REPO_HOME:?}/${repo}
        if [[ -e ${repo_path} ]]; then
            __xsh_log error "Repo already exists at ${repo_path}."
            return 255
        fi

        if [[ ${#git_options[@]} -gt 2 ]]; then
            __xsh_log error "-b and -t can't be used together."
            return 255
        fi

        # never use a shallow clone here
        git clone "${git_server}/${repo}" "${repo_path}"

        # update to latest tagged version
        (cd "${repo_path}" \
             && __xsh_git_force_update "${git_options[@]}" \
             && __xsh_git_chmod_x
        )

        declare ret=$?
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
    #? Option:
    #?   [-b BRANCH]      Update to the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Update to a specific TAG version.
    #?
    function __xsh_git_force_update () {
        declare target \
                OPTIND OPTARG opt

        while getopts b:t: opt; do
            case ${opt} in
                b|t)
                    target=${OPTARG}
                    ;;
                *)
                    return 255
                    ;;
            esac
        done

        if __xsh_git_is_workdir_dirty; then
            # discard all local changes and untracked files
            __xsh_git_discard_all
        fi

        # fetch remote tags to local
        __xsh_git_fetch_remote_tags

        if [[ -z ${target} ]]; then
            target=$(__xsh_git_get_latest_tag)

            if [[ -z ${target} ]]; then
                __xsh_log error "No any available tagged version found."
                return 255
            fi
        fi

        declare current
        current=$(__xsh_git_get_current_tag)
        if [[ ${current} == "${target}" ]]; then
            __xsh_log info "Already at the latest version: ${current}."
            return
        fi

        # suppress the warning of 'detached HEAD' state
        git config advice.detachedHead false

        __xsh_log info "Updating repo to ${target}."
        if ! git checkout -f "${target}"; then
            __xsh_log error "Failed to checkout repo."
            return 255
        fi

        if [[ $(__xsh_git_get_current_branch) != 'HEAD' ]]; then
            git reset --hard origin/"${target}"
            if ! git pull; then
                __xsh_log error "Failed to pull repo."
                return 255
            fi
        fi
    }

    #? Description:
    #?   Show help for xsh builtin functions or utilities.
    #?   The dev mode is being checked indirectly.
    #?
    #? Usage:
    #?   __xsh_help [-t] [-c] [-d] [-sS SECTION,...] [BUILTIN | LPUR]
    #?
    #? Option:
    #?   [-t]             Show title.
    #?
    #?   [-c]             Show code.
    #?                    The shown code is formatted by shell with BUILTIN.
    #?
    #?   [-d]             Show entire document.
    #?
    #?   [-sS SECTION]    Show specific section of the document.
    #?                    `-s` turns the section name on.
    #?                    `-S` turns the section name off.
    #?                    The section name is case sensitive.
    #?                    The section list can be delimited with comma `,`.
    #?                    The output order of section is determined by the document order
    #?                    rather than the list order.
    #?
    #?   [BUILTIN]        xsh builtin function name without leading `__xsh_`.
    #?                    Show help for xsh builtin functions.
    #?
    #?   [LPUR]           LPUR.
    #?                    Show help for matched utilities.
    #?
    #?   If both BUILTIN and LPUR unset, then show help for xsh itself.
    #?   The options order matters to the output.
    #?   All options can be used multi times.
    #?
    function __xsh_help () {
        declare topic
        if [[ $# -gt 0 ]]; then
            # get the last argument
            topic=${!#}

            # remove the last argument from argument list
            set -- "${@:1:$#-1}"
        fi

        if [[ $# -eq 0 ]]; then
            # add -d to $@
            set -- -d
        fi

        {
            if [[ -z ${topic} ]]; then
                __xsh_help_self_cache
            elif [[ $(type -t "__xsh_${topic//-/_}" || :) == function ]]; then
                __xsh_help_builtin "$@" "__xsh_${topic//-/_}"
            else
                __xsh_help_lib "$@" "${topic}"
            fi
        } | awk '{gsub(/^[^ ]+.*/, "\033[1m&\033[0m"); print}'
    }

    #? Description:
    #?   A wrapper of sha1sum on Linux, and shasum on macOS.
    #?
    #? Usage:
    #?   __xsh_sha1sum [OPTIONS]
    #?
    function __xsh_sha1sum () {
        if type -t sha1sum >/dev/null; then
            sha1sum "$@"
        else
            shasum "$@"
        fi
    }

    #? Description:
    #?   Show cachable help for xsh itself.
    #?
    #? Usage:
    #?   __xsh_help_self_cache
    #?
    function __xsh_help_self_cache () {
        declare hash cached_help

        # shellcheck disable=SC2207
        hash=( $(__xsh_sha1sum "${XSH_HOME}/xsh/xsh.sh") )
        cached_help=/tmp/.${FUNCNAME[0]}_${hash[0]}

        if [[ -f ${cached_help} ]]; then
            cat "${cached_help}"
        else
            (umask 0000 && __xsh_help_self | tee "${cached_help}")
        fi
    }

    #? Description:
    #?   Show help for xsh itself.
    #?
    #? Usage:
    #?   __xsh_help_self
    #?
    function __xsh_help_self () {
        # show sections of Description and Usage of xsh itself
        __xsh_help_builtin -s 'Description,Usage' xsh

        declare -a names=(
            calls imports unimports list load unload update
            upgrade version versions lib_dev_manager debug help log
        )

        declare name

        # show sections of Usage of xsh builtin functions
        for name in "${names[@]}"; do
            __xsh_help_builtin -S Usage "__xsh_${name}" \
                | sed -e '/^$/d' -e 's/__xsh_/xsh /g'
        done

        printf '\nCommands:\n'

        # show sections of Description and Option of xsh builtin functions
        for name in "${names[@]}"; do
            __xsh_help_builtin -i "${name}\n" -S Description,Option "__xsh_${name}" \
                | sed '/^$/! s/^/  /'
        done

        # show rest sections of xsh itself
        __xsh_help_builtin -s 'Builtin,Convention,Debug Mode,Dev Mode' xsh
    }

    #? Description:
    #?   Show help for xsh builtin functions.
    #?
    #? Usage:
    #?   __xsh_help_builtin [-t] [-c] [-d] [-sS SECTION,...] <BUILTIN>
    #?
    #? Option:
    #?   <BUILTIN>        xsh builtin function name.
    #?
    #?   See `xsh help help` for the rest options.
    #?
    function __xsh_help_builtin () {
        # get the last argument
        declare builtin=${!#}
        # remove the last argument from argument list
        declare -a options=( "${@:1:$#-1}" )

        __xsh_info -f "${builtin}" "${options[@]}" "${XSH_HOME}/xsh/xsh.sh"
    }

    #? Description:
    #?   Show help for xsh utilities.
    #?   The dev mode is being checked.
    #?
    #?   The util name appearing in the doc in syntax `@<UTIL>` will be replaced
    #?   as the full util name.
    #?
    #? Usage:
    #?   __xsh_help_lib [-t] [-c] [-d] [-sS SECTION,...] <LPUR>
    #?
    #? Option:
    #?   See `xsh help help`.
    #?
    function __xsh_help_lib () {

        function __xsh_help_lib__ () {
            # get the last argument
            declare lpur=${!#}
            # remove the last argument from argument list
            declare -a options=( "${@:1:$#-1}" )

            declare path
            path=$(__xsh_get_path_by_lpur "${lpur}")
            declare ln
            while read -r ln; do
                if [[ -n ${ln} ]]; then
                    declare util lpue
                    util=$(__xsh_get_util_by_path "${ln}")
                    lpue=$(__xsh_get_lpue_by_path "${ln}")

                    if [[ -z ${util} ]]; then
                        __xsh_log error "util is null: %s." "${path}"
                        return 255
                    fi

                    if [[ -z ${lpue} ]]; then
                        __xsh_log error "lpue is null: %s." "${path}"
                        return 255
                    fi

                    __xsh_info "${options[@]}" "${ln}" \
                        | sed "s|@${util}|xsh ${lpue}|g"
                fi
            done <<< "${path}"
        }

        # get the last argument
        declare lpur=${!#}

        if __xsh_is_dev "${lpur}"; then
            XSH_LIB_HOME=${XSH_DEV_HOME} __xsh_help_lib__ "$@"
        else
            __xsh_help_lib__ "$@"
        fi
    }

    #? Description:
    #?   Show specific info for xsh builtin functions or utilities.
    #?
    #? Usage:
    #?   __xsh_info [-f NAME,...] [-t] [-c] [-d] [-sS SECTION,...] [-i STRING] [...] <PATH>
    #?
    #? Option:
    #?   [-f NAME]        Show info for the function only.
    #?                    The name list can be delimited with comma `,`.
    #?                    The output order of function is determined by the coding order
    #?                    rather than the list order.
    #?
    #?   [-i STRING]      Insert STRING.
    #?                    The string is inserted without newline, use `\n` if needs.
    #?
    #?   <PATH>           Path to the scripts file.
    #?
    #?   See `xsh help help` for the rest options.
    #?
    function __xsh_info () {

        function __xsh_filter_section_with_title__ () {
            declare section=${1:?}

            awk -v sectionregex="^(${section//,/|}):" '{
                 if (str && substr($0, 1, 1) ~ "[[:alnum:]]") {
                    print str
                    str = ""
                 }
                 if ($0 ~ sectionregex) str = $0
                 else if (str) str = str RS $0
            } END {if (str) print str}'
        }

        function __xsh_filter_section_without_title__ () {
            declare section=${1:?}

            awk -v sectionregex="^(${section//,/|}):" '{
                 if (flag && substr($0, 1, 1) ~ "[[:alnum:]]") {
                    print str
                    flag = str = ""
                 }
                 if ($0 ~ sectionregex) flag = 1
                 else if (flag) str = str (str ? RS : "") $0
            } END {if (str) print str}'
        }

        # get the last argument
        declare path=${!#} funcname \
                OPTIND OPTARG opt

        if [[ -z ${path} || ${path:1:1} == - ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        while getopts f:tcds:S:i: opt; do
            case ${opt} in
                f)
                    funcname=${OPTARG}
                    ;;
                t)
                    if [[ -n ${funcname} ]]; then
                        __xsh_get_funcname_from_file "${path}" "${funcname}"
                    else
                        __xsh_get_title_by_path "${path}"
                    fi
                    ;;
                d)
                    if [[ -n ${funcname} ]]; then
                        __xsh_get_doc_from_file "${path}" "${funcname}"
                    else
                        awk '/^#\?/ {sub("^[ ]*#\\?[ ]?", ""); print}' "${path}"
                    fi
                    ;;
                c)
                    if [[ -n ${funcname} ]]; then
                        __xsh_get_funccode_from_file "${path}" "${funcname}"
                    else
                        sed '/^#?/d' "${path}"
                    fi
                    ;;
                s)
                    __xsh_info -f "${funcname}" -d "${path}" | __xsh_filter_section_with_title__ "${OPTARG}"
                    ;;
                S)
                    __xsh_info -f "${funcname}" -d "${path}" | __xsh_filter_section_without_title__ "${OPTARG}"
                    ;;
                i)
                    if [[ -n ${funcname} ]]; then
                        declare name
                        for name in ${funcname//,/ }; do
                            # shellcheck disable=SC2059
                            printf "${OPTARG}"  # do not use `printf '%s'`
                        done
                    else
                        # shellcheck disable=SC2059
                        printf "${OPTARG}"  # do not use `printf '%s'`
                    fi
                    ;;
                *)
                    return 255
                    ;;
            esac
        done
    }

    #? Description:
    #?   Extract the function name from file.
    #?
    #? Usage:
    #?   __xsh_get_funcname_from_file <FILE> [NAME,...]
    #?
    #? Option:
    #?   <FILE>           File path.
    #?
    #?   [NAME]           Show info for the function only.
    #?                    The name list can be delimited with comma `,`.
    #?                    The output order of function is determined by the coding order
    #?                    rather than the list order.
    #?
    function __xsh_get_funcname_from_file () {
        declare path=${1:?} funcname=$2

        awk -v nameregex="^(${funcname//,/|})$" '{
            if ($1 == "function" && $2 ~ nameregex)
                print "[functions]" FS $2
        }' "${path}"
    }

    #? Description:
    #?   Extract the function code from file.
    #?
    #? Usage:
    #?   __xsh_get_funccode_from_file <FILE> [NAME,...]
    #?
    #? Option:
    #?   <FILE>           File path.
    #?
    #?   [NAME]           Show info for the function only.
    #?                    The name list can be delimited with comma `,`.
    #?                    The output order of function is determined by the coding order
    #?                    rather than the list order.
    #?
    function __xsh_get_funccode_from_file () {
        declare path=${1:?} funcname=$2

        awk -v nameregex="^(${funcname//,/|})$" -v indent=-1 '{
            if ($1 == "function" && $2 ~ nameregex) {
                indent = index($0, "function") - 1
            }
            if (indent >= 0) {
                if (indent > 0) sub("^[ ]{" indent "}", "")
                str = str (str ? RS : "") $0
                if (substr($0, 1, 1) == "}") {
                    print str
                    str = ""
                    indent = -1
                }
            }
        }' "${path}"
    }

    #? Description:
    #?   Extract the document from file.
    #?   The document is defined by the line started with `#?`.
    #?
    #? Usage:
    #?   __xsh_get_doc_from_file <FILE> [NAME,...]
    #?
    #? Option:
    #?   <FILE>           File path.
    #?
    #?   [NAME]           Show info for the function only.
    #?                    The name list can be delimited with comma `,` wthout.
    #?                    The output order of function is determined by the coding order
    #?                    rather than the list order.
    #?
    function __xsh_get_doc_from_file () {
        declare path=${1:?} funcname=$2

        awk -v nameregex="^(${funcname//,/|})$" '{
            if (str && $1 == "function" && $2 ~ nameregex) {
                gsub("[ ]*#\\?[ ]?", "", str)
                print str
                str = ""
            }
            if ($1 == "#?") {
                str = str (str ? RS : "") $0
            } else {
                str = ""
            }
        }' "${path}"
    }

    #? Description:
    #?   Show available versions of xsh.
    #?
    #? Usage:
    #?   __xsh_versions
    #?
    function __xsh_versions () {
        (cd "${XSH_HOME}/xsh" \
             && __xsh_git_get_all_tags
        )
    }

    #? Description:
    #?   Show installed version of xsh.
    #?
    #? Usage:
    #?   __xsh_version
    #?
    function __xsh_version () {
        (cd "${XSH_HOME}/xsh" \
             && __xsh_git_get_current_tag
        )
    }

    #? Description:
    #?   Show a list of loaded xsh libraries.
    #?   If the LPUR is given, show a list of matching utils.
    #?   The dev mode is being checked indirectly.
    #?
    #? Usage:
    #?   __xsh_list [LPUR]
    #?
    #? Option:
    #?   [LPUR]           List matched libraries, packages and utilities.
    #?
    function __xsh_list () {
        declare lpur=$1

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
    #?   __xsh_lib_get_cfg_property <LIB | REPO> <PROPERTY>
    #?
    function __xsh_lib_get_cfg_property () {
        declare name=$1
        declare property=$2

        if [[ -z ${name} ]]; then
            __xsh_log error "Lib or repo name is null or not set."
            return 255
        fi

        if [[ -z ${property} ]]; then
            __xsh_log error "Property name is null or not set."
            return 255
        fi

        declare cfg

        if [[ -z ${name##*/*} ]]; then
            cfg=${XSH_REPO_HOME}/${name}/xsh.lib
        else
            cfg=${XSH_LIB_HOME}/${name}/xsh.lib
        fi

        if [[ ! -f ${cfg} ]]; then
            __xsh_log error "Not found xsh.lib at: ${cfg}."
            return 255
        fi

        awk -F= -v key="${property}" '{if ($1 == key) {print $2; exit}}' "${cfg}"
    }

    #? Description:
    #?   List loaded libraries with version.
    #?   The dev mode is being checked.
    #?
    #? Usage:
    #?   __xsh_lib_list
    #?
    function __xsh_lib_list () {
        declare path
        if __xsh_is_dev; then
            path=$(find "${XSH_DEV_HOME}" -maxdepth 1 -type l)
        else
            path=$(find "${XSH_LIB_HOME}" -maxdepth 1 -type l)
        fi

        declare lib lib_path repo version
        while read -r lib_path; do
            if [[ -z ${lib_path} ]]; then
                break
            fi
            lib=${lib_path##*/}
            version=$(cd "${lib_path}" && __xsh_git_get_current_tag)
            repo=$(readlink "${lib_path}" \
                       | awk -F/ '{print $(NF-1) FS $NF}')

            printf '%s (%s) => %s\n' "${lib}" "${version:-latest}" "${repo}"
        done <<< "${path}"
    }

    #? Description:
    #?   Library manager.
    #?
    #? Usage:
    #?   __xsh_lib_manager COMMAND <REPO> [COMMAND_OPTION]
    #?
    #? Commands:
    #?   unimport         Unimport all imported utilities for the library linked
    #?                    to the REPO.
    #?   link             Link the REPO as a library.
    #?   unlink           Unlink the linked library of the REPO.
    #?   delete           Delete the whole REPO linked to the library.
    #?
    #? Option:
    #?   <REPO>           Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_lib_manager () {
        declare command=$1 repo=$2

        if [[ -z ${command} ]]; then
            __xsh_log error "Command is null or not set."
            return 255
        fi

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        declare repo_path=${XSH_REPO_HOME:?}/${repo}
        if [[ ! -d ${repo_path} ]]; then
            __xsh_log error "Repo doesn't exist at ${repo_path}."
            return 255
        fi

        declare lib
        lib=$(__xsh_get_lib_by_repo "${repo}")
        if [[ -z ${lib} ]]; then
            __xsh_log error "library name is null for the repo ${repo}."
            return 255
        fi

        declare lib_path=${XSH_LIB_HOME:?}/${lib}

        case "${command}" in
            unimport)
                __xsh_unimport "${lib}"
                ;;
            link)
                ln -sf "${repo_path}" "${lib_path}"
                ;;
            unlink)
                /bin/rm -f "${lib_path}"
                ;;
            delete)
                /bin/rm -rf "${repo_path:?}"
                ;;
            *)
                __xsh_log error "${command}: unsupported command."
                return 255
                ;;
        esac

        declare ret=$?
        if [[ ${ret} -ne 0 ]]; then
            __xsh_log error "${command}: failed, returns: ${ret}."
            return ${ret}
        fi
    }

    #? Description:
    #?   Development library manager.
    #?
    #? Usage:
    #?   __xsh_lib_dev_manager COMMAND <REPO> <REPO_HOME>
    #?
    #? Commands:
    #?   unimport         Unimport all imported utilities for the development
    #?                    library linked to the REPO.
    #?   link             Link the REPO as a development library.
    #?   unlink           Unlink the linked development library of the REPO.
    #?   delete           Delete the whole REPO linked to the development REPO.
    #?
    #? Option:
    #?   <REPO>           Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    #?   <REPO_HOME>      The path to the Git repo without the REPO part.
    #?                    E.g. `/path/to/repohome` of
    #?                         `/path/to/repohome/username/xsh-lib-foo`.
    #?
    function __xsh_lib_dev_manager () {
        # set temporary environment variables for dev lib, and proxy __xsh_lib_manager
        XSH_LIB_HOME=${XSH_DEV_HOME:?} XSH_REPO_HOME=${3:?} __xsh_lib_manager "$@"
    }

    #? Description:
    #?   Load library from Git repo.
    #?   Without '-b' or '-t', it will load the latest tagged
    #?   version, if there's no any tagged version, returns error.
    #?
    #? Usage:
    #?   __xsh_load [-s GIT_SERVER] [-b BRANCH | -t TAG] REPO
    #?
    #? Option:
    #?   [-s GIT_SERVER]  Git server URL.
    #?                    E.g. `https://github.com`
    #?   [-b BRANCH]      Load the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Load a specific TAG version.
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_load () {
        # get the last argument
        declare repo=${!#}

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        __xsh_git_clone "$@" || return
        __xsh_lib_manager link "${repo}"
        declare ret=$?
        if [[ ${ret} -ne 0 ]]; then
            __xsh_log warning "Deleting repo ${XSH_REPO_HOME}/${repo}."
            rm -rf "${XSH_REPO_HOME:?}/${repo:?}"
            return ${ret}
        fi
    }

    #? Description:
    #?   Unload the loaded library.
    #?
    #? Usage:
    #?   __xsh_unload REPO
    #?
    #? Option:
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_unload () {
        declare repo=$1

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        __xsh_lib_manager unimport "${repo}"
        __xsh_lib_manager unlink "${repo}"
        __xsh_lib_manager delete "${repo}"
    }

    #? Description:
    #?   Update the loaded library.
    #?   Without '-b' or '-t', it will update to the latest tagged
    #?   version, if there's no any tagged version, returns error.
    #?
    #? Usage:
    #?   __xsh_update [-b BRANCH | -t TAG] REPO
    #?
    #? Option:
    #?   [-b BRANCH]      Update to the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Update to a specific TAG version.
    #?   REPO             Git repo in syntax: `USERNAME/REPO`.
    #?                    E.g. `username/xsh-lib-foo`
    #?
    function __xsh_update () {
        # get the last argument
        declare repo=${!#}

        if [[ -z ${repo} ]]; then
            __xsh_log error "Repo name is null or not set."
            return 255
        fi

        __xsh_lib_manager unimport "${repo}" || return
        __xsh_lib_manager unlink "${repo}" || return

        (cd "${XSH_REPO_HOME}/${repo}" \
             && __xsh_git_force_update "$@" \
             && __xsh_git_chmod_x
        ) || return

        __xsh_lib_manager link "${repo}"
    }

    #? Description:
    #?   Update xsh itself.
    #?   Without '-b' or '-t', it will update to the latest tagged
    #?   version, if there's no any tagged version, returns error.
    #?
    #? Usage:
    #?   __xsh_upgrade [-b BRANCH | -t TAG]
    #?
    #? Option:
    #?   [-b BRANCH]      Update to the BRANCH's latest state.
    #?                    This option is for developers.
    #?   [-t TAG]         Update to a specific TAG version.
    #?
    function __xsh_upgrade () {
        declare repo_path=${XSH_HOME}/xsh

        (cd "${repo_path}" \
             && __xsh_git_force_update "$@" \
             && __xsh_git_chmod_x
        ) || return

        # shellcheck source=/dev/null
        source "${repo_path}/xsh.sh"
    }

    #? Description:
    #?   Get the init files under the given library path.
    #?   The init files are searched from the utility's parent directory, up
    #?   along to the library root.
    #?   For example, given the path `/home/user/.xsh/lib/x/functions/date`, the
    #?   following init files are returned if they present.
    #?
    #?     * /home/user/.xsh/lib/x/functions/date/__init__.sh
    #?     * /home/user/.xsh/lib/x/functions/__init__.sh
    #?
    #? Usage:
    #?   __xsh_get_init_files <DIR>
    #?
    function __xsh_get_init_files () {
        declare dir=${1:?} scope

        # remove XSH_LIB_HOME path from beginning
        scope=${dir#${XSH_LIB_HOME}}
        # remove the leading `/`
        scope=${scope#/}
        # remove the tailing `/`
        scope=${scope%/}

        # replace all slash `/` to whitespace
        # shellcheck disable=SC2206
        declare -a scopes=( ${scope//\// } )

        declare index init_file
        for (( index = "${#scopes[@]}"; index >= 0; index-- )); do
            scope=${scopes[*]:0:index}
            # replace all whitespace to slash `/`
            init_file=${XSH_LIB_HOME}/${scope// //}/__init__.sh

            if [[ -f ${init_file} ]]; then
                echo "${init_file}"
            fi
        done
    }

    #? Description:
    #?   Apply the init files for the function utility.
    #?   The init files are searched from the library root, down to the
    #?   utility's parent directory.
    #?   For example: `__xsh_init /home/user/.xsh/lib/x/functions/date` will try to apply
    #?   the following init files in order if they present.
    #?
    #?     * /home/user/.xsh/lib/x/functions/__init__.sh
    #?     * /home/user/.xsh/lib/x/functions/date/__init__.sh
    #?
    #?   Previously applied init files will be skipped.
    #?
    #?   A global environment variable `__XSH_INIT__` is used to track all
    #?   applied init files.
    #?
    #? Usage:
    #?   __xsh_make_init <FILE>
    #?
    #? Option:
    #?   <FILE>           Path to the function utility.
    #?
    function __xsh_make_init () {
        declare path=${1:?} code util lpuc

        util=$(__xsh_get_util_by_path "${path}")
        lpuc=$(__xsh_get_lpuc_by_path "${path}")

        code=$(cat "${path}")

        declare init_file
        while read -r init_file; do
            if [[ ${__XSH_INIT__[*]} =~ (^| )"${init_file}"($| ) ]]; then
                # skip this init file
                continue
            fi

            # apply function decorators found in the init file
            declare name
            while read -r name; do
                # shellcheck disable=SC2015
                [[ -z ${name} ]] && continue || :
                name=init_${name}

                code=$(__xsh_apply_func_decorator "${name:?}" "${code:?}" "${init_file}")
            done < <(__xsh_get_init_decorators "${init_file}")

            # remember the applied init file
            # do not declare it, make it global
            code="${code}; __XSH_INIT__+=( \"${init_file}\" )"
        done < <(__xsh_get_init_files "${path%/*}")

        printf '%s' "${code}"
    }

    #? Description:
    #?   Import the matching utilities by a list of LPUR.
    #?   The functions are sourced, and exported to sub-processes.
    #?   The scripts are linked at `/usr/local/bin`.
    #?
    #?   The imported utilities can be called directly without
    #?   leading `xsh` as syntax: `LIB-PACKAGE-UTIL`.
    #?
    #?   The dev mode is being checked indirectly.
    #?
    #?   Legal input:
    #?     '*'
    #?     /, <lib>
    #?     <lib>/<pkg>, /<pkg>
    #?     <lib>/<pkg>/<util>, /<pkg>/<util>
    #?     <lib>/<util>, /<util>
    #?
    #? Usage:
    #?   __xsh_imports <LPUR> [...]
    #?
    #? Option:
    #?   <LPUR> [...]     See the section of Convention.
    #?
    function __xsh_imports () {
        declare lpur ret=0

        for lpur in "$@"; do
            __xsh_import "${lpur}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    #? Description:
    #?   Import the matching utilities for LPUR.
    #?   The dev mode is being checked.
    #?
    #? Usage:
    #?   __xsh_import <LPUR>
    #?
    function __xsh_import () {

        function __xsh_import__ () {
            declare lpur=${1:?} path
            path=$(__xsh_get_path_by_lpur "${lpur}")

            declare ln type
            while read -r ln; do
                if [[ -z ${ln} ]]; then
                    __xsh_log error "LPUC is not found for the LPUR."
                    return 255
                fi
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
            done <<< "${path}"
        }

        declare lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        if __xsh_is_dev "${lpur}"; then
            XSH_LIB_HOME=${XSH_DEV_HOME} __xsh_import__ "${lpur}"
        else
            __xsh_import__ "${lpur}"
        fi
    }

    #? Description:
    #?   Source a file like `.../<lib>/functions/<package>/<util>.sh`
    #?   as function `<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_import_function <FILE>
    #?
    #? Option:
    #?   <FILE>           Path to the function utility.
    #?
    function __xsh_import_function () {
        declare path=${1:?}

        # source the function
        source /dev/stdin <<< "$(__xsh_make_function "${path}")"
    }

    #? Descriptions:
    #?   Make the function code ready.
    #?     * Applying function decorators
    #?     * Renaming function name
    #?     * export -f the function
    #?
    #? Usage:
    #?   __xsh_make_function <FILE>
    #?
    #? Option:
    #?   <FILE>           Path to the function utility.
    #?
    #? Output:
    #?   The changed code.
    #?
    function __xsh_make_function () {
        declare path=${1:?} code util lpuc

        util=$(__xsh_get_util_by_path "${path}")
        lpuc=$(__xsh_get_lpuc_by_path "${path}")

        # apply init files if found
        code=$(__xsh_make_init "${path}")

        # renaming function name
        code=$(sed -e "s/^function ${util} ()/function ${lpuc} ()/g" \
                   -e "s/@${util} /${lpuc} /g" <(printf '%s' "${code:?}"))

        # apply function decorators if found
        declare decorator
        declare -a options
        while read -r decorator; do
            # shellcheck disable=SC2015
            [[ -z ${decorator} ]] && continue || :
            # do not double quote the variable
            # shellcheck disable=SC2206
            options=( ${decorator} )

            code=$(__xsh_apply_func_decorator "${options[0]}" "${code:?}" "${options[@]:1}")
        done < <(__xsh_get_decorators "${path}")

        # export function to sub-processes
        printf "%s\n%s\n" "${code}" "export -f ${lpuc}"
    }

    #? Description:
    #?   Get init file's decorators.
    #?   If the `runtime` decorator is not found, then the `static`
    #?   decorator will be added to the returned decorator list.
    #?
    #? Usage:
    #?   __xsh_get_init_decorators <FILE>
    #?
    #? Option:
    #?   <FILE>           Path to the init file.
    #?
    function __xsh_get_init_decorators () {
        declare -a decorators
        # shellcheck disable=SC2207
        decorators=( $(__xsh_get_decorators "$@") )
        if [[ ! ${decorators[*]} =~ (^| )runtime($| ) ]]; then
            decorators+=( 'static' )
        fi
        printf '%s\n' "${decorators[@]}"
    }

    #? Description:
    #?   Get decorators.
    #?
    #? Usage:
    #?   __xsh_get_decorators <FILE>
    #?
    #? Option:
    #?   <FILE>           File path.
    #?
    function __xsh_get_decorators () {
        declare path=${1:?}

        # filter the pattern `#? @foo bar` and output the part `foo bar`
        awk '/^#\? @.+/ {sub(/^#\? @/, ""); print $0}' "${path}"
    }

    #? Description:
    #?   Apply function decorator to function utilities.
    #?
    #? Usage:
    #?   __xsh_apply_func_decorator <NAME> <FUNC> [OPTIONS ...]
    #?
    #? Option:
    #?   <NAME>           Decorator name.
    #?
    #?   <FUNC>           Function code.
    #?
    #?   [OPTIONS]        Options for the decorator.
    #?
    #? Output:
    #?   The code after the decorator is applied.
    #?
    function __xsh_apply_func_decorator () {
        declare name=${1:?}

        if [[ $(type -t "__xsh_func_decorator_${name}" || :) == function ]]; then
            # applying the decorator
            __xsh_func_decorator_"${name}" "${@:2}"
        else
            __xsh_log error "${name}: not found the function decorator."
            return 255
        fi
    }

    #? Description:
    #?   Apply function decorator `xsh` to function utilities.
    #?
    #? Usage:
    #?   __xsh_func_decorator_xsh <FUNC> <OPTIONS ...>
    #?
    #? Option:
    #?   <FUNC>           Function code.
    #?
    #?   <OPTIONS>        xsh command/builtin and its options.
    #?
    #? Output:
    #?   The code after the decorator is applied.
    #?
    function __xsh_func_decorator_xsh () {
        declare code=${1:?}

        # insert the decorator code at the beginning of the function body
        sed "/^function [a-zA-Z-]* () {/ r /dev/stdin" <(printf '%s' "${code}") <<< "xsh ${*:2}"
    }

    #? Description:
    #?   Apply function decorator `subshell` to function utilities.
    #?   Wrap a function, for example:
    #?       function foo () { :; }
    #?
    #?   Into a subshell:
    #?       function foo () {(
    #?       function __foo__ () { :; }
    #?       __foo__ "$@"
    #?       )}
    #?
    #? Usage:
    #?   __xsh_func_decorator_subshell <FUNC>
    #?
    #? Option:
    #?   <FUNC>           Function code.
    #?
    #? Output:
    #?   The code after the decorator is applied.
    #?
    function __xsh_func_decorator_subshell () {
        declare code=${1:?} name

        name=$(awk '/^function [a-zA-Z-]+ ()/ {print $2}' <<< "${code}")
        code=${code/#function ${name} ()/function __${name}__ ()}
        printf 'function %s () {(\n%s\n__%s__ "$@"\n)}\n' \
               "${name}" "${code}" "${name}"
    }

    #? Description:
    #?   Apply init decorator `static` to function utilities.
    #?   The init file is put right before the function. It gets sourced
    #?   every time the function gets imported.
    #?
    #? Usage:
    #?   __xsh_func_decorator_init_static <FUNC> <INIT_FILE>
    #?
    #? Option:
    #?   <FUNC>           Function code.
    #?
    #?   <INIT_FILE>      Path to the init file.
    #?
    #? Output:
    #?   The code after the decorator is applied.
    #?
    function __xsh_func_decorator_init_static () {
        declare code=${1:?} init_file=${2:?}

        # insert the decorator code at the first line of the function
        sed "1 r /dev/stdin" <(printf '%s' "${code}") <<< "source ${init_file}"
    }

    #? Description:
    #?   Apply init decorator `runtime` to function utilities.
    #?   The init file is put at the beginning of the function. It gets sourced
    #?   every time the function get executed.
    #?
    #? Usage:
    #?   __xsh_func_decorator_init_runtime <FUNC> <INIT_FILE>
    #?
    #? Option:
    #?   <FUNC>           Function code.
    #?
    #?   <INIT_FILE>      Path to the init file.
    #?
    #? Output:
    #?   The code after the decorator is applied.
    #?
    function __xsh_func_decorator_init_runtime () {
        declare code=${1:?} init_file=${2:?}

        # insert the decorator code at the beginning of the function body
        sed "/^function [a-zA-Z-]* () {/ r /dev/stdin" <(printf '%s' "${code}") <<< "source ${init_file}"
    }

    #? Description:
    #?   Link a file like `.../<lib>/scripts/<package>/<util>.sh`
    #?   as `/usr/local/bin/<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_import_script <FILE>
    #?
    function __xsh_import_script () {
        declare path=$1
        declare lpuc

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        ln -sf "${path}" "/usr/local/bin/${lpuc}"
    }

    #? Description:
    #?   Un-import the matching utilities that have been sourced or linked.
    #?   The sourced functions are unset, and the linked scripts are unlinked.
    #?   The dev mode is being checked indirectly.
    #?
    #? Usage:
    #?   __xsh_unimports <LPUR> [...]
    #?
    #? Option:
    #?   <LPUR> [...]     See the section of Convention.
    #?
    function __xsh_unimports () {
        declare lpur
        declare ret=0

        for lpur in "$@"; do
            __xsh_unimport "${lpur}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    #? Description:
    #?   Un-import the matching utilities for LPUR.
    #?   The dev mode is being checked.
    #?
    #? Usage:
    #?   __xsh_unimport <LPUR>
    #?
    function __xsh_unimport () {

        function __xsh_unimport__ () {
            declare lpur=${1:?} path
            path=$(__xsh_get_path_by_lpur "${lpur}")

            declare ln type
            while read -r ln; do
                if [[ -z ${ln} ]]; then
                    continue
                fi
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
            done <<< "${path}"
        }

        declare lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        if __xsh_is_dev "${lpur}"; then
            XSH_LIB_HOME=${XSH_DEV_HOME} __xsh_unimport__ "${lpur}"
        else
            __xsh_unimport__ "${lpur}"
        fi
    }

    #? Description:
    #?   Source a file like `.../<lib>/functions/<package>/<util>.sh`
    #?   and unset the function by name `<lib>-<package>-<util>`
    #?
    #? Usage:
    #?   __xsh_unimport_function <FILE>
    #?
    function __xsh_unimport_function () {
        declare path=${1:?} util lpuc

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
        declare path=${1:?} lpuc

        lpuc=$(__xsh_get_lpuc_by_path "${path}")
        rm -f "/usr/local/bin/${lpuc}"

        # forget remembered commands locations
        hash -r
    }

    #? Description:
    #?   Test if the debug mode is enabled for current context.
    #?   The environment variable XSH_DEBUG is used during the test.
    #?
    #? Usage:
    #?   __xsh_is_debug <LPUE>
    #?
    #? Option:
    #?   <LPUE>          The debug mode is tested against the LPUE.
    #?
    #? Return:
    #?   0:               Enabled.
    #?   != 0:            Not enabled.
    #?
    function __xsh_is_debug () {
        if [[ -z ${XSH_DEBUG} ]]; then
            return 1
        fi

        declare input=${1:?}
        input=$(__xsh_complete_lpue "${input}")

        declare xsh_debug
        xsh_debug=$(declare -p XSH_DEBUG 2>/dev/null)

        if [[ ${xsh_debug} =~ ^declare\ -x ]]; then
            case ${XSH_DEBUG} in
                1)
                    XSH_DEBUG=( "${input}" )
                    ;;
                *)
                    # shellcheck disable=SC2207
                    # shellcheck disable=SC2128
                    XSH_DEBUG=( $(__xsh_get_lpue_by_lpur "${XSH_DEBUG}") )
                    ;;
            esac
        fi
        [[ ${XSH_DEBUG[*]} =~ (^| )"${input}"($| ) ]]
        return $?
    }

    #? Description:
    #?   Test if the dev mode is enabled for current context.
    #?   The environment variable XSH_DEV is used during the test.
    #?
    #? Usage:
    #?   __xsh_is_dev [INPUT]
    #?
    #? Option:
    #?   [INPUT]          The dev mode is tested against the INPUT.
    #?                    If the INPUT is not present, and XSH_DEV=1, it returns 0.
    #? Return:
    #?   0:               Enabled.
    #?   != 0:            Not enabled.
    #?
    function __xsh_is_dev () {
        if [[ -z ${XSH_DEV} ]]; then
            return 1
        fi

        declare input=$1

        if [[ -n ${input} ]]; then
            input=$(__xsh_complete_lpue "${input}")
        fi

        declare xsh_dev
        xsh_dev=$(declare -p XSH_DEV 2>/dev/null)

        if [[ ${xsh_dev} =~ ^declare\ -x ]]; then
            case ${XSH_DEV} in
                1)
                    # set to the exact input
                    XSH_DEV=( "${input}" )
                    ;;
                *)
                    # shellcheck disable=SC2128
                    # shellcheck disable=SC2178
                    XSH_DEV=$(__xsh_complete_lpue "${XSH_DEV}")
                    # shellcheck disable=SC2128
                    XSH_DEV=( "${XSH_DEV}" )
                    # set to a list of LPUE that matches XSH_DEV
                    # shellcheck disable=SC2207
                    # shellcheck disable=SC2128
                    XSH_DEV+=( $(XSH_LIB_HOME=${XSH_DEV_HOME} __xsh_get_lpue_by_lpur "${XSH_DEV}") )
            esac
        fi

        [[ ${XSH_DEV[*]} =~ (^| )"${input}"($| ) ]]
        return $?
    }

    #? Description:
    #?   Call utilities in a batch. No options can be passed.
    #?   The debug mode is being checked indirectly.
    #?   The dev mode is being checked indirectly.
    #?
    #? Usage:
    #?   __xsh_calls <LPUE> [...]
    #?
    #? Option:
    #?   <LPUE> [...]     LPUE. See the section of Convention.
    #?
    function __xsh_calls () {
        declare lpue ret=0

        for lpue in "$@"; do
            __xsh_call "${lpue}"
            ret=$((ret + $?))
        done
        return ${ret}
    }

    #? Description:
    #?   Call a function or a script by LPUE.
    #?   The debug mode is being checked indirectly.
    #?   The dev mode is being checked.
    #?
    #? Usage:
    #?   __xsh_call <LPUE> [OPTIONS]
    #?
    #?   <LPUE>           Call an individual utility.
    #?   [OPTIONS]        Will be passed to utility.
    #?
    function __xsh_call () {
        # legal input:
        #   <lib>/<pkg>/<util>, /<pkg>/<util>
        #   <lib>/<util>, /<util>
        declare lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_log error "LPUE is null or not set."
            return 255
        fi

        if __xsh_is_dev "${lpue}"; then
            # force to import and unimport dev util
            XSH_LIB_HOME=${XSH_DEV_HOME} __xsh_exec -i -u "${lpue}" "${@:2}"
        else
            __xsh_exec "${lpue}" "${@:2}"
        fi
    }

    #? Description:
    #?   Call a function or a script by LPUE.
    #?   The debug mode is being checked.
    #?
    #? Usage:
    #?   __xsh_exec [-i] [-u] <LPUE>
    #?
    #? Option:
    #?   [-i]             Import the util before the execution no matter if it's available.
    #?   [-u]             Unimport the util after the execution.
    #?
    function __xsh_exec () {
        declare import=0 unimport=0 \
                OPTIND OPTARG opt

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
        declare lpue=${1:?}

        declare lpuc
        lpuc=$(__xsh_get_lpuc_by_lpue "${lpue}")

        if [[ ${import} -eq 1 ]]; then
            __xsh_import "${lpue}"
        elif ! type -t "${lpuc}" >/dev/null; then
            __xsh_import "${lpue}"
        fi

        declare mime_type
        mime_type=$(__xsh_mime_type "$(command -v "$1")" 2>/dev/null)

        # shellcheck disable=SC2128
        if [[ -n ${XSH_DEBUG} ]]; then
            if __xsh_is_debug "${lpue}"; then
                __xsh_call_with_shell_option -1 vx "${lpuc}" "${@:2}"
            else
                __xsh_call_with_shell_option -0 vx "${lpuc}" "${@:2}"
            fi
        else
            if [[ $(type -t "${lpuc}" || :) == file && ${mime_type%%/*} == text ]]; then
                # call script
                bash "$(command -v "${lpuc}")" "${@:2}"
            else
                # call function
                ${lpuc} "${@:2}"
            fi
        fi
        declare ret=$?

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
        declare lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        lpur=$(__xsh_complete_lpue "${lpur}")

        # append `*` if the lpur is ended with slash `/`
        lpur=${lpur/%\//\/*}

        if [[ -n ${lpur##*\/*} ]]; then
            # append `/*` if the lpur doesn't contain any slash `/`
            lpur=${lpur}/\*
        fi
        echo "${lpur}"
    }

    #? Description:
    #?   Complete a LPUE.
    #?
    #? Usage:
    #?   __xsh_complete_lpue <LPUE>
    #?
    function __xsh_complete_lpue () {
        declare lpue=$1

        if [[ -z ${lpue} ]]; then
            __xsh_log error "LPUE is null or not set."
            return 255
        fi

        # prepend `x` as the default lib if the lpur is started with slash `/`
        echo "${lpue/#\//x/}"
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_path_by_lpur <LPUR>
    #?
    function __xsh_get_path_by_lpur () {
        declare lpur=${1:?} lib pur

        lpur=$(__xsh_complete_lpur "${lpur}")
        lib=${lpur%%/*}  # remove anything after first / (include the /)
        pur=${lpur#*/}  # remove lib part

        find -L "${XSH_LIB_HOME}" \
             \( \
             -path "${XSH_LIB_HOME}/${lib}/functions/${pur}.sh" \
             -or \
             -path "${XSH_LIB_HOME}/${lib}/functions/${pur}/*" \
             -name "*.sh" \
             -or \
             -path "${XSH_LIB_HOME}/${lib}/scripts/${pur}.sh" \
             -or \
             -path "${XSH_LIB_HOME}/${lib}/scripts/${pur}/*" \
             -name "*.sh" \
             \) \
             -and \
             -not \
             -name __init__.sh \
             2>/dev/null
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpue_by_lpur <LPUR>
    #?
    function __xsh_get_lpue_by_lpur () {
        declare lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        declare ln
        while read -r ln; do
            if [[ -n ${ln} ]]; then
                __xsh_get_lpue_by_path "${ln}"
            fi
        done < <(__xsh_get_path_by_lpur "${lpur}")
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpuc_by_lpur <LPUR>
    #?
    function __xsh_get_lpuc_by_lpur () {
        declare lpur=$1

        if [[ -z ${lpur} ]]; then
            __xsh_log error "LPUR is null or not set."
            return 255
        fi

        declare ln
        while read -r ln; do
            if [[ -n ${ln} ]]; then
                __xsh_get_lpuc_by_lpue "${ln}"
            fi
        done < <(__xsh_get_lpue_by_lpur "${lpur}")
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpuc_by_lpue <LPUE>
    #?
    function __xsh_get_lpuc_by_lpue () {
        declare lpue=$1

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
    #?   __xsh_get_title_by_path <PATH>
    #?
    function __xsh_get_title_by_path () {
        declare path=$1

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        declare type lpue
        type=$(__xsh_get_type_by_path "${path}")
        lpue=$(__xsh_get_lpue_by_path "${path}")

        printf '[%s] %s\n' "${type}" "${lpue}"
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_type_by_path <PATH>
    #?
    function __xsh_get_type_by_path () {
        declare path=$1 type

        if [[ -z ${path} ]]; then
            __xsh_log error "LPU path is null or not set."
            return 255
        fi

        type=${path#${XSH_LIB_HOME}/*/}  # strip path from beginning
        echo "${type%%/*}"  # strip path from end
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lib_by_repo <REPO>
    #?
    function __xsh_get_lib_by_repo () {
        declare repo=${1:?}

        __xsh_lib_get_cfg_property "${repo}" name
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_util_by_path <PATH>
    #?
    function __xsh_get_util_by_path () {
        declare path=${1:?} util

        util=${path%.sh}  # remove file extension
        util=${util%/[0-9]*}  # handle util selector, started with digits
        echo "${util##*/}"  # get util
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpue_by_path <PATH>
    #?
    function __xsh_get_lpue_by_path () {
        declare path=${1:?} lib pue

        lib=${path#${XSH_LIB_HOME}/}  # strip path from beginning
        lib=${lib%%/*}  # remove anything after first / (include the /)
        pue=${path#${XSH_LIB_HOME}/*/*/}  # strip path from beginning
        pue=${pue%.sh}  # remove file extension
        echo "${lib}/${pue}"
    }

    #? Description:
    #?   TODO
    #?
    #? Usage:
    #?   __xsh_get_lpuc_by_path <PATH>
    #?
    function __xsh_get_lpuc_by_path () {
        declare path=$1 lpue

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
        declare -f xsh \
            | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}'
    }

    #? Description:
    #?   Clean environment on xsh() returns.
    #?
    #? Usage:
    #?   __xsh_clean
    #?
    function __xsh_clean () {
        # shellcheck disable=SC2046
        unset -f $(__xsh_get_internal_functions)
        unset XSH_DEBUG
        unset XSH_DEV
    }


    # main

    # call __xsh_clean() while xsh() returns
    # clean env if reaching the final exit point of xsh
    # shellcheck disable=SC2016
    __xsh_trap_return '
            if [[ $(__xsh_count_in_funcstack xsh) -eq 1 ]]; then
                __xsh_clean >/dev/null 2>&1
            fi;'

    # check environment variable
    if [[ -n ${XSH_HOME%/} ]]; then
        # remove tailing '/'
        XSH_HOME=${XSH_HOME%/}
    else
        __xsh_log error "XSH_HOME is not set properly."
        return 255
    fi

    if [[ -n ${XSH_DEV_HOME%/} ]]; then
        # remove tailing '/'
        XSH_DEV_HOME=${XSH_DEV_HOME%/}
    else
        __xsh_log error "XSH_DEV_HOME is not set properly."
        return 255
    fi

    # declare global variables if they are not declared yet or are empty
    declare XSH_REPO_HOME=${XSH_REPO_HOME:-${XSH_HOME}/repo}
    declare XSH_LIB_HOME=${XSH_LIB_HOME:-${XSH_HOME}/lib}
    declare XSH_GIT_SERVER=${XSH_GIT_SERVER:-https://github.com}

    # check dirs
    if [[ ! -e ${XSH_REPO_HOME} ]]; then
        mkdir -p "${XSH_REPO_HOME}"
    fi
    if [[ ! -e ${XSH_LIB_HOME} ]]; then
        mkdir -p "${XSH_LIB_HOME}"
    fi

    # check input
    if [[ -z $1 ]]; then
        __xsh_help >&2
        return 255
    fi

    if [[ $(type -t "__xsh_${1//-/_}" || :) == function ]]; then
        # xsh command or builtin function
        __xsh_"${1//-/_}" "${@:2}"
    else
        # xsh library utility
        __xsh_call "$1" "${@:2}"
    fi
}
# export function to sub-processes
export -f xsh
