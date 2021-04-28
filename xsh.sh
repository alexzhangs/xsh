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
        unset XSH_DEBUG
        unset XSH_DEV
    }


    # main

    # call __xsh_clean() while xsh() returns
    # clean env if reaching the final exit point of xsh
    # shellcheck disable=SC2016
    __xsh_trap_return '
        unset -f $(__xsh_get_internal_functions);'

    if [[ $(type -t "__xsh_${1//-/_}" || :) == function ]]; then
        # xsh command or builtin function
        __xsh_"${1//-/_}" "${@:2}"
    else
        # xsh library utility
        __xsh_call "$1" "${@:2}"
    fi
}
export -f xsh
