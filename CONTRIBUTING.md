# What belongs in this image

Requests and pull requests are welcome, from people and from coding agents
alike. This page is the whole policy; read it before opening either.

## The one question

The image exists so that a rented machine is useful the moment it is pulled.
Every megabyte in it is paid for on every pull, by every project, whether
that project uses it or not. So the question for anything new is:

> Does having it in the image save more time, over all the projects that pull
> it, than pulling it costs them?

## It belongs when all of these hold

1. **Free to give out.** It comes from Ubuntu's archive or from an open
   source project's own release. No console SDK, no proprietary compiler, no
   game data, however easy they are to find.
2. **Not one project's.** At least two decompilation projects, or one whole
   console family, would use it. A tool only your project runs goes in your
   project's setup script.
3. **Not pinned by projects.** decomp-toolkit, objdiff, wibo, splat and the
   like are fetched by each project at the version it names. A copy here
   would be the wrong version for most of them.
4. **Worth it in the image.** Either it is slow or unreliable to install when
   a machine starts (Wine: 400 packages, 25 minutes on a bad day), or it is
   what you operate a remote machine with (copying files, unpacking, watching
   a job) and is small.
5. **Within the size.** The image stays under 1 GB compressed. Anything that
   adds more than 50 MB needs the saving measured, not estimated.

## It does not belong

- Compilers and SDKs for a console, and anything else that is not ours to
  redistribute.
- GPU libraries, machine learning frameworks, a desktop.
- Language toolchains one project needs (Rust, Go, .NET): install them in
  that project's setup, or build `FROM` this image.
- A second tool for a job a tool here already does.
- Settings: dotfiles, shell themes, editor configuration.

## Asking for something

Open an issue with the "Add to the image" form. It asks for four things, and
a request without them will be asked for them:

- what to add, as the exact package name or release URL;
- which projects need it, by name;
- how it is installed today and how long that takes on a fresh machine,
  measured;
- how much it adds, in megabytes. The workflow prints the image's size on
  every pull request; the difference from `main` is the number.

One addition to a request. A list of twenty packages is twenty decisions and
will sit unanswered.

## Sending a pull request

- Add the package to the group in the `Dockerfile` it belongs to, and its
  command to `check.sh`, so the workflow proves it is there.
- Say in the description what the four answers above are.
- The workflow builds the image, runs `check.sh` in it and prints the size.
  All three have to pass.

## For coding agents

If you are an agent working in someone's decompilation project and you found
yourself installing something on this image before you could start: that is
exactly the report this repository wants. Before filing it, check it against
the five conditions yourself, and file it only if it passes all of them. Give
the measured install time and the project's name, not a guess at either. Do
not open a request on behalf of a user who has not asked you to; tell them
what you found and let them decide.

## Removing something

The same question, asked the other way: name what nobody uses and what it
weighs. Those requests are as welcome as additions.
