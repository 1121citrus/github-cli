# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities by opening a **private** GitHub security
advisory at:

> **Settings → Security → Advisories → New draft security advisory**

Do **not** file a public issue for security bugs.  You will receive a response
within 5 business days.  If a fix is warranted, a patch and a new image will be
released and the advisory will be published once the fix is in production.

---

## Supported Versions

| Tag | Status |
| --- | --- |
| `latest` | Supported (current stable release) |
| `edge` | Best-effort (tracks `main` branch) |
| Older tags | Not supported — upgrade to `latest` |

---

## Known Unfixable CVEs

Nine CVEs are present in every published image.  All are **transitive Go module
dependencies** compiled directly into the `gh` binary by the Alpine package
maintainer.  They cannot be patched at the image level; the fix must come from
the upstream [cli/cli](https://github.com/cli/cli) project updating its
`go.mod`.

All affected packages are only exercised by `gh attestation` sub-commands.
Workloads that do not call `gh attestation` are not exposed.

| Severity | CVE | Package | Fixed in |
| --- | --- | --- | --- |
| HIGH | [CVE-2025-15558](https://www.cve.org/CVERecord?id=CVE-2025-15558) | `docker/cli` 29.0.3 | 29.2.0 |
| HIGH | [CVE-2025-66564](https://www.cve.org/CVERecord?id=CVE-2025-66564) | `sigstore/timestamp-authority` 1.2.9 | 2.0.3 |
| HIGH | [CVE-2026-24051](https://www.cve.org/CVERecord?id=CVE-2026-24051) | `go.opentelemetry.io/otel/sdk` 1.38 | 1.40.0 |
| MEDIUM | [CVE-2026-23992](https://www.cve.org/CVERecord?id=CVE-2026-23992) | `go-tuf/v2` 2.3.0 | 2.3.1 |
| MEDIUM | [CVE-2026-23991](https://www.cve.org/CVERecord?id=CVE-2026-23991) | `go-tuf/v2` 2.3.0 | 2.3.1 |
| MEDIUM | [CVE-2026-24686](https://www.cve.org/CVERecord?id=CVE-2026-24686) | `go-tuf/v2` 2.3.0 | 2.4.1 |
| MEDIUM | [CVE-2026-24117](https://www.cve.org/CVERecord?id=CVE-2026-24117) | `sigstore/rekor` 1.4.2 | 1.5.0 |
| MEDIUM | [CVE-2026-23831](https://www.cve.org/CVERecord?id=CVE-2026-23831) | `sigstore/rekor` 1.4.2 | 1.5.0 |
| MEDIUM | [CVE-2026-24137](https://www.cve.org/CVERecord?id=CVE-2026-24137) | `sigstore/sigstore` 1.9.6 | 1.10.4 |

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
