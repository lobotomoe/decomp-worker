#!/bin/bash
# Runs a command detached from the session that started it, so a dropped SSH
# connection does not end it, and answers afterwards whether it finished and
# how. A wait loop that polls a log cannot tell "still running" from "died
# without a word"; this keeps the exit code.
#   decomp-worker-job start NAME -- COMMAND...
#   decomp-worker-job status NAME    exit 0 finished well, 3 still running, else the command's code
#   decomp-worker-job wait NAME [SECONDS]
#   decomp-worker-job log NAME [LINES]
#   decomp-worker-job list
set -euo pipefail
root="${DECOMP_WORKER_JOBS:-/var/tmp/decomp-worker-jobs}"
usage() { sed -n '6,10s/^# *//p' "$0" >&2; exit 2; }
[ $# -ge 1 ] || usage
action="$1"; shift

folder() { [ $# -ge 1 ] && [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || usage; echo "$root/$1"; }
running() { [ -f "$1/pid" ] && [ ! -f "$1/exit" ] && kill -0 "$(cat "$1/pid")" 2>/dev/null; }
status() {
	[ -d "$1" ] || { echo "no such job" >&2; return 2; }
	if [ -f "$1/exit" ]; then
		code="$(cat "$1/exit")"; echo "exited $code after $(( $(stat -c %Y "$1/exit") - $(stat -c %Y "$1/pid") ))s"; return "$code"
	fi
	if running "$1"; then echo "running for $(( $(date +%s) - $(stat -c %Y "$1/pid") ))s"; return 3; fi
	# No exit code and no process: the machine restarted or the job was killed.
	echo "gone without an exit code"; return 1
}

case "$action" in
start)
	job="$(folder "$@")"; shift
	[ "${1:-}" = "--" ] && [ $# -ge 2 ] || usage
	shift
	if running "$job"; then echo "already running" >&2; exit 1; fi
	rm -rf "$job"; mkdir -p "$job"
	printf '%q ' "$@" > "$job/command"
	setsid nohup bash -c 'echo $$ > "$0/pid"; "$@" > "$0/log" 2>&1; echo $? > "$0/exit"' "$job" "$@" > /dev/null 2>&1 < /dev/null &
	# The pid is the job's own word that it began; without waiting for it a
	# status asked at once would find neither a process nor an exit code.
	for _ in $(seq 50); do [ -f "$job/pid" ] && break; sleep 0.1; done
	[ -f "$job/pid" ] || { echo "the job did not start" >&2; exit 1; }
	echo "started; log $job/log"
	;;
status) status "$(folder "$@")" ;;
wait)
	job="$(folder "$@")"; limit="${2:-0}"; began="$(date +%s)"
	[ -d "$job" ] || { echo "no such job" >&2; exit 2; }
	while running "$job" || { [ ! -f "$job/pid" ] && [ ! -f "$job/exit" ]; }; do
		if [ "$limit" -gt 0 ] && [ $(( $(date +%s) - began )) -ge "$limit" ]; then break; fi
		sleep 2
	done
	status "$job"
	;;
log) job="$(folder "$@")"; tail -n "${2:-40}" "$job/log" ;;
list)
	[ -d "$root" ] || exit 0
	for job in "$root"/*/; do [ -d "$job" ] || continue; printf '%s: ' "$(basename "$job")"; status "${job%/}" || true; done
	;;
*) usage ;;
esac
