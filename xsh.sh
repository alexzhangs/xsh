function xsh () {

    function __xsh_clean () {
        unset -f __xsh_clean
        unset XSH_DEBUG
        unset XSH_DEV
    }

    declare command="
    if [[ \${FUNCNAME} == xsh ]]; then
        trap - RETURN
        __xsh_clean
    fi;"

    trap "${command}" RETURN
}
export -f xsh
