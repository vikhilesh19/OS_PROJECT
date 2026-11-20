
# Track C — Live Demonstration Guide

## Project Title
Application-Specific Custom Linux Distribution for NVIDIA CUDA/GPU Computing

## Member 1: Introduction and Architecture

Explain:
- Objective: Build a customized Linux distribution for GPU computing.
- Base: Ubuntu 24.04 LTS.
- Target GPU: NVIDIA RTX 4050.
- CUDA development environment: WSL2 with CUDA 13.3.
- Virtual testing: QEMU with BIOS and UEFI.

Demonstrate:

cd ~/TRACK_C_PROJECT
ls
ls -lh build/*.iso

## Member 2: Kernel Customization

Explain:
- Custom kernel version: 6.8.12-trackc.
- Disabled unnecessary Bluetooth, CAN and FireWire support.
- Compiled kernel into Debian packages.
- Integrated kernel and modules into custom Linux ISO.

Demonstrate:

grep 'CONFIG_LOCALVERSION=' configs/final-kernel.config
ls -lh kernel/*.deb

## Member 3: Custom Linux Boot

Boot the optimized ISO:

qemu-system-x86_64 -m 3072 -smp 2 -machine accel=tcg -boot d -cdrom build/track-c-optimized-test.iso -nographic

Log in as track.

Inside QEMU:

uname -r
systemctl is-system-running
systemctl --failed
modinfo -F version nvidia
systemctl status trackc-cuda-check.service --no-pager
sysctl kernel.kptr_restrict kernel.dmesg_restrict

Explain:
- Custom kernel boots successfully.
- NVIDIA 615 modules are installed.
- Automatic CUDA detection service works.
- Basic security hardening is applied.

## Member 4: CUDA Programs and Benchmarks

In a separate WSL terminal:

/usr/lib/wsl/lib/nvidia-smi

cd ~/CUDA_PROJECT
./vector_add
./benchmark

Previously recorded results:
- CPU time: 25.212 ms
- GPU kernel time: 1.374 ms
- GPU total time: 39.114 ms
- CUDA result verification: PASSED

Explain:
- CUDA execution was verified in WSL.
- The customized Linux ISO has not yet been
  validated with a physical NVIDIA GPU.
- QEMU currently skips CUDA execution because
  GPU passthrough is unavailable.

## Results and Limitations

- Custom kernel: 6.8.12-trackc
- NVIDIA driver: 615.71.09
- BIOS and UEFI: Boot-tested in QEMU
- Failed systemd units: 0
- Optimized ISO: 1397649408 bytes
- Base ISO: 1182541824 bytes

Limitations:
- Native GPU execution is not yet verified.
- The optimized ISO is larger than the minimal base ISO.
- Physical USB boot and Secure Boot are not verified.
- Fully automated end-to-end build reproduction
  remains unfinished.
