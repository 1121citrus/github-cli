# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities through the [GitHub Security tab](https://github.com/1121citrus/github-cli/security).
Do not open a public GitHub issue for security vulnerabilities.

---

## Supported Versions

| Tag | Status |
| --- | --- |
| `latest` | Supported (current stable release) |
| `edge` | Best-effort (tracks `main` branch) |
| Older tags | Not supported — upgrade to `latest` |

---

## Known Unfixable CVEs

Thirteen CVEs are present in every published image.  All are **transitive Go
module dependencies** compiled directly into the `gh` binary by the Alpine
package maintainer.  They cannot be patched at the image level; the fix must
come from the upstream [cli/cli](https://github.com/cli/cli) project updating
its `go.mod`.

All affected packages are only exercised by `gh attestation` sub-commands.
Workloads that do not call `gh attestation` are not exposed.
Grype ignores are tracked in `.grype.yaml`.

| Severity | CVE / Advisory | Package | Version | Fixed in |
| --- | --- | --- | --- | --- |
| CRITICAL | [CVE-2026-33186](https://www.cve.org/CVERecord?id=CVE-2026-33186) | `google.golang.org/grpc` | 1.77.0 | 1.79.3 |
| HIGH | [CVE-2025-15558](https://www.cve.org/CVERecord?id=CVE-2025-15558) / [GHSA-p436-gjf2-799p](https://github.com/advisories/GHSA-p436-gjf2-799p) | `docker/cli` | 29.0.3 | 29.2.0 |
| HIGH | [CVE-2025-66564](https://www.cve.org/CVERecord?id=CVE-2025-66564) / [GHSA-4qg8-fj49-pxjh](https://github.com/advisories/GHSA-4qg8-fj49-pxjh) | `sigstore/timestamp-authority` | 1.2.9 | 2.0.3 |
| HIGH | [CVE-2026-24051](https://www.cve.org/CVERecord?id=CVE-2026-24051) / [GHSA-9h8m-3fm2-qjrq](https://github.com/advisories/GHSA-9h8m-3fm2-qjrq) | `go.opentelemetry.io/otel/sdk` | 1.38.0 | 1.40.0 |
| HIGH | [CVE-2026-39883](https://www.cve.org/CVERecord?id=CVE-2026-39883) | `go.opentelemetry.io/otel/sdk` | 1.38.0 | 1.43.0 |
| HIGH | [CVE-2026-34986](https://www.cve.org/CVERecord?id=CVE-2026-34986) | `github.com/go-jose/go-jose/v4` | 4.1.3 | 4.1.4 |
| MEDIUM | [CVE-2026-23992](https://www.cve.org/CVERecord?id=CVE-2026-23992) | `go-tuf/v2` | 2.3.0 | 2.3.1 |
| MEDIUM | [CVE-2026-23991](https://www.cve.org/CVERecord?id=CVE-2026-23991) | `go-tuf/v2` | 2.3.0 | 2.3.1 |
| MEDIUM | [CVE-2026-24686](https://www.cve.org/CVERecord?id=CVE-2026-24686) | `go-tuf/v2` | 2.3.0 | 2.4.1 |
| MEDIUM | [CVE-2026-24117](https://www.cve.org/CVERecord?id=CVE-2026-24117) | `sigstore/rekor` | 1.4.2 | 1.5.0 |
| MEDIUM | [CVE-2026-23831](https://www.cve.org/CVERecord?id=CVE-2026-23831) | `sigstore/rekor` | 1.4.2 | 1.5.0 |
| MEDIUM | [CVE-2026-24137](https://www.cve.org/CVERecord?id=CVE-2026-24137) | `sigstore/sigstore` | 1.9.6 | 1.10.4 |
| UNSPECIFIED | [GHSA-mqqf-5wvp-8fh8](https://github.com/advisories/GHSA-mqqf-5wvp-8fh8) | `go-chi/chi/v5` | 5.2.3 | 5.2.4 |

Tracking issue: [cli/cli upstream go.mod update](https://github.com/cli/cli)

---

## Defense-in-Depth Measures

Even with the unfixable CVEs above, the image applies multiple hardening layers:

| Measure | How |
| --- | --- |
| Non-root user | Container runs as UID 10001 (`github-cli`); no login shell, no home dir |
| No privilege escalation | `--security-opt no-new-privileges:true` on every `docker run` |
| All capabilities dropped | `--cap-drop ALL` on every `docker run`; `gh` requires no Linux capabilities |
| Minimal package surface | Only `bash`, `git`, `github-cli` installed; base image upgraded at build time |
| Host UID/GID preserved | `--user $(id -u):$(id -g)` prevents container-to-host ownership mismatch |
| Alpine edge + `apk upgrade` | Resolves all OS-level CVEs present in the base layer |
| Pinned action versions | CI actions pinned to version tags (not `@master`) to reduce supply-chain risk |
| SBOM + provenance | Multi-platform push includes `--sbom=true --provenance=mode=max` |
| Digest pinning (optional) | `ALPINE_SHA=sha256:<digest> bin/build` pins the base image to an immutable layer |

---

## Token Handling

When `GITHUB_PAT` is set, it is passed to the container via `-e GH_TOKEN=...`.
The token is therefore visible in `docker inspect` output on the host while the
container is running.

- **Prefer `gh auth login`** on trusted single-user machines; credentials are
  stored in `~/.config/gh` and mounted into the container.
- **Use `GITHUB_PAT_FILE`** (Docker Compose secrets) when running in automated
  environments where the plain env-var approach is unacceptable.
- **Avoid `GITHUB_PAT`** on shared hosts where other local users can call
  `docker inspect`.
