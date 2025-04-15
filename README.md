# RISC-V Emulation Environment

This project provides two ways to set up a RISC-V emulation environment:

1. Using Docker
2. Direct installation on your system (for better performance)

## Prerequisites

- At least 8GB of RAM (recommended)
- 20GB of free disk space
- A Linux-based system (tested on Ubuntu 22.04)
- For Docker setup: Docker installed on your system

## Option 1: Docker Setup (Recommended)

### Quick Start

1. Clone this repository:

```bash
git clone https://github.com/Posit-Foundation/soft-posit-riscv-test-sim
cd soft-posit-riscv-test-sim
```

2. Build the Docker image:

```bash
docker build -t riscv-emulator .
```

3. Run the container:

```bash
docker run -it --privileged riscv-emulator
```

4. Inside the container, start the RISC-V emulation:

```bash
/start_riscv.sh  # For standard configuration
# OR
/start_riscv_powerful.sh  # For more powerful configuration (8GB RAM, 11 CPUs)
```

## Option 2: Direct System Setup

### Quick Start

1. Clone this repository:

```bash
git clone https://github.com/yourusername/risc-v-sim.git
cd risc-v-sim
```

2. Make the setup script executable and run it:

```bash
chmod +x setup_riscv.sh
./setup_riscv.sh
```

3. After setup completes, you can start the RISC-V emulation:

```bash
~/riscv64-linux/start_riscv.sh        # For standard configuration
# OR
~/riscv64-linux/start_riscv_powerful.sh  # For powerful configuration
```

### Direct Setup Details

The direct setup script (`setup_riscv.sh`) will:

1. Install all required dependencies
2. Build QEMU from source
3. Download and set up the RISC-V Linux image
4. Create startup scripts in your home directory

## Detailed Setup Guide

### 1. Environment Setup

Both methods provide:

- QEMU with RISC-V support
- Required build tools and dependencies
- Pre-configured RISC-V Linux image
- Startup scripts for different configurations

### 2. Configuration Options

The environment provides two startup scripts:

- Standard configuration (1GB RAM)
- Powerful configuration (8GB RAM, 11 CPUs)

### 3. QEMU Configuration

The QEMU emulation includes:

- RISC-V 64-bit CPU
- VirtIO block device for storage
- Network support with port forwarding (SSH on port 2222)
- U-Boot bootloader
- OpenSBI firmware

### 4. Accessing the RISC-V System

Once the emulation starts, you can:

- Access the system through the console
- SSH into the system using port 2222
- Use the pre-installed Debian environment

## Technical Details

### QEMU Command Breakdown

```bash
qemu-system-riscv64 \
    -machine "virt" \
    -cpu "rv64" \
    -m 1G \
    -device virtio-blk-device,drive=hd \
    -drive file=image.qcow2,if=none,id=hd \
    -device virtio-net-device,netdev=net \
    -netdev user,id=net,hostfwd=tcp::2222-:22 \
    -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
    -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
    -object rng-random,filename=/dev/urandom,id=rng \
    -device virtio-rng-device,rng=rng \
    -nographic \
    -append "root=LABEL=rootfs console=ttyS0"
```

### Components

1. **QEMU**: Emulates the RISC-V hardware
2. **U-Boot**: Bootloader for the system
3. **OpenSBI**: RISC-V Supervisor Binary Interface
4. **Debian Image**: Pre-configured RISC-V Debian system

## Troubleshooting

### Common Issues

1. **Permission Issues**
   - Docker: Run with `--privileged` flag
   - Direct: Ensure proper permissions for QEMU and device access

2. **Network Issues**
   - Solution: Ensure port 2222 is available on the host

3. **Performance Issues**
   - Solution: Use the powerful configuration script
   - Direct setup generally provides better performance than Docker

### Debugging

- Check system logs for issues
- Monitor system resources during emulation
- Verify network connectivity
- For Docker: Check container logs
- For Direct: Check system logs and QEMU output

## References

- [RISC-V Machines Documentation](https://risc-v-machines.readthedocs.io/en/latest/linux/simple/)
- [Getting Started with Linux and BusyBox for RISC-V](https://viktor-prutyanov.github.io/2023/02/11/Getting-started-with-Linux-and-BusyBox-for-RISC-V-on-QEMU.html)
- [Running RISC-V QEMU](https://jborza.com/post/2021-04-03-running-riscv-qemu/)
- [Emulating RISC-V Debian on WSL2](https://blog.davidburela.com/2020/11/15/emulating-risc-v-debian-on-wsl2/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.
