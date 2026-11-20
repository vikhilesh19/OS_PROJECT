# TRACK C -- Three outstanding acceptance checks

**Do not run native NVIDIA `modprobe` in WSL.** `uname -r` must be `6.8.12-trackc` and you must be on real RTX 4050 hardware, not QEMU, before using the native-GPU script.

## 1. Image size requirement
Read `SIZE_JUSTIFICATION.md`. The assignment allows **40% reduction OR a documented shortfall justified by the GPU stack**. Quantitative evidence and honest qualification are included. Run in your project:

```bash
bash scripts/size-evidence.sh
```

## 2. Clean filesystem/ISO reproduction
The script creates a **new Ubuntu Noble filesystem using debootstrap**, installs existing custom kernel .deb packages, NVIDIA 615 driver and compiled CUDA programs, and generates a **separate** ISO. It does not change existing release images. Optional `--build-kernel` compiles source again. Requires network access, Ubuntu WSL with sudo, CUDA 13.3 nvcc, build utilities and 10+ GiB free space.

```bash
cd ~/TRACK_C_PROJECT
bash scripts/reproduce-trackc.sh
```

This is an untested full build *recipe*, not proof it has succeeded in your environment. A successful new ISO must still be boot-tested. Do not report full reproduction complete until it passes.

## 3. Native GPU validation
Needs physical USB-booted custom Linux with your NVIDIA RTX 4050. WSL's NVIDIA GPU interface is insufficient to prove the native driver works; QEMU lacks GPU passthrough. Place script on accessible USB or inside the final ISO. From native Track C boot:

```bash
uname -r
bash /path/to/validate-native-gpu.sh
```

It must detect the physical GPU, load both modules, execute vector addition, and finish with `PASS: Native CUDA executed ...`. Preserve the log before shutting down the live OS. See https://documentation.ubuntu.com/security/security-features/platform-protections/secure-boot/ for signed boot/module prerequisites. **Do not disable Secure Boot or modify Windows partitions without reviewing disk encryption recovery.**

## Remaining rubric coverage
The earlier assignment also mentions CUDA toolkit, cuDNN and container runtime *inside the image*. The current ISO includes compiled CUDA applications, native NVIDIA 615 user libraries and kernel modules but does not yet establish that cuDNN or the container runtime are installed. Do not claim those features without verification.
