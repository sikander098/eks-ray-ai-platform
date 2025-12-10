# Install KEDA v2.12 on astronomy-dev cluster
# PowerShell version

Write-Host "🚀 Installing KEDA..." -ForegroundColor Green

# Add KEDA Helm repo
Write-Host "📦 Adding KEDA Helm repository..." -ForegroundColor Cyan
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Install KEDA
Write-Host "⚙️  Installing KEDA v2.12.0..." -ForegroundColor Cyan
helm upgrade --install keda kedacore/keda `
  --namespace keda `
  --create-namespace `
  --version 2.12.0 `
  --wait

Write-Host "✅ KEDA installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Verifying installation..." -ForegroundColor Cyan
kubectl get pods -n keda
Write-Host ""
Write-Host "📝 Check CRDs:" -ForegroundColor Yellow
Write-Host "  kubectl get crd | Select-String keda"
Write-Host ""
Write-Host "📝 Check KEDA operator logs:" -ForegroundColor Yellow
Write-Host "  kubectl logs -n keda -l app=keda-operator -f"
