#!/bin/bash
set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./deploy-monitoring.sh <dev|staging|prod>"
  exit 1
fi

echo "🚀 Quick Deploy Monitoring for $ENVIRONMENT"
echo ""

# Install monitoring stack
./install-monitoring.sh $ENVIRONMENT

# Wait for pods to be ready
echo "⏳ Waiting for monitoring pods..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Apply ServiceMonitor
echo "📊 Deploying ServiceMonitor..."
kubectl apply -f servicemonitor.yaml -n titanic-api-$ENVIRONMENT

# Apply alert rules
echo "🚨 Deploying alert rules..."
kubectl apply -f prometheus-rules.yaml

# Apply dashboard ConfigMap
echo "📈 Deploying dashboard..."
kubectl apply -f dashboard-configmap.yaml

echo ""
echo "✅ Monitoring deployed successfully!"
echo ""
echo "📊 Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "📈 Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo ""
echo "🔑 Grafana Password:"
kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d
echo ""
