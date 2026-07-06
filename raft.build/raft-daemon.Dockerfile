# syntax=docker/dockerfile:1.24.0@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

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
ARG ver_raft_daemon
RUN pnpm setup \
    && pnpm add -g "@botiverse/raft-daemon@${ver_raft_daemon}"
ENTRYPOINT [ "raft-daemon" ]
ENV RAFT_SERVER_URL='https://api.raft.build'
CMD [ "--server-url", "$RAFT_SERVER_URL", "--api-key", "$RAFT_API_KEY" ]
