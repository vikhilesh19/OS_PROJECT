

# Custom Linux Distribution for NVIDIA CUDA Computing

An Ubuntu 24.04-based Linux distribution designed to support NVIDIA GPU and CUDA computing.

## Features

- Custom Linux kernel `6.8.12-trackc`
- NVIDIA driver components `615.71.09`
- CUDA vector addition and benchmark applications
- BIOS and UEFI boot support
- SquashFS and OverlayFS support
- Automatic CUDA detection through systemd
- Basic kernel and systemd security hardening

## Technologies

- Ubuntu 24.04.5 LTS
- Linux kernel 6.8.12
- NVIDIA driver 615.71.09
- CUDA C and C++
- Bash and systemd
- GRUB, QEMU and OVMF

## Repository Structure

```text
TRACK_C_PROJECT/
├── benchmarks/    # CUDA source code
├── build/         # Generated ISO images
├── configs/       # Kernel and system configurations
├── docs/          # Reports and project documentation
├── kernel/        # Custom kernel packages
├── results/       # Test evidence and checksums
└── scripts/       # Build and automation scripts
```

## Build

Rebuild the ISO from the existing prepared root filesystem:

```bash
./scripts/rebuild-release.sh
```

See `docs/REPRODUCE.md` for build requirements and reproduction limitations.

## Testing

The custom distribution has been boot-tested in QEMU with BIOS and UEFI.

The QEMU guest successfully reported:

- Custom kernel: `6.8.12-trackc`
- NVIDIA module version: `615.71.09`
- Systemd status: `running`
- Failed systemd services: `0`
- CUDA check service: `active (exited)`

The WSL2 host detects an NVIDIA GeForce RTX 4050 and reports CUDA UMD version 13.3. Native CUDA execution inside the custom distribution remains unverified because the QEMU guest did not have GPU access.

## Build Results

| Result | Value |
|---|---|
| Custom kernel | `6.8.12-trackc` |
| NVIDIA driver | `615.71.09` |
| Optimized test ISO | 1,397,649,408 bytes |
| SquashFS compressed size | 43.72% of uncompressed size |
| Duplicate files removed | 11,335 |
| QEMU failed services | 0 |

The SquashFS compression figure describes the filesystem image, not the overall ISO size reduction.

## Security

The distribution includes basic security settings:

- Restricted kernel pointer access
- Restricted access to kernel logs
- systemd service hardening
- `NoNewPrivileges` protection

## Documentation

- `docs/TECHNICAL_REPORT.md` contains the detailed project report.
- `docs/DEMO_GUIDE.md` explains the demonstration steps.
- `docs/REPRODUCE.md` describes the rebuild process.
- `docs/PROJECT_STATUS.md` records the project status.

## Limitations

- Native GPU execution inside the custom distribution still requires hardware validation.
- The rebuild script uses an existing prepared root filesystem.
- A complete clean build from an empty environment has not been verified.

