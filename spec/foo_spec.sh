Describe 'Foo'
  Include xsh.sh
  exported_functions() { declare -Fx | awk '{print $3}'; }

  It 'call function foo'
    foo() { echo FOO; export FOO=1; function bar () { echo BAR; }; export -f bar; }
    When call foo
    The status should be success
    The output should equal 'FOO'
    The variable FOO should be exported
    The result of function exported_functions should include 'bar'
  End

  It 'call function xsh help'
    When call xsh help
    The status should be success
    The output should include 'Usage'
    The variable XSH_HOME should be exported
    The result of function exported_functions should include 'xsh'
  End
End
