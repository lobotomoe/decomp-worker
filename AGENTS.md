# Working on a decomp-worker machine

For a coding agent, or anyone driving the machine through one command at a
time. `decomp-worker-info` prints this on the machine.

## Anything longer than a minute: start it as a job

    decomp-worker-job start build -- ninja -C /root/project
    decomp-worker-job status build     # exit 0 done, 3 running, else the command's own code
    decomp-worker-job wait build 600   # returns when it ends, or after 600 s
    decomp-worker-job log build 40     # the last 40 lines
    decomp-worker-job list

A job outlives the SSH connection that started it and keeps its exit code.
`status` tells apart running, finished and gone (machine restarted): a loop
that greps a log for "done" cannot, and waits forever on the third.

## What is already set

- Nothing asks a question: apt assumes yes, no pager, no colour codes.
- apt uses IPv4 with a timeout and retries; a host with a dead IPv6 route
  otherwise leaves `apt-get update` waiting without end.
- Wine prints the program's output and not its own diagnostics. Set
  `WINEDEBUG=` (empty) in front of a command to see them.
- git accepts a tree copied in by rsync, whoever owns the files.
- The open file limit is raised to the most the host allows.
- Python output is unbuffered, so a job's log grows as it runs.

## Traps

- `ssh host cmd < file` feeds the file to `cmd`. A command before it in the
  same line that reads stdin (rsync, ssh, apt) eats it; give those
  `< /dev/null`.
- Slow is not hung. Before deciding a step is stuck, look for growth:
  `decomp-worker-job log`, a file count, `htop`. Destroying a machine in the
  middle of a slow install costs the install twice.
- Results exist only on the machine. Copy them off and count them before it
  is destroyed.
- `nproc` can report more threads than the rental gives. Size `-j` and
  `parallel` from what was rented.
- 32-bit Wine inside a Docker with a strict seccomp profile stops with
  `socket : Function not implemented`; see the README.

## What is installed

`decomp-worker-check` lists and proves it. Moving files: rsync, rclone,
aria2c, curl, wget. Archives: 7z, zip, xz, zstd. Reading: rg, jq, file,
hexdump, tree. Building: gcc, ninja, cmake, make, python3 with numpy,
capstone, pyelftools; `python3 -m venv` for anything else. Binutils:
`mips-linux-gnu-`, `powerpc-linux-gnu-`, `arm-none-eabi-`. Wine 32 and 64.

Missing something every project would need? CONTRIBUTING.md in
github.com/lobotomoe/decomp-worker says how to ask.
