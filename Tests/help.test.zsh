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
