# Contributing

## Prerequisites

- Docker with buildx support
- Bash 4.0+ (macOS ships 3.2 — install via [Homebrew](https://brew.sh/): `brew install bash`)
- A GitHub account with `gh auth login` completed (or a `GITHUB_PAT` env var)

## Development Workflow

### Building

The `build` script runs all stages: lint → build → test → scan → push.

```bash
./build              # Local build and test
./build --push       # Push to Docker Hub after successful scan
./build --help       # See all options
```

Individual stages can be skipped:

```bash
./build --no-lint    # Skip hadolint and shellcheck
./build --no-scan    # Skip Trivy (and advisory scans by default)
./build --no-test    # Skip the test suite
```

### Testing

The full suite runs through the build script:

```bash
./build --no-lint --no-scan   # Lint + build + test only
```

Or directly against an already-built image:

```bash
./test/run-all
```

The `shell-functions` test does not require a built image and exercises the
host-side `include/github` shell function:

```bash
./test/shell-functions
```

See `test/README.md` for the full test layout.

### Code Style

All shell scripts must pass:

```bash
shellcheck include/github test/*
hadolint Dockerfile
```

These checks run automatically in Stage 1 of `./build`.

### Advisory Scans

Non-gating Grype, Docker Scout, and Dive scans are available:

```bash
./build --advise              # Default: grype + scout
./build --advise all          # All three: grype, scout, dive
```

### Submitting Changes

1. Branch from `main`.
2. Make your changes.
3. Run `./build` to lint, test, and scan.
4. Submit a pull request targeting `main`.

## Release Process

Releases are tag-driven:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Pushing a version tag triggers GitHub Actions to build a multi-platform image
and push to Docker Hub as `1.2.3` and `latest`.

See `.github/CI-WORKFLOWS.md` for the full CI pipeline description.
