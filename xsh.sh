function xsh () {
    local name
    local ret=0

    # check environment variable
    if [[ -z ${XSH_HOME} ]]; then
        printf "ERROR: XSH_HOME is not set properly: '%s'.\n" "${XSH_HONE}" >&2
        return 255
    fi

    # @private
    function __xsh_usage () {
        printf "Usage:\n"
        printf "  xsh <PACKAGE/ITEM> [ITEM_OPTIONS]\n"
        printf "  xsh list\n"
        printf "  xsh load <PACKAGE[/ITEM]> ...\n"
        printf "  xsh import <PACKAGE[/ITEM]> ...\n"
        printf "  xsh help|-h|--help\n\n"

        printf "Options:\n"
        printf "  PACKAGE/ITEM    Items to load, import or to call.\n"
        printf "                  A single '/' presents all packages.\n"
        printf "                  Package only without item presents all items under this package.\n"
        printf "                  There are 2 types of items: functions and scripts.\n"
        printf "  ITEM_OPTIONS    Options will be passed to item.\n"
        printf "  list            List available packages and items.\n"
        printf "  load            Load functions and scripts so can be called\n"
        printf "                  as syntax: 'x-<package>-<item>'\n"
        printf "  import          Call functions and scripts in a batch.\n"
        printf "                  No options can be passed.\n"
        printf "  help|-h|--help  This help.\n"
    }

    # @private
    # Source functions by relative file path and
    # file name(without extension).
    # Link scripts by relative file path and
    # file name(without extension).
    function __xsh_load () {
        local path=$1  # legal input: '/', 'foo', 'foo/', 'foo/bar', 'foo/bar/'
        local f_path s_path ln

        # join the path, remove tailing '/'
        f_path="${XSH_HOME%/}/functions/${path#/}"
        s_path="${XSH_HOME%/}/scripts/${path#/}"

        # handle functions
        while read ln; do
            __xsh_load_function "$ln"
        done <<< "$(
             find "${f_path%/}" -type f -name "*.sh" 2>/dev/null;
             find "${f_path%/}.sh" -type f 2>/dev/null)"

        # handle scripts
        while read ln; do
            __xsh_load_script "$ln"
        done <<< "$(
             find "${s_path%/}" -type f -name "*.sh" 2>/dev/null;
             find "${s_path%/}.sh" -type f 2>/dev/null)"
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
    # as "/usr/local/bin/x-<domain>-<foo>"
    function __xsh_load_script () {
        local symlink

        if [[ -n $1 ]]; then
            symlink=${1#${XSH_HOME%/}/scripts/}
            symlink=${symlink%.sh}
            symlink=x-${symlink//\//-}  # replace each '/' with '-'
            ln -sf "$1" "/usr/local/bin/$symlink"
        else
            :
        fi
    }

    # @private
    # Call a function or a script by relative file path
    # and file name(without extension).
    function __xsh_call () {
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
    function __xsh_clean () {
        # clean env if here is the final exit point of xsh
        # FUNCNAME[0]: __xsh_clean
        # FUNCNAME[1]: xsh
        if [[ $(printf '%s\n' "${FUNCNAME[@]}" \
                    | grep -c "^${FUNCNAME[1]}$") -eq 1 ]]; then
            unset __xsh_usage \
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
        list)
            printf "ERROR: not ready yet\n" >&2
            ret=255
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
