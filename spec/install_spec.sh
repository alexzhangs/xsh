#? Description:
#?   This is the test case for the installer scripts.
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/install_spec.sh
#?
Describe 'installer'
  # zsh cannot export functions to the environment, so the equivalent check
  # under zsh is "is the function defined" (`typeset +f` lists the names).
  if [ -n "${ZSH_VERSION:-}" ]; then
    exported_functions () { typeset +f; }
  else
    exported_functions () { declare -Fx | awk '{print $3}'; }
  fi
  # `unset -f` of an undefined function: bash is silent, zsh prints an error
  uninstall () { bash "${SHELLSPEC_PROJECT_ROOT}"/install.sh -u >/dev/null; unset -f xsh 2>/dev/null || :; unset XSH_HOME XSH_DEV_HOME; }
  AfterAll 'uninstall'

  Describe 'install.sh'
    It 'run install.sh'
      # the default install upgrades to the latest released tag, whose xsh.sh
      # predates zsh support and cannot be sourced under zsh.
      # Remove this skip after the first zsh-supporting release.
      Skip if "released xsh versions predate zsh support" [ -n "${ZSH_VERSION:-}" ]
      # shellcheck source=/dev/null
      install () { uninstall; bash "${SHELLSPEC_PROJECT_ROOT}"/install.sh; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path "${XSH_HOME}" should be directory
      The path "${XSH_HOME}"/xsh/xsh.sh should be file
      The path "${XSH_DEV_HOME}" should be directory
      The result of function exported_functions should include 'xsh'
    End

    It 'run install.sh -f'
      # see the skip note in 'run install.sh'
      Skip if "released xsh versions predate zsh support" [ -n "${ZSH_VERSION:-}" ]
      # shellcheck source=/dev/null
      install () { bash "${SHELLSPEC_PROJECT_ROOT}"/install.sh -f; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path "${XSH_HOME}" should be directory
      The path "${XSH_HOME}"/xsh/xsh.sh should be file
      The path "${XSH_DEV_HOME}" should be directory
      The result of function exported_functions should include 'xsh'
    End

    It 'run install.sh -s'
      # `-f` first: the previous example is skipped under zsh, leaving the
      # XSH_HOME of its own former run in place, which `-s` alone refuses
      install () { bash "${SHELLSPEC_PROJECT_ROOT}"/install.sh -f -s; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path "${XSH_HOME}" should be directory
      The path "${XSH_HOME}"/xsh/xsh.sh should be file
      The path "${XSH_DEV_HOME}" should be directory
      The contents of file ~/.zshrc should include '. ~/.xshrc'
      The result of function exported_functions should include 'xsh'
    End

    It 'run install.sh -b master'
      # see the skip note in 'run install.sh' - applies to the master branch
      # tip as well, until the zsh support is merged into master
      Skip if "released xsh versions predate zsh support" [ -n "${ZSH_VERSION:-}" ]
      # shellcheck source=/dev/null
      install () { bash "${SHELLSPEC_PROJECT_ROOT}"/install.sh -b master; . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path "${XSH_HOME}" should be directory
      The path "${XSH_HOME}"/xsh/xsh.sh should be file
      The path "${XSH_DEV_HOME}" should be directory
      The result of function exported_functions should include 'xsh'
      End
  End

  Describe 'boot'
    It 'run boot through web'
      # see the skip note in 'run install.sh' - boot installs from the
      # published master branch, which predates zsh support until merged
      Skip if "released xsh versions predate zsh support" [ -n "${ZSH_VERSION:-}" ]
      # shellcheck source=/dev/null
      install () { curl -s https://raw.githubusercontent.com/alexzhangs/xsh/master/boot | bash -s -- -f && . ~/.xshrc; }
      When call install
      The status should be success
      The output should include ''
      The error should include ''
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
      The path "${XSH_HOME}" should be directory
      The path "${XSH_HOME}"/xsh/xsh.sh should be file
      The path "${XSH_DEV_HOME}" should be directory
      The result of function exported_functions should include 'xsh'
    End
  End
End
