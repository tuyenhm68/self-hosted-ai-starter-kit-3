#!/bin/bash

# update-services.sh - Script to update all services to their latest versions
# Based on the self-hosted-ai-starter-kit

# Exit on error
set -e

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
echo "- n8n: https://n8n.$BASE_DOMAIN"
echo "- Open WebUI: https://openwebui.$BASE_DOMAIN"
echo "- Flowise: https://flowise.$BASE_DOMAIN"
echo "- Supabase: https://supabase.$BASE_DOMAIN"
echo "- Ollama: https://ollama.$BASE_DOMAIN"
echo ""
echo "If you've configured domains in the .env file, your services will be available at those domains."
echo ""
