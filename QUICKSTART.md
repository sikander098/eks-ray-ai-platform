# 🚀 Quick Start Guide

## Prerequisites

Before you begin, ensure you have:

- ✅ AWS Account with admin access
- ✅ AWS CLI configured (`aws configure`)
- ✅ Terraform >= 1.5 installed
- ✅ kubectl >= 1.28 installed
- ✅ Helm >= 3.0 installed
- ✅ Docker installed
- ✅ Git installed

## 5-Minute Setup

### 1. Clone the Repository

```bash
git clone https://github.com/sikander098/astronomy-platform.git
cd astronomy-platform
```

### 2. Deploy Infrastructure

```bash
cd live/dev
terraform init
terraform apply -auto-approve
```

**Expected time:** ~15 minutes (AWS EKS cluster creation)

### 3. Connect to Cluster

```bash
# Get kubeconfig
aws eks update-kubeconfig --region us-east-1 --name astronomy-dev

# Verify connection
kubectl get nodes
```

### 4. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### 5. Deploy Application

```bash
# Apply ArgoCD application
kubectl apply -f argocd/booking-service-dev.yaml

# Watch deployment
kubectl get pods -w
```

### 6. Access Application

```bash
# Get service endpoint
kubectl get svc booking-service

# Port forward (for local testing)
kubectl port-forward svc/booking-service 8080:80
```

Visit: `http://localhost:8080`

## 🎯 What You Just Built

- ✅ AWS VPC with public/private subnets
- ✅ EKS cluster with managed node group
- ✅ ArgoCD for GitOps deployment
- ✅ Crossplane for database provisioning
- ✅ Velero for disaster recovery
- ✅ Running Go microservice with PostgreSQL

## 🔄 Make Your First Deployment

1. **Edit the application:**
   ```bash
   cd app-source/booking-service
   # Edit main.go
   ```

2. **Commit and push:**
   ```bash
   git add .
   git commit -m "feat: my first change"
   git push origin main
   ```

3. **Watch GitOps magic:**
   ```bash
   # GitHub Actions builds image
   # ArgoCD syncs automatically
   kubectl get pods -w
   ```

## 📚 Next Steps

- [Provision a Database](docs/database-provisioning.md)
- [Deploy to Production](docs/production-deployment.md)
- [Test Disaster Recovery](docs/disaster-recovery.md)
- [Configure CI/CD](docs/cicd-setup.md)

## 🆘 Troubleshooting

### ArgoCD Not Syncing?
```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Database Not Provisioning?
```bash
# Check Crossplane status
kubectl get postgresinstance

# View Crossplane logs
kubectl logs -n crossplane-system deployment/crossplane
```

### Pods Not Starting?
```bash
# Check pod events
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
```

## 🧹 Cleanup

To destroy all resources:

```bash
cd live/dev
terraform destroy -auto-approve
```

**Warning:** This will delete everything including databases!

## 📞 Support

- 📖 [Full Documentation](README.md)
- 🐛 [Report Issues](https://github.com/sikander098/astronomy-platform/issues)
- 💬 [Discussions](https://github.com/sikander098/astronomy-platform/discussions)
