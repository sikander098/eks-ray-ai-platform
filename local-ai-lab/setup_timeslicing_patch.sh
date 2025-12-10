#!/bin/bash
set -e
echo "🎨 Configuring Time-Slicing for Minikube Addon..."

# 1. Create ConfigMap in kube-system (where the addon lives)
cat <<EOF | kubectl apply -n kube-system -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: kube-system
data:
  config.yaml: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4
EOF

# 2. Patch the DaemonSet
# We need to add the volume, volumeMount, and the argument.
# This patch assumes the container is named 'nvidia-device-plugin-ctr' (verified in logs earlier)

kubectl patch daemonset nvidia-device-plugin-daemonset -n kube-system --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "config",
      "configMap": {
        "name": "time-slicing-config"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "config",
      "mountPath": "/config"
    }
  },
  {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args",
      "value": ["--config-file=/config/config.yaml"]
  }
]'

echo "⏳ Waiting for patched rollout..."
kubectl rollout status daemonset/nvidia-device-plugin-daemonset -n kube-system

echo "✅ Done. Verifying capacity..."
for i in {1..10}; do
  CAPACITY=$(kubectl get node -o jsonpath='{.items[0].status.capacity.nvidia\.com/gpu}')
  if [[ "$CAPACITY" == "4" ]]; then
    echo "🎉 SUCCESS: Node is advertising 4 Virtual GPUs!"
    exit 0
  fi
  echo "Waiting for node capacity update... (attempt $i/10)"
  sleep 5
done

echo "⚠️  Capacity verification timed out, but check manually."
