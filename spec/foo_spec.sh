Describe 'Foo'
  Include xsh.sh
  exported_functions() { declare -Fx | awk '{print $3}'; }

  It 'call xsh log'
    When call xsh log 'LOG'
    The status should be success
    The output should include 'LOG'
    The variable XSH_HOME should be exported
    The result of function exported_functions should include 'xsh'
  End
End
