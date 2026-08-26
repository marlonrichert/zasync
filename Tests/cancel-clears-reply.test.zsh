_zasync_fd[s]=15
_zasync_reply[s]=old-result

.zasync.cancel s 2>/dev/null

assert 'reply is empty after cancel' "${_zasync_reply[s]-}" ''
