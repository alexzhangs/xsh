#? Description:
#?   This is a positive test case for the issue:
#?   * Segmentation fault (core dumped) with --kcov in circumstance on Travis linux xenial
#?     https://github.com/shellspec/shellspec/issues/214
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/bar_spec.sh
#?
Describe 'Bar'
  bar () { echo BAR; }

  It 'call function: bar'
    When call bar
    The status should be success
    The output should include 'BAR'
    The variable HOME should be exported
  End
End
