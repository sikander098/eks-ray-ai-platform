# =================================================================================================
# EKS NETWORK MIGRATION: AWS VPC CNI -> CILIUM eBPF
# =================================================================================================
# WARNING: This script will cause a temporary network interruption.
# USAGE: .\migrate-to-cilium.ps1
# =================================================================================================

# Helper Function
function Execute-Command ($Cmd, $Msg) {
    Write-Host "   Exec: $Msg..." -NoNewline
    Invoke-Expression $Cmd | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host " [OK]" -ForegroundColor Green }
    else { Write-Host " [FAILED] - Ignoring if already deleted" -ForegroundColor DarkGray }
}

$ClusterName = "astronomy-dev"
$Region = "us-east-1"

Write-Host "🚀 STARTING CILIUM MIGRATION FOR CLUSTER: $ClusterName" -ForegroundColor Cyan

# 1. Pre-Flight Checks
Write-Host "`n[1/5] Checking Cluster Access..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $Region --name $ClusterName
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to connect to cluster"; exit 1 }

# 2. Delete Legacy Networking (The "Blackout" Phase)
Write-Host "`n[2/5] Removing AWS VPC CNI & Kube-Proxy..." -ForegroundColor Yellow
Write-Host "⚠️  Network connectivity will be lost temporarily!" -ForegroundColor Red

# Delete AWS Node (CNI)
Execute-Command "kubectl -n kube-system delete daemonset aws-node" "Stopping AWS CNI"
# Delete Kube-Proxy (We are replacing it with eBPF)
Execute-Command "kubectl -n kube-system delete daemonset kube-proxy" "Stopping Kube-Proxy"

# 3. Install Cilium via Helm
Write-Host "`n[3/5] Installing Cilium (EKS Mode)..." -ForegroundColor Yellow

# Add Repo
helm repo add cilium https://helm.cilium.io/
helm repo update

# Install with EKS-Specific Flags
# eni.enabled=true -> Uses AWS ENI for IPAM (Critical for EKS)
# kubeProxyReplacement=true -> The main performance benefit
helm install cilium cilium/cilium --namespace kube-system `
    --set eni.enabled=true `
    --set ipam.mode=eni `
    --set egov.enabled=true `
    --set kubeProxyReplacement=true `
    --set hubble.enabled=true `
    --set hubble.ui.enabled=true `
    --set hubble.relay.enabled=true

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Cilium Helm Chart Installed" -ForegroundColor Green
}
else {
    Write-Error "Cilium Installation Failed"
    exit 1
}

# 4. Recycle Nodes (Verification)
Write-Host "`n[4/5] MIGRATION ACTION REQUIRED" -ForegroundColor Magenta
Write-Host "---------------------------------------------------------------"
Write-Host "To fully enable Cilium, existing pods need to be restarted."
Write-Host "Run this command to restart all kube-system pods:"
Write-Host "kubectl -n kube-system delete pods --all" -ForegroundColor Cyan
Write-Host "---------------------------------------------------------------"

# 5. Verification
Write-Host "`n[5/5] Verification Commands" -ForegroundColor Yellow
Write-Host "1. Check Status:    cilium status"
Write-Host "2. Hubble UI:       cilium hubble ui"
Write-Host "3. Pod Check:       kubectl get pods -n kube-system -o wide"

Write-Host "`n🚀 MIGRATION SCRIPT COMPLETE" -ForegroundColor Green

# Helper Function
function Execute-Command ($Cmd, $Msg) {
    Write-Host "   Exec: $Msg..." -NoNewline
    Invoke-Expression $Cmd | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host " [OK]" -ForegroundColor Green }
    else { Write-Host " [FAILED] - Ignoring if already deleted" -ForegroundColor DarkGray }
}
