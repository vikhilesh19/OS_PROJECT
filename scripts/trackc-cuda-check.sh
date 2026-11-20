#!/bin/bash

#!/bin/bash

set -u

echo "====================================="
echo "TRACK C - CUDA GPU COMPUTING"
echo "====================================="
echo "Kernel: $(uname -r)"
echo "Date: $(date)"
echo

if [ ! -e /dev/nvidiactl ] || [ ! -e /dev/nvidia0 ]; then
    echo "GPU STATUS: SKIPPED"
    echo "A native NVIDIA GPU driver/device is not available."
    echo "CUDA execution cannot run in this QEMU environment."
    exit 0
fi

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "GPU STATUS: SKIPPED"
    echo "nvidia-smi is not installed."
    exit 0
fi

echo "Checking NVIDIA GPU..."

if ! nvidia-smi; then
    echo "GPU STATUS: ERROR - NVIDIA driver is not working."
    exit 1
fi

echo
echo "Running CUDA vector addition..."

if ! /opt/trackc/bin/vector_add; then
    echo "CUDA VECTOR ADDITION: FAILED"
    exit 1
fi

echo
echo "Running CPU vs GPU benchmark..."

if ! /opt/trackc/bin/benchmark; then
    echo "CUDA BENCHMARK: FAILED"
    exit 1
fi

echo
echo "TRACK C CUDA TESTS COMPLETED SUCCESSFULLY"
