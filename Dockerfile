# syntax=docker/dockerfile:1

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# ALPINE_IMAGE must be declared before FROM to use it in the FROM instruction.
# All other build-time ARGs are declared after FROM (Docker ARG scoping).
#
# Alpine edge is required: stable 3.21 ships github-cli 2.63 / curl 8.14 which
# carry 12 fixable CVEs (2C+10H).  Edge ships github-cli 2.83 / curl 8.19 and
# resolves all OS-level CVEs. Using an edge base image with apk upgrade
# ensures all OS patches are applied.
#
# Sixteen CVEs/advisories remain: fourteen are transitive Go module deps
# compiled into the gh binary; two are transitive Alpine edge package deps.
# Many Go module CVEs are reported under both a CVE ID and a GHSA ID;
# all aliases are suppressed in .grype.yaml.
#
#   CRITICAL CVE-2026-6100   python 3.14.x (binary)               no fix yet
#   MEDIUM   CVE-2025-60876  busybox 1.37.0-r31 (apk)             no fix yet
#   CRITICAL CVE-2026-33186 / GHSA-p77j-4mvh-x3m3
#            google.golang.org/grpc 1.77.0                        fix: 1.79.3
#   HIGH    CVE-2025-15558 / GHSA-p436-gjf2-799p
#            github.com/docker/cli 29.0.3                         fix: 29.2.0
#   HIGH    CVE-2025-66564 / GHSA-4qg8-fj49-pxjh
#            sigstore/timestamp-authority 1.2.9                   fix: 2.0.3
#   HIGH    GHSA-mh2q-q3fh-2475
#            go.opentelemetry.io/otel 1.38.0                      fix: 1.41.0
#   HIGH    CVE-2026-24051 / GHSA-9h8m-3fm2-qjrq
#            go.opentelemetry.io/otel/sdk 1.38.0                  fix: 1.40.0
#   HIGH    CVE-2026-39883 / GHSA-hfvc-g4fc-pqhx
#            go.opentelemetry.io/otel/sdk 1.38.0                  fix: 1.43.0
#   HIGH    CVE-2026-34986 / GHSA-78h2-9frx-2jm8
#            github.com/go-jose/go-jose/v4 4.1.3                  fix: 4.1.4
#   MEDIUM  CVE-2026-23992 / GHSA-846p-jg2w-w324
#            go-tuf/v2 2.3.0                                       fix: 2.3.1
#   MEDIUM  CVE-2026-23991 / GHSA-fphv-w9fq-2525
#            go-tuf/v2 2.3.0                                       fix: 2.3.1
#   MEDIUM  CVE-2026-24686 / GHSA-jqc5-w2xx-5vq4
#            go-tuf/v2 2.3.0                                       fix: 2.4.1
#   MEDIUM  CVE-2026-24117 / GHSA-273p-m2cw-6833
#            sigstore/rekor 1.4.2                                  fix: 1.5.0
#   MEDIUM  CVE-2026-23831 / GHSA-4c4x-jm2x-pf9j
#            sigstore/rekor 1.4.2                                  fix: 1.5.0
#   MEDIUM  CVE-2026-24137 / GHSA-fcv2-xgw5-pqxf
#            sigstore/sigstore 1.9.6                               fix: 1.10.4
#   UNSPECIFIED GHSA-mqqf-5wvp-8fh8
#            go-chi/chi/v5 5.2.3                                   fix: 5.2.4
#
# Go module CVEs exercised only by `gh attestation` commands.
# Tracking: https://github.com/cli/cli (update go.mod deps)
#
# For reproducible production builds, pin to a specific digest:
#   ALPINE_SHA=sha256:<digest> bin/build
ARG ALPINE_IMAGE=alpine:edge

# hadolint ignore=DL3006
FROM ${ALPINE_IMAGE}

# Re-declare ALPINE_IMAGE so it is in scope after FROM.
# ALPINE_VERSION is declared separately so APP_ALPINE_VERSION has a clean value.
# Declare remaining build-time defaults here so they are in scope for ENV/LABEL.
ARG ALPINE_IMAGE
ARG ALPINE_VERSION=edge
ARG AUTHORS='Jim Hanlon «jim@hanlonsoftware.com»'
ARG BUILD_DATE=unknown
ARG GIT_COMMIT=unknown
ARG LICENSE=AGPL-3.0-or-later
ARG VERSION=dev

# Embed in env vars for runtime access
ENV \
    APP_ALPINE_IMAGE="${ALPINE_IMAGE}" \
    APP_ALPINE_VERSION="${ALPINE_VERSION}" \
    APP_AUTHORS="${AUTHORS}" \
    APP_BUILD_DATE="${BUILD_DATE}" \
    APP_COMMIT="${GIT_COMMIT}" \
    APP_LICENSE="${LICENSE}" \
    APP_VERSION="${VERSION}"

# OCI standard labels
LABEL org.opencontainers.image.authors="${AUTHORS}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.documentation="https://github.com/1121citrus/github-cli"
LABEL org.opencontainers.image.licenses="${LICENSE}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"
LABEL org.opencontainers.image.source="https://github.com/1121citrus/github-cli"
LABEL org.opencontainers.image.title="github Command Line Interface"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/1121citrus/github-cli"
LABEL org.opencontainers.image.vendor="1121 Citrus, LTD"

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001

# hadolint ignore=DL3017,DL3018
RUN apk upgrade --no-cache --no-interactive && \
    apk add --no-cache \
        bash \
        git \
        github-cli && \
    adduser \
        --disabled-password --gecos "" --shell "/sbin/nologin" \
        --no-create-home --uid "${UID}" \
        github-cli

# Switch to the non-privileged user to run the application.
USER github-cli

WORKDIR /workspace

ENTRYPOINT ["gh"]
CMD ["--help"]
