
# Track C — Custom CUDA Linux Distribution

## Project Objective
Develop an application-specific Ubuntu Linux distribution
for NVIDIA CUDA/GPU computing.

## Build Environment
- Ubuntu 24.04 LTS on WSL2
- NVIDIA GeForce RTX 4050 Laptop GPU
- CUDA Toolkit 13.3
- QEMU x86_64

## Customized Operating System
- Kernel: Linux 6.8.12-trackc
- NVIDIA driver: 615.71.09
- Root filesystem: SquashFS + OverlayFS
- Init system: systemd
- Custom CUDA benchmark startup service

## Verified Features
- Custom kernel compiled successfully
- BIOS boot successful in QEMU
- UEFI boot successful in QEMU
- NVIDIA DKMS modules built for 6.8.12-trackc
- CUDA binaries and driver library packaged
- Automatic CUDA service executes successfully
- Security hardening settings applied
- Zero failed systemd units in tested boots

## Image Sizes
Base ISO: 1182541824 bytes
NVIDIA-enabled USB ISO: 1444575232 bytes
Optimized ISO: 1397649408 bytes

Optimization saved 46925824 bytes compared with
the NVIDIA-enabled USB ISO.

## Performance
Baseline boot: 55.696 seconds
Custom Linux boot: 58.168 seconds
Baseline RAM used: 226 MiB
Custom Linux RAM used: 238 MiB

These are individual QEMU measurements.

## CUDA Validation
CUDA vector addition and CPU/GPU benchmark passed
in WSL using the NVIDIA RTX 4050.

The custom Linux ISO has not yet executed CUDA
on physical NVIDIA hardware.

## Outstanding Limitations
- Native GPU execution in the custom distribution
- Physical USB boot and Secure Boot validation
- Required 40% image-size reduction not demonstrated
- Fully automated end-to-end build reproduction

## Project Contents
benchmarks/ - CUDA program sources
configs/ - Kernel configuration files
scripts/ - Linux image and service scripts
results/ - Logs, measurements and checksums
docs/ - Technical documentation
kernel/ - Compiled kernel packages and sources
build/ - Linux filesystems and ISO images
