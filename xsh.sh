function xsh () {

    function __xsh_trap_return () {
        declare command="
        if [[ \${FUNCNAME} == xsh ]]; then
            trap - RETURN
            ${1:?}
        fi;"

        trap "${command}" RETURN
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

    function __xsh_foo () {
        echo FOO
     }

    __xsh_trap_return '
        __xsh_clean;'

    __xsh_foo
}
export -f xsh
