# EBS CSI Driver Setup

## Overview
The EBS CSI driver and gp3 StorageClass are now managed by Terraform in the EKS module.

## What Was Added
- `ebs-csi.tf` - EBS CSI driver EKS addon with IAM role
- `storageclass.tf` - gp3 StorageClass (set as default)
- `versions.tf` - Kubernetes provider requirement

## Apply Changes

### For Each Environment:

```bash
cd infra/environments/dev  # or staging/prod

# Review changes
terraform init -upgrade
terraform plan

# Apply (safe - only adds resources)
terraform apply
```

### What Gets Created:
- ✅ EBS CSI driver IAM role
- ✅ EBS CSI driver EKS addon
- ✅ gp3 StorageClass (default)
- ✅ gp2 StorageClass (default annotation removed)

### Verification:

```bash
# Check EBS CSI driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Check StorageClasses
kubectl get storageclass
# Should show gp3 as default

# Test PVC creation
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

kubectl get pvc test-pvc
kubectl delete pvc test-pvc
```

## Rollback (if needed)

```bash
# Remove resources
terraform destroy -target=kubernetes_storage_class_v1.gp3
terraform destroy -target=aws_eks_addon.ebs_csi
terraform destroy -target=aws_iam_role.ebs_csi
```

## Notes
- No disruption to existing workloads
- Existing gp2 volumes continue to work
- New PVCs will use gp3 by default
- gp3 is 20% cheaper and faster than gp2
