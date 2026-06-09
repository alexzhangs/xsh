#? Description:
#?   This is the main test case for the project.
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/xsh_func_spec.sh
#?
Describe 'xsh.sh'
  Include xsh.sh
  exported_functions () { declare -Fx | awk '{print $3}'; }

  Describe 'environments'
    It 'show XSH environment variables'
      The variable XSH_HOME should be exported
      The variable XSH_DEV_HOME should be exported
    End

    It 'show XSH paths'
      The path "${XSH_HOME}" should be directory
      The path "${XSH_HOME}"/xsh/xsh.sh should be file
      The path "${XSH_DEV_HOME}" should be directory
    End
  End

  Describe 'commands'
    It 'list available versions of xsh'
      When call xsh versions
      The status should be success
      The output should include 'bootstrap'
    End

    It 'show current version of xsh'
      When call xsh version
      The status should be success
      The lines of output should equal 1
    End

    It 'show help of xsh'
      When call xsh
      The status should be failure
      The error should include 'Usage'
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

    It 'show code of xsh help'
      When call xsh help -c help
      The status should be success
      The output should include 'function __xsh_help'
    End

    It 'show help of xsh update with suffix help'
      When call xsh update help
      The status should be success
      The output should include 'Usage'
    End

    It 'show code of xsh update with suffix help'
      When call xsh update help -c
      The status should be success
      The output should include 'function __xsh_update'
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

    It 'routes warning level to stderr'
      When call xsh log warning 'something suspect'
      The status should be success
      The error should include 'WARNING: something suspect'
    End

    It 'routes debug level to stdout'
      When call xsh log debug 'debugging info'
      The status should be success
      The output should include 'DEBUG: debugging info'
    End

    It 'routes fatal level to stderr'
      When call xsh log fatal 'critical failure'
      The status should be success
      The error should include 'FATAL: critical failure'
    End

    It 'routes unknown level to stdout preserving all args'
      When call xsh log notice 'just a note'
      The status should be success
      The output should include 'notice just a note'
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
      The error should include ''
      The path "${XSH_HOME}"/repo/xsh-lib/core should be directory
      The path "${XSH_HOME}"/lib/x should be symlink
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
      The result of function exported_functions should include 'x-string-upper'
    End

    It 'call calls /string/random'
      When call xsh calls /string/random
      The status should be success
      The output should not equal ''
      The result of function exported_functions should include 'x-string-random'
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
      The result of function exported_functions should include 'x-date-adjust'
      The variable XSH_X_DATE__POSIX_FMT should be exported
      The variable __XSH_INIT__ should be present
    End

    It 'unimports /date/adjust'
      When call xsh unimports /date/adjust
      The status should be success
      The output should equal ''
      The result of function exported_functions should not include 'x-date-adjust'
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

    It 'call /file/inject'
      BeforeCall 'touch /tmp/.xsh-file-inject'
      AfterCall 'rm -f /tmp/.xsh-file-inject'
      When call xsh /file/inject -c bar -p end /tmp/.xsh-file-inject
      The status should be success
    End

    It 'update library xsh-lib/core to latest stable version'
      When call xsh update xsh-lib/core
      The status should be success
      The output should not equal ''
      The error should include ''
    End

    It 'update library xsh-lib/core to latest version'
      When call xsh update -b master xsh-lib/core
      The status should be success
      The output should not equal ''
      The error should include ''
    End
  End

  Describe 'builtins'
    It 'call mime-type'
      When call xsh mime-type /bin/ls
      The status should be success
      The output should start with 'application/'
    End

    It 'sends output to stderr for a non-existent file'
      When call xsh mime-type /nonexistent/xsh/coverage/test/file
      The status should be success
      The error should not equal ''
      The output should equal ''
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

    It 'returns 2 when ver1 is less than ver2'
      When call xsh version-comparator '0.1' '0.2'
      The status should be success
      The output should equal '2'
    End

    It 'returns 0 for byte-identical version strings'
      When call xsh version-comparator '1.2.3' '1.2.3'
      The status should be success
      The output should equal '0'
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
      The path "${XSH_DEV_HOME}"/x should be symlink
    End

    It 'call imports /string/foo'
      When call xsh imports /string/foo
      The status should be failure
      The error should include 'not found'
    End

    It 'call imports /string with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      When call xsh imports /string
      The status should be success
      The result of function exported_functions should include 'x-string'
    End

    It 'call unimports /string with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      When call xsh unimports /string
      The status should be success
      The result of function exported_functions should not include 'x-string'
    End

    It 'call imports /string/foo with XSH_DEV=1'
      BeforeCall 'export XSH_DEV=1'
      When call xsh imports /string/foo
      The status should be success
      The result of function exported_functions should include 'x-string-foo'
    End

    It 'call unimports /string/foo with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      When call xsh unimports /string/foo
      The status should be success
      The result of function exported_functions should not include 'x-string-foo'
    End

    It 'call imports /string/foo with XSH_DEV=/string/foo'
      BeforeCall 'export XSH_DEV=/string/foo'
      When call xsh imports /string/foo
      The status should be success
      The result of function exported_functions should include 'x-string-foo'
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
      The result of function exported_functions should not include 'x-string-foo'
    End

    It 'call /string/foo with XSH_DEV=/string'
      BeforeCall 'export XSH_DEV=/string'
      When call xsh /string/foo
      The status should be success
      The output should equal 'foo'
      The result of function exported_functions should not include 'x-string-foo'
    End

    It 'call /string/foo with XSH_DEV=/string/foo'
      BeforeCall 'export XSH_DEV=/string/foo'
      When call xsh /string/foo
      The status should be success
      The output should equal 'foo'
      The result of function exported_functions should not include 'x-string-foo'
    End
  End

  Describe 'additional coverage'
    Describe '__xsh_repeat'
      It 'returns empty output for an empty string'
        When call xsh repeat '' 3
        The status should be success
        The output should equal ''
      End

      It 'repeats a string once by default'
        When call xsh repeat 'abc'
        The status should be success
        The output should equal 'abc'
      End

      It 'repeats a string N times'
        When call xsh repeat '-' 5
        The status should be success
        The output should equal '-----'
      End
    End

    Describe '__xsh_complete_lpue'
      It 'prepends x as default lib for a leading-slash LPUE'
        When call xsh complete-lpue '/string/upper'
        The status should be success
        The output should equal 'x/string/upper'
      End

      It 'leaves LPUE unchanged when it already has a lib prefix'
        When call xsh complete-lpue 'x/string/upper'
        The status should be success
        The output should equal 'x/string/upper'
      End

      It 'fails with empty input'
        When call xsh complete-lpue ''
        The status should be failure
        The stderr should include 'is null or not set'
      End
    End

    Describe '__xsh_complete_lpur'
      It 'expands a single-segment LPUR to lib/* wildcard'
        When call xsh complete-lpur 'x'
        The status should be success
        The output should equal 'x/*'
      End

      It 'prepends default lib for a leading-slash LPUR (no wildcard expansion)'
        When call xsh complete-lpur '/string'
        The status should be success
        The output should equal 'x/string'
      End

      It 'expands a trailing-slash LPUR to lib/pkg/* wildcard'
        When call xsh complete-lpur 'x/string/'
        The status should be success
        The output should equal 'x/string/*'
      End

      It 'leaves a full three-segment LPUE unchanged'
        When call xsh complete-lpur 'x/string/upper'
        The status should be success
        The output should equal 'x/string/upper'
      End

      It 'fails with empty input'
        When call xsh complete-lpur ''
        The status should be failure
        The stderr should include 'is null or not set'
      End
    End

    Describe '__xsh_get_lpuc_by_lpue'
      It 'converts a full LPUE to its hyphenated LPUC form'
        When call xsh get-lpuc-by-lpue 'x/string/upper'
        The status should be success
        The output should equal 'x-string-upper'
      End

      It 'prepends default lib and converts a leading-slash LPUE'
        When call xsh get-lpuc-by-lpue '/string/upper'
        The status should be success
        The output should equal 'x-string-upper'
      End

      It 'fails with empty input'
        When call xsh get-lpuc-by-lpue ''
        The status should be failure
        The stderr should include 'is null or not set'
      End
    End

    Describe '__xsh_get_util_by_path'
      It 'extracts the util name by stripping directory and .sh extension'
        When call xsh get-util-by-path '/some/lib/functions/string/upper.sh'
        The status should be success
        The output should equal 'upper'
      End

      It 'strips a trailing numeric selector file from the util directory'
        # xsh-lib/core convention: a util may be split across selector files
        # under a directory named for the util (e.g. string/repeat/{1,2,...}.sh).
        # The util name is the parent directory, not the selector filename.
        When call xsh get-util-by-path '/some/lib/functions/string/repeat/1.sh'
        The status should be success
        The output should equal 'repeat'
      End
    End

    Describe '__xsh_get_type_by_path'
      It 'returns functions for a path under the functions tree'
        When call xsh get-type-by-path "${XSH_HOME}/lib/x/functions/string/upper.sh"
        The status should be success
        The output should equal 'functions'
      End

      It 'returns scripts for a path under the scripts tree'
        When call xsh get-type-by-path "${XSH_HOME}/lib/x/scripts/string/upper.sh"
        The status should be success
        The output should equal 'scripts'
      End

      It 'fails with empty input'
        When call xsh get-type-by-path ''
        The status should be failure
        The stderr should include 'is null or not set'
      End
    End

    Describe '__xsh_get_lpue_by_path'
      It 'converts a functions-tree path to its LPUE'
        When call xsh get-lpue-by-path "${XSH_HOME}/lib/x/functions/string/upper.sh"
        The status should be success
        The output should equal 'x/string/upper'
      End

      It 'converts a scripts-tree path to its LPUE'
        When call xsh get-lpue-by-path "${XSH_HOME}/lib/x/scripts/string/upper.sh"
        The status should be success
        The output should equal 'x/string/upper'
      End
    End

    Describe '__xsh_get_title_by_path'
      It 'returns a [type] lpue formatted title for a functions path'
        When call xsh get-title-by-path "${XSH_HOME}/lib/x/functions/string/upper.sh"
        The status should be success
        The output should equal '[functions] x/string/upper'
      End
    End

    Describe '__xsh_get_funcname_from_file'
      setup () {
        printf 'function foo () {\n    echo foo\n}\nfunction bar () {\n    echo bar\n}\n' \
          > /tmp/xsh_coverage_func_test.sh
      }
      clean () {
        rm -f /tmp/xsh_coverage_func_test.sh
      }
      BeforeAll 'setup'
      AfterAll 'clean'

      It 'finds a single matching function name'
        When call xsh get-funcname-from-file /tmp/xsh_coverage_func_test.sh foo
        The status should be success
        The output should include '[functions] foo'
      End

      It 'finds all functions in a comma-separated name list'
        When call xsh get-funcname-from-file /tmp/xsh_coverage_func_test.sh 'foo,bar'
        The status should be success
        The output should include '[functions] foo'
        The output should include '[functions] bar'
      End
    End

    Describe '__xsh_get_funccode_from_file'
      setup () {
        printf 'function foo () {\n    echo foo\n}\n' \
          > /tmp/xsh_coverage_code_test.sh
      }
      clean () {
        rm -f /tmp/xsh_coverage_code_test.sh
      }
      BeforeAll 'setup'
      AfterAll 'clean'

      It 'extracts the complete function body'
        When call xsh get-funccode-from-file /tmp/xsh_coverage_code_test.sh foo
        The status should be success
        The output should include 'function foo'
        The output should include 'echo foo'
      End
    End

    Describe '__xsh_get_doc_from_file'
      setup () {
        printf '#? Description:\n#?   Test function.\n#?\nfunction foo () {\n    echo foo\n}\n' \
          > /tmp/xsh_coverage_doc_test.sh
      }
      clean () {
        rm -f /tmp/xsh_coverage_doc_test.sh
      }
      BeforeAll 'setup'
      AfterAll 'clean'

      It 'extracts the doc block for a named function'
        When call xsh get-doc-from-file /tmp/xsh_coverage_doc_test.sh foo
        The status should be success
        The output should include 'Description:'
        The output should include 'Test function.'
      End
    End

    Describe '__xsh_get_internal_functions'
      It 'lists internal __xsh_ function names'
        When call xsh get-internal-functions
        The status should be success
        The output should include '__xsh_log'
        The output should include '__xsh_repeat'
      End
    End

    Describe '__xsh_git_version'
      git_available () { command -v git >/dev/null 2>&1; }

      It 'returns a version string matching major.minor'
        Skip unless 'git is available' git_available
        When call xsh git-version
        The status should be success
        The output should match pattern '[0-9]*.[0-9]*'
      End
    End

    Describe '__xsh_git_get_current_branch'
      git_available () { command -v git >/dev/null 2>&1; }

      It 'returns a non-empty branch name or HEAD when in a git repo'
        Skip unless 'git is available' git_available
        cd "${SHELLSPEC_PROJECT_ROOT}"
        When call xsh git-get-current-branch
        The status should be success
        The output should not equal ''
      End
    End
  End

  Describe 'last thing to do'
    It 'unload library xsh-lib/core'
      When call xsh unload xsh-lib/core
      The status should be success
      The output should equal ''
      The error should include ''
      The path "${XSH_HOME}"/repo/xsh-lib/core should not be exist
      The path "${XSH_HOME}"/lib/x should not be exist
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
      The error should include ''
    End

    It 'upgrade xsh to latest version'
      When call xsh upgrade -b master
      The status should be success
      The output should not equal ''
      The error should include ''
    End

    It 'check if the local env is clean'
      When call set
      The output should not match pattern '^__xsh'
    End
  End
End
