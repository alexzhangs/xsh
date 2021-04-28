function xsh () {

    function __xsh_clean () {
        unset -f $(echo __xsh_clean); :
    }

    __xsh_clean
}
export -f xsh
