# Base image
FROM ubuntu:22.04

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    asciinema \
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
    sudo \
    qemu-system-misc \
    qemu-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /riscv64-linux

# Clone and build QEMU
RUN echo "Cloning QEMU repository..." && \
    git clone https://github.com/qemu/qemu && \
    cd qemu && \
    mkdir build && \
    cd build && \
    echo "Setting up Python virtual environment for QEMU build..." && \
    python3 -m venv .venv && \
    /bin/bash -c "source .venv/bin/activate && \
    pip install tomli && \
    echo 'Configuring QEMU with RISC-V softmmu and slirp support...' && \
    ../configure --target-list=riscv64-softmmu --enable-slirp && \
    echo 'Building QEMU (this may take a while)...' && \
    make -j $(nproc) && \
    make install" && \
    echo "QEMU installation completed" && \
    cd /riscv64-linux && \
    rm -rf qemu

# Setup Linux RISC-V environment
RUN mkdir -p /riscv64-linux/linux && \
    cd /riscv64-linux/linux && \
    echo "Downloading RISC-V Linux image..." && \
    wget https://gitlab.com/api/v4/projects/giomasce%2Fdqib/jobs/artifacts/master/download?job=convert_riscv64-virt -O artifacts.zip && \
    unzip artifacts.zip && \
    rm artifacts.zip && \
    echo "RISC-V image setup completed"

# Create a startup script
RUN echo '#!/bin/bash\n\
echo "Starting RISC-V QEMU environment..."\n\
cd /riscv64-linux/linux/dqib_riscv64-virt/\n\
qemu-system-riscv64 \\\n\
    -machine "virt" \\\n\
    -cpu "rv64" \\\n\
    -m 1G \\\n\
    -device virtio-blk-device,drive=hd \\\n\
    -drive file=image.qcow2,if=none,id=hd \\\n\
    -device virtio-net-device,netdev=net \\\n\
    -netdev user,id=net,hostfwd=tcp::2222-:22 \\\n\
    -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \\\n\
    -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \\\n\
    -object rng-random,filename=/dev/urandom,id=rng \\\n\
    -device virtio-rng-device,rng=rng \\\n\
    -nographic \\\n\
    -append "root=LABEL=rootfs console=ttyS0"\n\
' > /start_riscv.sh && chmod +x /start_riscv.sh

# Create a more powerful startup script as an alternative
RUN echo '#!/bin/bash\n\
echo "Starting RISC-V QEMU environment with 8GB RAM and 11 CPUs..."\n\
cd /riscv64-linux/linux/dqib_riscv64-virt/\n\
qemu-system-riscv64 \\\n\
    -machine "virt" \\\n\
    -cpu "rv64" \\\n\
    -smp 11 \\\n\
    -m 8G \\\n\
    -device virtio-blk-device,drive=hd \\\n\
    -drive file=image.qcow2,if=none,id=hd \\\n\
    -device virtio-net-device,netdev=net \\\n\
    -netdev user,id=net,hostfwd=tcp::2222-:22 \\\n\
    -bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \\\n\
    -kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \\\n\
    -object rng-random,filename=/dev/urandom,id=rng \\\n\
    -device virtio-rng-device,rng=rng \\\n\
    -nographic \\\n\
    -append "root=LABEL=rootfs console=ttyS0"\n\
' > /start_riscv_powerful.sh && chmod +x /start_riscv_powerful.sh

# Create a script to check system requirements
RUN echo '#!/bin/bash\n\
echo "Checking system requirements..."\n\
echo "CPU Cores: $(nproc)"\n\
echo "Total Memory: $(free -h | awk '\''/^Mem:/{print $2}'\'')"\n\
echo "Available Disk Space: $(df -h / | awk '\''NR==2{print $4}'\'')"\n\
echo "QEMU Version: $(qemu-system-riscv64 --version | head -n1)"\n\
' > /check_requirements.sh && chmod +x /check_requirements.sh

# Set entrypoint
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "echo 'RISC-V QEMU Environment is ready. Run /check_requirements.sh to verify system requirements, then /start_riscv.sh for standard VM or /start_riscv_powerful.sh for a more powerful VM.'"] 