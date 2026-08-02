# Project Constitution

All development in this repository must strictly adhere to the following rules and standards:

## 1. Code Style Standard: Google Shell Style Guide

Every shell script in this repository MUST comply with the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html):

- **Shell**: Bash (`#!/usr/bin/env bash`) is the only supported shell language.
- **Indentation**: Use **2 spaces** for indentation. Never use tabs.
- **Line Length**: Limit lines to a maximum of **80 characters**.
- **Functions**:
  - Format function names in `lowercase_with_underscores` (no `function` keyword).
  - Wrap script entry point logic inside a `main()` function and call `main "$@"` at the bottom.
  - Declare function variables as `local`.
- **Conditionals**: Always use `[[ ... ]]` instead of `[ ... ]` or `test`.
- **Variables & Expansion**:
  - Use `lowercase_with_underscores` for script variables and functions.
  - Use `UPPERCASE_WITH_UNDERSCORES` for `readonly` constants and environment variables.
  - Always quote variable expansions: `"${var}"`.
- **File Header**: Every file must start with a comment header describing its purpose.

## 2. Mandatory Pre-Commit Linting & Verification

- Before making any `git commit` or `git push`, the script `./lint.sh` MUST be executed.
- Commits and pushes are strictly prohibited if `lint.sh` (including `shellcheck` and style verification) fails.

## 3. Communication & Tone Rules

- No Emojis in commit messages, documentation, or responses.
- Use text status markers: `[OK]`, `[SKIP]`, `[ERROR]`, `●`, `→`.
- Always clean up temporary Git branches after pushing.
