# syntax=docker/dockerfile:1.24.0@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

FROM ghcr.io/pnpm/pnpm:11.10.0@sha256:9a6eb06d5f861d830fe27d85a91415e60527fa45ec45b52ee43c92a8aaf3bf8a AS node
RUN pnpm runtime set node 24.18.0 -g

FROM node
ARG ver_raft_daemon
RUN pnpm add -g "@botiverse/raft-daemon@${ver_raft_daemon}"
ENTRYPOINT [ "/pnpm/bin/raft-daemon" ]
ENV RAFT_SERVER_URL='https://api.raft.build'
CMD [ "--server-url", "$RAFT_SERVER_URL", "--api-key", "$RAFT_API_KEY" ]
