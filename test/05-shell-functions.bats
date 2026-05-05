#!/usr/bin/env bats
# test/05-shell-functions.bats — test src/github shell functions.
#
# Sources src/github and verifies argument construction without actually
# running Docker (docker is stubbed via test/bin/docker).
#
# Copyright (C) 2026 James Hanlon [mailto:jim@hanlonsoftware.com]
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
    WHEREAMI="${BATS_TEST_DIRNAME}"
    ROOT="$(cd "${WHEREAMI}/.." && pwd)"
    chmod +x "${WHEREAMI}/bin/"* 2>/dev/null || true
    export WHEREAMI ROOT
}

# Helper: source src/github with the docker stub on PATH, then invoke
# github(). Captures the docker command line emitted by the stub.
_run_github_fn() {
    (
        export PATH="${WHEREAMI}/bin:${PATH}"
        # shellcheck source=../src/github
        source "${ROOT}/src/github"
        github "$@"
    )
}

@test "basic invocation passes args to docker" {
    local output
    output=$(_run_github_fn repo list)
    echo "output: ${output}"
    [[ "${output}" == *"repo"* ]]
    [[ "${output}" == *"list"* ]]
}

@test "GH_CONFIG_DIR is set" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"GH_CONFIG_DIR=/gh-config"* ]]
}

@test "XDG_CACHE_HOME is set" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"XDG_CACHE_HOME=/gh-cache"* ]]
}

@test "workspace volume is mounted" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"/workspace"* ]]
}

@test "gh-config volume is mounted" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"/gh-config"* ]]
}

@test "gh-cache volume is mounted" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"/gh-cache"* ]]
}

@test "gh-config is not mounted read-only" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" != *":ro"* ]]
}

@test "GH_TOKEN absent when GITHUB_PAT is unset" {
    unset GITHUB_PAT 2>/dev/null || true
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" != *"GH_TOKEN"* ]]
}

@test "GH_TOKEN passed when GITHUB_PAT is set" {
    local output
    output=$(GITHUB_PAT="ghp_test123" _run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"GH_TOKEN=ghp_test123"* ]]
}

@test "--user flag is present" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"--user"* ]]
}

@test "no -t flag in non-interactive mode" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" != *" -t "* ]]
}

@test "GITHUB_PAT_FILE is read for GH_TOKEN" {
    local tmpfile
    tmpfile=$(mktemp)
    echo "ghp_fromfile" > "${tmpfile}"
    unset GITHUB_PAT 2>/dev/null || true
    local output
    output=$(GITHUB_PAT_FILE="${tmpfile}" _run_github_fn --version)
    rm -f "${tmpfile}"
    echo "output: ${output}"
    [[ "${output}" == *"GH_TOKEN=ghp_fromfile"* ]]
}

@test "GITHUB_USERNAME_FILE is read for GH_TOKEN" {
    local tmpfile_pat tmpfile_user
    tmpfile_pat=$(mktemp)
    tmpfile_user=$(mktemp)
    echo "ghp_fromfile" > "${tmpfile_pat}"
    echo "fileuser" > "${tmpfile_user}"
    unset GITHUB_PAT GITHUB_USERNAME 2>/dev/null || true
    local output
    output=$(GITHUB_PAT_FILE="${tmpfile_pat}" GITHUB_USERNAME_FILE="${tmpfile_user}" _run_github_fn --version)
    rm -f "${tmpfile_pat}" "${tmpfile_user}"
    echo "output: ${output}"
    [[ "${output}" == *"GH_TOKEN=ghp_fromfile"* ]]
}

@test "missing GITHUB_PAT_FILE returns error" {
    unset GITHUB_PAT 2>/dev/null || true
    local output
    output=$(GITHUB_PAT_FILE="/nonexistent/path" _run_github_fn --version 2>&1) && {
        echo "expected non-zero exit"
        false
    }
    echo "output: ${output}"
    [[ "${output}" == *"cannot read GITHUB_PAT_FILE"* ]]
}

@test "missing GITHUB_USERNAME_FILE returns error" {
    unset GITHUB_PAT GITHUB_USERNAME 2>/dev/null || true
    local output
    output=$(GITHUB_USERNAME_FILE="/nonexistent/path" _run_github_fn --version 2>&1) && {
        echo "expected non-zero exit"
        false
    }
    echo "output: ${output}"
    [[ "${output}" == *"cannot read GITHUB_USERNAME_FILE"* ]]
}

