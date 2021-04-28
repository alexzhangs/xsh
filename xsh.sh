function xsh () {

    declare command="
    if [[ \${FUNCNAME} == xsh ]]; then
        trap - RETURN
        unset -f $(declare -f xsh | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}')
        unset XSH_DEBUG
        unset XSH_DEV
    fi;"

    trap "${command}" RETURN
}
export -f xsh
