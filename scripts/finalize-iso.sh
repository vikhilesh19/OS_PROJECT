#!/bin/bash
set -euo pipefail

PROJECT="$HOME/TRACK_C_PROJECT"
ISO_ROOT="$PROJECT/build/grub-iso-root"
OUTPUT="$PROJECT/build/track-c-base.iso"

test -f "$ISO_ROOT/casper/filesystem.squashfs" || {
    echo "ERROR: SquashFS file missing"
    exit 1
}

echo "Updating GRUB configuration..."

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'GRUB'
set default=0
set timeout=5

serial --unit=0 --speed=115200
terminal_input serial
terminal_output serial

menuentry "Track C Custom Ubuntu Linux" {
    linux /casper/vmlinuz boot=casper live-media=/dev/sr0 live-media-path=/casper ignore_uuid console=ttyS0,115200n8 ---
    initrd /casper/initrd
}
GRUB

echo "Generating ISO integrity checksums..."

(
    cd "$ISO_ROOT"
    find . -type f ! -name md5sum.txt -print0 |
        sort -z |
        xargs -0 -r md5sum > md5sum.txt
)

echo "Rebuilding GRUB ISO..."

grub-mkrescue -o "$OUTPUT" "$ISO_ROOT"

echo "Finished:"
ls -lh "$OUTPUT"
