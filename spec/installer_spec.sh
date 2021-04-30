#? Description:
#?   This is the test case for the installer scripts.
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/installer_spec.sh
#?
Describe 'installer'
  exported_functions () { declare -Fx | awk '{print $3}'; }
  uninstall () { bash ${SHELLSPEC_PROJECT_ROOT}/install.sh -u; unset -f xsh; unset XSH_HOME XSH_DEV_HOME; }
  AfterEach 'uninstall'

  Describe 'install.sh'
    It 'run install.sh'
      install () { bash ${SHELLSPEC_PROJECT_ROOT}/install.sh; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The path ~/.xsh should be dir
      The path ~/.xsh/xsh should be dir
      The path ~/.xsh/xsh/xsh.sh should be file
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The result of function exported_functions should include 'xsh'
    End

    It 'run install.sh -f'
      install () { bash ${SHELLSPEC_PROJECT_ROOT}/install.sh; bash ${SHELLSPEC_PROJECT_ROOT}/install.sh -f; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path ${XSH_HOME} should be dir
      The path ${XSH_HOME}/xsh should be dir
      The path ${XSH_HOME}/xsh/xsh.sh should be file
      The path ${XSH_DEV_HOME} should be dir
      The result of function exported_functions should include 'xsh'
    End

    It 'run install.sh -s'
      install () { bash ${SHELLSPEC_PROJECT_ROOT}/install.sh -s; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path ${XSH_HOME} should be dir
      The path ${XSH_HOME}/xsh should be dir
      The path ${XSH_HOME}/xsh/xsh.sh should be file
      The path ${XSH_DEV_HOME} should be dir
      The result of function exported_functions should include 'xsh'
    End

    It 'run install.sh -b master'
      install () { bash ${SHELLSPEC_PROJECT_ROOT}/install.sh -b master; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path ${XSH_HOME} should be dir
      The path ${XSH_HOME}/xsh should be dir
      The path ${XSH_HOME}/xsh/xsh.sh should be file
      The path ${XSH_DEV_HOME} should be dir
      The result of function exported_functions should include 'xsh'
      End
  End

  Describe 'boot'
    It 'run boot through web'
      install () { curl -s https://raw.githubusercontent.com/alexzhangs/xsh/master/boot | bash -s -- -s && . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The path ~/.xsh should be dir
      The path ~/.xsh/xsh should be dir
      The path ~/.xsh/xsh/xsh.sh should be file
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The result of function exported_functions should include 'xsh'
    End
  End
End
