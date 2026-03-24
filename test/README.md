# test — github-cli test suite

Tests for `1121citrus/github-cli`.  The `build` script runs the automated
suite inside Docker.  The `shell-functions` test is host-side only and does
not require a built image.

## Running

```sh
# Via the build script (recommended):
./build

# Test only (skip lint and scan):
./build --no-lint --no-scan

# All tests against an already-built image:
./test/run-all

# Shell-function tests only (no Docker image needed):
./test/shell-functions
```

## Automated test files

| File | Requires image | What it tests |
| --- | --- | --- |
| `run-all` | Yes | Runner — executes all image-dependent tests |
| `image-structure` | Yes | Non-root user, `WORKDIR`, installed binaries, nologin shell |
| `gh-invocation` | Yes | Entrypoint, `gh --version`, `gh help`, unknown-command handling |
| `env-metadata` | Yes | `APP_*` env vars and OCI image labels |
| `shell-functions` | No | `include/github` argument passing, PAT injection, TTY detection |
| `build-options` | No | `build` script flag parsing without running a real Docker build |

## Test stubs (`test/bin/`)

The `shell-functions` test uses a `docker` stub so it can exercise the
`include/github` wrapper logic without actually starting a container.  The
stub is scoped to that single test and does not affect other tests.
