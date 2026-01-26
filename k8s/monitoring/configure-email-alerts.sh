 opp#!/bin/bash
set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: ./configure-email-alerts.sh <dev|staging|prod>"
  exit 1
fi

echo "📧 Configuring Email Notifications for AlertManager"
echo "Environment: $ENVIRONMENT"
echo ""

# Check if SMTP secret exists in Kubernetes
if ! kubectl get secret alertmanager-smtp -n monitoring &>/dev/null; then
  echo "❌ Error: SMTP secret not found in Kubernetes!"
  echo ""
  echo "Please run these steps first:"
  echo "1. ./store-smtp-secret.sh $ENVIRONMENT"
  echo "2. ./sync-alertmanager-secrets.sh $ENVIRONMENT"
  exit 1
fi

echo "✅ SMTP secret found"
echo ""

# Get values from Kubernetes secret
SMTP_SERVER=$(kubectl get secret alertmanager-smtp -n monitoring -o jsonpath='{.data.smtp_server}' | base64 -d)
SMTP_FROM=$(kubectl get secret alertmanager-smtp -n monitoring -o jsonpath='{.data.smtp_from}' | base64 -d)
SMTP_USERNAME=$(kubectl get secret alertmanager-smtp -n monitoring -o jsonpath='{.data.smtp_username}' | base64 -d)
SMTP_PASSWORD=$(kubectl get secret alertmanager-smtp -n monitoring -o jsonpath='{.data.smtp_password}' | base64 -d)
TEAM_EMAIL=$(kubectl get secret alertmanager-smtp -n monitoring -o jsonpath='{.data.team_email}' | base64 -d)
CRITICAL_EMAIL=$(kubectl get secret alertmanager-smtp -n monitoring -o jsonpath='{.data.critical_email}' | base64 -d)

echo ""
echo "📝 Updating AlertManager configuration..."

# Create temporary values file with email config
cat > values-${ENVIRONMENT}-email.yaml <<EOF
alertmanager:
  config:
    global:
      resolve_timeout: 5m
      smtp_from: '${SMTP_FROM}'
      smtp_smarthost: '${SMTP_SERVER}'
      smtp_auth_username: '${SMTP_USERNAME}'
      smtp_auth_password: '${SMTP_PASSWORD}'
      smtp_require_tls: true

    route:
      group_by: ['alertname', 'namespace', 'severity']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'email-notifications'
      routes:
        - match:
            severity: critical
          receiver: 'email-critical'
          continue: true
        - match:
            severity: warning
          receiver: 'email-warning'

    receivers:
      - name: 'email-notifications'
        email_configs:
          - to: '${TEAM_EMAIL}'
            send_resolved: true
            headers:
              Subject: '[{{ .Status | toUpper }}] {{ .GroupLabels.alertname }} - {{ .GroupLabels.namespace }}'
            html: |
              <h2>Alert: {{ .GroupLabels.alertname }}</h2>
              <p><strong>Status:</strong> {{ .Status }}</p>
              <p><strong>Severity:</strong> {{ .GroupLabels.severity }}</p>
              <p><strong>Namespace:</strong> {{ .GroupLabels.namespace }}</p>
              <p><strong>Summary:</strong> {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}</p>
              <p><strong>Description:</strong> {{ range .Alerts }}{{ .Annotations.description }}{{ end }}</p>

      - name: 'email-critical'
        email_configs:
          - to: '${CRITICAL_EMAIL}'
            send_resolved: true
            headers:
              Subject: '🔴 CRITICAL: {{ .GroupLabels.alertname }} - {{ .GroupLabels.namespace }}'
            html: |
              <h1 style="color: red;">🔴 CRITICAL ALERT</h1>
              <h2>{{ .GroupLabels.alertname }}</h2>
              <p><strong>Namespace:</strong> {{ .GroupLabels.namespace }}</p>
              <p><strong>Summary:</strong> {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}</p>
              <p><strong>Description:</strong> {{ range .Alerts }}{{ .Annotations.description }}{{ end }}</p>
              <p><strong>Action Required:</strong> Immediate investigation needed!</p>

      - name: 'email-warning'
        email_configs:
          - to: '${TEAM_EMAIL}'
            send_resolved: true
            headers:
              Subject: '⚠️ WARNING: {{ .GroupLabels.alertname }} - {{ .GroupLabels.namespace }}'
            html: |
              <h2 style="color: orange;">⚠️ WARNING</h2>
              <h3>{{ .GroupLabels.alertname }}</h3>
              <p><strong>Namespace:</strong> {{ .GroupLabels.namespace }}</p>
              <p><strong>Summary:</strong> {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}</p>
              <p><strong>Description:</strong> {{ range .Alerts }}{{ .Annotations.description }}{{ end }}</p>
EOF

echo "🔄 Upgrading Helm release with email configuration..."
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --values values-${ENVIRONMENT}-email.yaml \
  --wait

echo ""
echo "✅ Email notifications configured!"
echo ""
echo "📧 Configuration:"
echo "   SMTP Server: $SMTP_SERVER"
echo "   From: $SMTP_FROM"
echo "   Team Alerts: $TEAM_EMAIL"
echo "   Critical Alerts: $CRITICAL_EMAIL"
echo ""
echo "🧪 Test by triggering an alert or check AlertManager:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
echo ""
echo "⚠️  Note: values-${ENVIRONMENT}-email.yaml contains sensitive data. Add to .gitignore!"
