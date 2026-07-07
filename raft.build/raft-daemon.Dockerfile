# syntax=docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

# renovate: datasource=node-version packageName=node
ARG NODE_VERSION=24.18.0
# renovate: datasource=github-releases packageName=pnpm/pnpm
ARG PNPM_VERSION=11.10.0
# renovate: datasource=npm packageName=@botiverse/raft
ARG RAFT_CLI_VERSION=0.0.15
# renovate: datasource=npm packageName=@botiverse/raft-daemon
ARG RAFT_DAEMON_VERSION=0.70.2
# renovate: datasource=npm packageName=@openai/codex
ARG CODEX_VERSION=0.142.5

FROM icecodexi/python:debian-nonroot@sha256:e5e1284e0664e199d2b91e73196c15bd8c450cc52ccc66ebe3f5b2667c21274e AS secure-mirrors
COPY --link <<npm <<pip <<uv /

registry=https://npm.flatt.tech/
npm

[global]
index-url = https://token:tg_xxxxxx@pypi.flatt.tech/simple/
pip

[[index]]
url = "https://pypi.flatt.tech/simple/"
default = true
uv

USER root:root
ENV HOME=/home/nonroot
RUN mkdir -p \
    "/secure-mirrors/${HOME}/.config/pnpm/" \
    "/secure-mirrors/${HOME}/.config/pip/" \
    "/secure-mirrors/${HOME}/.config/uv" \
    && cp -f /npm "/secure-mirrors/${HOME}/.npmrc" \
    && cp -f /npm "/secure-mirrors/${HOME}/.config/pnpm/auth.ini" \
    && cp -f /pip "/secure-mirrors/${HOME}/.config/pip/pip.conf" \
    && cp -f /uv  "/secure-mirrors/${HOME}/.config/uv/uv.toml"

FROM icecodexi/python:debian-nonroot@sha256:e5e1284e0664e199d2b91e73196c15bd8c450cc52ccc66ebe3f5b2667c21274e AS pnpm
ARG NODE_VERSION
ARG PNPM_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV HOME=/home/nonroot
COPY --link --chown=65532:65532 <<EOF "${HOME}/.config/mise/config.toml"
[settings]
[settings.npm]
package_manager = "pnpm"

[tools]
node = "${NODE_VERSION}"
pnpm = "${PNPM_VERSION}"
EOF
USER root:root
RUN extrepo enable mise \
    && install_packages \
        libatomic1 mise \
        build-essential \
        curl \
        git \
        jq \
        openssh-client \
        ripgrep \
    && mkdir -p "${HOME}/.cache" "${HOME}/.local/share/mise" "${HOME}/.local/state/mise" /empty/home/nonroot/.local/share \
    && chown -R 65532:65532 "${HOME}" /empty

USER nonroot:nonroot
ENV PNPM_HOME="${HOME}/.local/share/pnpm"
ENV PNPM_CONFIG_STORE_DIR="${PNPM_HOME}/store"
ENV PATH="${HOME}/.local/share/mise/shims:${PNPM_HOME}/bin:${PATH}" \
    SHELL=bash
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    --mount=type=cache,id=sigstore-cache,target=/home/nonroot/.cache/sigstore-rust,uid=65532,gid=65532 \
    mise install && mise reshim

COPY --link --from=ghcr.io/astral-sh/uv:0.11.27 /uv /uvx /usr/local/bin/
ENV  NPM_CONFIG_REGISTRY=https://npm.flatt.tech/ \
    PNPM_CONFIG_REGISTRY=https://npm.flatt.tech/ \
           PIP_INDEX_URL=https://pypi.flatt.tech/simple/ \
        UV_DEFAULT_INDEX=https://pypi.flatt.tech/simple/ \
                 GOPROXY=https://golang.flatt.tech
COPY --link --from=secure-mirrors --chown=65532:65532 /secure-mirrors/ /


FROM pnpm AS raft-cli
ARG RAFT_CLI_VERSION
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    --mount=type=cache,id=pnpm-store,target=/home/nonroot/.local/share/pnpm/store,uid=65532,gid=65532 \
    --mount=type=cache,id=sigstore-cache,target=/home/nonroot/.cache/sigstore-rust,uid=65532,gid=65532 \
    mise use -g "npm:@botiverse/raft@${RAFT_CLI_VERSION}" \
    && rm -rf /empty/* \
    && mkdir -p /empty/home/nonroot/.local/share/mise/installs /empty/home/nonroot/.local/share/pnpm \
    && mv "${HOME}/.local/share/mise/installs/npm-botiverse-raft" /empty/home/nonroot/.local/share/mise/installs/ \
    && cp -a "${PNPM_CONFIG_STORE_DIR}" /empty/home/nonroot/.local/share/pnpm/store

FROM pnpm AS raft-daemon
ARG RAFT_DAEMON_VERSION
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    --mount=type=cache,id=pnpm-store,target=/home/nonroot/.local/share/pnpm/store,uid=65532,gid=65532 \
    --mount=type=cache,id=sigstore-cache,target=/home/nonroot/.cache/sigstore-rust,uid=65532,gid=65532 \
    mise use -g "npm:@botiverse/raft-daemon@${RAFT_DAEMON_VERSION}" \
    && rm -rf /empty/* \
    && mkdir -p /empty/home/nonroot/.local/share/mise/installs /empty/home/nonroot/.local/share/pnpm \
    && mv "${HOME}/.local/share/mise/installs/npm-botiverse-raft-daemon" /empty/home/nonroot/.local/share/mise/installs/ \
    && cp -a "${PNPM_CONFIG_STORE_DIR}" /empty/home/nonroot/.local/share/pnpm/store

FROM pnpm AS codex
ARG CODEX_VERSION
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    --mount=type=cache,id=pnpm-store,target=/home/nonroot/.local/share/pnpm/store,uid=65532,gid=65532 \
    --mount=type=cache,id=sigstore-cache,target=/home/nonroot/.cache/sigstore-rust,uid=65532,gid=65532 \
    mise use -g "npm:@openai/codex@${CODEX_VERSION}" \
    && rm -rf /empty/* \
    && mkdir -p /empty/home/nonroot/.local/share/mise/installs /empty/home/nonroot/.local/share/pnpm \
    && mv "${HOME}/.local/share/mise/installs/npm-openai-codex" /empty/home/nonroot/.local/share/mise/installs/ \
    && cp -a "${PNPM_CONFIG_STORE_DIR}" /empty/home/nonroot/.local/share/pnpm/store

FROM pnpm
ARG NODE_VERSION
ARG PNPM_VERSION
ARG RAFT_CLI_VERSION
ARG CODEX_VERSION
ARG RAFT_DAEMON_VERSION
COPY --link --from=raft-cli --chown=65532:65532 /empty/ /
COPY --link --from=raft-daemon --chown=65532:65532 /empty/ /
COPY --link --from=codex --chown=65532:65532 /empty/ /
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    <<EOF
set -euo pipefail
cat >> "${HOME}/.config/mise/config.toml" <<CONFIG

"npm:@botiverse/raft" = "${RAFT_CLI_VERSION}"
"npm:@botiverse/raft-daemon" = "${RAFT_DAEMON_VERSION}"
"npm:@openai/codex" = "${CODEX_VERSION}"
CONFIG
mise reshim
EOF
ENTRYPOINT [ "raft-daemon" ]
