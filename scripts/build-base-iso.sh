#!/bin/bash
set -euo pipefail

PROJECT="$HOME/TRACK_C_PROJECT"

cd "$PROJECT/build"

echo "Starting Track C Linux ISO build..."

sudo lb build 2>&1 | tee "$PROJECT/results/base-build.log"

echo "Build command completed."
echo "Checking generated ISO files..."

find . -maxdepth 1 -type f -name '*.iso' -ls
