Pre-built binaries for use in the (Linux) dev containers.

Set-up steps to be run from within a container:

# bun

curl -fsSL -o /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-aarch64.zip && unzip -p /tmp/bun.zip bun-linux-aarch64/bun > ~/dev/devcontainers/bin/bun && chmod +x ~/dev/devcontainers/bin/bun && rm /tmp/bun.zip

# dttop

cd ~/git/dttop && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ~/dev/devcontainers/bin/dttop .

# pixi

curl -fsSL -o ~/dev/devcontainers/bin/pixi https://github.com/prefix-dev/pixi/releases/latest/download/pixi-aarch64-unknown-linux-musl && chmod +x ~/dev/devcontainers/bin/pixi
