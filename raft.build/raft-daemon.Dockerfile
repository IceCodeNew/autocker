# syntax=docker/dockerfile:1.24.0@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM icecodexi/python:debian-nonroot@sha256:21101b4a4d5d7c9f98ca56141661be2312613e074f8c77eeb241d3897eb40786 AS node
COPY --link --chown=65532:65532 <<EOF "/home/nonroot/.config/mise/config.toml"
[settings]
[settings.npm]
package_manager = "pnpm"
EOF
USER root:root
RUN extrepo enable mise \
    && install_packages libatomic1 mise

USER nonroot:nonroot
ENV PATH="/home/nonroot/.local/share/mise/shims:${PATH}"
RUN mise use -g node@24.18.0 pnpm@11.10.0

FROM node
ARG ver_raft_daemon
RUN pnpm add -g "@botiverse/raft-daemon@${ver_raft_daemon}"
ENTRYPOINT [ "/pnpm/bin/raft-daemon" ]
ENV RAFT_SERVER_URL='https://api.raft.build'
CMD [ "--server-url", "$RAFT_SERVER_URL", "--api-key", "$RAFT_API_KEY" ]
