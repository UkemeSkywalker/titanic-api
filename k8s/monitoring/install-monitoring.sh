#!/bin/bash
set -e

ENVIRONMENT=$1
NAMESPACE="monitoring"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./install-monitoring.sh <dev|staging|prod>"
  exit 1
fi

echo "🔍 Installing Prometheus & Grafana for $ENVIRONMENT environment..."

# Validate prerequisites
echo "📋 Checking prerequisites..."
if ! kubectl get storageclass gp3 &>/dev/null; then
  echo "❌ Error: gp3 StorageClass not found!"
  echo "Please run 'terraform apply' in infra/environments/$ENVIRONMENT to install EBS CSI driver"
  exit 1
fi

if ! kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver &>/dev/null; then
  echo "❌ Error: EBS CSI driver not installed!"
  echo "Please run 'terraform apply' in infra/environments/$ENVIRONMENT to install EBS CSI driver"
  exit 1
fi

echo "✅ Prerequisites validated"

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
echo "Installing kube-prometheus-stack (this may take 3-5 minutes)..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --values values-$ENVIRONMENT.yaml \
  --timeout 10m \
  --wait \
  --debug

echo "✅ Monitoring stack installed!"
echo ""
echo "📊 Access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-grafana 3000:80"
echo "   Username: admin"
echo "   Password: \$(kubectl get secret -n $NAMESPACE prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d)"
echo ""
echo "📈 Access Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090"
