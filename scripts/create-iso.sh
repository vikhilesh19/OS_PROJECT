#!/bin/bash
set -euo pipefail

PROJECT="$HOME/TRACK_C_PROJECT"
ROOTFS="$PROJECT/build/chroot"
ISO_ROOT="$PROJECT/build/grub-iso-root"
OUTPUT="$PROJECT/build/track-c-base.iso"

echo "Checking Linux kernel..."

KERNEL=$(find "$ROOTFS/boot" -maxdepth 1 -name 'vmlinuz-*-generic' | head -n 1)

if [ -z "$KERNEL" ]; then
    echo "ERROR: Linux kernel not found"
    exit 1
fi

INITRD="$ROOTFS/boot/initrd.img-${KERNEL##*/vmlinuz-}"

if [ ! -f "$INITRD" ]; then
    echo "ERROR: Matching initramfs not found"
    exit 1
fi

echo "Checking chroot mounts..."

if findmnt -R -n "$ROOTFS" >/dev/null 2>&1; then
    echo "ERROR: Filesystems are still mounted inside the chroot."
    echo "Unmount them safely before creating the ISO."
    exit 1
fi

echo "Preparing ISO directories..."

mkdir -p "$ISO_ROOT/casper"
mkdir -p "$ISO_ROOT/boot/grub"
mkdir -p "$ISO_ROOT/.disk"

echo "Copying kernel and initramfs..."

sudo install -m 644 "$KERNEL" "$ISO_ROOT/casper/vmlinuz"
sudo install -m 644 "$INITRD" "$ISO_ROOT/casper/initrd"

echo "Compressing Linux filesystem..."

sudo mksquashfs "$ROOTFS" \
    "$ISO_ROOT/casper/filesystem.squashfs" \
    -noappend \
    -one-file-system \
    -comp xz \
    -processors 2

sudo du -sx --block-size=1 "$ROOTFS" | cut -f1 \
    > "$ISO_ROOT/casper/filesystem.size"

sudo chroot "$ROOTFS" dpkg-query -W \
    -f='${Package} ${Version}\n' \
    > "$ISO_ROOT/casper/filesystem.manifest"

echo "TRACK C CUDA Linux Base" > "$ISO_ROOT/.disk/info"

echo "Creating GRUB configuration..."

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'GRUB'
set default=0
set timeout=5

menuentry "Track C Custom Ubuntu Linux" {
    linux /casper/vmlinuz boot=casper ---
    initrd /casper/initrd
}
GRUB

echo "Generating bootable ISO..."

grub-mkrescue -o "$OUTPUT" "$ISO_ROOT"

echo "ISO creation finished."
ls -lh "$OUTPUT"
