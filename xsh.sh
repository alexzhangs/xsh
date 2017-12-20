function xsh () {
    local command name
    local ret=0

    # check environment variable
    if [[ -z ${XSH_HOME} ]]; then
        printf "ERROR: XSH_HOME is not set properly: '%s'.\n" "${XSH_HONE}" >&2
        return 255
    fi

    # check input
    if [[ -n $1 ]]; then
        command=$(echo "$1" | tr 'A-Z' 'a-z')
        shift
    else
        return 255
    fi

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
            symlink=x-${symlink/\//-}
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
            command=x-${1/\//-}
            shift
        else
            return 255
        fi

        if type $command >/dev/null 2>&1; then
            $command "$@"
        else
            __xsh_load "$1" && $command "$@"
        fi
    }

    # main
    case $command in
        load)
            for name in "$@"; do
                __xsh_load "$name"
                ret=$((ret + $?))
            done
            ;;
        import)
            for name in "$@"; do
                __xsh_call "$name"
                ret=$((ret + $?))
            done
            ;;
        *)
            __xsh_call "$command" "$@"
            ret=$?
            ;;
    esac

    # clean
    unset __xsh_load \
          __xsh_load_function \
          __xsh_load_script \
          __xsh_call

    return $ret
}
export -f xsh
