#!/bin/bash
#
# Simplifies stopping and removing a devcontainer and its Docker-in-Docker volumes without having to look up its name/ID
# and going via the `docker` CLI. To recreate the container but keep its volumes, use rebuild.sh instead.
# Assumes the script's located in <worktree>/.devcontainers.
 
set -euo pipefail
 
container=$(docker ps -a --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1)
 
if [[ -z "$container" ]]; then
  echo "No devcontainer found for $(pwd)" >&2
  exit 1
fi
 
volumes=$(docker inspect -f '{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' "$container" | grep '^dind-' || true)

docker rm -f "$container"
[[ -z "$volumes" ]] || docker volume rm $volumes
