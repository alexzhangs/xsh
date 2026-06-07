#? Description:
#?   Additional coverage tests for uncovered __xsh_* functions.
#?
#? Usage:
#?   shellspec --kcov -s /bin/bash spec/xsh_unit_spec.sh
#?
Describe 'xsh.sh additional coverage'
  Include xsh.sh

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

  Describe '__xsh_log'
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
  End

  Describe '__xsh_version_comparator'
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
    End
  End

  Describe '__xsh_complete_lpur'
    It 'expands a single-segment LPUR to lib/* wildcard'
      When call xsh complete-lpur 'x'
      The status should be success
      The output should equal 'x/*'
    End

    It 'expands a leading-slash LPUR to lib/pkg/* wildcard'
      When call xsh complete-lpur '/string'
      The status should be success
      The output should equal 'x/string/*'
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
    End
  End

  Describe '__xsh_get_util_by_path'
    It 'extracts the util name by stripping directory and .sh extension'
      When call xsh get-util-by-path '/some/lib/functions/string/upper.sh'
      The status should be success
      The output should equal 'upper'
    End

    It 'strips a leading numeric selector before the util name'
      When call xsh get-util-by-path '/some/lib/functions/string/2-upper.sh'
      The status should be success
      The output should equal 'upper'
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

  Describe '__xsh_mime_type'
    It 'sends output to stderr for a non-existent file'
      When call xsh mime-type /nonexistent/xsh/coverage/test/file
      The status should be success
      The error should not equal ''
      The output should equal ''
    End
  End
End
