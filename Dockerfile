# A worker for decompilation projects: everything a decomp-toolkit style build
# needs from the operating system, so a rented machine is ready as soon as the
# image is pulled. No compiler, no game file and no project is in it; a
# project brings those itself.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    WINEDEBUG=-all

# 32-bit Wine runs the Windows compilers that wibo cannot (MSVC among them),
# and is the larger part of this image.
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git rsync openssh-server unzip xz-utils zstd file less tmux \
        python3 python3-pip python3-numpy python3-capstone \
        ninja-build make patch \
        gcc g++ gcc-mingw-w64-i686 g++-mingw-w64-i686 \
        wine wine32 wine64 \
 && rm -rf /var/lib/apt/lists/*

# A build that holds thousands of objects open (a linker run under wibo does)
# stops without a message at Docker's soft limit of 1024 descriptors.
RUN printf '* soft nofile 65536\n* hard nofile 65536\n' > /etc/security/limits.d/nofile.conf

WORKDIR /root
CMD ["sleep", "infinity"]
