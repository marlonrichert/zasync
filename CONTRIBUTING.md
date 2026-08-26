# Developer Guidelines for zasync

## Adding a subfunction

`zasync`'s internal `.zasync.*` helpers live in `Functions/`, one file per function, autoloaded by absolute path from within `zasync` itself (see AGENTS.md). Add a new helper as its own file there rather than growing `zasync` or an existing helper. This keeps `zasync` safe to autoload multiple times without redefining shared state.

## Running tests

```zsh
./Tests/run.zsh
```

`Tests/run.zsh` is plain `zsh -f` with no external framework. It sets up `assert`/`xfail_assert`/`reset_state` and sources every `Tests/*.test.zsh` file. It prints one line per assertion and exits non-zero only when a `FAIL` occurs.

Test cases live in `Tests/*.test.zsh`, grouped by the behavior they cover (e.g. `cancel.test.zsh`, `buffering.test.zsh`). Add a new file for a new area instead of growing an existing one.

`XFAIL` marks an assertion for a known bug: the expectation is recorded but does not fail the run. When a fix lands, the line turns into `XPASS` — promote that assertion from `xfail_assert` to `assert`.

Behavior that needs ZLE and a live terminal cannot run headlessly. Those cases are documented as manual smoke tests in comments in `Tests/buffering.test.zsh`.

Each `Tests/*.test.zsh` file is sourced from inside `run_test_file` in `run.zsh`, which itself runs under `emulate -L zsh` and `setopt no_unset warn_create_global` — a function scope that unwinds when the file finishes, keeping its options and locals from leaking into the harness or later test files. Test files don't need to set these themselves.

GitHub Actions runs `./Tests/run.zsh` on every push to `main` and on every pull request (`.github/workflows/tests.yml`); a red run blocks merging.
