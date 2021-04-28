function xsh () {

    function __xsh_clean () {
        unset -f $(echo __xsh_clean); :
    }

    trap "trap - RETURN; __xsh_clean;" RETURN
}
export -f xsh
