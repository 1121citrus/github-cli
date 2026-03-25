# GitHub CI Workflows

Automated linting, building, testing, security scanning, and Docker image publication for the github-cli wrapper.

## Workflow Overview

| Stage | Trigger | Purpose | Artifacts |
|-------|---------|---------|-----------|
| **Lint** | All branches, PRs | Validate Dockerfile and shell scripts | None |
| **Build** | All branches, PRs | Build and cache Docker image | docker-image artifact |
| **Test** | All branches, PRs | Run integration test suite | None |
| **Scan** | All branches, PRs | Vulnerability scanning with Trivy | None |
| **Push** | Version tags and staging branch only | Multi-platform build and push to Docker Hub | Docker Hub image |
| **Dependabot** | Weekly (Monday 06:00 UTC) | Keep GitHub Actions versions current | None |

## CI Workflow (`ci.yml`)

Single unified workflow handling all CI/CD stages from lint through deployment.

### Trigger Events
- **Push:** `main`, `master`, `staging` branches and `v*` version tags
- **Pull requests:** To `main` or `master` branches

### Concurrency

- **Group:** `<workflow-name>-<ref>` — one concurrent run per workflow + branch/tag
- **Branches and PRs:** Cancel any in-progress run when a newer one starts
- **Version tags:** Never cancelled — release builds always complete

### Global Configuration
- **Image name:** `1121citrus/github-cli`
- **Node.js:** v24 (via `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24`)
- **Permissions:** Minimal—only `contents: read` by default; individual jobs request additional permissions as needed

---

## Stage 1: Lint

Validates Dockerfile and shell scripts before building.

### Steps

1. **Checkout Code** — Clones repository

2. **Lint Dockerfile with hadolint**
   - Uses hadolint v3.1.0
   - Checks for best practices and anti-patterns
   - Fails if any violations found

3. **Lint shell scripts with shellcheck**
   - Checks: `include/github`, `bin/build`, all `test/*` scripts
   - Enables dependency resolution (`-x` flag)
   - Validates syntax and common errors
   - **Note:** Explicitly lists files to handle glob negations correctly (e.g., excludes test/bin scripts that fail glob patterns)

---

## Stage 2: Build

Builds the Docker image locally and exports it for downstream jobs.

### Steps

1. **Set build metadata**
   - Extracts version from git ref:
     - `refs/tags/v1.2.3` → version `1.2.3`
     - `refs/heads/main` → version extracted from GITHUB_REF_NAME
   - Captures short commit hash and UTC build timestamp
   - Exports as outputs for downstream use

2. **Set up Docker Buildx** — Enables advanced Docker build features

3. **Build image**
   - **Tag:** `1121citrus/github-cli:latest` (version string embedded via build-args, not the local tag)
   - **Build arguments:** `VERSION`, `GIT_COMMIT`, `BUILD_DATE`
   - **Output:** Loaded into local Docker daemon (`load: true`)
   - **Layer cache:** `cache-from: type=gha` / `cache-to: type=gha,mode=max`

4. **Save image for downstream jobs**
   - Exports image to `/tmp/image.tar.gz` (gzip-compressed Docker image tarball)
   - Enables test and scan jobs to run against the exact same image without rebuilding

5. **Upload image artifact**
   - Stores image as GitHub Actions artifact
   - 1-day retention (sufficient for workflow duration)

**Artifact Name:** `docker-image`

---

## Stage 3: Test

Runs integration test suite against the built image.

### Steps

1. **Download image artifact** — Retrieves `/tmp/image.tar.gz`

2. **Load image** — Restores image into Docker daemon

3. **Run test suite**
   - Executes `./test/run-all`
   - Full integration testing against the containerized application
   - Blocks push if tests fail

---

## Stage 4: Security Scan

Scans built image for known vulnerabilities.

### Steps

1. **Download image artifact**

2. **Load image**

3. **Cache Trivy vulnerability DB**
   - `~/.cache/trivy` is cached between runs with `actions/cache`; the
     vulnerability DB is only re-downloaded when the cache is cold or the DB
     has been updated

