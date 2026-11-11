Pre-built binaries for use in the (Linux) dev containers.

# dttop

cd ~/git/dttop && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o ~/dev/devcontainers/bin/dttop .
