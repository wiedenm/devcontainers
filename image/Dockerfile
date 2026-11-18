FROM mcr.microsoft.com/devcontainers/go:1.26

# Claude Code's native install lives in the claude-code volume shared by all containers (see devcontainer.json). Docker
# seeds a new volume from the image, so lay it out here, with the paths the installer and auto-updater use linked to it.
# The same goes for the pixi-cache volume.
RUN mkdir -p /opt/claude-code/bin /opt/claude-code/share /opt/claude-code/state /opt/claude-code/cache \
        /home/vscode/.local/share /home/vscode/.local/state /home/vscode/.cache/rattler \
    && ln -s /opt/claude-code/bin /home/vscode/.local/bin \
    && ln -s /opt/claude-code/share /home/vscode/.local/share/claude \
    && ln -s /opt/claude-code/state /home/vscode/.local/state/claude \
    && ln -s /opt/claude-code/cache /home/vscode/.cache/claude \
    && chown -R vscode:vscode /opt/claude-code /home/vscode/.local /home/vscode/.cache
