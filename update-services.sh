#!/bin/bash

# update-services.sh - Script to update all services to their latest versions
# Based on the self-hosted-ai-starter-kit

# Exit on error
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    # Use a safer way to load environment variables that ignores comments and handles special characters
    set -a
    source .env
    set +a
fi

echo "=== Updating Services ==="
echo "Choose your GPU profile:"
echo "1) NVIDIA GPU"
echo "2) AMD GPU (Linux only)"
echo "3) CPU only (no GPU acceleration)"
echo "4) No Ollama in Docker"

read -p "Enter your choice (1-4): " gpu_choice

case $gpu_choice in
    1)
        profile="gpu-nvidia"
        ;;
    2)
        profile="gpu-amd"
        ;;
    3)
        profile="cpu"
        ;;
    4)
        profile="none"
        ;;
    *)
        echo "Invalid choice. Defaulting to CPU profile..."
        profile="cpu"
        ;;
esac

echo "Step 1: Stopping all services with profile: $profile"
docker compose -p localai --profile $profile -f docker-compose.yml -f supabase/docker/docker-compose.yml down

echo "Step 2: Pulling latest versions of all containers"
docker compose -p localai --profile $profile -f docker-compose.yml -f supabase/docker/docker-compose.yml pull

echo "Step 3: Starting services again with profile: $profile"
python3 start_services.py --profile $profile

echo ""
echo "=== Services Updated and Started ==="
echo ""
echo "Services should now be available at:"

# Check if domain variables are set, otherwise use localhost with ports
if [ -n "$N8N_HOSTNAME" ]; then
    echo "- n8n: https://$N8N_HOSTNAME"
else
    echo "- n8n: http://localhost:5678"
fi

if [ -n "$WEBUI_HOSTNAME" ]; then
    echo "- Open WebUI: https://$WEBUI_HOSTNAME"
else
    echo "- Open WebUI: http://localhost:3000"
fi

if [ -n "$FLOWISE_HOSTNAME" ]; then
    echo "- Flowise: https://$FLOWISE_HOSTNAME"
else
    echo "- Flowise: http://localhost:3001"
fi

if [ -n "$SUPABASE_HOSTNAME" ]; then
    echo "- Supabase: https://$SUPABASE_HOSTNAME"
else
    echo "- Supabase: http://localhost:8000"
fi

if [ -n "$OLLAMA_HOSTNAME" ]; then
    echo "- Ollama: https://$OLLAMA_HOSTNAME"
else
    echo "- Ollama: http://localhost:11434"
fi

if [ -n "$PORTAINER_HOSTNAME" ]; then
    echo "- Portainer: https://$PORTAINER_HOSTNAME"
else
    echo "- Portainer: http://localhost:9001"
fi

echo ""
echo "If you've configured domains in the .env file, your services will be available at those domains."
echo ""
