# syntax=docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

# renovate: datasource=node-version packageName=node
ARG NODE_VERSION=24.18.0
# renovate: datasource=github-releases packageName=pnpm/pnpm
ARG PNPM_VERSION=11.10.0
# renovate: datasource=npm packageName=@openai/codex
ARG CODEX_VERSION=0.143.0
# renovate: datasource=npm packageName=@jackwener/opencli
ARG OPENCLI_VERSION=1.8.6
# renovate: datasource=npm packageName=opencode-ai
ARG OPENCODE_VERSION=1.17.15
# renovate: datasource=npm packageName=@botiverse/raft
ARG RAFT_CLI_VERSION=0.0.16
# renovate: datasource=npm packageName=@botiverse/raft-daemon
ARG RAFT_DAEMON_VERSION=0.72.0
# renovate: datasource=github packageName=google-antigravity/antigravity-cli
ARG ANTIGRAVITY_CLI_VERSION=1.0.16

FROM icecodexi/python:debian-nonroot@sha256:e5e1284e0664e199d2b91e73196c15bd8c450cc52ccc66ebe3f5b2667c21274e AS secure-mirrors
COPY --link <<npm <<pip <<uv /

registry=https://npm.flatt.tech/
npm

[global]
index-url = https://pypi.flatt.tech/simple/
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
        build-essential musl \
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

ENV  NPM_CONFIG_REGISTRY=https://npm.flatt.tech/ \
    PNPM_CONFIG_REGISTRY=https://npm.flatt.tech/ \
           PIP_INDEX_URL=https://pypi.flatt.tech/simple/ \
        UV_DEFAULT_INDEX=https://pypi.flatt.tech/simple/ \
                 GOPROXY=https://golang.flatt.tech
COPY --link --from=secure-mirrors --chown=65532:65532 /secure-mirrors/ /


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

FROM pnpm AS opencli
ARG OPENCLI_VERSION
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    --mount=type=cache,id=pnpm-store,target=/home/nonroot/.local/share/pnpm/store,uid=65532,gid=65532 \
    --mount=type=cache,id=sigstore-cache,target=/home/nonroot/.cache/sigstore-rust,uid=65532,gid=65532 \
    mise use -g "npm:@jackwener/opencli@${OPENCLI_VERSION}" \
    && rm -rf /empty/* \
    && mkdir -p /empty/home/nonroot/.local/share/mise/installs /empty/home/nonroot/.local/share/pnpm \
    && mv "${HOME}/.local/share/mise/installs/npm-jackwener-opencli" /empty/home/nonroot/.local/share/mise/installs/ \
    && cp -a "${PNPM_CONFIG_STORE_DIR}" /empty/home/nonroot/.local/share/pnpm/store

FROM pnpm AS opencode
ARG ANTIGRAVITY_CLI_VERSION
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    mise use -g "opencode@${OPENCODE_VERSION}" \
    && rm -rf /empty/* \
    && mkdir -p /empty/home/nonroot/.local/share/mise/installs \
    && mv "${HOME}/.local/share/mise/installs/opencode" /empty/home/nonroot/.local/share/mise/installs/

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

FROM pnpm AS antigravity-cli
ARG ANTIGRAVITY_CLI_VERSION
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    mise use -g "antigravity-cli@${ANTIGRAVITY_CLI_VERSION}" \
    && rm -rf /empty/* \
    && mkdir -p /empty/home/nonroot/.local/share/mise/installs \
    && mv "${HOME}/.local/share/mise/installs/antigravity-cli" /empty/home/nonroot/.local/share/mise/installs/

FROM pnpm
ARG CODEX_VERSION
ARG OPENCLI_VERSION
ARG OPENCODE_VERSION
ARG RAFT_CLI_VERSION
ARG RAFT_DAEMON_VERSION
ARG ANTIGRAVITY_CLI_VERSION
COPY --link --from=codex --chown=65532:65532 /empty/ /
COPY --link --from=opencli --chown=65532:65532 /empty/ /
COPY --link --from=opencode --chown=65532:65532 /empty/ /
COPY --link --from=raft-cli --chown=65532:65532 /empty/ /
COPY --link --from=raft-daemon --chown=65532:65532 /empty/ /
COPY --link --from=antigravity-cli --chown=65532:65532 /empty/ /
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    <<EOF
set -euo pipefail
cat >> "${HOME}/.config/mise/config.toml" <<CONFIG
antigravity-cli = "${ANTIGRAVITY_CLI_VERSION}"
ast-grep = "latest"
gh = "latest"
opencode = "latest"
shellcheck = "latest"
tree-sitter = "latest"

"github:aptible/supercronic" = "latest"

"npm:@openai/codex" = "${CODEX_VERSION}"
"npm:@jackwener/opencli" = "${OPENCLI_VERSION}"
"npm:@botiverse/raft" = "${RAFT_CLI_VERSION}"
"npm:@botiverse/raft-daemon" = "${RAFT_DAEMON_VERSION}"
CONFIG
mise install && mise reshim
EOF

COPY --link --from=ghcr.io/astral-sh/ruff:0.15.20@sha256:03cc33c3f7f31ba53040fb1f1b8744a03a777033650f543d689d1ed98298f14b /ruff /usr/local/bin/
COPY --link --from=ghcr.io/astral-sh/ty:0.0.57@sha256:44b21aba6b4050cf5145794319cc5740c89d26df91a0db974e5fe3f80fdd5281 /ty /usr/local/bin/
COPY --link --from=ghcr.io/astral-sh/uv:0.11.28@sha256:0f36cb9361a3346885ca3677e3767016687b5a170c1a6b88465ec14aefec90aa /uv /uvx /usr/local/bin/
COPY --link --from=mikefarah/yq:4.53.3@sha256:11a1f0b604b13dbbdc662260d8db6f644b22d8553122a25c1b5b2e8713ca6977 /usr/bin/yq /usr/local/bin/
COPY --link --from=ghcr.io/j178/prek:v0.4.8@sha256:923fe4fde30504a5043a590e8dc175d0dc270a3311d14aec44994ad4fd4a088e /prek /usr/local/bin/
COPY --link --chmod=755 entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "catatonit", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
