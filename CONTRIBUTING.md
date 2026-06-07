# Contributing to xsh

Thank you for your interest in contributing to xsh!

## Prerequisites

- **bash 4+** — xsh requires associative arrays and other bash 4 features
- **git** — for cloning and version management
- **[shellspec](https://github.com/shellspec/shellspec)** — test framework used for all specs
- **[shellcheck](https://github.com/koalaman/shellcheck)** — static analysis; all code must pass

Install shellspec:

```bash
curl -fsSL https://git.io/shellspec | sh
```

Install shellcheck (macOS):

```bash
brew install shellcheck
```

## Development setup

1. **Fork and clone** the repository:

   ```bash
   git clone https://github.com/<your-fork>/xsh.git
   cd xsh
   ```

2. **Install xsh in dev mode** using the `-s` flag (skips the upgrade-to-latest-tag step, so the working tree is used as-is):

   ```bash
   bash install.sh -s
   source ~/.xshrc
   ```

3. **Symlink your working copy** for dev mode so `xsh` picks up your local edits without reinstalling:

   ```bash
   xsh lib-dev-manager link xsh ~/path/to/your/xsh-clone
   ```

   With the symlink in place, changes to your working tree take effect immediately.

## Running tests

```bash
shellspec spec/xsh_spec.sh spec/installer_spec.sh
```

Run with coverage (requires [kcov](https://github.com/SimonKagstrom/kcov)):

```bash
shellspec --kcov spec/xsh_spec.sh spec/installer_spec.sh
```

All existing tests must pass before a PR can be merged.

## Code style

- **ShellCheck compliant** — run `shellcheck xsh.sh install.sh` and fix all warnings before submitting.
- **Function documentation** uses the `#?` doc format consistent with the existing functions in `xsh.sh`:

  ```bash
  #? Description:
  #?   Brief description of what the function does.
  #?
  #? Usage:
  #?   function_name [-flag] <ARG>
  #?
  #? Options:
  #?   [-flag]   Description of the flag.
  #?   <ARG>     Description of the argument.
  function my_function () {
      ...
  }
  ```

- Keep functions focused and small. Prefer internal helpers (`__xsh_*` prefix) for shared logic.
- Do not add `set -e` inside library functions — callers control shell options.

## Commit message convention

Use the format `type: description` with a lowercase imperative description:

| Type | When to use |
|------|-------------|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code restructure with no behavior change |
| `test` | Adding or updating tests |
| `ci` | CI/CD pipeline changes |
| `chore` | Build scripts, dependency updates, housekeeping |

Examples:

```
fix: handle missing XSH_HOME during init
feat: add dependency management for xsh load
docs: document LPUR regex syntax
refactor: reduce debug output in __xsh_lib_load
```

## Branch naming

| Pattern | Purpose |
|---------|---------|
| `feature/<short-description>` | New features |
| `fix/<short-description>` | Bug fixes |
| `docs/<short-description>` | Documentation changes |

## Pull request process

1. Fork the repository and create a branch from `develop`.
2. Make your changes, following the code style and commit conventions above.
3. Ensure all tests pass: `shellspec spec/xsh_spec.sh spec/installer_spec.sh`
4. Ensure shellcheck is clean: `shellcheck xsh.sh install.sh`
5. Open a pull request against the `develop` branch (not `main`).
6. Fill out the pull request template completely.
7. A maintainer will review and merge or request changes.

PRs that skip tests, fail shellcheck, or target `main` directly will be asked to revise.
