# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.2] - 2026-06-11

### Fixed

- **No more ANSI escape garbage in completions** (e.g. `x/dotfile/diff^[[0m`)
  on stock macOS bash 3.2. `xsh help` (`__xsh_help`) unconditionally piped its
  output through an awk formatter that wrapped every line in bold escapes, even
  when stdout was not a TTY — so pipe consumers such as the tab-completer
  received the raw escapes. The formatter is now gated on `[ -t 1 ]` (plain
  `cat` otherwise), per the standard Unix convention; terminal output is still
  bolded. (Low-impact behavior change: tooling that grepped ANSI bold sequences
  from piped `xsh help` now sees plain text.)
- **~500ms delay on every TAB press** eliminated. The completer ran
  `xsh list '*'` — walking every loaded library — on each TAB. The LPUE list is
  now cached in a shell-global (`_XSH_COMPLETE_LPUE_CACHE`), populated lazily
  (cold ~581 ms → warm ~1 ms). Refresh after `xsh load`/`unload`/`update` with
  `unset _XSH_COMPLETE_LPUE_CACHE`.

### Added

- Substantially expanded the `xsh.sh` test suite (`spec/xsh_func_spec.sh`):
  error/guard branches (null-argument paths, `git-clone`/`git-force-update`
  option and failure handling, `lib-manager`/`lib-get-cfg-property` errors,
  `__xsh_help_self` cache rebuild, scripts-type util import/exec/unimport,
  the `init runtime` decorator, environment guards, and more). Library line
  coverage rose from ~76% to ~90%.

### Changed

- Coverage is now scoped to the library (`xsh.sh`) in `.shellspec`. `install.sh`
  and `boot` run as child `bash` processes, which kcov's bash tracer cannot
  instrument, so they always reported 0% despite `spec/install_spec.sh`
  exercising them end-to-end; counting them understated real coverage. They
  remain integration-tested rather than line-counted.

## [0.6.1] - 2026-06-08

### Fixed

- **Bash tab-completion now works on stock macOS bash 3.2** without requiring
  the `bash-completion` package. The 0.6.0 completion script called
  `_init_completion` from bash-completion, which on macOS native `/bin/bash`
  (3.2.57) was silently absent because `bash-completion@2` requires bash 4+
  and bails. The completion script now ships an `_init_completion` fallback
  shim guarded by `declare -F` — a real bash-completion load (now or later)
  still wins, so behavior on Linux and bash-completion-enabled setups is
  unchanged.
