#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ROOT="$PWD/build/chroot-trackc"
STAGE="$PWD/build/trackc-optimized-root"
OUTPUT="$PWD/build/track-c-rebuilt.iso"
KERNEL="6.8.12-trackc"

test -f "$ROOT/boot/vmlinuz-$KERNEL"
test -f "$ROOT/boot/initrd.img-$KERNEL"
test -d "$ROOT/lib/modules/$KERNEL"
test -f "$STAGE/boot/grub/grub.cfg"

if findmnt -R -n "$ROOT" | grep -q .; then
    echo "ERROR: Unmount chroot filesystems first."
    exit 1
fi

echo "Building compressed Linux filesystem..."
sudo mksquashfs "$ROOT" \
    "$STAGE/casper/filesystem.squashfs" \
    -noappend -one-file-system \
    -comp xz -b 1M -processors 2

echo "Installing kernel and initramfs..."
sudo install -m 644 "$ROOT/boot/vmlinuz-$KERNEL" \
    "$STAGE/casper/vmlinuz"
sudo install -m 644 "$ROOT/boot/initrd.img-$KERNEL" \
    "$STAGE/casper/initrd"

echo "Updating manifest..."
sudo chroot "$ROOT" dpkg-query -W \
    -f='${Package} ${Version}\n' |
    sudo tee "$STAGE/casper/filesystem.manifest" >/dev/null

sudo du -sx --block-size=1 "$ROOT" |
    cut -f1 |
    sudo tee "$STAGE/casper/filesystem.size" >/dev/null

echo "Updating checksums..."
sudo bash -c '
cd "$1"
find . -type f ! -name md5sum.txt -print0 |
    sort -z |
    xargs -0 -r md5sum > md5sum.txt
' _ "$STAGE"

echo "Creating ISO..."
grub-mkrescue -o "$OUTPUT" "$STAGE"

sha256sum "$OUTPUT" | tee results/rebuilt-iso.sha256
echo "REBUILD COMPLETE"
