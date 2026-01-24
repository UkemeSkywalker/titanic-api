#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="monitoring"

echo "🔍 Installing Prometheus & Grafana for $ENVIRONMENT environment..."

# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --values values-$ENVIRONMENT.yaml \
  --wait

echo "✅ Monitoring stack installed!"
echo ""
echo "📊 Access Grafana:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-grafana 3000:80"
echo "   Username: admin"
echo "   Password: \$(kubectl get secret -n $NAMESPACE prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d)"
echo ""
echo "📈 Access Prometheus:"
echo "   kubectl port-forward -n $NAMESPACE svc/prometheus-kube-prometheus-prometheus 9090:9090"