- `.xshrc` now auto-sources the completion file, so users don't need to
  edit `~/.bash_profile` or rely on `/etc/bash_completion.d/` discovery
  (which doesn't exist on stock macOS).

### Removed

- `install.sh` no longer copies `xsh.bash` into `/etc/bash_completion.d/` —
  redundant on Linux (now sourced via `.xshrc`) and a no-op on macOS.

### Changed

- **Test correction** — the `__xsh_get_util_by_path` Pending test added in
  0.6.0 assumed selectors are encoded as a leading `<N>-` basename prefix
  (e.g. `2-upper.sh`). Every selector in xsh-lib/core actually uses the
  opposite convention: the util is a directory, selectors are plain-numeric
  filenames inside it (e.g. `string/repeat/{1..8}.sh`). The existing
  implementation already strips that form correctly. Test replaced with a
  passing assertion of the real convention; no production code change.

## [0.6.0] - 2026-06-08

### Added

- **Bash and zsh tab-completion** for the `xsh` command and LPUE expressions
  (`completions/xsh.bash`, `completions/_xsh`). The bash completion is
  auto-installed to `/etc/bash_completion.d/xsh` when writable.
- **Multi-bash-version CI matrix** covering bash 3.2 (macOS native), bash 4.4
  (rockylinux:8 container — required gate, with explicit `dnf install git`
  before checkout so actions/checkout@v5 uses git instead of the REST tarball
  fallback, and `coreutils` swap from rocky's `coreutils-single`), bash 5.x
  (macOS Homebrew + Linux). Catches version-specific bugs the previous Travis
  pipeline missed — already paid for itself by catching a GHA shell-default
  inconsistency (containers default to `sh -e`, hosted runners to `bash`).
- **Release workflow** (`.github/workflows/release.yml`) — version-tag pushes
  now auto-create GitHub releases via gh CLI.
- **OSS community health files** — `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1),
  `SECURITY.md`, `CHANGELOG.md` (this file), `CONTRIBUTING.md`, GitHub issue and
  PR templates under `.github/`.
- **Variable taxonomy diagram** (`variable-type.drawio`) — clean 2x2 matrix
  documenting the three orthogonal bash variable dimensions (declared/undeclared,
  exported/shell-local, scalar/array/integer).
- **Coverage tests for previously-untested internal functions** — `__xsh_repeat`,
  `__xsh_log`, `__xsh_version_comparator`, `__xsh_complete_lpue`/`lpur`,
  `__xsh_get_*` family, `__xsh_git_*` family. Coverage rose from ~62% to ~80%.
- **Internal-function docstring backfill** — 10 placeholder `TODO` lines on
  internal `__xsh_*` helpers replaced with real `#? Description:` blocks.

### Changed

- **README polish** — added table of contents, fixed section numbering, updated
  version references, reorganized Roadmap.
- **Single consolidated CI workflow** (`ci.yml`) replaces the two prior
  `ci-unittest.yml` + `ci-multiversion.yml` workflows; uses an os×bash-version
  matrix so coverage and compatibility are tested in one pipeline.
- **Spec files renamed** to reflect actual test level — `xsh_spec.sh` →
  `xsh_func_spec.sh`, `installer_spec.sh` → `install_spec.sh`. The redundant
  `xsh_unit_spec.sh` (originally added as `xsh_coverage_spec.sh`) was merged
  back into `xsh_func_spec.sh` — the unit/func split didn't hold up, both
  tested the public dispatch.
- **Installer hardening** — `boot` now uses `mktemp -d` with a cleanup trap
  instead of `${RANDOM}` plus manual `rm`.
- **`.xshrc` zsh-safe** — non-bash shells exit early instead of erroring on
  the bash-only function definition.

### Fixed

- **`install.sh` exit codes** — non-zero exits now return `1` (was `255`);
  `-h` now exits `0` (was treated as an error).
- **ShellCheck false positives** documented in `.shellcheckrc` with
  `SC2148,SC2317,SC2329,SC2086` (sourced-file shebang, dynamic dispatch
  warnings, intentional `return ${ret}` numeric pattern).
- **CI shell consistency** — explicit `defaults.run.shell: bash` on the
  workflow so process substitution in `xsh.sh` doesn't fail under container
  default `sh -e`.
- **Dead `git.io` shellspec installer URL** replaced with the canonical
  `raw.githubusercontent.com` URL across CI and local-ci-test.sh.
- **6 broken test assertions** carried over from the coverage spec — 4
  stderr-leak warnings (added `The stderr should include`), 1 wrong
  assertion fix (`complete-lpur '/string'` doesn't expand to wildcard),
  1 production bug surfaced as `Pending` (`__xsh_get_util_by_path` strips
  the wrong segment for numeric-selector filenames).

### Removed

- **Dead regression specs** — `spec/foo_spec.sh` and `spec/bar_spec.sh` were
  regression tests for ShellSpec issue #214 (bash 4.3.2 kcov segfault, fixed
  upstream in bash 4.4.0). No version in the matrix is affected.

## [0.5.3] - 2024-03-15

### Changed

- README.md updated with documentation for xsh library INIT files and decorators.

## [0.5.2] - 2024-02-29

### Changed

- Improved help documentation for the `xsh` command.
- Minor document fixes.

### Fixed

- ShellCheck linting issues resolved across the codebase.

## [0.5.1] - 2022-04-18

### Changed

- Various improvements to `xsh.sh`.

## [0.5.0] - 2022-04-17

### Changed

- Updated `xsh.sh` with improvements.
- Updated `local-ci-test.sh`.
- Updated `xsh_spec.sh` test suite.

## [0.4.9] - 2022-04-16

### Changed

- Updated `xsh.sh` with bug fixes and improvements.
- Updated README.md.

### Fixed

- Fixed typo in `xsh.sh`.

## [0.4.8] - 2021-10-11

### Added

- CNAME file added; GitHub Pages adopted for project site.
- `_config.yml` for GitHub Pages configuration.
- MIT LICENSE file.

## [0.4.7] - 2021-05-27

### Added

- Kcov coverage integration in CI.

### Changed

- Refactored dynamic code formatting.
- Improved tag management: allow moving tags on remote.
- Refactored internals to reduce debug output.

### Fixed

- Decorator not applied for functions with numbers or underscores in name (ShellSpec issue #214).
- Failed to get `mime_type`.
- Various issues in `local-ci-test.sh`.

## [0.4.6] - 2021-04-29

### Added

- Kcov coverage integration.
- Dev mode fully enabled with support for INIT file decorators.
- ShellSpec test adapter.
- Installer options `-s` and `-b BRANCH`.

### Fixed

- Multiple bug fixes across the framework.

## [0.2.0] - 2021-03-07

### Added

- Initial working implementation: load scripts, functions, and the bash library framework.

[Unreleased]: https://github.com/alexzhangs/xsh/compare/0.6.1...HEAD
[0.6.1]: https://github.com/alexzhangs/xsh/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/alexzhangs/xsh/compare/0.5.3...0.6.0
[0.5.3]: https://github.com/alexzhangs/xsh/compare/0.5.2...0.5.3
[0.5.2]: https://github.com/alexzhangs/xsh/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/alexzhangs/xsh/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/alexzhangs/xsh/compare/0.4.9...0.5.0
[0.4.9]: https://github.com/alexzhangs/xsh/compare/0.4.8...0.4.9
[0.4.8]: https://github.com/alexzhangs/xsh/compare/0.4.7...0.4.8
[0.4.7]: https://github.com/alexzhangs/xsh/compare/0.4.6...0.4.7
[0.4.6]: https://github.com/alexzhangs/xsh/compare/0.2.0...0.4.6
[0.2.0]: https://github.com/alexzhangs/xsh/releases/tag/0.2.0
