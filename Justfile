# Justfile for Docker container operations
# This file provides convenience commands for managing Docker containers

# Define variables for repeated values
CONTAINER := "code-workspace"
COMPOSE_CMD := "docker compose -f compose.workspace.yaml"

# Start all containers in detached mode with environment files
# Builds images if needed and runs in the background
up:
    {{COMPOSE_CMD}} up -d

# Execute an interactive bash shell in the workspace container
# Allows you to run commands directly inside the container
shell:
    {{COMPOSE_CMD}} exec -it {{CONTAINER}} /bin/bash

# Open Neovim editor in the workspace container
# Launches the editor with the current directory mounted
vim:
    {{COMPOSE_CMD}} exec -it {{CONTAINER}} nvim .

# Stop and remove all containers using environment files
# Terminates all running containers in the compose project
down:
    {{COMPOSE_CMD}} down
