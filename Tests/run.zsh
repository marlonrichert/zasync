#!/bin/zsh -f
#
# Test harness for zasync. No framework: plain `zsh -f`.
#
# Run with `./Tests/run.zsh` or `zsh -f Tests/run.zsh` from anywhere.
#
# Individual test cases live in `Tests/*.test.zsh` and are sourced in
# lexical order under `emulate -L zsh; setopt no_unset warn_create_global`,
# with `reset_state` run before each file. Each has access to `assert`,
# `xfail_assert`, and `reset_state` below, plus `$REPO` (the repo root).

emulate -L zsh
setopt no_unset warn_create_global

typeset -g REPO=${0:A:h:h}
typeset -g TESTS_DIR=${0:A:h}

fpath=($REPO $fpath)
autoload -Uz zasync
zasync help >/dev/null

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

run_test_file() {
  emulate -L zsh
  setopt no_unset warn_create_global
  source $1
}

for test_file in $TESTS_DIR/*.test.zsh; do
  reset_state
  run_test_file $test_file
done

print -r -- ''
print -r -- "passed: $PASSED  failed: $FAILED  xfail: $XFAILED  xpass: $XPASSED"
(( FAILED == 0 ))
