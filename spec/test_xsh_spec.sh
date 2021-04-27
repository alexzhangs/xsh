Describe 'xsh.sh'
  Include xsh.sh

  Describe 'commands'
    It 'load library xsh-lib/core'
      When call xsh load xsh-lib/core
      The status should be success
      The output should not equal ''
      The path ${XSH_HOME}/repo/xsh-lib/core should be directory
      The path ${XSH_HOME}/lib/x should be symlink
    End

    It 'imports /date/adjust'
      When call xsh imports /date/adjust
      The status should be success
      The output should equal ''
      The function 'x-date-adjust' should equal 'x-date-adjust'
      The variable XSH_X_DATE__POSIX_FMT should be exported
      The variable __XSH_INIT__ should be present
    End

    It 'unimports /date/adjust'
      When call xsh unimports /date/adjust
      The status should be success
      The output should equal ''
      The function 'x-date-adjust' should not equal 'x-date-adjust'
    End
  End
End