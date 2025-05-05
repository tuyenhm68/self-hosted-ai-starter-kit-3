#!/bin/bash

# install-vps.sh - Script to install n8n and related services on a cloud VPS
# Based on the self-hosted-ai-starter-kit instructions

# Exit on error
set -e

echo "=== Starting n8n and Local AI Package Installation ==="
echo "This script will install Docker, Docker Compose, and set up the Local AI Package"

# 1. Install Docker and Docker Compose
echo "=== Installing Docker and Docker Compose ==="

# Remove incompatible or out of date Docker implementations if they exist
echo "Removing any existing Docker installations..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg || true
done

# Install prereq packages
echo "Installing prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl git python3 python3-pip

# Download the repo signing key
echo "Setting up Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Configure the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker and Docker Compose
echo "Installing Docker and Docker Compose..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group to avoid using sudo
echo "Adding current user to docker group..."
sudo usermod -aG docker $USER
echo "NOTE: You may need to log out and back in for the group changes to take effect"

# 2. Clone the repository
# echo "=== Cloning the repository ==="
# git clone https://github.com/coleam00/local-ai-packaged.git
# cd local-ai-packaged

# 3. Set up environment variables
echo "=== Setting up environment variables ==="
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    
    # Generate random secure values for required environment variables
    N8N_ENCRYPTION_KEY=$(openssl rand -hex 24)
    N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 24)
    POSTGRES_PASSWORD=$(openssl rand -hex 24)
    # JWT_SECRET=$(openssl rand -hex 24)
    # ANON_KEY=$(openssl rand -hex 24)
    # SERVICE_ROLE_KEY=$(openssl rand -hex 24)
    DASHBOARD_USERNAME="admin"
    DASHBOARD_PASSWORD=$(openssl rand -hex 12)
    POOLER_TENANT_ID=$(openssl rand -hex 24)
    # CLICKHOUSE_PASSWORD=$(openssl rand -hex 24)
    # MINIO_ROOT_PASSWORD=$(openssl rand -hex 24)
    # LANGFUSE_SALT=$(openssl rand -hex 24)
    # NEXTAUTH_SECRET=$(openssl rand -hex 24)
    # ENCRYPTION_KEY=$(openssl rand -hex 24)
    
    # Caddy configuration
    echo "Setting up Caddy configuration..."
    read -p "Do you want to configure domains for your services? (y/n): " setup_domains
    
    if [[ "$setup_domains" == "y" || "$setup_domains" == "Y" ]]; then
        read -p "Enter your base domain (e.g., example.com): " BASE_DOMAIN
        read -p "Enter your email for Let's Encrypt: " LETSENCRYPT_EMAIL
        
        # Uncomment and configure Caddy section in .env
        sed -i 's/^#\(.*# Caddy Config.*\)/\1/' .env
        sed -i "s|^#N8N_HOSTNAME=.*|N8N_HOSTNAME=n8n.$BASE_DOMAIN|" .env
        sed -i "s|^#WEBUI_HOSTNAME=.*|WEBUI_HOSTNAME=openwebui.$BASE_DOMAIN|" .env
        sed -i "s|^#FLOWISE_HOSTNAME=.*|FLOWISE_HOSTNAME=flowise.$BASE_DOMAIN|" .env
        sed -i "s|^#SUPABASE_HOSTNAME=.*|SUPABASE_HOSTNAME=supabase.$BASE_DOMAIN|" .env
        sed -i "s|^#OLLAMA_HOSTNAME=.*|OLLAMA_HOSTNAME=ollama.$BASE_DOMAIN|" .env
        sed -i "s|^#PORTAINER_HOSTNAME=.*|PORTAINER_HOSTNAME=portainer.$BASE_DOMAIN|" .env
        sed -i "s|^#LETSENCRYPT_EMAIL=.*|LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL|" .env
        
        echo "Caddy configuration has been set up with your domains in the .env file."
    else
        echo "Skipping domain configuration. You can set it up later by editing the .env file."
    fi
    
    # Update the .env file with generated values
    sed -i "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY/" .env
    sed -i "s/^N8N_USER_MANAGEMENT_JWT_SECRET=.*/N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET/" .env
    sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
    # sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    # sed -i "s/^ANON_KEY=.*/ANON_KEY=$ANON_KEY/" .env
    # sed -i "s/^SERVICE_ROLE_KEY=.*/SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY/" .env
    sed -i "s/^DASHBOARD_USERNAME=.*/DASHBOARD_USERNAME=$DASHBOARD_USERNAME/" .env
    sed -i "s/^DASHBOARD_PASSWORD=.*/DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD/" .env
    sed -i "s/^POOLER_TENANT_ID=.*/POOLER_TENANT_ID=$POOLER_TENANT_ID/" .env
    # sed -i "s/^CLICKHOUSE_PASSWORD=.*/CLICKHOUSE_PASSWORD=$CLICKHOUSE_PASSWORD/" .env
    # sed -i "s/^MINIO_ROOT_PASSWORD=.*/MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD/" .env
    # sed -i "s/^LANGFUSE_SALT=.*/LANGFUSE_SALT=$LANGFUSE_SALT/" .env
    # sed -i "s/^NEXTAUTH_SECRET=.*/NEXTAUTH_SECRET=$NEXTAUTH_SECRET/" .env
    # sed -i "s/^ENCRYPTION_KEY=.*/ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
    
    echo "Environment variables have been set with secure random values."
    echo "IMPORTANT: If you want to deploy to production with a domain, edit the .env file"
    echo "and uncomment the Caddy Config section, setting your domain names and email."
else
    echo ".env file already exists. Skipping environment setup."
fi

# 4. Start the services
echo "=== Starting services ==="
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
echo "=== Installation Complete ==="
echo ""
echo "Services should now be available at:"
echo "- n8n: https://n8n.$BASE_DOMAIN"
echo "- Open WebUI: https://openwebui.$BASE_DOMAIN"
echo "- Flowise: https://flowise.$BASE_DOMAIN"
echo "- Supabase: https://supabase.$BASE_DOMAIN"
echo "- Ollama: https://ollama.$BASE_DOMAIN"
echo "- Portainer: https://portainer.$BASE_DOMAIN"
echo ""
echo "If you've configured domains in the .env file, your services will be available at those domains."
echo ""
echo "IMPORTANT: Save your credentials from the .env file in a secure location."
echo "Dashboard username: $DASHBOARD_USERNAME"
echo "Dashboard password: See .env file"
echo ""
echo "For more information and troubleshooting, refer to the README.md file."
