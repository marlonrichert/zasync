#!/bin/zsh -f
#
# Test harness for zasync. No framework: plain `zsh -f`.
#
# Run with `./Tests/run.zsh` or `zsh -f Tests/run.zsh` from anywhere.

emulate -L zsh
setopt no_unset warn_create_global

typeset -g REPO=${0:A:h:h}

# Sourcing runs `zasync "$@"` at the end of the file, so pass a harmless
# command and discard its output.
source $REPO/zasync help >/dev/null

typeset -gi PASSED=0 FAILED=0 XFAILED=0 XPASSED=0

# assert <desc> <actual> <expected>
assert() {
  local desc=$1 actual=$2 expected=$3
  if [[ $actual == $expected ]]; then
    print -r -- "PASS  $desc"
    (( ++PASSED ))
  else
    print -r -- "FAIL  $desc"
    print -r -- "        expected: ${(qqq)expected}"
    print -r -- "        actual:   ${(qqq)actual}"
    (( ++FAILED ))
  fi
}

# Same as `assert`, but for behavior that is known-broken: a mismatch is
# reported without failing the run, and a match is reported loudly so the
# expectation gets promoted to a plain `assert` once the bug is fixed.
xfail_assert() {
  local desc=$1 actual=$2 expected=$3
  if [[ $actual == $expected ]]; then
    print -r -- "XPASS $desc (bug appears fixed: promote to assert)"
    (( ++XPASSED ))
  else
    print -r -- "XFAIL $desc (known bug)"
    (( ++XFAILED ))
  fi
}

# Reset all zasync state between test cases.
reset_state() {
  _zasync_fd=() _zasync_seq=() _zasync_fd_slot=() _zasync_fd_seq=()
  _zasync_fd_pwd=() _zasync_fd_cb=() _zasync_fd_pid=() _zasync_fd_buf=()
  _zasync_reply=()
  _zasync_n=0
}

print -r -- '--- `zasync help help` ---'

reset_state
typeset out= err= rc=
out=$( zasync help help 2>/dev/null )
rc=$?
err=$( zasync help help 2>&1 >/dev/null )

assert 'zasync help help exits 0' $rc 0
assert 'zasync help help does not report an unknown command' \
  "${${(M)err:#*unknown command*}:+yes}" ''

# `zasync help help` should describe the `help` command itself, not fall back
# to the top-level command list.
typeset general=
general=$( zasync help 2>/dev/null )
assert 'zasync help help differs from zasync help' \
  "${${(M)out:#$general}:+same}" ''

reset_state

# fds below 10 are never closed (they are stdin/stdout/stderr and other
# reserved descriptors), but bookkeeping must still happen. Fake that state
# directly: `.zasync.start` cannot run headlessly (it needs ZLE for `zle -Fw`).
_zasync_fd[s]=5
_zasync_seq[s]=1
_zasync_fd_slot[5]=s
_zasync_fd_seq[5]=1
_zasync_fd_pwd[5]=$PWD
_zasync_fd_cb[5]=cb
_zasync_fd_pid[5]=0

.zasync.cancel s

assert 'cancel drops the slot → fd entry' "${_zasync_fd[s]-}" ''
assert 'cancel drops fd → slot' "${_zasync_fd_slot[5]-}" ''
assert 'cancel drops fd → seq' "${_zasync_fd_seq[5]-}" ''
assert 'cancel drops fd → pwd' "${_zasync_fd_pwd[5]-}" ''
assert 'cancel drops fd → cb' "${_zasync_fd_cb[5]-}" ''
assert 'cancel drops fd → pid' "${_zasync_fd_pid[5]-}" ''

reset_state

# Cancelling an unknown slot must be a silent no-op: `.zasync.start` calls it
# unconditionally before every launch.
.zasync.cancel nonexistent
assert 'cancel of unknown slot succeeds' $? 0

# `.zasync.fd-callback` itself needs a live ZLE fd watcher to invoke (it calls
# `zle -F`/`builtin zle -f`), so it cannot run headlessly. What is testable
# without ZLE is the buffering contract it relies on: `sysread` returning
# per-chunk data (status 0) until EOF (status 5), accumulated across calls
# into `_zasync_fd_buf`, with no byte loss and no trailing-newline stripping.

reset_state
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

reset_state
_zasync_fd[s]=15
_zasync_reply[s]=old-result

.zasync.cancel s 2>/dev/null

assert 'reply is empty after cancel' "${_zasync_reply[s]-}" ''

print -r -- ''
print -r -- "passed: $PASSED  failed: $FAILED  xfail: $XFAILED  xpass: $XPASSED"
(( FAILED == 0 ))
