# GitHub CI workflows

Automated linting, building, testing, security scanning, and Docker image publication
for the github-cli wrapper.

## Workflow overview

| Stage | Trigger | Purpose |
| ----- | ------- | ------- |
| **Lint** | All pushes, PRs to main/master, tags | Validate Dockerfile and shell scripts |
| **Build** | After lint | Build image (with embedded metadata) and share as artifact |
| **Test** | After build (parallel with scan) | Run integration test suite |
| **Scan** | After build (parallel with test) | Trivy image scan — blocks push on fixable CVEs |
| **Push** | Version tags and staging branch only | Multi-platform build and push to Docker Hub |
| **Dependabot** | Weekly (Monday 06:00 UTC) | Keep GitHub Actions versions current |
| **Release Please** | Push to main/master | Open release PR; create tag and GitHub Release |

## CI workflow (`ci.yml`)

Lint, Build, Scan, and Push delegate to shared reusable workflows in
[1121citrus/shared-github-workflows](https://github.com/1121citrus/shared-github-workflows).
The Test job is defined inline because it is specific to this repo.

### Global configuration

- **Image name:** `1121citrus/github-cli`
- **Build metadata:** `inject-metadata: true` — `VERSION`, `GIT_COMMIT`, and `BUILD_DATE`
  are injected as build-args so test suites can verify them at runtime

### Trigger events

- **Push:** `main`, `master`, `staging` branches and `v*` version tags
- **Pull requests:** To `main` or `master` branches

### Concurrency

- **Group:** `<workflow-name>-<ref>` — one concurrent run per workflow + branch/tag
- **Branches and PRs:** Cancel any in-progress run when a newer one starts
- **Version tags:** Never cancelled — release builds always complete

### Versioning

Tag-driven. Push a git tag to publish a release:

```bash
git tag v1.2.3
git push origin v1.2.3
# Publishes: 1121citrus/github-cli:1.2.3 + :1.2 + :1 + :latest
```

---

## Stage 1: Lint

Shared workflow: `lint.yml` — runs Hadolint, ShellCheck, and markdownlint-cli.

---

## Stage 2: Build

Shared workflow: `build.yml` with `inject-metadata: true` — builds image once,
injects `VERSION`/`GIT_COMMIT`/`BUILD_DATE` as build-args, and exports it as
the `docker-image` artifact. Re-tagged as `:latest`. Artifact retention: 1 day.

---

## Stage 3: Test

Inline job. Downloads the artifact, loads the image, and runs the bats suite
in a `bats/bats:1.13.0` container with the Docker socket mounted:

- `test/01-build.bats` — image build assertions
- `test/02-image-structure.bats` — file layout and permissions
- `test/03-gh-invocation.bats` — `gh` command invocation
- `test/04-env-metadata.bats` — `VERSION`, `GIT_COMMIT`, `BUILD_DATE` env vars
- `test/05-shell-functions.bats` — shell helper functions
- `test/06-image-metadata.bats` — OCI label verification

---

## Stage 4: Security scan

Shared workflow: `scan.yml` — Trivy CRITICAL/HIGH scan of the built image
before it is pushed. Fails and blocks push on any fixable CVE.

---

## Stage 5: Push to Docker Hub

Shared workflow: `push.yml` — runs only on version tags and the staging branch.

### Tagging

| Trigger | Docker Hub tags |
| ------- | --------------- |
| Tag `v1.2.3` | `1121citrus/github-cli:1.2.3` + `:1.2` + `:1` + `:latest` |
| Push to `staging` | `1121citrus/github-cli:staging-<sha>` + `:staging` |

### Build configuration

- **Platforms:** `linux/amd64`, `linux/arm64`
- **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)

---

## Execution flow

```text
On push/PR
    ↓
[Lint] — shared: hadolint + shellcheck + markdownlint
    ↓
[Build] — shared: single-arch image (+ metadata) → artifact
    ↓ (parallel)
[Test]                        [Scan]
 - load artifact               - shared: Trivy CRITICAL/HIGH
 - bats in bats:1.13.0         - ✅/❌ blocks push
 - ✅/❌

[Push] (tags and staging only, after Test + Scan pass)
 - shared: QEMU + Buildx multi-arch
 - push amd64 + arm64
 - SBOM + provenance
```

---

## Configuration reference

### Required secrets

- `DOCKERHUB_USERNAME` — Docker Hub account
- `DOCKERHUB_TOKEN` — Docker Hub access token

### Key files

- `Dockerfile` — container build definition
- `include/github` — shell functions (`gh` / `github`)
- `test/` — bats test suites

## Automated dependency updates

`dependabot.yml` configures weekly automated PRs to keep GitHub Actions current.

---

## Automated releases (release-please)

`release-please.yml` delegates to the shared `release-please.yml` workflow.

### Configuration

- `release-please-config.json` — release type (`simple`) and package root
- `.release-please-manifest.json` — current version
- `version.txt` — plain-text version file
- `CHANGELOG.md` — generated/updated by release-please
