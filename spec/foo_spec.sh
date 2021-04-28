Describe 'Foo'
  It 'call function foo'
    foo() { echo FOO; export FOO=1; }
    When call foo
    The status should be success
    The output should equal 'FOO'
    The variable FOO should be exported
  End
End
