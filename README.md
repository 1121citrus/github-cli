# 1121citrus/github-cli

[![CI](https://github.com/1121citrus/github-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/1121citrus/github-cli/actions/workflows/ci.yml)

A Docker wrapper for the [GitHub CLI](https://cli.github.com/) (`gh`),
providing a containerized `gh` command with your existing GitHub authentication.

## Contents

- [Contents](#contents)
- [Prerequisites](#prerequisites)
- [Synopsis](#synopsis)
- [Usage](#usage)
  - [Environment Variables](#environment-variables)
- [Example: List repositories](#example-list-repositories)
- [Example: Create a pull request](#example-create-a-pull-request)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Security considerations](#security-considerations)
- [Building](#building)
  - [Base image](#base-image)
  - [Known unfixable CVEs](#known-unfixable-cves)
- [Testing](#testing)
- [CI/CD](#cicd)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with
  [buildx](https://docs.docker.com/build/buildx/) for building images)
- Bash 4.0+ (macOS ships 3.2 — install a newer version via
  [Homebrew](https://brew.sh/): `brew install bash`)
- An existing `gh auth login` session **or** a `GITHUB_PAT` environment
  variable (see [Authentication](#authentication))

## Synopsis

- Run `gh` commands in an isolated Docker container.
- Mounts your existing GitHub CLI configuration for seamless authentication.
- Mounts the current working directory as `/workspace` for repository operations.

## Usage

Source the shell functions from `include/github` in your `.bashrc` or `.bash_profile`:

```bash
source /path/to/github-cli/include/github
```

Then use `gh` or `github` as you normally would. See the
[GitHub CLI manual](https://cli.github.com/manual/) for full command reference.

| Command | Documentation |
| --- | --- |
| `gh auth status` | [gh auth status](https://cli.github.com/manual/gh_auth_status) |
| `gh repo list` | [gh repo list](https://cli.github.com/manual/gh_repo_list) |
| `gh pr list` | [gh pr list](https://cli.github.com/manual/gh_pr_list) |
| `gh issue create` | [gh issue create](https://cli.github.com/manual/gh_issue_create) |

### Environment Variables

Variable | Default | Type | Notes
--- | --- | --- | ---
`GITHUB_PAT` | None | `«string»` | GitHub Personal Access Token. Passed to the container as `GH_TOKEN`. Takes precedence over `GITHUB_PAT_FILE` and `~/.config/gh` credentials.
`GITHUB_PAT_FILE` | None | `«file»` | Path to a file containing a GitHub PAT (first line is read). Suitable for Docker Compose secrets. Ignored when `GITHUB_PAT` is set.
`GITHUB_USERNAME` | None | `«string»` | GitHub username. Exported as `GITHUB_LOGIN` when a PAT is also provided.
`GITHUB_USERNAME_FILE` | None | `«file»` | Path to a file containing a GitHub username (first line is read). Suitable for Docker Compose secrets. Ignored when `GITHUB_USERNAME` is set.

## Example: List repositories

See [gh repo list](https://cli.github.com/manual/gh_repo_list) for all options.

```text
NAME                           DESCRIPTION                    INFO
1121citrus/github-cli          GitHub CLI Docker wrapper      public
1121citrus/pfsense-backup      pfSense backup to S3           public
```

## Example: Create a pull request

See [gh pr create](https://cli.github.com/manual/gh_pr_create) for all options.

```text
https://github.com/1121citrus/github-cli/pull/1
```

## Configuration

The `include/github` file provides two shell functions:

| Function | Description |
| --- | --- |
| `gh` | Alias for `github` |
| `github` | Runs the GitHub CLI in a Docker container |

The container mounts:

| Host path | Container path | Mode | Purpose |
| --- | --- | --- | --- |
| [`~/.config/gh`](https://cli.github.com/manual/gh_auth_login) | `/gh-config` | read-write | GitHub CLI auth and config |
| `$PWD` | `/workspace` | read-write | Current repository |

Authentication uses your existing `gh auth login` credentials from
[`~/.config/gh`](https://cli.github.com/manual/gh_auth_login).
If you have not authenticated yet, run `gh auth login` — the wrapper
runs the login flow inside the container and writes the resulting
credentials to `~/.config/gh` on the host.

## Authentication

Two authentication methods are supported, in priority order:

| Priority | Method | How |
| --- | --- | --- |
| 1 | **Personal Access Token** | Set `GITHUB_PAT` (and optionally `GITHUB_USERNAME`) in the environment |
| 2 | **CLI config** | Run `gh auth login`; the resulting `~/.config/gh` is mounted into the container |

When `GITHUB_PAT` is set, it is passed to the container as `GH_TOKEN`,
which the GitHub CLI uses in preference to any stored credentials.

If `GITHUB_USERNAME` is also set, it is exported as `GITHUB_LOGIN` for
use by calling scripts.

```bash
export GITHUB_PAT="ghp_..."
export GITHUB_USERNAME="octocat"
gh repo list
```

## Security considerations

- **Token handling:** When `GITHUB_PAT` is set, it is passed to the
  container via `-e GH_TOKEN=...`. This is visible in `docker inspect`
  output. Do not use this method on shared hosts where other users can
  inspect running containers. Prefer `gh auth login` on trusted
  single-user machines.
- **Config mount:** `~/.config/gh` is mounted **read-write** so that
  `gh auth login` can store credentials from inside the container.
  The container runs as your host UID/GID, so file ownership is preserved.
- **Workspace mount:** The current directory (`$PWD`) is mounted
  **read-write** so that `gh` can operate on the repository.
  Only run this in directories you trust.
- **Non-root execution:** The container runs as the host user's
  UID/GID (`--user "$(id -u):$(id -g)"`), so all file operations
  (including git writes) use the correct ownership.
- **TTY detection:** The wrapper allocates a pseudo-TTY only when
  stdin and stdout are terminals, allowing safe use in CI pipelines
  and non-interactive scripts.

## Building

```bash
VERSION=x.y.z bin/build
```

To build and push to Docker Hub (multi-platform `linux/amd64` + `linux/arm64`):

```bash
VERSION=x.y.z PUSH=true bin/build
```

For reproducible production builds, pin the base image to a specific digest:

```bash
VERSION=x.y.z ALPINE_SHA=sha256:<digest> bin/build
```

The build script will:

1. Lint the Dockerfile with [hadolint](https://github.com/hadolint/hadolint)
2. Build the image locally and tag as `1121citrus/github-cli:VERSION`
   and `github-cli`
3. Scan with [Trivy](https://github.com/aquasecurity/trivy) and
   [Docker Scout](https://docs.docker.com/scout/) for HIGH and CRITICAL
   vulnerabilities
4. Optionally push a multi-platform image to Docker Hub when `PUSH=true`

### Base image

The default base is [`alpine:edge`](https://hub.docker.com/_/alpine). Stable
[`alpine:3.21`](https://hub.docker.com/_/alpine) ships `github-cli 2.63` and
`curl 8.14` carrying 2 CRITICAL and 13 HIGH CVEs. Edge ships `github-cli 2.83`
and `curl 8.19` resolving all OS-level CVEs. The `apk upgrade` step also
upgrades `zlib` to `1.3.2-r0`, fixing the 1M+1L CVEs present in the
`alpine:edge` base layer.

### Known unfixable CVEs

Nine CVEs remain. All are transitive Go module dependencies compiled
into the `gh` binary by the Alpine package maintainer. They cannot be
patched at the image level and require the
[cli/cli](https://github.com/cli/cli) project to update its `go.mod`.
All are only reachable via `gh attestation` commands.

| Severity | CVE | Package | Fix |
| --- | --- | --- | --- |
| HIGH | [CVE-2025-15558](https://www.cve.org/CVERecord?id=CVE-2025-15558) | [`docker/cli` 29.0.3](https://github.com/docker/cli) | 29.2.0 |
| HIGH | [CVE-2025-66564](https://www.cve.org/CVERecord?id=CVE-2025-66564) | [`sigstore/timestamp-authority` 1.2.9](https://github.com/sigstore/timestamp-authority) | 2.0.3 |
| HIGH | [CVE-2026-24051](https://www.cve.org/CVERecord?id=CVE-2026-24051) | [`otel/sdk` 1.38.0](https://github.com/open-telemetry/opentelemetry-go) | 1.40.0 |
| MEDIUM | [CVE-2026-23992](https://www.cve.org/CVERecord?id=CVE-2026-23992) | [`go-tuf/v2` 2.3.0](https://github.com/theupdateframework/go-tuf) | 2.3.1 |
| MEDIUM | [CVE-2026-23991](https://www.cve.org/CVERecord?id=CVE-2026-23991) | [`go-tuf/v2` 2.3.0](https://github.com/theupdateframework/go-tuf) | 2.3.1 |
| MEDIUM | [CVE-2026-24686](https://www.cve.org/CVERecord?id=CVE-2026-24686) | [`go-tuf/v2` 2.3.0](https://github.com/theupdateframework/go-tuf) | 2.4.1 |
| MEDIUM | [CVE-2026-24117](https://www.cve.org/CVERecord?id=CVE-2026-24117) | [`sigstore/rekor` 1.4.2](https://github.com/sigstore/rekor) | 1.5.0 |
| MEDIUM | [CVE-2026-23831](https://www.cve.org/CVERecord?id=CVE-2026-23831) | [`sigstore/rekor` 1.4.2](https://github.com/sigstore/rekor) | 1.5.0 |
| MEDIUM | [CVE-2026-24137](https://www.cve.org/CVERecord?id=CVE-2026-24137) | [`sigstore/sigstore` 1.9.6](https://github.com/sigstore/sigstore) | 1.10.4 |

## Testing

The test suite requires a built Docker image. Build first, then run:

```bash
bin/build
./test/run-all
```

Individual test files can also be run directly:

| Test file | What it validates |
| --- | --- |
| `test/image-structure` | Non-root user, WORKDIR, installed binaries, nologin shell |
| `test/gh-invocation` | Entrypoint, `gh --version`, `gh help`, unknown-command handling |
| `test/env-metadata` | Build-time `APP_*` env vars and OCI labels |
| `test/shell-functions` | `include/github` argument passing, PAT injection, TTY detection (uses a docker stub — no image required) |

To run only the shell-function tests (no Docker image needed):

```bash
./test/shell-functions
```

## CI/CD

GitHub Actions runs on every push to `main`/`master` and on pull requests.
The pipeline is defined in `.github/workflows/ci.yml`.

| Stage | What it does |
| --- | --- |
| **lint** | hadolint on Dockerfile, shellcheck on all shell scripts |
| **build** | Builds the Docker image and uploads it as an artifact |
| **test** | Downloads the artifact and runs `test/run-all` |
| **scan** | Trivy vulnerability scan at all severity levels |
| **push** | Multi-platform build + push to Docker Hub (tags and `main`/`master` only) |

### Required repository secrets

| Secret | Description |
| --- | --- |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub [access token](https://docs.docker.com/security/for-developers/access-tokens/) |

### Tagging strategy

- Pushes to `main`/`master`: tagged as `edge`
- Version tags (`v1.2.3`): tagged as `1.2.3` and `latest`
