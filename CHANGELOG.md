# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitHub Actions workflow for unit tests with coverage, replacing Travis CI.

### Removed

- Travis CI configuration retired in favor of GitHub Actions.

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

[Unreleased]: https://github.com/alexzhangs/xsh/compare/0.5.3...HEAD
[0.5.3]: https://github.com/alexzhangs/xsh/compare/0.5.2...0.5.3
[0.5.2]: https://github.com/alexzhangs/xsh/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/alexzhangs/xsh/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/alexzhangs/xsh/compare/0.4.9...0.5.0
[0.4.9]: https://github.com/alexzhangs/xsh/compare/0.4.8...0.4.9
[0.4.8]: https://github.com/alexzhangs/xsh/compare/0.4.7...0.4.8
[0.4.7]: https://github.com/alexzhangs/xsh/compare/0.4.6...0.4.7
[0.4.6]: https://github.com/alexzhangs/xsh/compare/0.2.0...0.4.6
[0.2.0]: https://github.com/alexzhangs/xsh/releases/tag/0.2.0
