Describe 'xsh.sh'
  Include xsh.sh

  Describe 'environments'
    It 'show XSH environment variables'
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
    End

    It 'show XSH paths'
      The path ${XSH_HOME} should be directory
      The path ${XSH_DEV_HOME} should be directory
    End
  End

  Describe 'commands'
    It 'list available versions of xsh'
      When call xsh versions
      The status should be success
      The output should include '0.2.0'
    End

    It 'show current version of xsh'
      When call xsh version
      The status should be success
      The lines of output should equal 1
    End

    It 'show help of xsh'
      When call xsh help
      The status should be success
      The output should include 'Usage'
    End

    It 'show help of xsh help'
      When call xsh help help
      The status should be success
      The output should include 'Usage'
    End

    It 'call log info'
      When call xsh log info 'something normal'
      The status should be success
      The output should include 'INFO: something normal'
    End

    It 'call log error'
      When call xsh log error 'something wrong'
      The status should be success
      The error should include 'ERROR: something wrong'
    End

    It 'show loaded libraries of xsh'
      When call xsh list
      The status should be success
      The output should equal ''
    End

    It 'load library xsh-lib/core'
      When call xsh load xsh-lib/core
      The status should be success
      The output should not equal ''
      The path ${XSH_HOME}/repo/xsh-lib/core should be directory
      The path ${XSH_HOME}/lib/x should be symlink
    End

    It 'show loaded libraries of xsh'
      When call xsh list
      The status should be success
      The word 1 of line 1 should equal 'x'
    End

    It 'list the utils of library core'
      When call xsh list /
      The status should be success
      The output should include 'functions'
    End

    It 'show help of /string/upper'
      When call xsh help /string/upper
      The status should be success
      The output should include '/string/upper'
    End

    It 'show code of /string/upper'
      When call xsh help -c /string/upper
      The status should be success
      The output should include 'function upper'
    End

    It 'call /string/upper'
      When call xsh /string/upper 'Hello World'
      The status should be success
      The output should equal 'HELLO WORLD'
    End

    It 'call calls /string/random'
      When call xsh calls /string/random
      The status should be success
      The output should not equal ''
    End

    It 'call debug xsh /string/random'
      When call xsh debug xsh /string/random
      The status should be success
      The output should not equal ''
      The error should include '+'
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
    End

    It 'call calls /string/random'
      When call xsh calls /string/random
      The status should be success
      The output should not equal ''
    End

    It 'call /string/random with XSH_DEBUG=1'
      BeforeCall 'export XSH_DEBUG=1'
      When call xsh /string/random
      The status should be success
      The output should not equal ''
      The error should include '+'
    End

    It 'call /string/upper with XSH_DEBUG=/string/pipe/upper'
      BeforeCall 'export XSH_DEBUG=/string/pipe/upper'
      When call xsh /string/upper 'Hello World'
      The status should be success
      The output should equal 'HELLO WORLD'
      The error should include '+'
    End

    It 'update library xsh-lib/core to latest stable version'
      When call xsh update xsh-lib/core
      The status should be success
      The output should not equal ''
    End

    It 'update library xsh-lib/core to latest version'
      When call xsh update -b master xsh-lib/core
      The status should be success
      The output should not equal ''
    End
  End

  Describe 'builtins'
    It 'call mime-type'
      When call xsh mime-type /bin/ls
      The status should be success
      The output should start with 'application/'
    End

    It 'call shell-option h +v -x'
      When call xsh shell-option h +v -x
      The status should be success
      The output should equal '-h +vx'
    End

    It 'call shell-option h'
      When call xsh shell-option h
      The status should be success
      The output should equal '-h'
    End

    It 'call shell-option +v -x'
      When call xsh shell-option +v -x
      The status should be success
      The output should equal '+vx'
    End

    It 'call shell-option'
      When call xsh shell-option
      The status should be success
      The output should equal ''
    End

    It 'call call-with-shell-option'
      When call xsh call-with-shell-option -1 x echo foo
      The status should be success
      The output should equal 'foo'
      The error should include '+'
    End

    It 'call count-in-funcstack'
      When call xsh count-in-funcstack xsh
      The status should be success
      The output should equal '1'
    End

    It 'call version-comparator'
      When call xsh version-comparator '0.1' '0.1.0'
      The status should be success
      The output should equal '0'
    End

    It 'call version-comparator'
      When call xsh version-comparator '0.1.10' '0.1.2'
      The status should be success
      The output should equal '1'
    End

    It 'call sha1sum'
      Data
        #|foo
      End
      When call xsh sha1sum
      The status should be success
      The word 1 of output should equal 'f1d2d2f924e986ac86fdf7b36c94bcdf32beec15'
    End

    It 'call get-init-files'
      When call xsh get-init-files "${XSH_HOME}/lib/x/functions/date"
      The status should be success
      The lines of output should equal 2
      The line 1 should end with 'lib/x/functions/date/__init__.sh'
      The line 2 should end with 'lib/x/functions/__init__.sh'
    End
  End

  Describe 'dev mode'
    setup () {
        cp -a "${XSH_HOME}"/repo/xsh-lib /tmp
        cp -a "${SHELLSPEC_PROJECT_ROOT}"/spec/foo.sh /tmp/xsh-lib/core/functions/string/
    }
    clean () {
        rm -rf /tmp/xsh-lib
    }
    BeforeAll 'setup'
    AfterAll 'clean'

    It 'call lib-dev-manager link'
      When call xsh lib-dev-manager link xsh-lib/core /tmp
      The status should be success
      The output should equal ''
      The path ${XSH_DEV_HOME}/x should be symlink
    End

    It 'call imports /string/foo'
      When call xsh imports /string/foo
      The status should be failure
      The error should include 'not found'
    End

    It 'call imports /string with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      AfterCall 'unset -f x-string-foo'
      When call xsh imports /string
      The status should be success
      The function 'x-string-foo' should equal 'x-string-foo'
    End

    It 'call imports /string with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      AfterCall 'unset -f x-string-foo'
      When call xsh imports /string
      The status should be success
      The function 'x-string-foo' should equal 'x-string-foo'
    End

    It 'call imports /string/foo with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      AfterCall 'unset -f x-string-foo'
      When call xsh imports /string/foo
      The status should be success
      The function 'x-string-foo' should equal 'x-string-foo'
    End

    It 'call imports /string/foo with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      AfterCall 'unset -f x-string-foo'
      When call xsh imports /string/foo
      The status should be success
      The function 'x-string-foo' should equal 'x-string-foo'
    End

    It 'call imports /string/foo with XSH_DEV=/string/foo'
      BeforeCall 'export XSH_DEV=/string/foo'
      AfterCall 'unset -f x-string-foo'
      When call xsh imports /string/foo
      The status should be success
      The function 'x-string-foo' should equal 'x-string-foo'
    End

    It 'call list with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      When call xsh list
      The status should be success
      The output should include 'xsh-lib/core'
    End

    It 'call list /string/foo with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      When call xsh list /string/foo
      The status should be success
      The output should include 'x/string/foo'
    End

    It 'call list /string/foo with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      When call xsh list /string/foo
      The status should be success
      The output should include 'x/string/foo'
    End

    It 'call help /string/foo with XSH_DEV=/string/foo'
      BeforeCall 'export XSH_DEV=/string/foo'
      When call xsh help /string/foo
      The status should be success
      The output should include 'Usage'
    End

    It 'call help /string/foo with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      When call xsh help /string/foo
      The status should be success
      The output should include 'Usage'
    End

    It 'call help /string/foo with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      When call xsh help /string/foo
      The status should be success
      The output should include 'Usage'
    End

    It 'call help /string/foo with XSH_DEV=/string/foo'
      BeforeCall 'export XSH_DEV=/string/foo'
      When call xsh help /string/foo
      The status should be success
      The output should include 'Usage'
    End

    It 'call /string/foo with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      When call xsh /string/foo
      The status should be success
      The output should equal 'foo'
    End

    It 'call /string/foo with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      When call xsh /string/foo
      The status should be success
      The output should equal 'foo'
    End

    It 'call /string/foo with XSH_DEV=/string/foo'
      BeforeCall 'export XSH_DEV=/string/foo'
      When call xsh /string/foo
      The status should be success
      The output should equal 'foo'
    End
  End

  Describe 'last thing to do'
    It 'unload library xsh-lib/core'
      When call xsh unload xsh-lib/core
      The status should be success
      The output should equal ''
      The path ${XSH_HOME}/repo/xsh-lib/core should not be exist
      The path ${XSH_HOME}/lib/x should not be exist
    End

    It 'show loaded libraries of xsh'
      When call xsh list
      The status should be success
      The output should equal ''
    End

    It 'upgrade xsh to latest stable version'
      When call xsh upgrade
      The status should be success
      The output should not equal ''
    End

    It 'check if the local env is clean'
      When call set
      The output should not match pattern '^__xsh'
    End
  End
End