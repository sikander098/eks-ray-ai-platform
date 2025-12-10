# Architecture Summary

## 🌍 Infrastructure (AWS/Terraform)
*   **Region**: `us-east-1`
*   **VPC**: 3 AZs, Private/Public subnets, NAT Gateways.
*   **EKS**: Managed Node Groups (initial) + Karpenter (scaling).

## 👁️ Observability Stack (Helm/Terraform)
The stack is defined in `modules/observability` and deployed via Helm options.

### 1. Correlation Features
We have enabled strict correlation between signals to allow "3-Click Triage":
*   **Loki Config**: `derivedFields` regex parses `traceID=(\w+)` and links to Tempo.
*   **Tempo Config**: `tracesToLogs` datasource link enabled.
*   **App Instrumentation**: Apps must log to stdout in JSON or LogFmt with a `traceID` field.

### 2. Data Flow
*   **Metrics**: Prometheus scrapes `/metrics` endpoints.
*   **Logs**: Promtail (DaemonSet) reads host paths `/var/log/pods`. Pushes to Loki.
*   **Traces**: OTel SDKs push to Tempo Service (`tempo.monitoring:4317` gRPC).

## 🤖 Automation
*   **Karpenter**: Monitors unschedulable pods. Provisions `c5`/`m5` instances for general work, `g4dn` for GPU work (pending quota).
*   **KEDA**: Installed (v2.12) but currently idle (no scaledobjects defined yet).
