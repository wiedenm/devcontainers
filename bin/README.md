Pre-built binaries for use in the (Linux) dev containers.

# dttop

cd ~/git/dttop && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ~/dev/devcontainers/bin/dttop .

# pixi

curl -fsSL -o ~/dev/devcontainers/bin/pixi https://github.com/prefix-dev/pixi/releases/latest/download/pixi-aarch64-unknown-linux-musl && chmod +x ~/dev/devcontainers/bin/pixi
