# Ensure sudo works first
sudo -v || { echo "❌ sudo verification failed. Aborting."; exit 1; }

# Function to install dependencies
install_dependency() {
    CMD=$1
    echo "🔍 Checking for $CMD..."
    if ! command -v $CMD &> /dev/null; then
        echo "⚠️  $CMD not found. Installing..."
        case $CMD in
            kind)
                LATEST_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                # Fallback if rate limited
                [ -z "$LATEST_VERSION" ] && LATEST_VERSION="v0.20.0"
                curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${LATEST_VERSION}/kind-linux-amd64"
                chmod +x ./kind
                sudo mv ./kind /usr/local/bin/kind
                ;;
            kubectl)
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                sudo mv kubectl /usr/local/bin/
                ;;
            helm)
                curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                ;;
        esac
        echo "✅ $CMD installed."
    else
        echo "✅ $CMD is already installed."
    fi
}

install_dependency kind
install_dependency kubectl
install_dependency helm

echo "🛠️  Step 1: Installing NVIDIA Container Toolkit..."

# Ensure sudo works first
sudo -v || { echo "❌ sudo verification failed. Aborting."; exit 1; }

echo "🛠️  Step 1: Installing NVIDIA Container Toolkit..."

# Add package repositories ONLY if not present
if [ ! -f /etc/apt/sources.list.d/nvidia-container-toolkit.list ]; then
    echo "📦 Adding NVIDIA Repositories..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
else
    echo "✅ NVIDIA repositories already configured."
fi

echo "🔄 Updating package lists..."
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker Runtime
echo "⚙️  Configuring Docker Runtime..."
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker || echo "⚠️  Could not restart Docker (Systemd might not be active). Please restart Docker Desktop manually if this step fails."

echo "✅ NVIDIA Toolkit installed."

# ------------------------------------------------------------------
# 2. Configure & Create Kind Cluster (GPU-Aware)
# ------------------------------------------------------------------
echo "🏗️  Step 2: Creating GPU-Aware Kind Cluster 'ai-platform'..."

CLUSTER_NAME="ai-platform"
KIND_CONFIG="kind-gpu-config.yaml"

# Create Kind Config with critical extraMounts for GPU passthrough
cat <<EOF > $KIND_CONFIG
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
    # Pass through the NVIDIA GPUs
    - hostPath: /dev/null
      containerPath: /dev/null
    - hostPath: /var/lib/kubelet/device-plugins
      containerPath: /var/lib/kubelet/device-plugins
EOF

# Delete existing cluster if it exists
kind delete cluster --name $CLUSTER_NAME || true

# Create Cluster
kind create cluster --name $CLUSTER_NAME --config $KIND_CONFIG

echo "✅ Kind cluster '$CLUSTER_NAME' created."

# ------------------------------------------------------------------
# 3. Install NVIDIA Device Plugin (Time-Slicing Enabled)
# ------------------------------------------------------------------
echo "🎨 Step 3: Installing NVIDIA Device Plugin with Time-Slicing (4 vGPUs)..."

# Add Helm Repo
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

# Install with Time-Slicing Config
# We define a ConfigMap to share the GPU into 4 replicas
echo "🛠️  Creating ConfigMap for Time-Slicing..."
kubectl create namespace nvidia-device-plugin || true
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: nvidia-device-plugin
data:
  any-name-works.yaml: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4
EOF

echo "📦 Installing Device Plugin via Helm..."
helm upgrade --install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.14.3 \
  --set config.name=time-slicing-config

echo "⏳ Waiting for Device Plugin to initialize..."
kubectl rollout status ds/nvdp-nvidia-device-plugin -n nvidia-device-plugin

echo "✅ NVIDIA Device Plugin installed."

# ------------------------------------------------------------------
# 4. Verify Capacity
# ------------------------------------------------------------------
echo "🔍 Step 4: Verifying Node Capacity..."
echo "Checking if NVIDIA GPUs are advertised..."

# Simple wait loop for capacity updates
for i in {1..10}; do
  CAPACITY=$(kubectl get node -o jsonpath='{.items[0].status.capacity.nvidia\.com/gpu}')
  if [[ "$CAPACITY" == "4" ]]; then
    echo "🎉 SUCCESS: Node is advertising 4 Virtual GPUs!"
    break
  fi
  echo "Waiting for node capacity update... (attempt $i/10)"
  sleep 5
done

if [[ "$CAPACITY" != "4" ]]; then
  echo "⚠️  WARNING: Node capacity is not showing 4 GPUs yet. It may take a moment."
fi

echo "🚀 Setup Complete! Run 'kubectl apply -f gpu-test-pod.yaml' to test."
