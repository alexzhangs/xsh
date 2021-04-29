Describe 'Bar'
  bar () { echo BAR; }

  It 'call function: bar'
    When call bar
    The status should be success
    The output should include 'BAR'
    The variable HOME should be exported
  End
End
