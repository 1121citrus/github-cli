# GitHub CI Workflows

Automated linting, building, testing, security scanning, and Docker image publication for the github-cli wrapper.

## Workflow Overview

| Stage | Trigger | Purpose | Artifacts |
|-------|---------|---------|-----------|
| **Lint** | All branches, PRs | Validate Dockerfile and shell scripts | None |
| **Build** | All branches, PRs | Build and cache Docker image | docker-image artifact |
| **Test** | All branches, PRs | Run integration test suite | None |
| **Scan** | All branches, PRs | Vulnerability scanning with Trivy | None |
| **Push** | main/master branches, version tags | Multi-platform build and push to Docker Hub | Docker Hub image |

## CI Workflow (`ci.yml`)

Single unified workflow handling all CI/CD stages from lint through deployment.

### Trigger Events
- **Push:** main, master branches and `v*` version tags
- **Pull requests:** To main or master branches

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
   - **Tags:**
     - `1121citrus/github-cli:<version>`
     - `1121citrus/github-cli:latest`
   - **Build arguments:** `VERSION`, `GIT_COMMIT`, `BUILD_DATE`
   - **Output:** Loaded into local Docker daemon (`load: true`)

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

3. **Trivy vulnerability scan**
   - **Version:** 0.35.0 (pinned for supply-chain security; update periodically from [trivy-action releases](https://github.com/aquasecurity/trivy-action/releases))
   - **Scope:** CRITICAL, HIGH severity
   - **Output format:** Table
   - **Exit code:** 1 — **blocks push** if fixable HIGH/CRITICAL CVEs found
   - `ignore-unfixed: true` — suppresses CVEs with no available patch

---

## Stage 5: Push to Docker Hub

Builds and publishes multi-platform image to Docker Hub.

### Trigger Condition
- **Events:** `push` only (no PRs)
- **Refs:**
  - `refs/heads/main` or `refs/heads/master`
  - `refs/tags/v*` (semantic version tags)

### Permissions

- `contents: read` (Docker Hub auth uses secrets, not OIDC)

### Steps

1. **Set build metadata**
   - Version logic:
     - Version tag (`refs/tags/v1.2.3`) → `1.2.3`
     - Branch push (main/master) → `edge`

2. **Set up QEMU** — Enables cross-platform compilation (arm64 on amd64 CI runner)

3. **Set up Docker Buildx**

4. **Log in to Docker Hub**
   - Uses secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`

5. **Determine tags**
   - **Version tag pushed:** Tags as `<image>:<version>` AND `<image>:latest`
   - **Branch pushed:** Tags as `<image>:edge` only (keeps `:latest` pointing to released versions)

6. **Build and push (multi-platform)**
   - **Platforms:** `linux/amd64`, `linux/arm64`
   - **Build arguments:** `VERSION`, `GIT_COMMIT`, `BUILD_DATE`
   - **Attestations:**
     - `sbom: true` — SPDX Software Bill of Materials
     - `provenance: mode=max` — SLSA Build Provenance Level 3
   - **Output:** Pushed directly to Docker Hub (no local load)

---

## Configuration Reference

### Required Secrets
- `DOCKERHUB_USERNAME` — Docker Hub account username
- `DOCKERHUB_TOKEN` — Docker Hub authentication token (personal access token recommended)

### Build Arguments (passed to Dockerfile)
- `VERSION` — Semantic version or branch name (e.g., `1.2.3` or `edge`)
- `GIT_COMMIT` — Short git commit hash (7 characters)
- `BUILD_DATE` — ISO 8601 UTC timestamp

### Runner
- **Ubuntu version:** Latest (ubuntu-latest)
- **Docker:** Docker Engine with Buildx plugin

---

## Execution Flow

```
On push to any branch or PR to main/master
    ↓
[Lint Job]
  - Hadolint (Dockerfile)
  - Shellcheck (shell scripts)
  - ✅ Pass → Proceed to Build
  - ❌ Fail → Blocks all downstream

[Build Job] (after Lint)
  - Build image locally
  - Export to artifact
  - Output: artifact "docker-image"

[Test Job] (after Build)
  - Load image from artifact
  - Run test suite
  - ✅ Pass → Proceed to Push gate
  - ❌ Fail → Blocks Push

[Scan Job] (after Build, parallel with Test)
  - Load image from artifact
  - Run Trivy scan (CRITICAL, HIGH only)
  - ✅ No fixable HIGH/CRITICAL → Proceed
  - ❌ Fixable HIGH/CRITICAL found → Blocks Push

[Push Job] (after Test & Scan, conditional)
  - Only on: main/master branch or v* tag push
  - Multi-platform build & push to Docker Hub
  - Tag:
    - Version tag → image:X.Y.Z + image:latest
    - Branch push → image:edge
```

---

## Tagging Strategy

| Event | Image Tag | Stable |
|-------|-----------|--------|
| Push to main/master | `1121citrus/github-cli:edge` | No |
| Push tag `v1.2.3` | `1121citrus/github-cli:1.2.3` + `:latest` | Yes |
| PR or feature branch | Not pushed (test only) | — |

The `edge` tag points to the latest main branch build; `latest` is reserved for released (tagged) versions.

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
