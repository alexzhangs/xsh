function XSH () {
    local command name
    local ret=0

    if [[ -n $1 ]]; then
        command=$(echo "$1" | tr 'A-Z' 'a-z')
        shift
    else
        return 255
    fi
        
    case $command in
        load)
            for name in "$@"; do
                XSH_LOAD "$name"
                ret=$((ret + $?))
            done
            ;;
        import)
            for name in "$@"; do
                XSH_CALL "$name"
                ret=$((ret + $?))
            done
            ;;
        *)
            XSH_CALL "$command" "$@"
            ret=$?
            ;;
    esac

    return $ret
}


function XSH_LOAD () {
    if [[ -f ${XSH_HOME}/functions/${1}.sh ]]; then
        source "${XSH_HOME}/functions/${1}.sh"
    else
        return 255
    fi
}


function XSH_CALL () {
    local command
    
    if [[ -n $1 ]]; then
        command=$1
        shift
    else
        return 255
    fi

    if type -p x-${command/\//-}; then
        x-${command/\//-} "$@"
    else
        XSH_LOAD "$command" && XSH_CALL "$command" "$@"
    fi
}


alias xsh='XSH'
