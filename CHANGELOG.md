# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.7](https://github.com/1121citrus/github-cli/compare/v1.0.6...v1.0.7) (2026-04-18)


### Bug Fixes

* **changelog:** remove extra blank line to resolve MD012 lint error ([f00d3e6](https://github.com/1121citrus/github-cli/commit/f00d3e6ba5a98fc418791b6926d4b7c9c47157b6))
* **changelog:** remove markdownlint spacing issue ([c1e1e97](https://github.com/1121citrus/github-cli/commit/c1e1e97962bf9ea5353aa9c7ffaaac2390b68e22))
* **lint:** resolve markdown and shellcheck linting errors ([d5fbc07](https://github.com/1121citrus/github-cli/commit/d5fbc075e1149642666fc16997cdfa01659fa46f))
* **security:** suppress grype CRITICAL/HIGH; register two new CVEs ([715d285](https://github.com/1121citrus/github-cli/commit/715d2855a150e30e07f3fe202ccf9fecbb362a2c))

## [1.0.6](https://github.com/1121citrus/github-cli/compare/v1.0.5...v1.0.6) (2026-04-17)

### Bug Fixes

* **changelog:** remove markdownlint spacing issue ([c1e1e97](https://github.com/1121citrus/github-cli/commit/c1e1e97962bf9ea5353aa9c7ffaaac2390b68e22))
* **lint:** resolve markdown and shellcheck linting errors ([d5fbc07](https://github.com/1121citrus/github-cli/commit/d5fbc075e1149642666fc16997cdfa01659fa46f))
* **security:** suppress grype CRITICAL/HIGH; register two new CVEs ([715d285](https://github.com/1121citrus/github-cli/commit/715d2855a150e30e07f3fe202ccf9fecbb362a2c))

## [Unreleased]

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

- [Unreleased](https://github.com/1121citrus/github-cli/compare/v1.0.7...HEAD)
- [1.0.7](https://github.com/1121citrus/github-cli/compare/v1.0.6...v1.0.7)
- [1.0.6](https://github.com/1121citrus/github-cli/compare/v1.0.5...v1.0.6)
- [1.0.5](https://github.com/1121citrus/github-cli/compare/v1.0.4...v1.0.5)
- [1.0.4](https://github.com/1121citrus/github-cli/compare/v1.0.3...v1.0.4)
- [1.0.3](https://github.com/1121citrus/github-cli/compare/v1.0.2...v1.0.3)
- [1.0.2](https://github.com/1121citrus/github-cli/compare/v1.0.1...v1.0.2)
- [1.0.1](https://github.com/1121citrus/github-cli/compare/v1.0.0...v1.0.1)
- [1.0.0](https://github.com/1121citrus/github-cli/releases/tag/v1.0.0)
