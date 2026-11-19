# A worker for decompilation projects: everything such a build needs from the
# operating system, and what it takes to run a machine from far away, so a
# rented one is ready as soon as the image is pulled. No console compiler, no
# game file and no project is in it; a project brings those itself.
# CONTRIBUTING.md says what belongs here.
FROM ubuntu:22.04

# For `docker run`; a session opened over SSH gets the same from
# image/env.sh, since sshd passes none of this on.
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    WINEDEBUG=-all \
    PAGER=cat GIT_PAGER=cat SYSTEMD_PAGER=cat \
    NO_COLOR=1 \
    PYTHONUNBUFFERED=1

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

# No Wine prefix is made here: it is 327 MB compressed, a third of the
# image, to save the few seconds Wine takes to make one on first use.

# The machine is driven one command at a time, by a person or an agent, and
# none of those commands may stop to ask. AGENTS.md lists what this sets.
COPY image/env.sh /etc/decomp-worker/env.sh
COPY AGENTS.md /etc/decomp-worker/AGENTS.md
COPY image/check.sh /usr/local/bin/decomp-worker-check
COPY image/job.sh /usr/local/bin/decomp-worker-job
COPY image/info.sh /usr/local/bin/decomp-worker-info
ARG BUILT=unknown
# bash.bashrc returns at its first lines when the shell is not interactive,
# so the environment goes in front of them.
RUN sed -i '1i . /etc/decomp-worker/env.sh' /etc/bash.bashrc \
 && chmod +x /usr/local/bin/decomp-worker-* \
 && echo "$BUILT" > /etc/decomp-worker/built \
 && printf 'APT::Get::Assume-Yes "true";\nAcquire::ForceIPv4 "true";\nAcquire::http::Timeout "30";\nAcquire::Retries "3";\n' > /etc/apt/apt.conf.d/90decomp-worker \
 && git config --system --add safe.directory '*' \
 && git config --system advice.detachedHead false

WORKDIR /root
CMD ["sleep", "infinity"]
