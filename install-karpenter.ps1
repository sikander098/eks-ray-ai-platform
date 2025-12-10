# Install Karpenter v0.32+ on astronomy-dev cluster
# PowerShell version

Write-Host "🚀 Installing Karpenter..." -ForegroundColor Green

# Get Terraform outputs
Push-Location live\dev
$KARPENTER_ROLE_ARN = terraform output -raw karpenter_controller_role_arn
$KARPENTER_INSTANCE_PROFILE = terraform output -raw karpenter_node_instance_profile
$CLUSTER_NAME = terraform output -raw cluster_name
$CLUSTER_ENDPOINT = terraform output -raw cluster_endpoint
Pop-Location

Write-Host "📋 Configuration:" -ForegroundColor Cyan
Write-Host "  Cluster: $CLUSTER_NAME"
Write-Host "  Controller Role: $KARPENTER_ROLE_ARN"
Write-Host "  Instance Profile: $KARPENTER_INSTANCE_PROFILE"

# Add Karpenter Helm repo
Write-Host "📦 Adding Karpenter Helm repository..." -ForegroundColor Cyan
helm repo add karpenter https://charts.karpenter.sh
helm repo update

# Install Karpenter
Write-Host "⚙️  Installing Karpenter v0.32.0..." -ForegroundColor Cyan
helm upgrade --install karpenter karpenter/karpenter `
  --namespace karpenter `
  --create-namespace `
  --version 0.32.0 `
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$KARPENTER_ROLE_ARN" `
  --set settings.clusterName=$CLUSTER_NAME `
  --set settings.clusterEndpoint=$CLUSTER_ENDPOINT `
  --set settings.defaultInstanceProfile=$KARPENTER_INSTANCE_PROFILE `
  --set settings.interruptionQueue=$CLUSTER_NAME `
  --wait

Write-Host "✅ Karpenter installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Verifying installation..." -ForegroundColor Cyan
kubectl get pods -n karpenter
Write-Host ""
Write-Host "📝 Check logs with:" -ForegroundColor Yellow
Write-Host "  kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f"
