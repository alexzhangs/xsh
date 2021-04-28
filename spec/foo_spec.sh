Describe 'Foo'
  Include xsh.sh
  exported_functions() { declare -Fx | awk '{print $3}'; }

  It 'call function: xsh'
    When call xsh
    The status should be success
    The output should include ''
    The variable XSH_HOME should be exported
    #The result of function exported_functions should include 'xsh'
  End
End
