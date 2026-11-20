TRACK C FINISH PACK -- read before running
==========================================
This package does NOT pretend that a GPU test has passed without physical hardware.
It gives you a clean-rootfs build script, native GPU validator and size calculator.

1) size-evidence.sh
   Copy the pack's scripts into ~/TRACK_C_PROJECT/scripts.
   From ~/TRACK_C_PROJECT run: bash scripts/size-evidence.sh
   Optionally supply the path to an actual official stock Ubuntu ISO:
   bash scripts/size-evidence.sh /path/to/ubuntu-stock.iso
   Official Ubuntu 24.04.5 server ISO: https://releases.ubuntu.com/24.04.5/

2) reproduce-trackc.sh
   Requires a full local TRACK_C_PROJECT containing the CUDA sources, original
   service files, kernel .deb packages, and native Linux build dependencies.
   For the truly source-based variant, it also needs the retained kernel source
   in kernel/linux-source-6.8.0, correct upstream source and packaging changes.
   Run in WSL from ~/TRACK_C_PROJECT, not QEMU.
   Host tools: sudo apt install debootstrap squashfs-tools grub-common grub-pc-bin
     grub-efi-amd64-bin xorriso qemu-system-x86 ovmf build-essential
   CUDA nvcc (13.3) must be installed on the WSL host.
   Run: bash scripts/reproduce-trackc.sh
   OR to recompile kernel source first (long, needs kernel dev dependencies):
       bash scripts/reproduce-trackc.sh --build-kernel
   This makes a NEW Ubuntu rootfs from debootstrap, installs the supplied kernel,
   NVIDIA drivers, CUDA executables, startup service and hardening, then builds
   build/track-c-clean-reproduction.iso. It NEVER replaces the verified images.
   It prompts for the temporary LIVE user's password.
   IMPORTANT: We have syntax-checked this script but NOT boot-tested it in your WSL.
   Successful exit still requires a QEMU BIOS/UEFI boot and service check before
   it can be claimed as reproducible. Package repository versions may change.
   ISO checksum may differ due to timestamps and updated APT packages.

3) validate-native-gpu.sh
   Only for a physical live boot of Track C on your RTX 4050 laptop, NOT WSL/QEMU.
   Copy the script to the bootable USB or place in target /usr/local/bin before
   making your physical release image.
   Native live shell command: bash /path/to/validate-native-gpu.sh
   It rejects WSL/QEMU, checks the 6.8.12-trackc kernel, loads NVIDIA modules,
   verifies nvidia-smi and runs both actual CUDA applications.
   The log is in your live user's home directory. Live-system writes are temporary;
   save to USB or photograph before shutdown.
   First confirm Windows drive encryption/BitLocker recovery readiness, and
   check Secure Boot. The custom kernel+GRUB may be unsigned; do not change
   firmware protection settings casually. Rufus can create an experimental
   bootable USB, but laptop boot is NOT guaranteed merely by a QEMU test.

Do not run any custom Linux native driver installation in WSL's own root filesystem.
