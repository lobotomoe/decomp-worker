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

- Wine, 32 and 64 bit, for Windows compilers that wibo does not run
- Python 3 with numpy and capstone, ninja, make, patch
- gcc, g++ and the i686 MinGW cross compiler
- git, rsync, curl, wget, unzip, xz, zstd, an SSH server, tmux

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

## Changing it

Edit the `Dockerfile` and push; the workflow builds and publishes the image.
It also rebuilds on the first of each month for Ubuntu's updates.
