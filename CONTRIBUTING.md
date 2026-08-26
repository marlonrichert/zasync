# Developer Guidelines for zasync

## Running tests

```zsh
./Tests/run.zsh
```

The harness is plain `zsh -f` with no external framework. It prints one line
per assertion and exits non-zero only when a `FAIL` occurs.

`XFAIL` marks an assertion for a known bug: the expectation is recorded but
does not fail the run. When a fix lands, the line turns into `XPASS` — promote
that assertion from `xfail_assert` to `assert`.

Behavior that needs ZLE and a live terminal cannot run headlessly. Those cases
are documented as manual smoke tests in comments in `Tests/run.zsh`.
