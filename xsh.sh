function xsh () {
    local command name
    local ret=0

    if [[ -n $1 ]]; then
        command=$(echo "$1" | tr 'A-Z' 'a-z')
        shift
    else
        return 255
    fi

    function __xsh_load () {
        if [[ -f ${XSH_HOME}/functions/${1}.sh ]]; then
            source /dev/stdin \
                   <<<"$(sed "s|^function ${1##*/} ()|function x-${1/\//-} ()|" \
                             "${XSH_HOME}/functions/${1}.sh")"
        else
            return 255
        fi
    }

    function __xsh_call () {
        local command

        if [[ -n $1 ]]; then
            command=$1
            shift
        else
            return 255
        fi

        if type x-${command/\//-} >/dev/null 2>&1; then
            x-${command/\//-} "$@"
        elif [[ -f ${XSH_HOME}/scripts/${command}.sh ]]; then
            bash ${XSH_HOME}/scripts/${command}.sh "$@"
        else
            __xsh_load "$command" && x-${command/\//-} "$@"
        fi
    }

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

    unset __xsh_load __xsh_call
    return $ret
}
export -f xsh
