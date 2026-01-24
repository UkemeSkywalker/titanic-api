# Observability & Monitoring

Complete Prometheus and Grafana monitoring stack for Titanic API across dev, staging, and prod environments.

## Architecture

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alert routing and management
- **ServiceMonitor**: Automatic service discovery for scraping

## Resource Allocation by Environment

### Dev (t3.small nodes - 2 vCPU, 2GB RAM)
- Prometheus: 200m CPU / 400Mi RAM
- Grafana: 100m CPU / 128Mi RAM
- Retention: 7 days
- Storage: 10Gi

### Staging (t3.small nodes - 2 vCPU, 2GB RAM)
- Prometheus: 250m CPU / 512Mi RAM
- Grafana: 100m CPU / 192Mi RAM
- Retention: 15 days
- Storage: 20Gi

### Prod (t3.medium nodes - 2 vCPU, 4GB RAM)
- Prometheus: 500m CPU / 1Gi RAM
- Grafana: 200m CPU / 256Mi RAM
- Retention: 30 days
- Storage: 50Gi

## Installation

```bash
# Install for specific environment
cd k8s/monitoring
chmod +x install-monitoring.sh
./install-monitoring.sh <dev|staging|prod>
```

## Deploy Application Monitoring

```bash
# Apply ServiceMonitor for Prometheus scraping
kubectl apply -f servicemonitor.yaml -n titanic-api-<env>

# Apply alert rules
kubectl apply -f prometheus-rules.yaml
```

## Access Dashboards

### Grafana
```bash
# Port forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Get admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d

# Access: http://localhost:3000
# Username: admin
```

### Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Access: http://localhost:9090
```

### AlertManager
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Access: http://localhost:9093
```

## Dashboard Panels

The Titanic API dashboard includes:

1. **Request Rate**: Real-time request throughput per namespace
2. **Request Latency**: P50, P95, P99 latency percentiles
3. **Error Rate**: 4xx and 5xx error rates
4. **CPU Utilization**: Per-pod CPU usage
5. **Memory Utilization**: Per-pod memory consumption
6. **Pod Status**: Running pod count gauge

## Alert Rules

### Critical Alerts
- **HighErrorRate**: >5% error rate for 5 minutes
- **PodCrashLooping**: Pod restarting continuously
- **PodNotReady**: Pod not running for 10 minutes
- **DatabaseConnectionFailure**: High 500 error rate

### Warning Alerts
- **HighLatency**: P95 latency >1s for 5 minutes
- **HighMemoryUsage**: >85% memory usage
- **HighCPUUsage**: >85% CPU usage

### Info Alerts
- **LowRequestRate**: Very low traffic detected

## Metrics Exposed

The Flask application exposes:
- `flask_http_request_total`: Total HTTP requests by method, status, endpoint
- `flask_http_request_duration_seconds`: Request duration histogram
- `flask_http_request_exceptions_total`: Total exceptions
- `app_info`: Application metadata

## Querying Metrics

### Request Rate
```promql
sum(rate(flask_http_request_total{namespace="titanic-api-prod"}[5m]))
```

### Error Rate
```promql
sum(rate(flask_http_request_total{status=~"5..", namespace="titanic-api-prod"}[5m])) 
/ sum(rate(flask_http_request_total{namespace="titanic-api-prod"}[5m]))
```

### P95 Latency
```promql
histogram_quantile(0.95, 
  sum(rate(flask_http_request_duration_seconds_bucket{namespace="titanic-api-prod"}[5m])) by (le)
)
```

### CPU Usage
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="titanic-api-prod", container="titanic-api"}[5m])) * 100
```

### Memory Usage
```promql
sum(container_memory_working_set_bytes{namespace="titanic-api-prod", container="titanic-api"})
```

## Troubleshooting

### No metrics appearing
```bash
# Check ServiceMonitor
kubectl get servicemonitor -n titanic-api-<env>

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check app metrics endpoint
kubectl port-forward -n titanic-api-<env> svc/titanic-api 5000:80
curl http://localhost:5000/metrics
```

### High resource usage
```bash
# Check Prometheus resource usage
kubectl top pod -n monitoring -l app.kubernetes.io/name=prometheus

# Reduce retention or scrape interval in values-<env>.yaml
```

### Alerts not firing
```bash
# Check PrometheusRule
kubectl get prometheusrule -n monitoring

# Check AlertManager
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager
```

## Cleanup

```bash
# Remove monitoring stack
helm uninstall prometheus -n monitoring

# Remove namespace
kubectl delete namespace monitoring
```

## Integration with CI/CD

The monitoring stack integrates with ArgoCD for GitOps deployment:
- Dashboard configurations stored in Git
- Alert rules version controlled
- Environment-specific resource limits

## Best Practices

1. **Resource Limits**: Always set appropriate limits based on node capacity
2. **Retention**: Balance storage costs with data retention needs
3. **Scrape Interval**: 30s default, adjust based on cardinality
4. **Alert Fatigue**: Tune thresholds to reduce false positives
5. **Dashboard Sharing**: Export and version control dashboard JSON
