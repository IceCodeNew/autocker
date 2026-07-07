# Repository Guidelines

## Project Structure & Module Organization

This repository maintains container images and automation. Images may be unrelated, so keep each image isolated in its own build directory.

- `raft.build/raft-daemon.Dockerfile` defines the current `raft-daemon` image.
- `.github/workflows/raft.build.yml` builds and publishes `linux/amd64` and `linux/arm64` images.
- `renovate.json` controls dependency update rules and regex managers for `_VERSION` values.
- `prek.toml` configures formatting, config validation, Dockerfile linting, Actions linting, and secret scanning.

There is no shared source tree or test suite. New images should use a separate `<name>.build/` directory.

## Build, Test, and Development Commands

- `docker buildx build --file raft.build/raft-daemon.Dockerfile raft.build` builds the image locally without pushing it.
- `prek run --all-files` runs all configured hooks from `prek.toml`.
- `docker buildx imagetools inspect <image>:<tag>` inspects a pushed manifest list.

Use BuildKit-compatible Docker tooling; the Dockerfile uses cache mounts and heredoc `COPY`.

## Coding Style & Naming Conventions

Use two-space indentation in JSON and YAML. Keep Dockerfile stages focused and named descriptively, such as `secure-mirrors` and `node`. Version arguments should use uppercase `_VERSION` names with Renovate comments, for example `ARG RAFT_DAEMON_VERSION=...`.

Pin GitHub Actions by full commit SHA and keep readable version comments.

Keep Dockerfiles, workflows, tags, and build contexts named after the image family. `raft.build/` and `.github/workflows/raft.build.yml` should not collect unrelated images.

## Testing Guidelines

There are no unit tests. Validate changes with `prek run --all-files` and a local `docker buildx build`. For dependency changes, confirm Renovate still matches the updated `_VERSION` variable.

## Renovate & Image Isolation

Renovate is the common dependency update mechanism for all images. Add Renovate comments beside every automatically updated dependency. Keep regex managers able to find new image directories without mixing unrelated package names or workflows.

When adding an image, verify that its `_VERSION` variables and workflow environment values are independently matched. Prefer image-specific workflow files, paths, cache scopes, image names, and tags so one image can be updated or rolled back without affecting another.

## Container Dependency Notes

Do not cache-mount runtime install destinations such as `~/.local/share/mise` or `PNPM_HOME` unless the needed runtime files are explicitly copied into the final image. BuildKit cache mounts are discarded from the final image; pnpm-managed `node_modules` may symlink into the store, so any pnpm store used by installed tools must be copied into the final image when those links are retained.

For independent CLI tools, prefer one dependency stage per tool from a shared base. Have each tool stage move runtime files under `/empty/`, then let the final stage `COPY --link /empty/ /`; include the pnpm store there only for pnpm-backed tools. This keeps high-churn tools such as Codex and opencode from invalidating raft layers. Cache disposable data such as `~/.cache/mise`, mise downloads, npm cache, and Sigstore cache. If cache-mounting the pnpm store for build speed, copy the store from the mount into `/empty/` so the final image retains the runtime links.

After changing container build steps, build the image locally and inspect the final artifact before finishing. Analyze image layers with `docker history`, `dive`, or an equivalent tool, and check for avoidable cache/download files, duplicated runtime layers, repeated package stores, and other large unexpected additions.

When new maintenance lessons affect future agent behavior, update this file in the same change.

## Commit & Pull Request Guidelines

Recent commits follow Conventional Commits, such as `feat: install codex`, `fix: regex of customManagers`, and `chore(deps): update all non-major dependencies`. Use the same style.

Keep commits minimal and ordered from low-risk mechanical changes to higher-impact behavior changes. Split unrelated fixes into separate commits, and split PRs the same way when one PR would mix independent image, Renovate, or workflow concerns.

Pull requests should name the affected image directories and include the `prek` or `buildx` validation result.
