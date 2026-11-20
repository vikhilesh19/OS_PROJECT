# Track C image size: precise evidence and approved shortfall rationale

The assignment states: **reduce the image by at least 40% versus the stock distribution, or justify a shortfall because GPU stacks are large**.

Measured output images from the current Track C project:

| Image | Bytes |
| --- | ---: |
| Track C minimal base ISO | 1,182,541,824 |
| Track C USB ISO with NVIDIA stack | 1,444,575,232 |
| Optimized Track C ISO | 1,397,649,408 |

- XZ SquashFS optimization saved **46,925,824 bytes (3.25%)** versus the NVIDIA-integrated USB ISO.
- The optimized ISO is **215,107,584 bytes (18.19%) larger** than the project's minimal base; do **not** claim 40% smaller than that base.
- The official Ubuntu 24.04.5 AMD64 *Server installer* is listed as about 3.8 GB; using that rounded published value, the optimized Track C image is roughly **63.2% smaller**. However, a general-purpose Server installer and a custom live image are **not functionally equivalent**. The 63.2% figure is a size comparison, not a matched-workload optimization result.
- Official stock image source: https://releases.ubuntu.com/24.04.5/

**Engineering justification when the stock/matched baseline is not reduced by 40%:** Track C deliberately includes proprietary-compatible NVIDIA userspace compute libraries, GPU firmware, DKMS source/build support, a custom Linux kernel and 476 MB (uncompressed) of modules. These increase capacity relative to a generic minimal boot-only build; stripping them indiscriminately would undermine CUDA use or hardware compatibility. The project removed redundant stock kernel modules and improved SquashFS compression. Rather than claiming 40% against an unmatched baseline, we report the measured shortfall and this GPU-stack tradeoff, as explicitly permitted by the assignment. For a rigorous full comparison, use a matched stock **live OS** built with comparable features and the same measurement method.
