#? Description:
#?   This is a negitive test case for the issue:
#?   * Segmentation fault (core dumped) with --kcov in circumstance on Travis linux xenial
#?     https://github.com/shellspec/shellspec/issues/214
#?
#?   Update - 2021-05-27:
#?     It's confirmed that this issue was introduced in bash 4.3.2 and fixed in 4.4.0.
#?     * https://github.com/shellspec/shellspec/issues/214#issuecomment-847222179
#?     * https://github.com/bminor/bash/commit/a0c0a00fc419b7bc08202a79134fcd5bc0427071
#?     Use Travis linux dist `bionic` (bash 4.3.2) rather than `xenial` (bash 4.4.20) to
#?     overcome this issue.
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
