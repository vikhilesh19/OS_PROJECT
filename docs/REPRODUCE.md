
# Track C — Build and Reproduction Guide

## 1. Requirements

Development host:
- Ubuntu 24.04
- QEMU and OVMF
- GRUB image-building utilities
- SquashFS tools
- Kernel compilation dependencies
- NVIDIA driver packages for Ubuntu Noble

The custom kernel version is 6.8.12-trackc.

## 2. Project Structure

benchmarks/  CUDA source code
configs/     Kernel configurations
scripts/     ISO and service scripts
results/     Logs and measurement evidence
docs/        Documentation
kernel/      Compiled kernel Debian packages
build/       Generated filesystems and ISOs

## 3. Kernel Packages

The source archive contains the compiled custom
kernel image and header Debian packages.

The configuration used is stored in:

configs/final-kernel.config

For a full rebuild, obtain the corresponding Linux
6.8.12 source and apply the supplied configuration
and package-generation changes.

## 4. Image Construction

The existing build process uses an Ubuntu Noble
root filesystem, the custom kernel, its matching
initramfs, Casper, SquashFS and GRUB.

Relevant scripts:

scripts/build-base-iso.sh
scripts/create-iso.sh
scripts/finalize-iso.sh
scripts/create-custom-iso.sh

The custom ISO script expects an already prepared
build/chroot-trackc directory.

IMPORTANT:
The source archive does not contain this complete
root filesystem, and several original construction
steps were manual.

Consequently, extraction of the source archive
alone does not reproduce the complete ISO.

## 5. NVIDIA Integration

NVIDIA packages:
- nvidia-dkms-615-open
- libnvidia-compute-615
- nvidia-utils-615
- nvidia-compute-utils-615

Required kernel version:
6.8.12-trackc

Verify the driver installation using:

dkms status
modinfo -k 6.8.12-trackc nvidia

A DKMS build must explicitly target the custom kernel.
Builds inside a chroot require correctly mounted
virtual filesystems.

## 6. CUDA Applications

CUDA source files:

benchmarks/vector_add.cu
benchmarks/benchmark.cu

CUDA compiler used during development:
CUDA Toolkit 13.3

Installed executable location:

/opt/trackc/bin/

Application startup:

/usr/local/bin/trackc-cuda-check

systemd service:

trackc-cuda-check.service

## 7. Boot Verification

From the project root, run:

qemu-system-x86_64 -m 3072 -smp 2 -machine accel=tcg -boot d -cdrom build/track-c-optimized-test.iso -nographic

After logging into the guest:

uname -r
systemctl is-system-running
systemctl --failed
modinfo -F version nvidia
systemctl status trackc-cuda-check.service

Expected kernel:
6.8.12-trackc

Expected NVIDIA module version:
615.71.09

## 8. Checksums

Use:

sha256sum -c results/verified-images.sha256

The referenced ISO files must be present at the
paths stored in the checksum file.

## 9. Known Limitations

- End-to-end ISO build automation is incomplete.
- Native physical NVIDIA GPU testing is pending.
- The final image-size reduction target is unmet.
- Physical USB and Secure Boot testing is pending.
