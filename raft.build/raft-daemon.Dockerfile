# syntax=docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

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


FROM icecodexi/python:debian-nonroot@sha256:e5e1284e0664e199d2b91e73196c15bd8c450cc52ccc66ebe3f5b2667c21274e AS mise
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root:root
RUN extrepo enable mise \
    && install_packages \
        libatomic1 mise \
        build-essential musl \
        curl \
        git \
        jq \
        openssh-client \
        ripgrep
ENV HOME=/home/nonroot
RUN mkdir -p \
    "/empty/${HOME}/.local/share/" \
    "${HOME}/.cache" "${HOME}/.config/mise" "${HOME}/.local/share/mise" "${HOME}/.local/state/mise" \
    && chown -R 65532:65532 "${HOME}" /empty/

USER nonroot:nonroot
ENV PNPM_HOME="${HOME}/.local/share/pnpm"
ENV PNPM_CONFIG_STORE_DIR="${PNPM_HOME}/store"
ENV PATH="${HOME}/.local/share/mise/shims:${PNPM_HOME}/bin:${PATH}" \
    SHELL=bash


FROM mise AS cache
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
RUN --mount=type=cache,id=mise-cache,target=/home/nonroot/.cache/mise,uid=65532,gid=65532 \
    --mount=type=cache,id=mise-downloads-cache,target=/home/nonroot/.local/share/mise/downloads,uid=65532,gid=65532 \
    --mount=type=cache,id=npm-cache,target=/home/nonroot/.npm,uid=65532,gid=65532 \
    --mount=type=cache,id=pnpm-store,target=/home/nonroot/.local/share/pnpm/store,uid=65532,gid=65532 \
    --mount=type=cache,id=sigstore-cache,target=/home/nonroot/.cache/sigstore-rust,uid=65532,gid=65532 \
    <<EOF
set -euo pipefail
mise use -g \
    node@${NODE_VERSION} pnpm@${PNPM_VERSION} \
    antigravity-cli@${ANTIGRAVITY_CLI_VERSION} \
    ast-grep gh opencode shellcheck tree-sitter \
    "github:aptible/supercronic"
cat >> "${HOME}/.config/mise/config.toml" <<CONFIG

[settings]
[settings.npm]
package_manager = "pnpm"
CONFIG

mise use -g \
    "npm:@openai/codex"@${CODEX_VERSION} \
    "npm:@jackwener/opencli"@${OPENCLI_VERSION} \
    "npm:@botiverse/raft"@${RAFT_CLI_VERSION} \
    "npm:@botiverse/raft-daemon"@${RAFT_DAEMON_VERSION}
mise reshim

cp -a "${HOME}/.local/share/mise" "${HOME}/.local/share/pnpm" \
    "/empty/${HOME}/.local/share/"
rm -rf "${HOME}/.cache/pnpm"
EOF


FROM scratch AS assets
COPY --link --from=cache /home/nonroot/ /home/nonroot/
COPY --link --from=cache /empty/ /


FROM mise AS final
COPY --link --from=ghcr.io/astral-sh/ruff:0.15.20@sha256:03cc33c3f7f31ba53040fb1f1b8744a03a777033650f543d689d1ed98298f14b /ruff /usr/local/bin/
COPY --link --from=ghcr.io/astral-sh/ty:0.0.57@sha256:44b21aba6b4050cf5145794319cc5740c89d26df91a0db974e5fe3f80fdd5281 /ty /usr/local/bin/
COPY --link --from=ghcr.io/astral-sh/uv:0.11.28@sha256:0f36cb9361a3346885ca3677e3767016687b5a170c1a6b88465ec14aefec90aa /uv /uvx /usr/local/bin/
COPY --link --from=mikefarah/yq:4.53.3@sha256:11a1f0b604b13dbbdc662260d8db6f644b22d8553122a25c1b5b2e8713ca6977 /usr/bin/yq /usr/local/bin/
COPY --link --from=ghcr.io/j178/prek:v0.4.8@sha256:923fe4fde30504a5043a590e8dc175d0dc270a3311d14aec44994ad4fd4a088e /prek /usr/local/bin/
COPY --link --from=assets --chown=65532:65532 /home/nonroot/ /home/nonroot/
COPY --link --chmod=755 entrypoint.sh /
ENTRYPOINT [ "catatonit", "-g", "--", "/entrypoint.sh" ]
