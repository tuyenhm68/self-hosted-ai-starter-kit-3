#!/bin/bash

# start-services.sh - Script to start n8n and related services
# Based on the self-hosted-ai-starter-kit

# Exit on error
set -e

echo "=== Starting Services ==="
echo "Choose your GPU profile:"
echo "1) NVIDIA GPU"
echo "2) AMD GPU (Linux only)"
echo "3) CPU only (no GPU acceleration)"
echo "4) No Ollama in Docker"

read -p "Enter your choice (1-4): " gpu_choice

case $gpu_choice in
    1)
        echo "Starting services with NVIDIA GPU profile..."
        python3 start_services.py --profile gpu-nvidia
        ;;
    2)
        echo "Starting services with AMD GPU profile..."
        python3 start_services.py --profile gpu-amd
        ;;
    3)
        echo "Starting services with CPU profile..."
        python3 start_services.py --profile cpu
        ;;
    4)
        echo "Starting services without Ollama..."
        python3 start_services.py --profile none
        ;;
    *)
        echo "Invalid choice. Defaulting to CPU profile..."
        python3 start_services.py --profile cpu
        ;;
esac

echo ""
echo "=== Services Started ==="
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
