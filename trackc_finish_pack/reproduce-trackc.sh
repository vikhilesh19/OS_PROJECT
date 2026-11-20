#!/usr/bin/env bash
# Clean-room Ubuntu Noble rootfs + Track C kernel/NVIDIA/CUDA + GRUB ISO.
# Run from inside ~/TRACK_C_PROJECT in Ubuntu WSL (not inside QEMU).
set -Eeuo pipefail

PROJECT="$(pwd -P)"
KERNEL="6.8.12-trackc"
DRIVER="615"
BUILD_KERNEL=0
[[ "${1:-}" == "--build-kernel" ]] && BUILD_KERNEL=1
[[ -d "$PROJECT/benchmarks" && -d "$PROJECT/configs" && -d "$PROJECT/kernel" ]] || { echo 'ERROR: Run from TRACK_C_PROJECT root'; exit 1; }

for cmd in debootstrap mksquashfs grub-mkrescue xorriso nvcc; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ "$cmd" == nvcc && -x /usr/local/cuda-13.3/bin/nvcc ]]; then continue; fi
    echo "Missing host tool: $cmd"; exit 1
  fi
done
NVCC="$(command -v nvcc || true)"
[[ -n "$NVCC" ]] || NVCC=/usr/local/cuda-13.3/bin/nvcc

if (( BUILD_KERNEL )); then
  for cmd in make dpkg-buildpackage gcc bc flex bison; do command -v "$cmd" >/dev/null || { echo "Missing host kernel build tool: $cmd"; exit 1; }; done
  SRC="$PROJECT/kernel/linux-source-6.8.0"
  [[ -f "$SRC/Makefile" && -f "$PROJECT/configs/final-kernel.config" ]] || { echo 'Kernel source/config missing'; exit 1; }
  echo 'Rebuilding kernel packages from retained Linux source (may be CPU-intensive)...'
  (
    cd "$SRC"
    cp "$PROJECT/configs/final-kernel.config" .config
    ./scripts/config --set-str SYSTEM_TRUSTED_KEYS ''
    ./scripts/config --set-str SYSTEM_REVOCATION_KEYS ''
    make olddefconfig
    [[ "$(make -s kernelrelease)" == "$KERNEL" ]] || { echo 'Kernel version mismatch'; exit 1; }
    make -j2 bindeb-pkg
  )
fi

