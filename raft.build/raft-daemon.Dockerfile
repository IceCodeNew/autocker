# syntax=docker/dockerfile:1.25.0@sha256:0adf442eae370b6087e08edc7c50b552d80ddf261576f4ebd6421006b2461f12

# renovate: datasource=npm packageName=@botiverse/raft
ARG RAFT_CLI_VERSION=0.0.15
# renovate: datasource=npm packageName=@botiverse/raft-daemon
ARG RAFT_DAEMON_VERSION=0.70.2
# renovate: datasource=npm packageName=@openai/codex
ARG CODEX_VERSION=0.142.5

FROM icecodexi/python:debian-nonroot@sha256:21101b4a4d5d7c9f98ca56141661be2312613e074f8c77eeb241d3897eb40786 AS secure-mirrors
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

FROM icecodexi/python:debian-nonroot@sha256:21101b4a4d5d7c9f98ca56141661be2312613e074f8c77eeb241d3897eb40786 AS node
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV HOME=/home/nonroot
COPY --link --chown=65532:65532 <<EOF "${HOME}/.config/mise/config.toml"
[settings]
[settings.npm]
package_manager = "pnpm"
EOF
USER root:root
RUN extrepo enable mise \
    && install_packages libatomic1 mise

USER nonroot:nonroot
ENV PNPM_HOME="${HOME}/.local/share/pnpm"
ENV PATH="${HOME}/.local/share/mise/shims:${PNPM_HOME}/bin:${PATH}" \
    SHELL=bash
RUN mise use -g node@24.18.0 pnpm@11.10.0

ENV  NPM_CONFIG_REGISTRY=https://npm.flatt.tech/ \
    PNPM_CONFIG_REGISTRY=https://npm.flatt.tech/ \
           PIP_INDEX_URL=https://pypi.flatt.tech/simple/ \
        UV_DEFAULT_INDEX=https://pypi.flatt.tech/simple/ \
                 GOPROXY=https://golang.flatt.tech
COPY --link --from=secure-mirrors --chown=65532:65532 /secure-mirrors/ /


FROM node
ARG RAFT_CLI_VERSION
ARG RAFT_DAEMON_VERSION
ARG CODEX_VERSION
RUN mise use -g \
    "npm:@botiverse/raft@${RAFT_CLI_VERSION}" \
    "npm:@botiverse/raft-daemon@${RAFT_DAEMON_VERSION}" \
    "npm:@openai/codex@${CODEX_VERSION}"
ENTRYPOINT [ "raft-daemon" ]
