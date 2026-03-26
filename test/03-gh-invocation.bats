#!/usr/bin/env bats
# test/03-gh-invocation.bats — verify gh CLI invocation and version output.
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    IMAGE="${IMAGE:-1121citrus/github-cli:latest}"
    export IMAGE
}

@test "gh --version produces expected output" {
    local output
    output=$(docker run --rm "${IMAGE}" --version 2>&1)
    echo "output: ${output}"
    [[ "${output}" == *"gh version"* ]]
}

@test "gh help produces usage information" {
    local output
    output=$(docker run --rm "${IMAGE}" help 2>&1)
    echo "output: ${output}"
    [[ "${output}" == *"USAGE"* || "${output}" == *"usage"* || \
       "${output}" == *"Available commands"* || "${output}" == *"CORE COMMANDS"* ]]
}

@test "gh exits non-zero for unknown command" {
    run docker run --rm "${IMAGE}" this-command-does-not-exist
    [ "$status" -ne 0 ]
}

@test "ENTRYPOINT is [\"gh\"]" {
    local output
    output=$(docker inspect --format '{{json .Config.Entrypoint}}' "${IMAGE}" 2>&1)
    echo "expected: [\"gh\"]"
    echo "     got: ${output}"
    [ "${output}" = '["gh"]' ]
}
