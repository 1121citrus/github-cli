# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.6](https://github.com/1121citrus/github-cli/compare/v1.0.5...v1.0.6) (2026-04-17)

### Bug Fixes

* **changelog:** remove markdownlint spacing issue ([c1e1e97](https://github.com/1121citrus/github-cli/commit/c1e1e97962bf9ea5353aa9c7ffaaac2390b68e22))
* **lint:** resolve markdown and shellcheck linting errors ([d5fbc07](https://github.com/1121citrus/github-cli/commit/d5fbc075e1149642666fc16997cdfa01659fa46f))
* **security:** suppress grype CRITICAL/HIGH; register two new CVEs ([715d285](https://github.com/1121citrus/github-cli/commit/715d2855a150e30e07f3fe202ccf9fecbb362a2c))

## [Unreleased]

## [1.1.2] - 2026-05-04

### Security

- `.grype.yaml`: add GHSA advisory aliases for all existing Go module CVEs;
  Grype reports each vulnerability under both its CVE ID and GHSA ID
  simultaneously and the ignore list must cover both.
- `.grype.yaml`: add GHSA-mh2q-q3fh-2475 (High) for the base
  `go.opentelemetry.io/otel` module (separate from the `/sdk` submodule).
- `.grype.yaml`: add CVE-2026-6100 ignore entry; Python 3.14.x is a transitive
  Alpine edge package dependency and cannot be removed from the image.
- `.grype.yaml`: add CVE-2025-60876 (Medium) for `busybox`/`busybox-binsh`/
  `ssl_client`; no fix available in Alpine edge; `apk upgrade` will install
  it automatically when Alpine ships a patch.
- `Dockerfile`: update CVE comment block to sixteen total unfixable CVEs;
  include GHSA aliases alongside existing CVE IDs.
- `SECURITY.md`: update count and table to reflect all new GHSA aliases,
  `otel` base module, and `busybox` entries.

### Changed

- `build`: regenerate with gitleaks Stage 5e advisement and tool version
  bumps (Grype v0.87.0→v0.112.0, Hadolint v2.12.0→v2.14.0,
  Shellcheck v0.10.0→v0.11.0, Trivy 0.62.1→0.70.0).

## [1.1.1] - 2026-04-30

### Changed

- `build`: regenerate from template — fix `test/run-all` path, improve staging
  `SYNOPSIS` formatting, and tighten argument validation.
- `build`: add leading docstrings to all generated helper functions.
- `build`: regenerate with Phase 2 test/staging integration.
- `build`: add `--tag IMAGE:dev-latest` handling for local development builds.
- `build`: regenerate to sync provenance SHA.
- `test/run-all`: replace hand-written version with generator-managed version.

### Added

- `test/07-build-scan-regressions.bats`: regression tests covering the full
  build and scan fix history for `github-cli`.

### Fixed

- `ci.yml`: pin shared-github-workflows ref to `@v1` for reproducible CI.

## [1.1.0] - 2026-04-20

### Security

- `.grype.yaml`: expand Grype ignore list to cover all unfixed Go module CVEs
  compiled into the `gh` binary (`grpc`, `go-jose`, `go-tuf/v2`,
  `sigstore/*`, and others); set `fail-on-severity: high` so only
  Critical/High findings are gating.

### Changed

- `build`: regenerate Phase 3 script — Grype and Scout are now gating scans;
  Dive remains advisory only (Stage 5c).
- `build`: fix watchdog exit-143 race by using
  `wait "${_watcher}" 2>/dev/null || true`.
- `test/01-build.bats`: update test expectations to match gating/advisory
  split (Scout is gating, not advisory).

### Added

- `CLAUDE.md`: document PR merge prohibition — all fixes must go through
  local `dev` branch QA before pushing to `origin`.

## [1.0.9] - 2026-04-17

### Security

- `.grype.yaml`: add ignore rules for three HIGH CVEs now reported by Grype
  under their GHSA aliases (`GHSA-p436-gjf2-799p` for `docker/cli`,
  `GHSA-4qg8-fj49-pxjh` for `sigstore/timestamp-authority`,
  `GHSA-9h8m-3fm2-qjrq` for `go.opentelemetry.io/otel/sdk`).
- `.grype.yaml`: register two new HIGH CVEs (`CVE-2026-39883` for
  `go.opentelemetry.io/otel/sdk 1.38.0`, fix: 1.43.0; `CVE-2026-34986` for
  `github.com/go-jose/go-jose/v4 4.1.3`, fix: 4.1.4).
- `Dockerfile`: update unfixable CVE count comment from 11 to 13.
- `SECURITY.md`: add `CVE-2026-39883` and `CVE-2026-34986` to the unfixable
  CVE table; add GHSA aliases to existing HIGH rows; note that Grype ignores
  are tracked in `.grype.yaml`.
- `build`: mount and pass `--config /.grype.yaml` to Grype when the file is
  present.

## [1.0.8] - 2026-04-16

### Fixed

- `build`: expand shellcheck coverage to include the `build` script itself
  and the Bats test suite; set `-S warning` threshold to suppress info-level
  noise.
- `build`, `test/05-shell-functions.bats`: resolve shellcheck SC2034
  (unused variable) warnings by tightening environment variable scoping in
  the test file.
- `CHANGELOG.md`: remove empty `Added` blocks that caused MD012
  (multiple consecutive blank lines) markdownlint errors.

## [1.0.7] - 2026-04-06

### Changed

- Update GitHub Actions dependencies for `actions/checkout` and `actions/download-artifact`.
- Clean up changelog formatting after the automated release update.

## [1.0.6] - 2026-04-06

### Changed

- Update documentation to source `src/github` directly from GitHub in the usage examples.

## [1.0.5](https://github.com/1121citrus/github-cli/compare/v1.0.4...v1.0.5) (2026-04-06)

### Bug Fixes

* build script syntax and unbound variable errors ([ae0f48d](https://github.com/1121citrus/github-cli/commit/ae0f48d7d13eccae70d9d86a090cecee9f1db14f))
* move source to src/, fix coverage path normalization, expand unit tests ([46968fe](https://github.com/1121citrus/github-cli/commit/46968fe2b2f58f5b687efee21a4a3c8cdf5a00b3))
* unify test environment and add missing test suite ([5b264ac](https://github.com/1121citrus/github-cli/commit/5b264ac5f08510f68adf90fd27dccff3405884fe))

## [1.0.4] - 2025-03-25

### Added
## [1.0.3] - 2026-03-22

### Added

- Extend the developer `build` tool with Docker Scout support and optional `dive` guidance for image inspection.

## [1.0.2] - 2026-03-22

### Changed

- Align the local `build` process with the CI pipeline so local validation matches automated release checks.
- Address code review feedback across the codebase, documentation, and test coverage setup.

### Fixed

- Remove the stale `bin/build` reference from CI shellcheck handling.

## [1.0.1] - 2026-03-18

### Added

- Add `CI-WORKFLOWS.md` to document the standardized CI process.

### Changed

- Update the GitHub Actions workflow to follow the standard repository pattern.

## [1.0.0] - 2026-03-17

### Added

- Initial release of the Dockerized GitHub CLI wrapper, including the `build` tool, shell helper library, CI workflow, and Bats-based test suite.
- Project documentation and security guidance for containerized use and development

## Change Details

- [Unreleased](https://github.com/1121citrus/github-cli/compare/v1.1.2...HEAD)
- [1.1.2](https://github.com/1121citrus/github-cli/compare/v1.1.1...v1.1.2)
- [1.1.1](https://github.com/1121citrus/github-cli/compare/v1.1.0...v1.1.1)
- [1.1.0](https://github.com/1121citrus/github-cli/compare/v1.0.9...v1.1.0)
- [1.0.9](https://github.com/1121citrus/github-cli/compare/v1.0.8...v1.0.9)
- [1.0.8](https://github.com/1121citrus/github-cli/compare/v1.0.7...v1.0.8)
- [1.0.7](https://github.com/1121citrus/github-cli/compare/v1.0.6...v1.0.7)
- [1.0.6](https://github.com/1121citrus/github-cli/compare/v1.0.5...v1.0.6)
- [1.0.5](https://github.com/1121citrus/github-cli/compare/v1.0.4...v1.0.5)
- [1.0.4](https://github.com/1121citrus/github-cli/compare/v1.0.3...v1.0.4)
- [1.0.3](https://github.com/1121citrus/github-cli/compare/v1.0.2...v1.0.3)
- [1.0.2](https://github.com/1121citrus/github-cli/compare/v1.0.1...v1.0.2)
- [1.0.1](https://github.com/1121citrus/github-cli/compare/v1.0.0...v1.0.1)
- [1.0.0](https://github.com/1121citrus/github-cli/releases/tag/v1.0.0)
