# Troubleshooting History & Decisions

## 🔧 Recent Fixes (Last 24h)

### 1. Grafana LoadBalancer Pending
*   **Issue**: Grafana Service stuck in Pending state.
*   **Root Cause**: Subnet tags mismatch. VPC subnets had `kubernetes.io/cluster/dev-cluster` but EKS cluster is `astronomy-dev`.
*   **Fix**: Updated VPC module to accept `cluster_name` variable. Updated tags to `kubernetes.io/cluster/astronomy-dev`. Confirmed LB provisioned immediately after.

### 2. Loki "Connection Refused"
*   **Issue**: `loki-gateway` logs showed connection refused to upstream.
*   **Root Cause**: Transient error during Helm release recreation (triggered by config update).
*   **Resolution**: Self-healed. Verified by checking `loki-0` logs which showed successful index uploads and query processing.

### 3. Missing App Logs in Loki
*   **Issue**: User query `{app="broken-checkout"}` returned no logs.
*   **Root Cause**: Promtail scraping config prefers official K8s labels. The deployment had metadata labels but the **Pod Template** lacked `app.kubernetes.io/name`.
*   **Fix**: Patched `broken-checkout.yaml` to include:
    ```yaml
    labels:
      app.kubernetes.io/name: broken-checkout
      app.kubernetes.io/instance: broken-checkout
    ```
*   **Status**: Fixed. New pods deployed. Correct query is `{app_kubernetes_io_name="broken-checkout"}`.

### 4. Application Logs Not Ingested (Loki)
*   **Issue**: Logs for `broken-checkout` and other apps were not appearing in Loki despite correct labels.
*   **Root Cause**: The default `PodLogs` resource (`loki`) had a restrictive selector matching only `app.kubernetes.io/name: loki`. The `LogsInstance` also enforced this selector.
*   **Fix**: Created a new `PodLogs` resource (`all-pods`) in the `monitoring` namespace that selects all pods (`matchLabels: {}`) and tagged it with `app.kubernetes.io/name: loki` to satisfy the `LogsInstance` selector.
*   **Status**: Fixed. Promtail is now tailing `broken-checkout` and `trace-gen`.

## 🧠 Key Design Decisions
*   **Terraform Structure**: Modular design (`modules/vpc`, `modules/eks`, `modules/observability`, `modules/karpenter`).
*   **State Management**: Local state currently (migrating to backend later).
*   **Auth**: EKS Access Entries used instead of `aws-auth` ConfigMap. IRSA used for all Service Accounts (Karpenter, Loki, Tempo).
*   **Storage**: S3 for object storage (Loki/Tempo), gp3 EBS for block storage (Prometheus).
