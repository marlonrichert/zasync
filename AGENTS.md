# AGENTS.md

`zasync` is a single-file zsh script providing async workers backed by
`sysopen` on a process substitution plus a `zle -Fw` fd watcher.

## Tests

`./Tests/run.zsh` — plain `zsh -f`, no framework. See `CONTRIBUTING.md` for the
`XFAIL`/`XPASS` convention.


## Pitfalls to avoid

- **Never source `zasync` for its side effects alone.** The file ends with
  `zasync "$@"`, so sourcing it inherits the caller's positional parameters and
  dispatches on them. Pass an explicit harmless command (`source zasync help`)
  or the plugin will run an arbitrary subcommand.
