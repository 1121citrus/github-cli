# src — github-cli source

`github-cli` has no `src/` directory.  Its source files are at the project
root:

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds the image — installs `gh` on a slim base, adds non-root user and OCI labels |
| `include/github` | **Host-side shell functions** — source in `.bashrc`/`.bash_profile` to get the `github` wrapper function |

## `include/github`

A bash library for the host.  It is not copied into the Docker image; it is
intended to be sourced by the calling shell on the developer's workstation.

### What it provides

A `github` shell function (and a `gh` alias) that wraps `docker run` so that
`gh` commands are invoked inside the container without the user needing to
manage Docker flags manually.

### Authentication

Priority order:

1. `GITHUB_PAT` env var → forwarded to the container as `GH_TOKEN`
2. `~/.config/gh` → mounted read-only into the container

`GITHUB_PAT_FILE` and `GITHUB_USERNAME_FILE` are also supported for
secrets-file patterns; the plain env vars take precedence.

### Host-user identity

The container is started with `--user $(id -u):$(id -g)` so that file
operations (e.g. `gh repo create --source=.`) write as the host user, not as
root.  `GITHUB_LOGIN` is exported when `GITHUB_USERNAME` is set alongside
`GITHUB_PAT`.

### Sourcing

```bash
# Add to ~/.bashrc or ~/.bash_profile:
source /path/to/github-cli/include/github
```

After sourcing, `gh` and `github` are available as shell functions that
transparently delegate to the container.
