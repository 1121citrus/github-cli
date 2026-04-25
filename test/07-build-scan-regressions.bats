#!/usr/bin/env bats
# test/07-build-scan-regressions.bats — regression checks for build/scan fixes.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    BUILD_SCRIPT="${REPO_ROOT}/build"
    GRYPE_CONFIG="${REPO_ROOT}/.grype.yaml"
}

@test "build _timed ignores watcher wait exit under set -e" {
    run grep -F 'wait "${_watcher}" 2>/dev/null || true' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "build requires values for --version --platform and --registry" {
    run grep -F '_require_value "$1" "${2:-}"; VERSION="$2"; shift' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]

    run grep -F '_require_value "$1" "${2:-}"; PLATFORMS="$2"; shift' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]

    run grep -F '_require_value "$1" "${2:-}"; REGISTRY="$2"; shift' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "build prints explicit skip-update messages for trivy and grype" {
    run grep -F 'Trivy DB update skipped (--cache skip-update=trivy)' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]

    run grep -F 'Grype DB update skipped (--cache skip-update=grype)' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test "build uses .grype.yaml config and 600 second grype timeout" {
    run grep -F '_grype_cfg=(--config /.grype.yaml)' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]

    run grep -F '_timed 600 docker run --rm \' "${BUILD_SCRIPT}"
    [ "$status" -eq 0 ]
}

@test ".grype.yaml gates at high severity" {
    run grep -F 'fail-on-severity: "high"' "${GRYPE_CONFIG}"
    [ "$status" -eq 0 ]
}

@test ".grype.yaml tracks grpc CVE from latest scan fix" {
    run grep -F 'CVE-2026-33186' "${GRYPE_CONFIG}"
    [ "$status" -eq 0 ]
}