@test "direct GITHUB_PAT takes precedence over GITHUB_PAT_FILE" {
    local tmpfile
    tmpfile=$(mktemp)
    echo "ghp_fromfile" > "${tmpfile}"
    local output
    output=$(GITHUB_PAT="ghp_direct" GITHUB_PAT_FILE="${tmpfile}" _run_github_fn --version)
    rm -f "${tmpfile}"
    echo "output: ${output}"
    [[ "${output}" == *"GH_TOKEN=ghp_direct"* ]]
    [[ "${output}" != *"ghp_fromfile"* ]]
}

@test "image tag is 1121citrus/github-cli:latest" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"1121citrus/github-cli:latest"* ]]
}

@test "gh() alias produces identical output to github()" {
    local out_github out_gh
    out_github=$(_run_github_fn --version)
    out_gh=$(
        export PATH="${WHEREAMI}/bin:${PATH}"
        # shellcheck source=../src/github
        source "${ROOT}/src/github"
        gh --version
    )
    echo "github output: ${out_github}"
    echo "    gh output: ${out_gh}"
    [ "${out_github}" = "${out_gh}" ]
}

@test "--cap-drop ALL is present" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"--cap-drop ALL"* ]]
}

@test "--security-opt no-new-privileges is present" {
    local output
    output=$(_run_github_fn --version)
    echo "output: ${output}"
    [[ "${output}" == *"no-new-privileges:true"* ]]
}

@test "empty GITHUB_PAT_FILE returns error" {
    local tmpfile output
    tmpfile=$(mktemp)
    # empty file — _read_secret_file returns 1 for empty value
    unset GITHUB_PAT 2>/dev/null || true
    output=$(GITHUB_PAT_FILE="${tmpfile}" _run_github_fn --version 2>&1) && {
        echo "expected non-zero exit"
        false
    }
    rm -f "${tmpfile}"
    echo "output: ${output}"
    [[ "${output}" == *"cannot read GITHUB_PAT_FILE"* ]]
}

@test "empty GITHUB_USERNAME_FILE returns error" {
    local tmpfile_pat tmpfile_user output
    tmpfile_pat=$(mktemp)
    tmpfile_user=$(mktemp)
    echo "ghp_test" > "${tmpfile_pat}"
    # leave tmpfile_user empty — _read_secret_file returns 1 for empty value
    unset GITHUB_PAT GITHUB_USERNAME 2>/dev/null || true
    output=$(GITHUB_PAT_FILE="${tmpfile_pat}" GITHUB_USERNAME_FILE="${tmpfile_user}" _run_github_fn --version 2>&1) && {
        echo "expected non-zero exit"
        false
    }
    rm -f "${tmpfile_pat}" "${tmpfile_user}"
    echo "output: ${output}"
    [[ "${output}" == *"cannot read GITHUB_USERNAME_FILE"* ]]
}

@test "GITHUB_USERNAME and GITHUB_PAT together export GITHUB_LOGIN" {
    local login
    login=$(
        export PATH="${WHEREAMI}/bin:${PATH}"
        # shellcheck source=../src/github
        source "${ROOT}/src/github"
        GITHUB_PAT="ghp_test" GITHUB_USERNAME="testuser" github --version >/dev/null
        echo "${GITHUB_LOGIN:-}"
    )
    echo "login: ${login}"
    [ "${login}" = "testuser" ]
}

@test "-t flag present when stdin and stdout are terminals" {
    command -v script > /dev/null 2>&1 || skip "script command not available"
    local tmpscript output
    tmpscript=$(mktemp)
    cat > "${tmpscript}" <<EOF
#!/usr/bin/env bash
PATH="${WHEREAMI}/bin:${PATH}"
source "${ROOT}/src/github"
github --version
EOF
    chmod +x "${tmpscript}"
    output=$(script -q -c "${tmpscript}" /dev/null 2>/dev/null | tr -d '\r') || true
    rm -f "${tmpscript}"
    echo "output: ${output}"
    [[ "${output}" == *" -t "* ]]
}
