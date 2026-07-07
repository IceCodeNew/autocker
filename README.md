```shell
#!/bin/sh
set -eu

mkdir -p \
    "${HOME}/.agents/" \
    "${HOME}/.codex/" \
    "${HOME}/.local/share/opencode/"
    "${HOME}/.opencode/" \
    "${HOME}/.pi/“ \
    "${HOME}/.slock/"
chown -R 65532:65532 \
    "${HOME}/.agents/" \
    "${HOME}/.codex/" \
    "${HOME}/.local/share/opencode/"
    "${HOME}/.opencode/" \
    "${HOME}/.pi/“ \
    "${HOME}/.slock/"

export 'RAFT_SERVER_URL=https://api.raft.build'
export 'RAFT_API_KEY=xxxxxx'
export 'RAFT_DAEMON_IMAGE=icecodexi/raft-daemon:0.70.3'

docker pull "$RAFT_DAEMON_IMAGE"
docker rm -f raft-daemon
docker run --name raft-daemon --detach \
    --volume /etc/localtime:/etc/localtime:ro \
    --volume "${HOME}/.agents/:/home/nonroot/.agents/" \
    --volume "${HOME}/.codex/:/home/nonroot/.codex/" \
    --volume "${HOME}/.local/share/opencode/:/home/nonroot/.local/share/opencode/" \
    --volume "${HOME}/.opencode/:/home/nonroot/.opencode/" \
    --volume "${HOME}/.pi/:/home/nonroot/.pi/" \
    --volume "${HOME}/.slock/:/home/nonroot/.slock/" \
    --env 'TZ=Asia/Shanghai' \
    --security-opt no-new-privileges \
    --restart unless-stopped \
    "$RAFT_DAEMON_IMAGE" \
    --server-url "$RAFT_SERVER_URL" --api-key "$RAFT_API_KEY"
```
