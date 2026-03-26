#!/usr/bin/env bats
# test/04-env-metadata.bats — verify build-time metadata is embedded correctly.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    IMAGE="${IMAGE:-1121citrus/github-cli:latest}"
    export IMAGE

    run_image() {
        docker run --rm --entrypoint /bin/sh "${IMAGE}" -c "$1" 2>&1
    }
    export -f run_image

    inspect_label() {
        docker inspect --format "{{index .Config.Labels \"$1\"}}" "${IMAGE}" 2>&1
    }
    export -f inspect_label
}

@test "APP_VERSION env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_VERSION")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "APP_COMMIT env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_COMMIT")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "APP_BUILD_DATE env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_BUILD_DATE")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "APP_LICENSE env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_LICENSE")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "APP_AUTHORS env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_AUTHORS")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "APP_ALPINE_VERSION env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_ALPINE_VERSION")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "APP_ALPINE_IMAGE env var is set and non-empty" {
    local output
    output=$(run_image "printenv APP_ALPINE_IMAGE")
    echo "got: ${output}"
    [ -n "${output}" ]
}

@test "org.opencontainers.image.authors label is set" {
    local output
    output=$(inspect_label "org.opencontainers.image.authors")
    echo "got: ${output}"
    [ -n "${output}" ] && [ "${output}" != "<no value>" ]
}

@test "org.opencontainers.image.source label is set" {
    local output
    output=$(inspect_label "org.opencontainers.image.source")
    echo "got: ${output}"
    [ -n "${output}" ] && [ "${output}" != "<no value>" ]
}

@test "org.opencontainers.image.licenses label is set" {
    local output
    output=$(inspect_label "org.opencontainers.image.licenses")
    echo "got: ${output}"
    [ -n "${output}" ] && [ "${output}" != "<no value>" ]
}

@test "org.opencontainers.image.title label is set" {
    local output
    output=$(inspect_label "org.opencontainers.image.title")
    echo "got: ${output}"
    [ -n "${output}" ] && [ "${output}" != "<no value>" ]
}

@test "org.opencontainers.image.documentation label is set" {
    local output
    output=$(inspect_label "org.opencontainers.image.documentation")
    echo "got: ${output}"
    [ -n "${output}" ] && [ "${output}" != "<no value>" ]
}

@test "APP_LICENSE is AGPL-3.0-or-later" {
    local output
    output=$(run_image "printenv APP_LICENSE")
    echo "expected: AGPL-3.0-or-later"
    echo "     got: ${output}"
    [ "${output}" = "AGPL-3.0-or-later" ]
}
