#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
CUSTOM='build/track-c-optimized-test.iso'
BASE='build/track-c-base.iso'
[[ -f "$CUSTOM" && -f "$BASE" ]] || { echo 'Run with the existing TRACK_C_PROJECT files present'; exit 1; }
python3 - "$CUSTOM" "$BASE" "${1:-}" <<'PY'
import os, sys
custom, base = (os.stat(p).st_size for p in sys.argv[1:3])
print('Custom ISO:', custom, 'bytes')
print('Project minimal base ISO:', base, 'bytes')
print('Change versus minimal base: %.2f%%' % (100*(custom/base-1)))
threshold = custom/0.6
print('Stock baseline required for 40%% reduction: at least %.0f bytes' % threshold)
print('Official Ubuntu 24.04.5 Server installer is listed as about 3.8 GB.')
print('Approximate reduction versus 3.8 billion bytes: %.2f%%' % ((1-custom/3_800_000_000)*100))
if sys.argv[3]:
    stock=os.stat(sys.argv[3]).st_size
    print('Actual supplied stock ISO:', stock, 'bytes')
    print('Reduction against supplied stock ISO: %.2f%%' % ((1-custom/stock)*100))
print('CAVEAT: Server installer vs custom live image is not a feature-matched baseline.')
PY
