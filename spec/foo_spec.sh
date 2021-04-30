#? Description:
#?   This is a negitive test case for the issue:
#?   * Segmentation fault (core dumped) with --kcov in circumstance on Travis linux xenial
#?     https://github.com/shellspec/shellspec/issues/214
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/foo_spec.sh
#?
Describe 'Foo'
  xsh () {
    # shellcheck disable=SC2116
    function __xsh_clean () { unset -f "$(echo __xsh_clean)"; :; }
    trap "trap - RETURN; __xsh_clean;" RETURN
    export XSH_HOME=~/.xsh
  }
  export -f xsh
  exported_functions () { declare -Fx | awk '{print $3}'; }

  It 'call function: xsh'
    When call xsh
    The status should be success
    The output should include ''
    The variable XSH_HOME should be exported
    The result of function exported_functions should include 'xsh'
  End
End
