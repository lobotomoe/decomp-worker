# A worker for decompilation projects: everything such a build needs from the
# operating system, and what it takes to run a machine from far away, so a
# rented one is ready as soon as the image is pulled. No console compiler, no
# game file and no project is in it; a project brings those itself.
# CONTRIBUTING.md says what belongs here.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    WINEDEBUG=-all

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    # Reaching the machine and moving files to and from it.
        ca-certificates openssh-server openssh-client rsync rclone curl wget aria2 \
    # Archives a disc image, a toolchain or a result set comes in.
        unzip zip p7zip-full xz-utils zstd bzip2 \
    # Running and watching a long job.
        tmux htop parallel pv lsof procps less nano \
    # Reading what came back.
        git file jq ripgrep tree bsdextrautils \
    # Building.
        build-essential ninja-build cmake pkg-config patch \
        python3 python3-pip python3-venv python3-numpy python3-capstone python3-pyelftools \
    # Binutils for the consoles' processors, and MinGW for building a
    # Windows tool from source.
        binutils-mips-linux-gnu binutils-powerpc-linux-gnu binutils-arm-none-eabi \
        gcc-mingw-w64-i686 g++-mingw-w64-i686 \
    # 32-bit Wine runs the Windows compilers that wibo cannot (MSVC among
    # them), and is the larger part of this image.
        wine wine32 wine64 \
 && rm -rf /var/lib/apt/lists/*

# A build that holds thousands of objects open (a linker run under wibo does)
# stops without a message at Docker's soft limit of 1024 descriptors.
RUN printf '* soft nofile 65536\n* hard nofile 65536\n' > /etc/security/limits.d/nofile.conf

COPY check.sh /usr/local/bin/decomp-worker-check
WORKDIR /root
CMD ["sleep", "infinity"]
