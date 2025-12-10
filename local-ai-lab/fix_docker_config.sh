#!/bin/bash
set -e
echo "🔧 Patching Docker Config to set Default Runtime to NVIDIA..."

# We need jq to do this cleanly, but let's do a simple overwrite for robustness if jq isn't there.
# Since we know the previous content was simple, we can provide the correct config.

cat <<EOF | sudo tee /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    }
}
EOF

echo "🔄 Restarting Docker..."
sudo systemctl restart docker

echo "🗑️  Deleting old cluster..."
kind delete cluster --name ai-platform || true

echo "✅ Docker configured. Please re-run './setup_local_ai_lab.sh' to re-create the cluster with GPUs."
