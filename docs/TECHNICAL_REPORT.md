
# CUSTOM LINUX FOR NVIDIA CUDA COMPUTING

## 1. Abstract

This project develops an application-specific Linux distribution
based on Ubuntu 24.04 for NVIDIA CUDA/GPU computing.

The system uses a customized Linux 6.8.12 kernel, NVIDIA 615
driver modules, CUDA benchmark applications, automatic systemd
startup and basic security hardening.

The custom operating system was successfully boot-tested in
QEMU using both legacy BIOS and UEFI firmware.

## 2. Project Objectives

- Build a bootable customized Linux distribution.
- Customize and compile the Linux kernel.
- Integrate NVIDIA GPU driver components.
- Include CUDA applications and automatic execution.
- Apply security controls.
- Compare image size, RAM usage and boot performance.
- Produce reproducible build evidence and documentation.

## 3. Development Environment

Host environment: Ubuntu 24.04 under WSL2
Target GPU: NVIDIA RTX 4050 Laptop GPU
CUDA Toolkit: 13.3
Custom kernel: Linux 6.8.12-trackc
NVIDIA Linux driver: 615.71.09
Virtualization: QEMU x86_64
Root filesystem: SquashFS with OverlayFS
Init system: systemd

## 4. System Architecture

Hardware / QEMU
       |
GRUB Bootloader
       |
Linux 6.8.12-trackc
       |
Initramfs and Casper
       |
SquashFS + OverlayFS
       |
systemd
       |
Track C CUDA Detection Service
       |
NVIDIA Driver and CUDA Applications

## 5. Kernel Customization

The kernel configuration was derived from an Ubuntu kernel
configuration and modified for Track C.

Changes included:

- Custom kernel suffix: -trackc
- Bluetooth support disabled
- CAN bus support disabled
- FireWire support disabled
- Required kernel module infrastructure retained

The custom kernel was compiled using the Linux Debian
package-building process.

Generated packages included:
- linux-image-6.8.12-trackc
- linux-headers-6.8.12-trackc

## 6. Linux Image Construction

An Ubuntu Noble filesystem was constructed using live-build
and related Linux image-building utilities.

The final ISO uses:
- GRUB for boot loading
- Casper for live boot
- SquashFS for compressed base storage
- OverlayFS for a writable live filesystem

The custom kernel and corresponding initramfs were
integrated into the ISO.

## 7. NVIDIA and CUDA Integration

NVIDIA driver version 615.71.09 was installed into the
target Linux filesystem.

DKMS successfully built NVIDIA modules for kernel
6.8.12-trackc.

Installed modules include:
- nvidia
- nvidia-modeset
- nvidia-drm
- nvidia-uvm
- nvidia-peermem

CUDA vector addition and benchmark executables were
placed under /opt/trackc/bin.

The CUDA driver library libcuda.so.1 was confirmed
inside the custom Linux filesystem.

A systemd service starts automatically and checks for
an available NVIDIA GPU.

In QEMU, the service skips execution because no NVIDIA
GPU device is exposed to the virtual machine.

## 8. Security Configuration

The CUDA systemd service uses:

- NoNewPrivileges=yes
- PrivateTmp=yes
- ProtectSystem=full
- RestrictSUIDSGID=yes

Kernel settings include:

- kernel.kptr_restrict=2
- kernel.dmesg_restrict=1
- fs.protected_symlinks=1
- fs.protected_hardlinks=1

These controls provide basic hardening, not a complete
security audit.

## 9. System Performance

Metric                 Base Linux     Custom Linux

Boot time              55.696 s       58.168 s
RAM used               226 MiB        238 MiB
Installed packages     312            375
Failed systemd units   0              0

These are individual QEMU measurements. More repeated
trials are required for statistical conclusions.

## 10. ISO Size Comparison

Base ISO:
1,182,541,824 bytes

NVIDIA-enabled USB ISO:
1,444,575,232 bytes

Optimized ISO:
1,397,649,408 bytes

The optimized ISO is 46,925,824 bytes smaller than the
NVIDIA-enabled USB ISO, approximately a 3.25% reduction.

However, the optimized ISO remains larger than the
minimal base ISO. The target of 40% reduction has
not been demonstrated.

## 11. CUDA Benchmark Results

Test workload: 10,000,000-element vector addition

CPU execution time: 25.212 ms
GPU kernel execution time: 1.374 ms
GPU total time: 39.114 ms

Result verification: PASSED

The GPU kernel is faster than the measured CPU loop,
but total GPU execution is slower for this workload
when data transfer overhead is included.

These CUDA results were measured using the RTX 4050
through WSL, not inside the custom Linux ISO.

## 12. Validation Results

Successfully verified:
- Custom kernel compilation
- Linux ISO creation
- Legacy BIOS boot in QEMU
- UEFI boot in QEMU
- NVIDIA DKMS module compilation
- NVIDIA module version detection
- Automatic CUDA service startup
- Basic security settings
- Zero failed systemd units in recorded tests
- SHA-256 checksums for working ISO images

## 13. Limitations

Actual CUDA execution inside the custom Linux ISO
has not yet been validated on physical NVIDIA hardware.

Physical USB boot and Secure Boot compatibility are
not yet verified.

The image-size reduction target has not been achieved.

The build process includes some manual steps and is
not yet fully automated end-to-end.

## 14. Conclusion

The project successfully demonstrates the development
of a customized Ubuntu Linux distribution with a
custom kernel, installed NVIDIA driver components,
CUDA application integration, automatic systemd
startup, and basic security hardening.

The distribution boots under BIOS and UEFI in QEMU.

Further work is required for native NVIDIA GPU validation,
image-size reduction and complete build automation.
