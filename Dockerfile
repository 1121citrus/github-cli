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
# resolves all OS-level CVEs.  apk upgrade also upgrades zlib to 1.3.2-r0,
# fixing the 1M+1L CVEs present in the alpine:edge base layer.
#
# Nine CVEs remain; all are transitive Go module deps compiled into the gh
# binary by the Alpine package maintainer and cannot be patched here:
#
#   HIGH    CVE-2025-15558  github.com/docker/cli 29.0.3       fix: 29.2.0
#   HIGH    CVE-2025-66564  sigstore/timestamp-authority 1.2.9 fix: 2.0.3
#   HIGH    CVE-2026-24051  go.opentelemetry.io/otel/sdk 1.38  fix: 1.40.0
#   MEDIUM  CVE-2026-23992  github.com/theupdateframework/go-tuf/v2 2.3.0  fix: 2.3.1
#   MEDIUM  CVE-2026-23991  github.com/theupdateframework/go-tuf/v2 2.3.0  fix: 2.3.1
#   MEDIUM  CVE-2026-24686  github.com/theupdateframework/go-tuf/v2 2.3.0  fix: 2.4.1
#   MEDIUM  CVE-2026-24117  github.com/sigstore/rekor 1.4.2    fix: 1.5.0
#   MEDIUM  CVE-2026-23831  github.com/sigstore/rekor 1.4.2    fix: 1.5.0
#   MEDIUM  CVE-2026-24137  github.com/sigstore/sigstore 1.9.6 fix: 1.10.4
#
# These packages are only exercised by `gh attestation` commands.
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

# hadolint ignore=DL3017,DL3018
RUN apk update \
    && apk upgrade --no-cache \
    && apk add --no-cache \
        bash \
        git \
        github-cli

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
        --disabled-password --gecos "" --shell "/sbin/nologin" \
        --no-create-home --uid "${UID}" \
        github-cli

# Switch to the non-privileged user to run the application.
USER github-cli

WORKDIR /workspace

ENTRYPOINT ["gh"]
CMD ["--help"]
