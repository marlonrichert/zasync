# AGENTS.md

`zasync` provides async workers backed by `sysopen` on a process substitution
plus a `zle -Fw` fd watcher. `zasync` is meant to be autoloaded as a function
and called, never sourced (see README.md § Installation for why and how to
load it correctly); its internal `.zasync.*` subfunctions live in
`Functions/` and are autoloaded by absolute path from within `zasync` itself.

## Tests

`./Tests/run.zsh` — plain `zsh -f`, no framework. See `CONTRIBUTING.md` for the
`XFAIL`/`XPASS` convention.
