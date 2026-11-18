Pre-built binaries for use in the (Linux) dev containers.

Set-up steps to be run from within a container:

# bun

curl -fsSL -o /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-aarch64.zip && unzip -p /tmp/bun.zip bun-linux-aarch64/bun > ~/dev/devcontainers/bin/bun && chmod +x ~/dev/devcontainers/bin/bun && rm /tmp/bun.zip

# docker-credential-ecr-login

curl -fsSL -o ~/dev/devcontainers/bin/docker-credential-ecr-login https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.13.0/linux-arm64/docker-credential-ecr-login && chmod +x ~/dev/devcontainers/bin/docker-credential-ecr-login

# dttop

cd ~/git/dttop && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ~/dev/devcontainers/bin/dttop .

# pixi

curl -fsSL -o ~/dev/devcontainers/bin/pixi https://github.com/prefix-dev/pixi/releases/latest/download/pixi-aarch64-unknown-linux-musl && chmod +x ~/dev/devcontainers/bin/pixi

# helm

curl -fsSL https://get.helm.sh/helm-v4.3.2-linux-arm64.tar.gz | tar -xzO linux-arm64/helm > ~/dev/devcontainers/bin/helm && chmod +x ~/dev/devcontainers/bin/helm

# mcp-grafana

curl -fsSL https://github.com/grafana/mcp-grafana/releases/latest/download/mcp-grafana_Linux_arm64.tar.gz | tar -xzO mcp-grafana > ~/dev/devcontainers/bin/mcp-grafana && chmod +x ~/dev/devcontainers/bin/mcp-grafana
