# zasync

A minimal, correct async framework for [Zsh Line Editor (ZLE)](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html).

`zasync` is an autoloadable function that lets you run a shell command in the background and get notified via a ZLE widget when the output is ready — no subshells, no polling, no stale results.

## Features

- **Slot-based cancellation** — starting a new job for a slot automatically cancels any previous in-flight job for that slot.
- **Stale-result protection** — results are discarded if the directory changed between launch and delivery.
- **Sequence-number ordering** — only the most recently started job per slot can deliver results; earlier jobs that finish late are silently dropped.
- **Yank/kill-safe** — the ZLE flag passed at delivery time is compatible with active yank and kill widget sequences.


## Requirements

- Zsh 5.8 or later (needs `$sysparams[procsubstpid]`, plus `sysopen` and `zle -Fw`)


## Installation

`zasync` is an autoloadable function. Add its directory to `fpath` and
autoload it:

```zsh
fpath+=(/path/to/zasync)
autoload -Uz zasync
```

Always install `zasync` via `fpath`/`autoload`, not by `source`-ing the file
directly — `zasync` refuses to run and warns if sourced. Autoload keys a
function by name, so at most one `zasync` implementation can ever be loaded at
a time — sourcing multiple copies (e.g. bundled by different plugins) instead
lets each redefine `zasync` and its internal `_zasync_*` state, silently
overwriting one another.


## Usage

### Commands

| Command | Description |
|---|---|
| `start <slot> <worker> <cb>` | Run `<worker>` asynchronously; call ZLE widget `<cb>` when done. Worker stderr is discarded; wrap your worker function if you need it elsewhere. |
| `cancel <slot>` | Cancel any in-flight job for `<slot>`. |
| `reply <slot>` | Print the most recent output received for `<slot>`. Empty before the first delivery or after `cancel`. |
| `help [command]` | Show help for all commands or a single `<command>`. |


### Parameters

| Parameter | Description |
|---|---|
| `slot` | A name that uniquely identifies this background job. Starting a new job with the same slot cancels the previous one. |
| `worker` | The name of a command or function to run asynchronously (no arguments). Its stdout is captured and stored. |
| `cb` | The name of a ZLE widget to invoke when the worker finishes. Inside the widget, call `zasync reply <slot>` to retrieve the output. |


### Example

```zsh
# Define a worker function
_my_worker() {
  git rev-parse --abbrev-ref HEAD
}

# Define a ZLE widget to receive the result
_my_callback() {
  local branch
  branch=$(zasync reply git-branch)
  # update your prompt, etc.
  zle reset-prompt
}
zle -N _my_callback

# zasync is autoloadable — make it available, then kick off the first job
autoload -Uz zasync
zasync start git-branch _my_worker _my_callback

# Re-trigger on every prompt
precmd() {
  zasync start git-branch _my_worker _my_callback
}
```

Since `start` cancels any previous job for the slot, and `cancel` clears its
reply, a widget that renders `zasync reply` on every prompt will flicker to
empty each cycle until the new result lands, rather than holding the previous
value.


### Global variables

`zasync` stores state in associative arrays prefixed with `_zasync_`. These are internal and subject to change; do not rely on them directly — use `zasync reply` instead.


## Author & License

See the [LICENSE](LICENSE) file for details.
