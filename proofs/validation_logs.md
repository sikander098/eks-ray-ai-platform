# ✅ Validation Proofs

## 1. Infrastructure Scaling (Karpenter)
**Evidence**: Nodes `ip-10-0-10-115` and `ip-10-0-19-250` were dynamically provisioned when the Ray Cluster requested resources.

```bash
NAME                          STATUS   ROLES    AGE     VERSION                LABELS
ip-10-0-10-115.ec2.internal   Ready    <none>   9m27s   v1.28.15-eks-c39b1d0   karpenter.sh/capacity-type=spot
ip-10-0-19-250.ec2.internal   Ready    <none>   7m13s   v1.28.15-eks-c39b1d0   karpenter.sh/capacity-type=spot
```

## 2. Distributed Compute (Ray)
**Evidence**: A custom Python script distributed 1,000 tasks across the cluster. The results show execution on both the **Head** node and the **Worker** node.

```text
Cluster Resources: {'memory': 8589934592.0, 'object_store_memory': 2467656498.0, 'CPU': 3.0}

--- Ease of Distribution ---
Node ray-cluster-kuberay-worker-small-group-4mdx9: 609 tasks  <-- WORKER
Node ray-cluster-kuberay-head-p5jx7: 391 tasks                <-- HEAD

SUCCESS: Tasks were distributed across multiple nodes!
```

## 3. Real-World AI Training (XGBoost)
**Evidence**: A distributed XGBoost training job (`ray_xgboost_test.py`) was executed. It successfully ran 20 boosting rounds with 0 errors.

```text
TRAINING LOGS:
(XGBoostTrainer pid=482, ip=10.0.20.152) [RayXGBoost] Created 2 new actors (2 total actors).
...
Training finished iteration 20 at 2025-12-09 23:32:02. Total running time: 7s
╭───────────────────────────────╮
│ Training result               │
├───────────────────────────────┤
│ training_iteration         20 │
│ train-error                 0 │
│ train-logloss         0.01607 │
╰───────────────────────────────╯
```
