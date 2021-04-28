function xsh () {

    function __xsh_clean () {
        unset -f $(echo __xsh_clean)
        unset XSH_DEBUG
        :
    }

    trap "trap - RETURN; __xsh_clean;" RETURN
}
export -f xsh
