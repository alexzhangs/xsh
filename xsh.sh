function xsh () {

    function __xsh_clean () {
        unset -f $(declare -f xsh | awk '$1 == "function" && match($2, "^__xsh_") > 0 && $3 == "()" {print $2}')
        unset XSH_DEBUG
        :
    }

    trap "trap - RETURN; __xsh_clean;" RETURN
}
export -f xsh
