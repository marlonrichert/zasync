# `.zasync.fd-callback` itself needs a live ZLE fd watcher to invoke (it calls
# `zle -F`/`builtin zle -f`), so it cannot run headlessly. What is testable
# without ZLE is the buffering contract it relies on: `sysread` returning
# per-chunk data (status 0) until EOF (status 5), accumulated across calls
# into `_zasync_fd_buf`, with no byte loss and no trailing-newline stripping.

typeset -i r=
exec {r}< <(printf '%0.sA' {1..70000}; print -n $'\n')
typeset chunk= rc= n=0
while true; do
  sysread -i $r chunk
  rc=$?
  (( rc != 0 )) && break
  _zasync_fd_buf[$r]+=$chunk
  (( n++ ))
done
exec {r}<&-

assert 'sysread reassembles output across multiple chunks' \
  "${#_zasync_fd_buf[$r]}" 70001
assert 'sysread needed more than one chunk for >64KiB output' \
  "${${(M)n:#<2->}:+multi}" multi
assert 'sysread preserves the trailing newline (raw bytes, no strip)' \
  "${_zasync_fd_buf[$r]: -1}" $'\n'
assert 'EOF is reported as sysread status 5' $rc 5

# Manual regression test (needs a live terminal + ZLE):
#   1. In an interactive zsh: `source ./zasync help`
#   2. `stall() { print -n partial; sleep 30 }`
#   3. `noop-widget() { }` and `zle -N noop-widget`
#   4. Bind a widget that runs `zasync start s stall noop-widget`, invoke it.
#   5. The prompt must stay responsive for the full 30s.
