#!/bin/bash

# Exit on error
set -e

echo "Setting up RISC-V emulation environment..."

# Install required packages
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y \
    git \
    wget \
    build-essential \
    ninja-build \
    python3-setuptools \
    python3-venv \
    python3-pip \
    libglib2.0-dev \
    libpixman-1-dev \
    libslirp-dev \
    u-boot-qemu \
    opensbi \
    unzip \
    qemu-system-misc \
    qemu-utils

# Create working directory
WORKDIR="$HOME/riscv64-linux"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Clone and build QEMU
echo "Cloning and building QEMU..."
git clone https://github.com/qemu/qemu
cd qemu
mkdir build
cd build
python3 -m venv .venv
source .venv/bin/activate
pip install tomli
../configure --target-list=riscv64-softmmu --enable-slirp
make -j $(nproc)
sudo make install
deactivate

# Setup Linux RISC-V environment
echo "Setting up RISC-V Linux environment..."
cd "$WORKDIR"
mkdir -p linux
cd linux
wget https://gitlab.com/api/v4/projects/giomasce%2Fdqib/jobs/artifacts/master/download?job=convert_riscv64-virt -O artifacts.zip
unzip artifacts.zip

# Create startup scripts
echo "Creating startup scripts..."

# Standard configuration script
cat > "$WORKDIR/start_riscv.sh" << 'EOF'
#!/bin/bash
cd "$HOME/riscv64-linux/linux/dqib_riscv64-virt/"
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
EOF

# Powerful configuration script
cat > "$WORKDIR/start_riscv_powerful.sh" << 'EOF'
#!/bin/bash
cd "$HOME/riscv64-linux/linux/dqib_riscv64-virt/"
qemu-system-riscv64 \
    -machine "virt" \
    -cpu "rv64" \
    -smp 11 \
    -m 8G \
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
EOF

# Make scripts executable
chmod +x "$WORKDIR/start_riscv.sh"
chmod +x "$WORKDIR/start_riscv_powerful.sh"

echo "Setup completed successfully!"
echo "You can now run:"
echo "  $WORKDIR/start_riscv.sh        # For standard configuration"
echo "  $WORKDIR/start_riscv_powerful.sh  # For powerful configuration" 