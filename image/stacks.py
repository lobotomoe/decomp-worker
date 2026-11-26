"""Loaded into every Python process a decomp-worker job starts, through
decomp_worker_stacks.pth: on SIGUSR1 the process appends every thread's stack
to the job's stacks file, which `decomp-worker-job where` reads. A rented
machine allows no ptrace of a process that is not a child, so py-spy cannot
do this there. Outside a job, without DECOMP_WORKER_STACKS, it does nothing."""

import os

_path = os.environ.get("DECOMP_WORKER_STACKS")
if _path:
    import faulthandler
    import signal

    # faulthandler writes from the signal handler into a file kept open.
    _stream = open(_path, "a", encoding="utf-8")  # noqa: SIM115
    faulthandler.register(signal.SIGUSR1, file=_stream, all_threads=True)
