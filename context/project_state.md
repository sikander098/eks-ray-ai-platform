# Project State: EKS Observability & Autoscaling Platform
**Last Updated:** 2025-12-07 13:17 UTC

## 🚀 Current Status
**Verified & Operational**. 
The `dev` environment is fully provisioned with an EKS cluster, working Karpenter autoscaling, and a complete LGTM (Loki, Grafana, Tempo, Prometheus) observability stack.

## 🏗️ Active Components
| Component | Status | Details |
|-----------|--------|---------|
| **EKS Cluster** | ✅ Ready | `astronomy-dev` (v1.28). |
| **Karpenter** | ✅ Ready | v1.8.2. Provisioning spots/on-demand. `default-pool` active. |
| **Prometheus** | ✅ Ready | Metrics flowing. EBS backed. |
| **Grafana** | ✅ Ready | Exposed via LB. `admin` / `wf0&esCf+2lMdL9<`. |
# Project State: EKS Observability & Autoscaling Platform
**Last Updated:** 2025-12-07 13:17 UTC

## 🚀 Current Status
**Verified & Operational**. 
The `dev` environment is fully provisioned with an EKS cluster, working Karpenter autoscaling, and a complete LGTM (Loki, Grafana, Tempo, Prometheus) observability stack.

## 🏗️ Active Components
| Component | Status | Details |
|-----------|--------|---------|
| **EKS Cluster** | ✅ Ready | `astronomy-dev` (v1.28). |
| **Karpenter** | ✅ Ready | v1.8.2. Provisioning spots/on-demand. `default-pool` active. |
| **Prometheus** | ✅ Ready | Metrics flowing. EBS backed. |
| **Grafana** | ✅ Ready | Exposed via LB. `admin` / `wf0&esCf+2lMdL9<`. |
| **Loki** | ✅ Ready | Logs ingesting to S3. Derived Fields enabled for Trace ID linking. |
| **Tempo** | ✅ Ready | Traces ingesting to S3. Linked to Loki logs. |
| **Demo Apps** | ✅ Running | `trace-gen` (synthetic traffic) and `broken-checkout` (simulated errors). |
| **Local AI Lab** | ✅ Operational | Minikube on WSL2 (Docker Driver) with NVIDIA RTX 2060 Super (8GB), 4 Virtual GPUs (Time-Slicing enabled). Ready for inference workload deployment. |

## 🛑 Current Blockers / Open Items
1.  **GPU Provisioning**: `gpu-pool` is created but likely blocked by AWS Service Quota for G-series instances. Needs verification.
2.  **Loki Querying**: Logs are now flowing. User is learning to query Loki. Correct query: `{app_kubernetes_io_name="broken-checkout"}`.

## 🔜 Next Actions
- Verify GPU quotas.
- Finalize user handover of the "SRE Triage" workflow.

## 4. Next Steps & Roadmap
- [ ] Deploy an actual AI Model (e.g., DeepSeek-R1 or Llama-3) to the local lab.
- [ ] Connect the Local Lab to the Terraform Platform via Federation (Tailscale/VPN)?
- [ ] Continue with EKS Observability tasks (verify Loki/Tempo deep integration).
