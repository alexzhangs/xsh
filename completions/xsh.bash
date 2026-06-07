_xsh_complete() {
    local cur prev words cword
    _init_completion || return

    local builtins="load unload update list imports unimports import unimport help debug version versions upgrade calls call exec log lib-manager lib-dev-manager"

    if [[ $cword -eq 1 ]]; then
        # complete built-ins and LPUEs from loaded libs
        local lpues
        lpues=$(xsh list '*' 2>/dev/null | awk '{print $2}')
        COMPREPLY=( $(compgen -W "$builtins $lpues" -- "$cur") )
    elif [[ $prev == "load" ]]; then
        # suggest known public libs; user can type free-form
        COMPREPLY=( $(compgen -W "xsh-lib/core xsh-lib/aws xsh-lib/git" -- "$cur") )
    elif [[ $prev == "help" || $prev == "list" ]]; then
        local lpues
        lpues=$(xsh list '*' 2>/dev/null | awk '{print $2}')
        COMPREPLY=( $(compgen -W "$lpues" -- "$cur") )
    fi
}
complete -F _xsh_complete xsh
