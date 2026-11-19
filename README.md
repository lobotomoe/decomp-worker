# decomp-worker

A Docker image for decompilation projects built with
[decomp-toolkit](https://github.com/encounter/decomp-toolkit) and tools like
it: the operating system packages such a build needs, already installed, so a
rented machine can start compiling as soon as the image is pulled.

    ghcr.io/lobotomoe/decomp-worker:latest

Tags are `latest` and the date of the build (`2026-11-19`). Pin the date when
a run has to be repeatable.

## What is in it

Ubuntu 22.04 for x86-64 with:

- **Wine**, 32 and 64 bit, for Windows compilers that wibo does not run
- **Building**: gcc, g++, make, ninja, cmake, the i686 MinGW cross compiler;
  Python 3 with pip, venv, numpy, capstone and pyelftools
- **Binutils** for MIPS, PowerPC and ARM (`mips-linux-gnu-`,
  `powerpc-linux-gnu-`, `arm-none-eabi-`)
- **Moving files**: an SSH server and client, rsync, rclone, curl, wget,
  aria2; zip, 7z, xz, zstd
- **Running a long job**: tmux, htop, GNU parallel, pv
- **Reading results**: git, jq, ripgrep, file, hexdump, tree

`decomp-worker-check` on a machine proves all of it is there.

## What is not in it

No compiler for a console, no game file, no project. Those are not ours to
give out; a project fetches its own compilers and copies its own files, as
its build already does on any machine.

## Why

Installing Wine on a fresh Ubuntu machine is about 400 packages. On a rented
machine that took 25 minutes on a day the mirrors were slow, for a job that
ran four. With the packages in the image the wait is the pull.

## Using it

On [vast.ai](https://vast.ai), name it as the image when creating an
instance:

    vastai create instance OFFER --image ghcr.io/lobotomoe/decomp-worker:latest --disk 40 --ssh --direct

Anywhere else:

    docker run --rm -it -v "$PWD":/work -w /work ghcr.io/lobotomoe/decomp-worker bash

## Wine under a strict Docker

32-bit Wine needs a system call some Docker installations refuse; it then
stops with `wine: socket : Function not implemented`. GitHub's hosted runners
are set up that way. Add `--security-opt seccomp=unconfined` to `docker run`
there. On vast.ai it runs as is.

## Changing it

Something missing, or something nobody needs? [CONTRIBUTING.md](CONTRIBUTING.md)
says what belongs in the image and how to ask. Requests from coding agents
are as welcome as from people, on the same terms.

The workflow builds the image, checks it and publishes it on every push to
`main`, and rebuilds it on the first of each month for Ubuntu's updates.
