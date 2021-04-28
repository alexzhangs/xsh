function xsh () {

    function __xsh_get_internal_functions () {
        declare -f xsh \
            | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}'
    }

    function __xsh_clean () {
        unset -f $(__xsh_get_internal_functions)
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
