
#!/bin/bash
set -euo pipefail

PROJECT="$HOME/TRACK_C_PROJECT"
ROOTFS="$PROJECT/build/chroot-trackc"
ISO_ROOT="$PROJECT/build/trackc-iso-root"
OUTPUT="$PROJECT/build/track-c-custom.iso"
VERSION="6.8.12-trackc"

echo "Checking custom kernel files..."

test -f "$ROOTFS/boot/vmlinuz-$VERSION"
test -f "$ROOTFS/boot/initrd.img-$VERSION"
test -d "$ROOTFS/lib/modules/$VERSION"

if findmnt -R -n "$ROOTFS" >/dev/null 2>&1; then
    echo "ERROR: Mounted filesystems detected in chroot."
    exit 1
fi

echo "Creating ISO directories..."

mkdir -p "$ISO_ROOT/casper"
mkdir -p "$ISO_ROOT/boot/grub"
mkdir -p "$ISO_ROOT/.disk"

echo "Copying custom kernel..."

sudo install -m 644 \
    "$ROOTFS/boot/vmlinuz-$VERSION" \
    "$ISO_ROOT/casper/vmlinuz"

sudo install -m 644 \
    "$ROOTFS/boot/initrd.img-$VERSION" \
    "$ISO_ROOT/casper/initrd"

echo "Compressing custom Linux filesystem..."

sudo mksquashfs "$ROOTFS" \
    "$ISO_ROOT/casper/filesystem.squashfs" \
    -noappend \
    -one-file-system \
    -comp xz \
    -processors 2

sudo du -sx --block-size=1 "$ROOTFS" |
    cut -f1 > "$ISO_ROOT/casper/filesystem.size"

sudo chroot "$ROOTFS" dpkg-query -W \
    -f='${Package} ${Version}\n' \
    > "$ISO_ROOT/casper/filesystem.manifest"

echo "Creating GRUB configuration..."

cat > "$ISO_ROOT/boot/grub/grub.cfg" <<'GRUB'
set default=0
set timeout=5

serial --unit=0 --speed=115200
terminal_input serial
terminal_output serial

menuentry "Track C Custom Linux - 6.8.12-trackc" {
    linux /casper/vmlinuz boot=casper live-media=/dev/sr0 live-media-path=/casper ignore_uuid console=ttyS0,115200n8 ---
    initrd /casper/initrd
}
GRUB

echo "Track C Custom CUDA Linux" > "$ISO_ROOT/.disk/info"

echo "Creating checksums..."

(
    cd "$ISO_ROOT"
    find . -type f ! -name md5sum.txt -print0 |
        sort -z |
        xargs -0 -r md5sum > md5sum.txt
)

echo "Generating custom ISO..."

grub-mkrescue -o "$OUTPUT" "$ISO_ROOT"

echo "Custom ISO created successfully!"
ls -lh "$OUTPUT"
