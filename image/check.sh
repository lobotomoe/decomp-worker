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
python3 -c "import numpy, capstone, elftools, venv, pytest, xdist"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
printf '#include <stdio.h>\nint main(void) { puts("ran under wine"); return 0; }\n' > "$scratch/hello.c"
i686-w64-mingw32-gcc -o "$scratch/hello.exe" "$scratch/hello.c"
if ! wine "$scratch/hello.exe" > "$scratch/out" 2> "$scratch/err" || ! grep -q "ran under wine" "$scratch/out"; then
	echo "wine did not run a 32-bit program:" >&2
	cat "$scratch/out" "$scratch/err" >&2
	exit 1
fi
# The environment has to reach a shell that is given one command, which is
# how sshd runs `ssh host command`.
[ "$(env -i SSH_CLIENT=check bash -c 'echo $PAGER')" = "cat" ] || { echo "the environment does not reach a command shell" >&2; exit 1; }
export DECOMP_WORKER_JOBS="$scratch/jobs"
decomp-worker-job start probe -- bash -c 'echo out; exit 7' > /dev/null
code=0; decomp-worker-job wait probe 20 > /dev/null || code=$?
[ "$code" = 7 ] && [ "$(decomp-worker-job log probe)" = "out" ] || { echo "decomp-worker-job lost a job's exit code or output" >&2; exit 1; }
# A running job reports its progress and gives its Python stack, and a
# process that does not catch SIGUSR1 is refused rather than ended by it.
decomp-worker-job start spin -- python3 -c '
import os
def spin_for_the_check():
    with open(os.environ["DECOMP_WORKER_PROGRESS"], "a") as progress:
        for i in range(10**10):
            if i % 1000000 == 0:
                progress.write(f"spin: {i}\n"); progress.flush()
spin_for_the_check()' > /dev/null
decomp-worker-job start bare -- python3 -S -c 'import time
while True: time.sleep(0.05)' > /dev/null
sleep 2
decomp-worker-job status spin > "$scratch/status" || true
grep -q "progress: spin:" "$scratch/status" || { echo "a job's progress did not reach its status:" >&2; cat "$scratch/status" >&2; exit 1; }
decomp-worker-job where spin > "$scratch/where" || { echo "decomp-worker-job where failed:" >&2; cat "$scratch/where" >&2; exit 1; }
grep -q "spin_for_the_check" "$scratch/where" || { echo "the stack did not name the running function:" >&2; cat "$scratch/where" >&2; exit 1; }
if decomp-worker-job where bare > /dev/null 2>&1; then echo "where signalled a process that does not catch SIGUSR1" >&2; exit 1; fi
code=0; decomp-worker-job status bare > /dev/null || code=$?
[ "$code" = 3 ] || { echo "where ended a process that does not catch SIGUSR1" >&2; exit 1; }
kill -- -"$(cat "$DECOMP_WORKER_JOBS/spin/pid")" -"$(cat "$DECOMP_WORKER_JOBS/bare/pid")"
decomp-worker-info --json | jq -e .cores > /dev/null
echo "decomp-worker: all there"
