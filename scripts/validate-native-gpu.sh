#!/usr/bin/env bash
# Run this ONLY from the actual Track C live Linux session, booted on the RTX 4050 laptop.
set -uo pipefail
LOG="${HOME}/trackc-native-gpu-validation.txt"
exec > >(tee "$LOG") 2>&1
ok=1
check() { echo; echo "=== $1 ==="; }
check 'IDENTITY'
echo "Kernel: $(uname -r)"
echo "OS release: $(cat /proc/sys/kernel/osrelease)"
if [[ "$(uname -r)" != '6.8.12-trackc' ]]; then
  echo 'FAIL: Not booted into your custom Track C kernel'; exit 2
fi
if grep -qi microsoft /proc/sys/kernel/osrelease /proc/version 2>/dev/null; then
  echo 'FAIL: This is WSL, not native Linux'; exit 2
fi
if grep -qi qemu /sys/class/dmi/id/sys_vendor 2>/dev/null; then
  echo 'FAIL: This is QEMU, not native GPU hardware'; exit 2
fi
check 'PCI GPU DISCOVERY'
if ! lspci -nn | grep -Ei 'NVIDIA|3D controller|VGA compatible controller'; then
  echo 'FAIL: Unable to identify PCI GPU'; exit 2
fi
check 'NVIDIA DRIVER MODULE'
modinfo -F version nvidia || { echo 'FAIL: NVIDIA kernel module absent'; exit 2; }
sudo modprobe nvidia || { echo 'FAIL: NVIDIA kernel module cannot load. Check Secure Boot and dmesg.'; exit 2; }
sudo modprobe nvidia_uvm || { echo 'FAIL: NVIDIA UVM module cannot load'; exit 2; }
check 'NVIDIA-SMI'
if ! nvidia-smi; then echo 'FAIL: NVIDIA driver could not initialize GPU'; exit 2; fi
check 'CUDA VECTOR ADDITION'
if /opt/trackc/bin/vector_add; then echo 'PASS: Vector addition'; else echo 'FAIL: Vector addition'; ok=0; fi
check 'CUDA BENCHMARK'
if /opt/trackc/bin/benchmark; then echo 'PASS: Benchmark'; else echo 'FAIL: Benchmark'; ok=0; fi
check 'CONCLUSION'
if (( ok )); then
  echo 'PASS: Native CUDA executed in the custom Track C Linux distribution.'
else
  echo 'FAIL: Native CUDA validation incomplete.'
fi
echo "Evidence: $LOG (copy to external storage before shutting down the live session)"
(( ok ))
