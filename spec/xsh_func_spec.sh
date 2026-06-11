#? Description:
#?   This is the main test case for the project.
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/xsh_func_spec.sh
#?
Describe 'xsh.sh'
  # `./`-prefixed: zsh's `.` builtin searches only PATH (not CWD) for
  # unprefixed names, while bash falls back to CWD
  Include ./xsh.sh
  # zsh cannot export functions to the environment, so the equivalent check
  # under zsh is "is the function defined" (`typeset +f` lists the names).
  if [ -n "${ZSH_VERSION:-}" ]; then
    exported_functions () { typeset +f; }
  else
    exported_functions () { declare -Fx | awk '{print $3}'; }
  fi

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
      # NOTE: under zsh this needs xsh-lib/core > 0.5.0 (x/trap/return ported
      # to zsh with a cascade of function-scoped EXIT traps)
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

    # `h` (bash hashall) is on by default in bash scripts and shows in `$-`;
    # zsh has no `h` in its `$-`, so it is correctly reported as off there
    It 'call shell-option h +v -x'
      When call xsh shell-option h +v -x
      The status should be success
      The output should equal "$([ -n "${ZSH_VERSION:-}" ] && echo '+hvx' || echo '-h +vx')"
    End

    It 'call shell-option h'
      When call xsh shell-option h
      The status should be success
      The output should equal "$([ -n "${ZSH_VERSION:-}" ] && echo '+h' || echo '-h')"
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

  Describe 'error and edge-case coverage'
    # xsh-lib/core (lib `x`) is loaded at this point in the suite.

    Describe '__xsh_call_with_shell_option'
      It 'fails on an unrecognized option'
        When call xsh call-with-shell-option -z echo foo
        The status should be failure
        The stderr should include ''
      End

      It 'runs a text script with the requested shell options'
        setup () { printf '#!/bin/bash\necho scripted\n' > /tmp/xsh-cwso.sh; chmod +x /tmp/xsh-cwso.sh; }
        clean () { rm -f /tmp/xsh-cwso.sh; }
        BeforeCall 'setup'
        AfterCall 'clean'
        When call xsh call-with-shell-option -1 x /tmp/xsh-cwso.sh
        The status should be success
        The output should equal 'scripted'
        The error should include '+'
      End
    End

    Describe '__xsh_chmod_x_by_dir'
      It 'chmods .sh files under a directory'
        setup () { rm -rf /tmp/xsh-cxd && mkdir -p /tmp/xsh-cxd/sub && touch /tmp/xsh-cxd/sub/a.sh; }
        clean () { rm -rf /tmp/xsh-cxd; }
        BeforeCall 'setup'
        AfterCall 'clean'
        When call xsh chmod-x-by-dir /tmp/xsh-cxd
        The status should be success
      End
    End

    Describe '__xsh_git_chmod_x'
      It 'chmods the ./scripts dir when present'
        setup () { rm -rf /tmp/xsh-gcx && mkdir -p /tmp/xsh-gcx/scripts && touch /tmp/xsh-gcx/scripts/a.sh; }
        clean () { rm -rf /tmp/xsh-gcx; }
        BeforeCall 'setup'
        AfterCall 'clean'
        BeforeCall 'cd /tmp/xsh-gcx'
        When call xsh git-chmod-x
        The status should be success
      End
    End

    Describe '__xsh_git_clone'
      It 'fails when no repo is given'
        When call xsh git-clone
        The status should be failure
        The stderr should include 'Repo name is null'
      End

      It 'fails on an unrecognized option'
        When call xsh git-clone -z
        The status should be failure
        The stderr should not equal ''
      End

      It 'fails when the git server is empty'
        When call xsh git-clone -s '' some/repo
        The status should be failure
        The stderr should include 'Git server is null'
      End

      It 'fails when the repo already exists'
        When call xsh git-clone xsh-lib/core
        The status should be failure
        The stderr should include 'already exists'
      End

      It 'rejects -b and -t together'
        When call xsh git-clone -b master -t 1.0.0 nonexist/repo
        The status should be failure
        The stderr should include "can't be used together"
      End

      It 'cleans up after a failed clone'
        When call xsh git-clone -s https://github.com xsh-nonexistent-zzz/xsh-nonexistent-zzz
        The status should be failure
        The stderr should include ''
      End
    End

    Describe '__xsh_git_force_update'
      It 'fails on an unrecognized option'
        When call xsh git-force-update -z
        The status should be failure
        The stderr should not equal ''
      End

      It 'fails when no tagged version exists'
        setup () {
          rm -rf /tmp/xsh-gnt && mkdir -p /tmp/xsh-gnt && cd /tmp/xsh-gnt \
            && git init -q \
            && git -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init \
            && git remote add origin /tmp/xsh-gnt
        }
        clean () { rm -rf /tmp/xsh-gnt; }
        BeforeCall 'setup'
        AfterCall 'clean'
        BeforeCall 'cd /tmp/xsh-gnt'
        When call xsh git-force-update
        The status should be failure
        The stderr should include 'No any available tagged version'
      End

      It 'fails to checkout a nonexistent target'
        setup () {
          rm -rf /tmp/xsh-gfu && mkdir -p /tmp/xsh-gfu && cd /tmp/xsh-gfu \
            && git init -q \
            && git -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init \
            && git tag 0.1.0 \
            && git remote add origin /tmp/xsh-gfu
        }
        clean () { rm -rf /tmp/xsh-gfu; }
        BeforeCall 'setup'
        AfterCall 'clean'
        BeforeCall 'cd /tmp/xsh-gfu'
        When call xsh git-force-update -t 9.9.9
        The status should be failure
        The output should include 'Updating repo'
        The stderr should include 'Failed to checkout'
      End
    End

    Describe '__xsh_info'
      It 'fails when the path is empty'
        When call xsh info -d ''
        The status should be failure
        The stderr should include 'LPU path is null'
      End

      It 'fails on an unrecognized option'
        When call xsh info -z "${XSH_HOME}/xsh/xsh.sh"
        The status should be failure
        The stderr should not equal ''
      End

      It 'inserts a string per function name with -i'
        When call xsh info -f __xsh_log -i 'INSERTED' "${XSH_HOME}/xsh/xsh.sh"
        The status should be success
        The output should include 'INSERTED'
      End
    End

    Describe '__xsh_lib_get_cfg_property'
      It 'fails when the name is missing'
        When call xsh lib-get-cfg-property
        The status should be failure
        The stderr should include 'Lib or repo name is null'
      End

      It 'fails when the property is missing'
        When call xsh lib-get-cfg-property x
        The status should be failure
        The stderr should include 'Property name is null'
      End

      It 'fails when xsh.lib is not found'
        When call xsh lib-get-cfg-property nonexist/repo name
        The status should be failure
        The stderr should include 'Not found xsh.lib'
      End

      It 'reads a property from a loaded lib'
        When call xsh lib-get-cfg-property x name
        The status should be success
        The output should equal 'x'
      End
    End

    Describe '__xsh_lib_manager'
      It 'fails when the command is missing'
        When call xsh lib-manager
        The status should be failure
        The stderr should include 'Command is null'
      End

      It 'fails when the repo is missing'
        When call xsh lib-manager link
        The status should be failure
        The stderr should include 'Repo name is null'
      End

      It 'fails when the repo does not exist'
        When call xsh lib-manager link nonexist/repo
        The status should be failure
        The stderr should include "doesn't exist"
      End

      It 'fails on an unsupported command'
        When call xsh lib-manager bogus xsh-lib/core
        The status should be failure
        The stderr should include 'unsupported command'
      End
    End

    Describe '__xsh_apply_func_decorator'
      It 'fails for an unknown decorator'
        When call xsh apply-func-decorator nosuchdeco 'function f () { :; }'
        The status should be failure
        The stderr should include 'not found the function decorator'
      End
    End

    Describe 'null-argument guards'
      It 'load fails on an empty repo'
        When call xsh load ''
        The status should be failure
        The stderr should include 'Repo name is null'
      End

      It 'unload fails on an empty repo'
        When call xsh unload ''
        The status should be failure
        The stderr should include 'Repo name is null'
      End

      It 'update fails on an empty repo'
        When call xsh update ''
        The status should be failure
        The stderr should include 'Repo name is null'
      End

      It 'import fails on an empty lpur'
        When call xsh import ''
        The status should be failure
        The stderr should include 'LPUR is null'
      End

      It 'unimport fails on an empty lpur'
        When call xsh unimport ''
        The status should be failure
        The stderr should include 'LPUR is null'
      End

      It 'import-script fails on an empty path'
        When call xsh import-script ''
        The status should be failure
        The stderr should include 'LPU path is null'
      End

      It 'call fails on an empty lpue'
        When call xsh call ''
        The status should be failure
        The stderr should include 'LPUE is null'
      End

      It 'exec fails on an unrecognized option'
        When call xsh exec -z foo
        The status should be failure
        The stderr should not equal ''
      End

      It 'unimport silently skips a non-matching lpur'
        When call xsh unimport /string/nomatchzzz
        The status should be success
        The output should equal ''
      End
    End

    Describe '__xsh_load cleanup on link failure'
      # A local "git server" holding a repo that clones cleanly (it has a tag)
      # but whose xsh.lib has no `name=`, so `lib_manager link` fails and
      # __xsh_load deletes the half-installed repo.
      setup () {
        rm -rf /tmp/xsh-srv
        mkdir -p /tmp/xsh-srv/fakeuser/fakerepo
        ( cd /tmp/xsh-srv/fakeuser/fakerepo \
            && git init -q \
            && printf 'foo=bar\n' > xsh.lib \
            && git -c user.email=a@b.c -c user.name=t add -A \
            && git -c user.email=a@b.c -c user.name=t commit -q -m init \
            && git tag 1.0.0 )
      }
      clean () { rm -rf /tmp/xsh-srv "${XSH_HOME}/repo/fakeuser"; }
      BeforeCall 'setup'
      AfterCall 'clean'

      It 'deletes the repo when linking fails'
        When call xsh load -s /tmp/xsh-srv fakeuser/fakerepo
        The status should be failure
        The output should include 'Already at the latest'
        The stderr should include 'Deleting repo'
      End

      It 'get-lpue-by-lpur fails on empty input'
        When call xsh get-lpue-by-lpur ''
        The status should be failure
        The stderr should include 'LPUR is null'
      End

      It 'get-lpuc-by-lpur fails on empty input'
        When call xsh get-lpuc-by-lpur ''
        The status should be failure
        The stderr should include 'LPUR is null'
      End

      It 'get-title-by-path fails on an empty path'
        When call xsh get-title-by-path ''
        The status should be failure
        The stderr should include 'LPU path is null'
      End
    End

    Describe 'lpur resolution of loaded utils'
      It 'get-lpue-by-lpur resolves a loaded util'
        When call xsh get-lpue-by-lpur '/string/upper'
        The status should be success
        The output should include 'x/string/upper'
      End

      It 'get-lpuc-by-lpur resolves a loaded util'
        When call xsh get-lpuc-by-lpur '/string/upper'
        The status should be success
        The output should include 'x-string-upper'
      End
    End

    Describe 'environment guards'
      It 'fails when XSH_HOME is unset'
        BeforeCall 'unset XSH_HOME'
        When call xsh version
        The status should be failure
        The stderr should include 'XSH_HOME is not set'
      End

      It 'fails when XSH_DEV_HOME is unset'
        BeforeCall 'unset XSH_DEV_HOME'
        When call xsh version
        The status should be failure
        The stderr should include 'XSH_DEV_HOME is not set'
      End
    End

    Describe '__xsh_help_self'
      It 'renders self help, rebuilding the cache from scratch'
        setup () { rm -f /tmp/.__xsh_help_self_cache_*; }
        BeforeCall 'setup'
        When call xsh help
        The status should be success
        The output should include 'Commands:'
      End
    End

    Describe '__xsh_info -i without a function filter'
      It 'inserts a string verbatim'
        When call xsh info -i 'INSERTEDX' "${XSH_HOME}/xsh/xsh.sh"
        The status should be success
        The output should include 'INSERTEDX'
      End
    End

    Describe '__xsh_is_debug'
      It 'returns non-zero when XSH_DEBUG is unset'
        BeforeCall 'unset XSH_DEBUG'
        When call xsh is-debug /string/upper
        The status should be failure
      End
    End

    Describe '__xsh_lib_manager null lib name'
      setup () {
        mkdir -p "${XSH_HOME}/repo/fakeuser/fakerepo"
        printf 'foo=bar\n' > "${XSH_HOME}/repo/fakeuser/fakerepo/xsh.lib"
      }
      clean () { rm -rf "${XSH_HOME}/repo/fakeuser"; }
      BeforeCall 'setup'
      AfterCall 'clean'

      It 'fails when the lib name is empty in xsh.lib'
        When call xsh lib-manager link fakeuser/fakerepo
        The status should be failure
        The stderr should include 'library name is null'
      End
    End

    Describe '__xsh_func_decorator_init_runtime'
      setup () {
        mkdir -p "${XSH_HOME}/repo/xsh-lib/core/functions/spec"
        printf '#? @runtime\n:\n' \
          > "${XSH_HOME}/repo/xsh-lib/core/functions/spec/__init__.sh"
        printf '#? Usage:\n#?   @rtsample\n#?\nfunction rtsample () {\n    echo rt-sample-out\n}\n' \
          > "${XSH_HOME}/repo/xsh-lib/core/functions/spec/rtsample.sh"
      }
      clean () {
        rm -rf "${XSH_HOME}/repo/xsh-lib/core/functions/spec"
        unset -f x-spec-rtsample 2>/dev/null ||:
      }
      BeforeAll 'setup'
      AfterAll 'clean'

      It 'applies the runtime init decorator on import'
        When call xsh imports /spec/rtsample
        The status should be success
        The result of function exported_functions should include 'x-spec-rtsample'
      End
    End

    Describe 'scripts-type utility'
      setup () {
        mkdir -p "${XSH_HOME}/repo/xsh-lib/core/scripts/spec"
        printf '#? Usage:\n#?   @sample\n#?\necho script-sample-out\n' \
          > "${XSH_HOME}/repo/xsh-lib/core/scripts/spec/sample.sh"
        chmod +x "${XSH_HOME}/repo/xsh-lib/core/scripts/spec/sample.sh"
      }
      clean () {
        rm -rf "${XSH_HOME}/repo/xsh-lib/core/scripts/spec"
        rm -f /usr/local/bin/x-spec-sample
      }
      BeforeAll 'setup'
      AfterAll 'clean'

      It 'imports a script util as a bin symlink'
        When call xsh imports /spec/sample
        The status should be success
        The path /usr/local/bin/x-spec-sample should be symlink
      End

      It 'executes a script util'
        When call xsh /spec/sample
        The status should be success
        The output should include 'script-sample-out'
      End

      It 'unimports a script util'
        When call xsh unimports /spec/sample
        The status should be success
        The path /usr/local/bin/x-spec-sample should not be exist
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
      # `xsh upgrade` checks out the latest released tag and re-sources its
      # xsh.sh - released versions predating zsh support cannot be sourced
      # under zsh. Remove this skip after the first zsh-supporting release.
      Skip if "released xsh versions predate zsh support" [ -n "${ZSH_VERSION:-}" ]
      When call xsh upgrade
      The status should be success
      The output should not equal ''
      The error should include ''
    End

    It 'upgrade xsh to latest version'
      # see the skip note above - applies to the master branch tip as well,
      # until the zsh support is merged into master
      Skip if "released xsh versions predate zsh support" [ -n "${ZSH_VERSION:-}" ]
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
