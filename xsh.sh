function xsh () {

    function __xsh_count_in_funcstack () {
        printf '%s\n' "${FUNCNAME[@]}" \
            | grep -c "^${1}$"
    }

    function __xsh_trap_return () {
        declare command="
        if [[ \${FUNCNAME} == xsh ]]; then
            trap - RETURN
            ${1:?}
        fi;"

        trap "${command}" RETURN
    }

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

    function __xsh_get_internal_functions () {
        declare -f xsh \
            | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}'
    }

    function __xsh_clean () {
        unset -f $(__xsh_get_internal_functions)
        unset XSH_DEBUG
        unset XSH_DEV
    }


    __xsh_trap_return '
            __xsh_clean;'

    __xsh_"${1}" "${@:2}"
}
export -f xsh
