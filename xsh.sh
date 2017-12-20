function xsh () {
    local command name
    local ret=0

    # check environment variable
    if [[ -z $XSH_HOME ]]; then
        printf "ERROR: XSH_HOME is not set or exported.\n" >&2
        return 255
    fi

    # check XSH_HOME existence
    if [[ ! -d $XSH_HOME ]]; then
        printf "ERROR: XSH_HOME '%s' does not exist or readable.\n" >&2
        return 255
    fi

    # check input
    if [[ -n $1 ]]; then
        command=$(echo "$1" | tr 'A-Z' 'a-z')
        shift
    else
        return 255
    fi

    #@private
    # Source a function by relative file path and
    # file name(without extension).
    # Link a script by relative file path and
    # file name(without extension).
    function __xsh_load () {
        # handle functions
        if [[ -f ${XSH_HOME}/functions/${1}.sh ]]; then
            # source "function <foo>" within "functions/<domain>/<foo>.sh"
            # as "function x-<domain>-<foo>"
            source /dev/stdin \
                   <<<"$(sed "s|^function ${1##*/} ()|function x-${1/\//-} ()|" \
                             "${XSH_HOME}/functions/${1}.sh")"
        # handle scripts
        elif [[ -f ${XSH_HOME}/scripts/${1}.sh ]]; then
            # link "scripts/<domain>/<foo>.sh"
            # as "/usr/local/bin/x-<domain>-<foo>"
            ln -sf "${XSH_HOME}/scripts/${1}.sh" "/usr/local/bin/x-${1/\//-}"
        else
            return 255
        fi
    }

    # @private
    # Call a function or a script by relative file path
    # and file name(without extension).
    function __xsh_call () {
        local command

        # check input
        if [[ -n $1 ]]; then
            command=$1
            shift
        else
            return 255
        fi

        if type x-${command/\//-} >/dev/null 2>&1; then
            x-${command/\//-} "$@"
        else
            __xsh_load "$command" && x-${command/\//-} "$@"
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
    unset __xsh_load __xsh_call

    return $ret
}
export -f xsh
