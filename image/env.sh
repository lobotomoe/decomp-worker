# Read by every bash on the machine, the one sshd starts for `ssh host command`
# included: Docker's ENV does not reach a session opened over SSH.
export LANG=C.UTF-8
# Wine's fixme and err lines run to hundreds for one compile.
export WINEDEBUG="${WINEDEBUG--all}"
# Nothing here waits for a key: no pager, no question from apt.
export PAGER=cat GIT_PAGER=cat SYSTEMD_PAGER=cat DEBIAN_FRONTEND=noninteractive
export NO_COLOR=1
# A Python job's progress reaches its log as it is printed, not at exit.
export PYTHONUNBUFFERED=1
# A linker run over thousands of objects stops without a message at 1024.
ulimit -n "$(ulimit -Hn)" 2>/dev/null || true
