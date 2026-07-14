```shell
#!/bin/sh
set -eu

mkdir -p \
    "${HOME}/.agents/" \
    "${HOME}/.codex/" \
    "${HOME}/.gemini/" \
    "${HOME}/.pi/" \
    "${HOME}/.slock/" \
    "${HOME}/.config/opencode/" \
    "${HOME}/.local/share/opencode/" \
    "${HOME}/.local/state/opencode/" \
    "${HOME}/.opencode/"
chown -R 65532:65532 \
    "${HOME}/.agents/" \
    "${HOME}/.codex/" \
    "${HOME}/.gemini/" \
    "${HOME}/.pi/" \
    "${HOME}/.slock/" \
    "${HOME}/.config/opencode/" \
    "${HOME}/.local/share/opencode/" \
    "${HOME}/.local/state/opencode/" \
    "${HOME}/.opencode/"

export 'RAFT_SERVER_URL=https://api.raft.build'
export 'RAFT_API_KEY=xxxxxx'
# renovate: datasource=npm packageName=@botiverse/raft-daemon
export RAFT_DAEMON_VERSION=0.72.12
export "RAFT_DAEMON_IMAGE=icecodexi/raft-daemon:${RAFT_DAEMON_VERSION}"

docker pull "$RAFT_DAEMON_IMAGE"
docker rm -f raft-daemon
docker run --name raft-daemon --detach \
    --volume /etc/localtime:/etc/localtime:ro \
    --volume "${HOME}/.agents/:/home/nonroot/.agents/" \
    --volume "${HOME}/.codex/:/home/nonroot/.codex/" \
    --volume "${HOME}/.gemini/:/home/nonroot/.gemini/" \
    --volume "${HOME}/.pi/:/home/nonroot/.pi/" \
    --volume "${HOME}/.slock/:/home/nonroot/.slock/" \
    --volume "${HOME}/.config/opencode/:/home/nonroot/.config/opencode/" \
    --volume "${HOME}/.local/share/opencode/:/home/nonroot/.local/share/opencode/" \
    --volume "${HOME}/.local/state/opencode/:/home/nonroot/.local/state/opencode/" \
    --volume "${HOME}/.opencode/:/home/nonroot/.opencode/" \
    --env "CRONTAB_PATH=/home/nonroot/crontab" \
    --env 'TZ=Asia/Shanghai' \
    --security-opt no-new-privileges \
    --restart unless-stopped \
    "$RAFT_DAEMON_IMAGE" \
    --server-url "$RAFT_SERVER_URL" --api-key "$RAFT_API_KEY"
```
