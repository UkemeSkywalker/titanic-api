# Installation Guide - Lightweight Observability

**For: 3x t3.small nodes (2GB RAM each)**

## Prerequisites

✅ EKS cluster running
✅ kubectl configured
✅ Helm 3.x installed
✅ Docker installed

## Step-by-Step Installation

### Step 1: Install Monitoring Stack (5 minutes)

```bash
cd /Users/ukeme/titanic-api/k8s

# Install Prometheus, Grafana, Loki (lightweight)
./deploy-observability-lite.sh dev
```

**Expected output:**
```
✅ Observability stack installed successfully!
🔑 Grafana Credentials
   Username: admin
   Password: xK9mP2nQ7vR4sT8w
```

**Save the password!**

### Step 2: Verify Installation (2 minutes)

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Should see:
# prometheus-kube-prometheus-operator-xxx    1/1  Running
# prometheus-prometheus-kube-prometheus-xxx  1/1  Running
# prometheus-grafana-xxx                     1/1  Running
# loki-0                                     1/1  Running
# loki-promtail-xxx (3 pods, one per node)   1/1  Running
```

```bash
# Check resource usage
kubectl top nodes

# Should show each node using <1.5GB RAM
```

### Step 3: Update Application Code (Already Done ✅)

The following files have been updated:
- ✅ `requirements.txt` - Added observability dependencies
- ✅ `src/observability.py` - Metrics and logging
- ✅ `src/app.py` - Integrated observability
- ✅ `src/views/people.py` - Structured logging

### Step 4: Build and Push Docker Image (5 minutes)

```bash
cd /Users/ukeme/titanic-api

# Install dependencies locally (optional, for testing)
pip install -r requirements.txt

# Build Docker image
docker build -t ukemzyskywalker/titanic-api:v1.0-observability .

# Push to Docker Hub
docker push ukemzyskywalker/titanic-api:v1.0-observability
```

### Step 5: Deploy Application (3 minutes)

```bash
cd /Users/ukeme/titanic-api/k8s

# Deploy to dev environment
helm upgrade --install titanic-api-dev helm/titanic-api \
  -f helm/titanic-api/values-dev.yaml \
  --set image.tag=v1.0-observability \
  -n titanic-api-dev \
  --create-namespace \
  --wait
```

**Verify deployment:**
```bash
kubectl get pods -n titanic-api-dev

# Should see:
# titanic-api-xxx  1/1  Running
```

### Step 6: Test Metrics Endpoint (1 minute)

```bash
# Port forward to app
kubectl port-forward -n titanic-api-dev svc/titanic-api 5000:80 &

# Test health endpoint
curl http://localhost:5000/health
# Should return: {"status":"healthy"}

# Test metrics endpoint
curl http://localhost:5000/metrics
# Should return Prometheus metrics

# Generate some traffic
for i in {1..50}; do 
  curl -s http://localhost:5000/people > /dev/null
  echo -n "."
done
echo " Done!"

# Stop port forward
pkill -f "port-forward.*5000"
```

### Step 7: Access Grafana (2 minutes)

```bash
# Get Grafana password (if you lost it)
kubectl get secret grafana-credentials -n monitoring \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Port forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Open browser:**
1. Go to: http://localhost:3000
2. Login:
   - Username: `admin`
   - Password: (from above command)
3. Go to: Explore → Prometheus
4. Query: `rate(flask_http_request_total[5m])`
5. Click "Run query" - you should see metrics!

### Step 8: View Logs in Grafana (2 minutes)

**In Grafana:**
1. Go to: Explore → Loki
2. Query: `{app="titanic-api"}`
3. Click "Run query" - you should see JSON logs!

**Example queries:**
```logql
# All logs
{app="titanic-api"}

# Error logs only
{app="titanic-api"} |= "ERROR"

# Logs with specific message
{app="titanic-api"} |= "Retrieved people"
```

### Step 9: Check Alerts (1 minute)

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
```

**Open browser:**
1. Go to: http://localhost:9090/alerts
2. You should see 4 alerts:
   - HighErrorRate
   - PodDown
   - HighLatency
   - NodeMemoryPressure

```bash
# Stop port forward
pkill -f "port-forward.*9090"
```

### Step 10: Test Alert (Optional, 5 minutes)

```bash
# Trigger PodDown alert by scaling to 0
kubectl scale deployment titanic-api -n titanic-api-dev --replicas=0

# Wait 3 minutes, then check Prometheus alerts
# The PodDown alert should fire

# Scale back up
kubectl scale deployment titanic-api -n titanic-api-dev --replicas=2
```

## Verification Checklist

- [ ] All monitoring pods running: `kubectl get pods -n monitoring`
- [ ] Application pod running: `kubectl get pods -n titanic-api-dev`
- [ ] Metrics endpoint works: `curl http://localhost:5000/metrics`
- [ ] Grafana accessible: http://localhost:3000
- [ ] Prometheus shows metrics
- [ ] Loki shows logs
- [ ] Alerts configured: http://localhost:9090/alerts
- [ ] Resource usage acceptable: `kubectl top nodes`

## Troubleshooting

### Pods not starting?

```bash
# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n monitoring <pod-name>

# Check resource usage
kubectl top nodes
```

### Metrics not showing?

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n titanic-api-dev

# Check Prometheus targets
# Go to: http://localhost:9090/targets
# Should see titanic-api target as UP
```

### Out of memory?

```bash
# Reduce Prometheus retention
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --reuse-values \
  --set prometheus.prometheusSpec.retention=3d

# Reduce Loki retention
helm upgrade loki grafana/loki-stack \
  -n monitoring --reuse-values \
  --set loki.config.limits_config.retention_period=72h
```

## Next Steps

### 1. Create Custom Dashboard

In Grafana:
1. Click "+" → "Dashboard"
2. Add panel
3. Select Prometheus datasource
4. Query: `rate(flask_http_request_total[5m])`
5. Save dashboard

### 2. Configure Slack Alerts

Edit AlertManager config:
```bash
kubectl edit secret alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring
```

Add Slack webhook (base64 encoded).

### 3. Create Runbooks

```bash
mkdir -p docs/runbooks
# Create markdown files for each alert
# Update URLs in monitoring/alerts/prometheus-alerts-lite.yaml
```

## Useful Commands

```bash
# Get Grafana password
kubectl get secret grafana-credentials -n monitoring -o jsonpath='{.data.password}' | base64 -d

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# View app logs
kubectl logs -n titanic-api-dev -l app=titanic-api -f

# Check resource usage
kubectl top nodes
kubectl top pods -n monitoring
kubectl top pods -n titanic-api-dev

# Restart Grafana
kubectl rollout restart deployment prometheus-grafana -n monitoring

# Uninstall (if needed)
helm uninstall prometheus -n monitoring
helm uninstall loki -n monitoring
kubectl delete namespace monitoring
```

## Summary

**Total time**: ~20 minutes

**What you have now:**
- ✅ Prometheus collecting metrics
- ✅ Grafana for visualization
- ✅ Loki aggregating logs
- ✅ 4 critical alerts configured
- ✅ Application instrumented
- ✅ Using only ~1GB RAM

**Resource usage:**
- Monitoring: ~1GB RAM, ~300m CPU
- Your app: ~5GB RAM available
- Storage: ~30GB used

**Access:**
- Grafana: http://localhost:3000 (after port-forward)
- Prometheus: http://localhost:9090 (after port-forward)
- Metrics: http://localhost:5000/metrics (after port-forward)

🎉 **You're all set!**
