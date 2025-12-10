# 🤖 EKS AI Platform: Ray, Karpenter, & Cilium
**An Enterprise-Grade, Auto-Scaling AI Infrastructure on AWS**

This project demonstrates a production-ready Kubernetes platform built for **Distributed AI/ML Workloads**. It replaces manual node management with an intelligent, serverless-like dynamic scaling engine.

```mermaid
graph TD
    User[👩‍💻 Data Scientist] -->|JupyterHub| LB[Load Balancer]
    LB -->|Spawns| Hub[JupyterHub Pod]
    Hub -->|Submits Job| RayHead[🧠 Ray Head Node]
    
    subgraph EKS Cluster
        subgraph Compute Plane
            RayHead -->|Orchestrates| Worker1["👷 Ray Worker (Spot)"]
            RayHead -->|Orchestrates| Worker2["👷 Ray Worker (Spot)"]
        end
        
        subgraph Control Plane
            Karpenter[🏗️ Karpenter] -->|Watches| RayHead
            Karpenter -->|Provisions| EC2[AWS EC2 API]
        end
    end
    
    EC2 -->|Creates| Worker1
    EC2 -->|Creates| Worker2
```
*(Architecture: User -> JupyterHub -> Ray Cluster <- Autoscaled by Karpenter)*

## 🚀 Key Features

### 1. 🏭 Dynamic Infrastructure (Karpenter v1.0)
- **Just-in-Time Compute**: The cluster sits at minimal size (saving cost) until a job arrives.
- **Spot Instance Orchestration**: Automatically bids on AWS Spot Instances (r5dn.large, c5.large), reducing compute costs by **~70-90%**.
- **Self-Healing**: Integrated `SQS` and `EventBridge` rules to handle AWS Spot Interruptions gracefully.

### 2. 🧠 Distributed Compute Engine (Ray)
- **KubeRay Operator**: Manages the lifecycle of Ray Clusters on K8s.
- **Massive Parallelism**: Allows Python code (Pandas, PyTorch, XGBoost) to be instanty distributed across hundreds of CPU cores.
- **Unified Interface**: Data Science teams interface via **JupyterHub**, which is pre-wired to the Ray Head.

### 3. ⚡ High-Performance Networking (Cilium eBPF)
- **No Kube-Proxy**: Traditional iptables replaced by **eBPF** for O(1) scalability.
- **Performance**: Lower latency for inter-node communication (critical for parameter server training).

---

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **IaC** | Terraform | State-managed Infrastructure as Code |
| **Orchestrator** | EKS (Kubernetes 1.28) | Container Management |
| **Scaling** | Karpenter (v1.0.6) | Node Autoscaling (Provisioner) |
| **Compute** | Ray (v2.9.0) | Distributed ML Framework |
| **Network** | Cilium (v1.16) | CNI & Network Policy |
| **Interface** | JupyterHub | IDE for Data Scientists |

---

## 📸 Validation & Proofs

We have validated the platform with real distributed workloads. See [`proofs/`](./proofs/) for detailed logs.

### ✅ Test 1: Infrastructure Scaling
**Scenario**: User submits a job requiring 6 CPUs.
**Result**: Karpenter detects pending pods and provisions `ip-10-0-10-115` (Spot Instance) in <60 seconds.

### ✅ Test 2: Distributed XGBoost Training
**Scenario**: Training a Breast Cancer detection model on a distributed dataset.
**Result**:
```text
(XGBoostTrainer) [RayXGBoost] Created 2 new actors.
Training finished iteration 20. Accuracy: 100%.
```
*Successfully distributed training logic across multiple physical nodes.*

---

## 📂 Project Structure

```bash
├── live/dev/               # Terraform Root Module (Environment)
│   ├── main.tf             # Core Infrastructure
│   ├── karpenter.tf        # Autoscaler Config
│   ├── kuberay.tf          # Ray Operator
│   └── cilium.tf           # Networking Config
├── modules/                # Reusable Terraform Modules
│   ├── eks/                # EKS Cluster Logic
│   └── karpenter/          # IAM, SQS, and Helm setups
├── k8s/                    # Kubernetes Manifests
│   ├── ray/                # RayCluster definitions
│   └── jupyterhub/         # JupyterHub values
└── scripts/                # Utility Scripts
```

## 🎓 How It Works (For Beginners)
Not sure what all this means? Check out [**Project Explained**](./project_explained.md) for a plain-english breakdown using a "Factory" analogy!
