#!/usr/bin/env bats
# test/02-image-structure.bats — verify image filesystem structure and user config.
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
}

@test "container runs as UID 10001" {
    local output
    output=$(run_image "id -u")
    echo "expected: 10001"
    echo "     got: ${output}"
    [ "${output}" = "10001" ]
}

@test "container user is github-cli" {
    local output
    output=$(run_image "whoami")
    echo "expected: github-cli"
    echo "     got: ${output}"
    [ "${output}" = "github-cli" ]
}

@test "WORKDIR is /workspace" {
    local output
    output=$(run_image "pwd")
    echo "expected: /workspace"
    echo "     got: ${output}"
    [ "${output}" = "/workspace" ]
}

@test "gh binary is installed" {
    run docker run --rm --entrypoint /bin/sh "${IMAGE}" -c "command -v gh"
    [ "$status" -eq 0 ]
}

@test "git binary is installed" {
    run docker run --rm --entrypoint /bin/sh "${IMAGE}" -c "command -v git"
    [ "$status" -eq 0 ]
}

@test "bash binary is installed" {
    run docker run --rm --entrypoint /bin/sh "${IMAGE}" -c "command -v bash"
    [ "$status" -eq 0 ]
}

@test "github-cli user shell is /sbin/nologin" {
    local output
    output=$(run_image "grep github-cli /etc/passwd | cut -d: -f7")
    echo "expected: /sbin/nologin"
    echo "     got: ${output}"
    [ "${output}" = "/sbin/nologin" ]
}

@test "no home directory for github-cli user" {
    run docker run --rm --entrypoint /bin/sh "${IMAGE}" -c "test ! -d /home/github-cli"
    [ "$status" -eq 0 ]
}
