
# Track C — Custom Linux for NVIDIA CUDA Computing

## Overview
A customized Ubuntu 24.04-based Linux distribution
designed for NVIDIA CUDA/GPU computing.

## Features
- Custom Linux kernel 6.8.12-trackc
- NVIDIA 615.71.09 driver components
- CUDA vector-addition and benchmark applications
- BIOS and UEFI boot support
- SquashFS and OverlayFS
- Automatic CUDA detection using systemd
- Basic systemd and kernel security hardening

## Technologies
- Ubuntu 24.04 LTS
- Linux kernel 6.8.12
- NVIDIA CUDA Toolkit 13.3
- C++ and CUDA C
- QEMU, GRUB and OVMF
- Bash and systemd

## Repository Structure
- benchmarks/ — CUDA source code
- configs/ — Kernel configurations
- scripts/ — Build and automation scripts
- docs/ — Technical reports and demo guide
- results/ — Test evidence and measurements

## Build
The ISO can be rebuilt from an existing prepared
root filesystem using:

./scripts/rebuild-release.sh

See docs/REPRODUCE.md for build requirements
and known reproduction limitations.

## Testing
The custom distribution has been boot-tested
in QEMU using BIOS and UEFI.

CUDA applications have been tested on an NVIDIA
RTX 4050 through WSL.

Native CUDA execution inside the custom
distribution has not yet been verified.

## Results
- Custom kernel: 6.8.12-trackc
- NVIDIA driver: 615.71.09
- Optimized ISO: 1,397,649,408 bytes
- Automatic CUDA service: Working
- QEMU failed services: 0

## Documentation
See docs/TECHNICAL_REPORT.md
and docs/DEMO_GUIDE.md.

## Limitations
Physical GPU execution and full clean-build
reproduction require further verification.
```
