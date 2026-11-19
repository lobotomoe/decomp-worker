#!/bin/bash
# Proves the image holds what the README says: every tool answers, and Wine
# runs a 32-bit program. The workflow runs this before publishing; on a
# machine, `decomp-worker-check` says whether it is the image it claims to be.
set -euo pipefail
for tool in ssh rsync rclone curl wget aria2c unzip zip 7z xz zstd tmux htop parallel pv \
            git file jq rg tree hexdump gcc g++ make ninja cmake python3 pip3 \
            mips-linux-gnu-objdump powerpc-linux-gnu-objdump arm-none-eabi-objdump \
            i686-w64-mingw32-gcc wine; do
	command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done
python3 -c "import numpy, capstone, elftools, venv"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
printf '#include <stdio.h>\nint main(void) { puts("ran under wine"); return 0; }\n' > "$scratch/hello.c"
i686-w64-mingw32-gcc -o "$scratch/hello.exe" "$scratch/hello.c"
[ "$(wine "$scratch/hello.exe" 2>/dev/null | tr -d '\r')" = "ran under wine" ] || { echo "wine did not run a 32-bit program" >&2; exit 1; }
echo "decomp-worker: all there"
