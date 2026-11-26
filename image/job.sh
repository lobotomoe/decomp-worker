#!/bin/bash
# Runs a command detached from the session that started it, so a dropped SSH
# connection does not end it, and answers afterwards whether it finished and
# how. A wait loop that polls a log cannot tell "still running" from "died
# without a word"; this keeps the exit code.
#   decomp-worker-job start NAME -- COMMAND...
#   decomp-worker-job status NAME    exit 0 finished well, 3 still running, else the command's code
#   decomp-worker-job wait NAME [SECONDS]
#   decomp-worker-job log NAME [LINES]
#   decomp-worker-job where NAME     the stack of the job's busiest Python process
#   decomp-worker-job list
#
# A running job's status says what it is doing, under the first line: the
# command deepest in its process tree, how many cores the tree used over the
# last second, how long the log has been quiet and its last line, and the
# last line the job wrote to $DECOMP_WORKER_PROGRESS, a file every job is
# handed for reporting its own progress ("similar: 1200 of 3700").
set -euo pipefail
root="${DECOMP_WORKER_JOBS:-/var/tmp/decomp-worker-jobs}"
usage() { sed -n '6,11s/^# *//p' "$0" >&2; exit 2; }
[ $# -ge 1 ] || usage
action="$1"; shift

folder() { [ $# -ge 1 ] && [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] || usage; echo "$root/$1"; }
running() { [ -f "$1/pid" ] && [ ! -f "$1/exit" ] && kill -0 "$(cat "$1/pid")" 2>/dev/null; }
# The job's processes: its own and every descendant, parents first.
tree() {
	ps -eo pid=,ppid= | awk -v root="$1" '
		{ parent[$1] = $2; order[NR] = $1 }
		END {
			keep[root] = 1; print root
			do { grown = 0
				for (i = 1; i <= NR; i++) { p = order[i]
					if (!(p in keep) && (parent[p] in keep)) { keep[p] = 1; print p; grown = 1 } }
			} while (grown)
		}'
}
# Clock ticks the given processes have run, from /proc. The command name, the
# second field, may hold spaces, so the fields are counted after it: utime
# and stime are the 12th and 13th from there.
ticks() { local total=0 pid stat; local -a fields
	for pid in "$@"; do
		stat=$(cat "/proc/$pid/stat" 2>/dev/null) || continue
		read -ra fields <<< "${stat##*) }"
		total=$(( total + fields[11] + fields[12] ))
	done
	echo "$total"; }
# Each process of the tree with the ticks it ran over the last second,
# busiest first.
sample() { local pid; declare -A before
	for pid in "$@"; do before[$pid]=$(ticks "$pid"); done
	sleep 1
	# A process that ended within the second has no ticks left to read and
	# counts as none, not as the negative of what it had.
	for pid in "$@"; do [ -e "/proc/$pid" ] && echo "$(( $(ticks "$pid") - ${before[$pid]:-0} )) $pid"; done | sort -rn; }
describe() {
	local job="$1" used=0 top="" ticked pid hz quiet
	local -a pids
	mapfile -t pids < <(tree "$(cat "$job/pid")")
	hz=$(getconf CLK_TCK)
	while read -r ticked pid; do
		[ -n "$top" ] || top=$pid
		used=$(( used + ticked ))
	done < <(sample "${pids[@]}")
	used=$(( used * 100 / hz ))
	echo "  busiest: $(ps -o args= -p "$top" 2>/dev/null | cut -c1-160)"
	echo "  cpu: $(( used / 100 )).$(( used % 100 / 10 )) cores over the last second, ${#pids[@]} processes"
	if [ -s "$job/log" ]; then
		quiet=$(( $(date +%s) - $(stat -c %Y "$job/log") ))
		echo "  log: quiet for ${quiet}s: $(tail -n 1 "$job/log" | cut -c1-160)"
	else
		echo "  log: empty"
	fi
	if [ -s "$job/progress" ]; then
		echo "  progress: $(tail -n 1 "$job/progress" | cut -c1-160) ($(( $(date +%s) - $(stat -c %Y "$job/progress") ))s ago)"
	fi
}

status() {
	[ -d "$1" ] || { echo "no such job" >&2; return 2; }
	if [ -f "$1/exit" ]; then
		code="$(cat "$1/exit")"; echo "exited $code after $(( $(stat -c %Y "$1/exit") - $(stat -c %Y "$1/pid") ))s"; return "$code"
	fi
	if running "$1"; then
		echo "running for $(( $(date +%s) - $(stat -c %Y "$1/pid") ))s"
		[ -n "${DECOMP_WORKER_QUIET:-}" ] || describe "$1"
		return 3
	fi
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
	: > "$job/progress"
	: > "$job/stacks"
	DECOMP_WORKER_PROGRESS="$job/progress" DECOMP_WORKER_STACKS="$job/stacks" setsid nohup bash -c 'echo $$ > "$0/pid"; "$@" > "$0/log" 2>&1; echo $? > "$0/exit"' "$job" "$@" > /dev/null 2>&1 < /dev/null &
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
	export DECOMP_WORKER_QUIET=1
	while running "$job" || { [ ! -f "$job/pid" ] && [ ! -f "$job/exit" ]; }; do
		if [ "$limit" -gt 0 ] && [ $(( $(date +%s) - began )) -ge "$limit" ]; then break; fi
		sleep 2
	done
	status "$job"
	;;
log) job="$(folder "$@")"; tail -n "${2:-40}" "$job/log" ;;
where)
	job="$(folder "$@")"
	running "$job" || { status "$job"; exit $?; }
	mapfile -t pids < <(tree "$(cat "$job/pid")")
	pid=""
	while read -r _ candidate; do
		case "$(ps -o comm= -p "$candidate" 2>/dev/null)" in python*) pid=$candidate; break ;; esac
	done < <(sample "${pids[@]}")
	[ -n "$pid" ] || { echo "the job runs no Python process" >&2; exit 1; }
	echo "pid $pid: $(ps -o args= -p "$pid" | cut -c1-160)"
	# SIGUSR1 ends a process that does not catch it, so the signal goes only
	# to one that does: bit 9 (signal 10) of the caught mask.
	caught=$(awk '/^SigCgt:/ { print $2 }' "/proc/$pid/status")
	if [ $(( 0x$caught & 0x200 )) -eq 0 ]; then
		echo "pid $pid does not catch SIGUSR1: it started before the image had decomp_worker_stacks" >&2; exit 1
	fi
	: > "$job/stacks"
	kill -USR1 "$pid"
	for _ in $(seq 20); do [ -s "$job/stacks" ] && break; sleep 0.1; done
	[ -s "$job/stacks" ] || { echo "pid $pid caught SIGUSR1 and wrote no stack" >&2; exit 1; }
	sleep 0.2
	cat "$job/stacks"
	;;
list)
	[ -d "$root" ] || exit 0
	export DECOMP_WORKER_QUIET=1
	for job in "$root"/*/; do [ -d "$job" ] || continue; printf '%s: ' "$(basename "$job")"; status "${job%/}" || true; done
	;;
*) usage ;;
esac
