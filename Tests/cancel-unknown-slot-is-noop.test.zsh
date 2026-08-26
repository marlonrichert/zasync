# Cancelling an unknown slot must be a silent no-op: `.zasync.start` calls it
# unconditionally before every launch.
.zasync.cancel nonexistent
assert 'cancel of unknown slot succeeds' $? 0