shopt -s nullglob
IMAGES=("$PROJECT"/kernel/linux-image-"$KERNEL"_*.deb)
HEADERS=("$PROJECT"/kernel/linux-headers-"$KERNEL"_*.deb)
(( ${#IMAGES[@]} >= 1 && ${#HEADERS[@]} >= 1 )) || { echo 'Missing custom kernel image or header .deb'; exit 1; }
# Use most recent package version when a source rebuild has produced an additional .deb.
mapfile -t IMAGES < <(printf '%s\n' "${IMAGES[@]}" | sort -V)
mapfile -t HEADERS < <(printf '%s\n' "${HEADERS[@]}" | sort -V)
IMAGE_DEB="${IMAGES[${#IMAGES[@]}-1]}"
HEADER_DEB="${HEADERS[${#HEADERS[@]}-1]}"

mkdir -p "$PROJECT/build" "$PROJECT/results"
WORK="$(mktemp -d "$PROJECT/build/trackc-clean-XXXXXX")"
ROOT="$WORK/rootfs"
STAGE="$WORK/iso-root"
LOG="$PROJECT/results/clean-rebuild-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$LOG") 2>&1
cleanup() {
  code=$?
  trap - EXIT
  if [[ -d "$ROOT/dev" ]] && mountpoint -q "$ROOT/dev"; then sudo umount -R "$ROOT/dev" || true; fi
  if [[ -d "$ROOT/sys" ]] && mountpoint -q "$ROOT/sys"; then sudo umount -R "$ROOT/sys" || true; fi
  if [[ -d "$ROOT/proc" ]] && mountpoint -q "$ROOT/proc"; then sudo umount -R "$ROOT/proc" || true; fi
  if (( code != 0 )); then echo "BUILD FAILED; work directory retained: $WORK ; log: $LOG"; fi
  exit "$code"
}
trap cleanup EXIT

echo "Fresh rootfs: $ROOT"
echo "Using Linux kernel packages: $IMAGE_DEB and $HEADER_DEB"
read -rsp 'Choose a temporary password for the LIVE track account: ' PASS
echo
[[ -n "$PASS" ]] || { echo 'Empty password refused'; exit 1; }

sudo debootstrap --arch=amd64 --variant=minbase noble "$ROOT" http://archive.ubuntu.com/ubuntu/
sudo tee "$ROOT/etc/apt/sources.list" >/dev/null <<'EOF'
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
EOF
sudo rm -f "$ROOT/etc/resolv.conf"
sudo cp -L /etc/resolv.conf "$ROOT/etc/resolv.conf"
sudo mkdir -p "$ROOT/dev" "$ROOT/sys" "$ROOT/proc" "$ROOT/tmp"
sudo mount -t proc proc "$ROOT/proc"
sudo mount --rbind /sys "$ROOT/sys"
sudo mount --make-rslave "$ROOT/sys"
sudo mount --rbind /dev "$ROOT/dev"
sudo mount --make-rslave "$ROOT/dev"
sudo tee "$ROOT/usr/sbin/policy-rc.d" >/dev/null <<'EOF'
#!/bin/sh
exit 101
EOF
sudo chmod 755 "$ROOT/usr/sbin/policy-rc.d"

sudo chroot "$ROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update
sudo chroot "$ROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  casper systemd-sysv sudo initramfs-tools kmod pciutils procps iproute2 \
  ca-certificates udev dbus linux-firmware

sudo install -m 644 "$IMAGE_DEB" "$ROOT/tmp/kernel-image.deb"
sudo install -m 644 "$HEADER_DEB" "$ROOT/tmp/kernel-headers.deb"
sudo chroot "$ROOT" dpkg -i /tmp/kernel-image.deb /tmp/kernel-headers.deb

sudo chroot "$ROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  nvidia-dkms-${DRIVER}-open libnvidia-compute-${DRIVER} nvidia-utils-${DRIVER} \
  nvidia-compute-utils-${DRIVER} dkms build-essential
sudo chroot "$ROOT" dkms autoinstall -k "$KERNEL"
sudo chroot "$ROOT" depmod -a "$KERNEL"
sudo chroot "$ROOT" update-initramfs -u -k "$KERNEL"
AUDIT="$(sudo chroot "$ROOT" dpkg --audit)"
if [[ -n "$AUDIT" ]]; then echo "BROKEN PACKAGES: $AUDIT"; exit 1; fi
sudo chroot "$ROOT" dkms status | tee "$WORK/dkms-status.txt"
grep -Eq "nvidia/[0-9.]+, ${KERNEL}, .*: installed" "$WORK/dkms-status.txt" || { echo "ERROR: No NVIDIA DKMS module installed for $KERNEL"; exit 1; }
sudo chroot "$ROOT" ldconfig -p | grep -F libcuda.so.1

sudo chroot "$ROOT" useradd -m -s /bin/bash -G sudo track
printf 'track:%s\n' "$PASS" | sudo chroot "$ROOT" chpasswd
unset PASS
sudo tee "$ROOT/etc/hostname" >/dev/null <<'EOF'
track
EOF
sudo mkdir -p "$ROOT/opt/trackc/bin" "$ROOT/usr/local/bin" "$ROOT/etc/systemd/system/trackc-cuda-check.service.d" "$ROOT/etc/sysctl.d"
"$NVCC" -arch=sm_89 "$PROJECT/benchmarks/vector_add.cu" -o "$WORK/vector_add"
"$NVCC" -arch=sm_89 "$PROJECT/benchmarks/benchmark.cu" -o "$WORK/benchmark"
sudo install -m 755 "$WORK/vector_add" "$ROOT/opt/trackc/bin/vector_add"
sudo install -m 755 "$WORK/benchmark" "$ROOT/opt/trackc/bin/benchmark"
# Remove blank lines preceding shebang (earlier release had Exec format error).
sed '/./,$!d' "$PROJECT/scripts/trackc-cuda-check.sh" | sudo tee "$ROOT/usr/local/bin/trackc-cuda-check" >/dev/null
sudo chmod 755 "$ROOT/usr/local/bin/trackc-cuda-check"
head -n 1 "$ROOT/usr/local/bin/trackc-cuda-check" | grep -qx '#!/bin/bash'
sudo install -m 644 "$PROJECT/scripts/trackc-cuda-check.service" "$ROOT/etc/systemd/system/trackc-cuda-check.service"
sudo install -m 644 "$PROJECT/scripts/trackc-security.conf" "$ROOT/etc/systemd/system/trackc-cuda-check.service.d/security.conf"
sudo tee "$ROOT/etc/sysctl.d/90-trackc-security.conf" >/dev/null <<'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
EOF
sudo systemctl --root="$ROOT" enable trackc-cuda-check.service
sudo chroot "$ROOT" apt-get clean
sudo rm -f "$ROOT/tmp/kernel-image.deb" "$ROOT/tmp/kernel-headers.deb" "$ROOT/usr/sbin/policy-rc.d"
# Unmount special filesystems BEFORE SquashFS creation.
sudo umount -R "$ROOT/dev"
sudo umount -R "$ROOT/sys"
sudo umount "$ROOT/proc"

sudo mkdir -p "$STAGE/casper" "$STAGE/boot/grub" "$STAGE/.disk"
sudo install -m 644 "$ROOT/boot/vmlinuz-$KERNEL" "$STAGE/casper/vmlinuz"
sudo install -m 644 "$ROOT/boot/initrd.img-$KERNEL" "$STAGE/casper/initrd"
sudo mksquashfs "$ROOT" "$STAGE/casper/filesystem.squashfs" -noappend -one-file-system -comp xz -b 1M -processors 2
sudo chroot "$ROOT" dpkg-query -W -f='${Package} ${Version}\n' | sudo tee "$STAGE/casper/filesystem.manifest" >/dev/null
sudo du -sx --block-size=1 "$ROOT" | cut -f1 | sudo tee "$STAGE/casper/filesystem.size" >/dev/null
sudo tee "$STAGE/boot/grub/grub.cfg" >/dev/null <<'EOF'
set default=0
set timeout=8
serial --unit=0 --speed=115200
terminal_input console serial
terminal_output console serial
menuentry "Track C Linux - Live USB / Auto detection" {
 linux /casper/vmlinuz boot=casper live-media-path=/casper ignore_uuid console=tty0 console=ttyS0,115200n8 ---
 initrd /casper/initrd
}
menuentry "Track C Linux - QEMU CD fallback" {
 linux /casper/vmlinuz boot=casper live-media=/dev/sr0 live-media-path=/casper ignore_uuid console=ttyS0,115200n8 ---
 initrd /casper/initrd
}
EOF
printf 'Track C Custom CUDA Linux\n' | sudo tee "$STAGE/.disk/info" >/dev/null
sudo bash -c 'cd "$1"; find . -type f ! -name md5sum.txt -print0 | sort -z | xargs -0 -r md5sum > md5sum.txt' _ "$STAGE"
OUTPUT="$PROJECT/build/track-c-clean-reproduction.iso"
[[ ! -e "$OUTPUT" ]] || { echo "Refusing to overwrite existing $OUTPUT"; exit 1; }
grub-mkrescue -o "$OUTPUT" "$STAGE"
sha256sum "$OUTPUT" | tee "$PROJECT/results/clean-reproduction.sha256"
echo 'CLEAN ROOTFS + NVIDIA + CUDA + ISO ASSEMBLY COMPLETED.'
echo "ISO: $OUTPUT"
echo "Working rootfs and ISO stage retained in $WORK for investigation."
echo 'Hardware CUDA validation still requires a native boot.'