4. **Trivy vulnerability scan**
   - **Version:** 0.35.0 (pinned for supply-chain security; update periodically from [trivy-action releases](https://github.com/aquasecurity/trivy-action/releases))
   - **Scope:** CRITICAL, HIGH severity
   - **Output format:** Table
   - **Exit code:** 1 — **blocks push** if fixable HIGH/CRITICAL CVEs found
   - `ignore-unfixed: true` — suppresses CVEs with no available patch
   - `TRIVY_NO_PROGRESS=true` suppresses progress bars; `TRIVY_QUIET=true`
     suppresses `INFO [vulndb]` log lines during DB download

---

## Stage 5: Push to Docker Hub

Builds and publishes multi-platform image to Docker Hub.

### Trigger Condition
- **Events:** `push` only (no PRs)
- **Refs:**
  - `refs/tags/v*` (semantic version tags)
  - `refs/heads/staging`

### Tagging

| Trigger           | Docker Hub tags                                                     |
| ----------------- | ------------------------------------------------------------------- |
| Tag `v1.2.3`      | `1121citrus/github-cli:1.2.3` + `:latest`                           |
| Push to `staging` | `1121citrus/github-cli:staging-<timestamp>` + `:staging`            |

`:latest` is set **only** on version-tagged releases. Staging gets a datetime timestamp
for traceability.

### Permissions

- `contents: read` (Docker Hub auth uses secrets, not OIDC)

### Steps

1. **Compute tags and build metadata**
   - Version logic:
     - Version tag (`refs/tags/v1.2.3`) → version `1.2.3`, tags `image:1.2.3` + `image:latest`
     - Staging push → version `staging-<timestamp>`, tags `image:staging-<timestamp>` + `image:staging`
   - Captures short commit hash and UTC build timestamp

2. **Set up QEMU** — Enables cross-platform compilation (arm64 on amd64 CI runner)

3. **Set up Docker Buildx**

4. **Log in to Docker Hub**
   - Uses secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`

5. **Build and push (multi-platform)**
   - **Platforms:** `linux/amd64`, `linux/arm64`
   - **Build arguments:** `VERSION`, `GIT_COMMIT`, `BUILD_DATE`
   - **Attestations:** `sbom: true` + `provenance: mode=max` (SLSA L3)
   - **Layer cache:** `cache-from: type=gha` / `cache-to: type=gha,mode=max`
   - **Output:** Pushed directly to Docker Hub (no local load)

---

## Configuration Reference

### Required Secrets
- `DOCKERHUB_USERNAME` — Docker Hub account username
- `DOCKERHUB_TOKEN` — Docker Hub authentication token (personal access token recommended)

### Build Arguments (passed to Dockerfile)
- `VERSION` — Semantic version or staging timestamp (e.g., `1.2.3` or `staging-2026.03.25.134500`)
- `GIT_COMMIT` — Short git commit hash (7 characters)
- `BUILD_DATE` — ISO 8601 UTC timestamp

### Runner
- **Ubuntu version:** Latest (ubuntu-latest)
- **Docker:** Docker Engine with Buildx plugin

---

## Execution Flow

```
On push/PR
    ↓
[Lint] — hadolint + shellcheck + markdownlint
    ↓
[Build] — single-arch image → artifact
    ↓ (parallel)
[Test]                        [Scan]
 - load artifact               - load artifact
 - run test/run-all            - Trivy CRITICAL/HIGH
 - ✅/❌                        - ✅/❌ blocks push

[Push] (tags and staging only, after Test + Scan pass)
 - QEMU + Buildx multi-arch
 - push amd64 + arm64
 - SBOM + provenance
```

---

---

## Monitoring and Troubleshooting

### Lint Failures
- **Hadolint issues:** Review Dockerfile for best-practice violations
- **Shellcheck issues:** Check shell script syntax in `include/`, `bin/`, `test/`
- Common fixes: Quote variables, escape special characters, use `set -e`

### Build Failures
- Check Dockerfile `FROM` image availability
- Verify build arguments are defined in Dockerfile with `ARG` directives
- Look for network timeouts during `apt-get` or package installation

### Test Failures
- Examine `test/run-all` output for specific failures
- Verify test fixtures and mock data are present
- Check environment variables passed to container

### Push Failures
- Verify Docker Hub secrets are configured correctly
- Check if `DOCKERHUB_TOKEN` has `read` and `write` permissions
- Ensure repository visibility allows push

### Multi-platform Build Hangs
- QEMU emulation of arm64 on amd64 can be slow
- Check GitHub Actions logs for progress
- Consider using a self-hosted runner with native arm64 support

---

## Related Files
- `Dockerfile` — Container build definition
- `test/run-all` — Integration test suite
- `include/github` — Shell function library
- `build` — Primary local build script (lint → build → test → scan → push)
- `bin/build` — Legacy build script (env-var interface; supports `ALPINE_SHA` digest pinning)

## Automated dependency updates

`dependabot.yml` configures weekly automated PRs to keep GitHub Actions current.

- **Schedule:** Every Monday at 06:00 UTC
- **Scope:** GitHub Actions (`package-ecosystem: github-actions`) — updates action pins in
  `.github/workflows/*.yml`
- **Labels:** `dependencies`, `github-actions`
- **Security benefit:** Dependabot also proposes SHA-pinned digests (recommended for SLSA /
  OpenSSF Scorecard hardening)

---

## Local Workflow Parity

- `./build` supports `--advice` (alias for `--advise`) and `--cache` for one-run scanner cache controls.
