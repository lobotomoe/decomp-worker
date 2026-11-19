#!/bin/bash
# What this machine is, in one call. --json for a program.
set -euo pipefail
built="$(cat /etc/decomp-worker/built)"
cores="$(nproc)"
memory="$(awk '/MemTotal/ { printf "%d", $2 / 1048576 }' /proc/meminfo)"
disk="$(df -BG --output=avail / | tail -1 | tr -dc 0-9)"
if [ "${1:-}" = "--json" ]; then
	printf '{"image":"decomp-worker","built":"%s","cores":%s,"memory_gb":%s,"disk_free_gb":%s,"open_files":%s,"wine":"%s"}\n' \
		"$built" "$cores" "$memory" "$disk" "$(ulimit -n)" "$(wine --version 2>/dev/null)"
	exit 0
fi
echo "decomp-worker built $built: $cores cores, $memory GB memory, $disk GB free, $(ulimit -n) open files"
cat /etc/decomp-worker/AGENTS.md
