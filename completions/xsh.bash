# Minimal fallback for systems without bash-completion installed (notably
# stock macOS /bin/bash 3.2.57, where bash-completion@2 requires bash 4+ and
# silently bails). The real _init_completion handles edge cases this shim
# skips (quoting, redirection), but populates the same four caller-local
# variables this completer reads. Defined only if not already present, so a
# later bash-completion load wins.
if ! declare -F _init_completion >/dev/null 2>&1; then
    _init_completion() {
        COMPREPLY=()
        # Match real _init_completion: bail when cword <= 0 (degenerate case
        # that real completion never triggers, but bash 3.2 errors on
        # ${COMP_WORDS[-1]} before the ${...:-} default can apply).
        [[ ${COMP_CWORD:-0} -gt 0 ]] || return 1
        cur=${COMP_WORDS[COMP_CWORD]}
        prev=${COMP_WORDS[COMP_CWORD-1]}
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
        return 0
    }
fi

# Populate the per-shell-session LPUE cache if not already set. Called
# directly (NOT via $(...)) so the assignment lands in the caller's shell
# rather than in a subshell. `xsh list '*'` walks every loaded library and
# can take ~500ms with many libs loaded; caching makes second+ TAB instant.
#
# To refresh after `xsh load`/`xsh unload`/`xsh update`, run:
#   unset _XSH_COMPLETE_LPUE_CACHE
#
# The awk picks column 2 (the LPUE) from lines like '[scripts] x/string/upper'.
# Older xsh (≤ 0.6.1) emitted ANSI bold around every line even when stdout
# wasn't a TTY; the sed is defensive against that and is a no-op once
# the matching xsh.sh fix is in place.
_xsh_complete_load_lpue_cache() {
    [[ -n ${_XSH_COMPLETE_LPUE_CACHE+x} ]] && return
    _XSH_COMPLETE_LPUE_CACHE=$(xsh list '*' 2>/dev/null \
        | sed $'s/\033\\[[0-9;]*[a-zA-Z]//g' \
        | awk '{print $2}')
}

_xsh_complete() {
    local cur prev words cword
    _init_completion || return

    local builtins="load unload update list imports unimports import unimport help debug version versions upgrade calls call exec log lib-manager lib-dev-manager"

    if [[ $cword -eq 1 ]]; then
        # complete built-ins and LPUEs from loaded libs
        _xsh_complete_load_lpue_cache
        COMPREPLY=( $(compgen -W "$builtins $_XSH_COMPLETE_LPUE_CACHE" -- "$cur") )
    elif [[ $prev == "load" ]]; then
        # suggest known public libs; user can type free-form
        COMPREPLY=( $(compgen -W "xsh-lib/core xsh-lib/aws xsh-lib/git" -- "$cur") )
    elif [[ $prev == "help" || $prev == "list" ]]; then
        _xsh_complete_load_lpue_cache
        COMPREPLY=( $(compgen -W "$_XSH_COMPLETE_LPUE_CACHE" -- "$cur") )
    fi
}
complete -F _xsh_complete xsh
