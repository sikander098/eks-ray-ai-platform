#!/bin/bash
set -e
echo "🔄 Restarting Docker via 'service' command..."
sudo service docker stop
sudo service docker start
sleep 3
echo "🔍 Checking Default Runtime..."
docker info | grep "Default Runtime"

# Check if it worked
RUNTIME=$(docker info | grep "Default Runtime" | awk '{print $3}')
if [ "$RUNTIME" == "nvidia" ]; then
    echo "✅ Success! Default Runtime is nvidia."
    echo "🗑️  Recreating Kind Cluster..."
    kind delete cluster --name ai-platform || true
    # We exit here so the user can run the setup script again
    exit 0
else
    echo "❌ Failed. Runtime is still $RUNTIME."
    exit 1
fi
