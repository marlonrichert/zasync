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
