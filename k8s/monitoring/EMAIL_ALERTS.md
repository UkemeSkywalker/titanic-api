# Email Alert Configuration

## Overview
AlertManager sends email notifications for all alerts. SMTP credentials are securely stored in AWS Secrets Manager.

## Quick Setup

### 1. Apply Terraform (Create Secret Placeholder)
```bash
cd infra
./deploy.sh <dev|staging|prod> apply module.secrets
```

### 2. Store SMTP Credentials in AWS Secrets Manager
```bash
cd k8s/monitoring
./store-smtp-secret.sh <dev|staging|prod>
```

Prompts for:
- SMTP server (e.g., `smtp.gmail.com:587`)
- From email address
- SMTP username and password
- Team and critical alert emails

### 3. Sync Secrets to Kubernetes
```bash
./sync-alertmanager-secrets.sh <dev|staging|prod>
```

### 4. Configure AlertManager
```bash
./configure-email-alerts.sh <dev|staging|prod>
```

## Gmail Setup (Recommended for Testing)

### 1. Enable 2-Factor Authentication
Go to Google Account → Security → 2-Step Verification

### 2. Create App Password
1. Go to https://myaccount.google.com/apppasswords
2. Select "Mail" and "Other (Custom name)"
3. Name it "AlertManager"
4. Copy the 16-character password

### 3. Configure AlertManager
```bash
./configure-email-alerts.sh <dev|staging|prod>

# When prompted:
SMTP Server: smtp.gmail.com:587
From Email: your-email@gmail.com
SMTP Username: your-email@gmail.com
SMTP Password: [paste 16-char app password]
Team Email: team@example.com
Critical Email: oncall@example.com
```

## Other SMTP Providers

### AWS SES
```
SMTP Server: email-smtp.us-east-1.amazonaws.com:587
Username: [Your SMTP username]
Password: [Your SMTP password]
```

### SendGrid
```
SMTP Server: smtp.sendgrid.net:587
Username: apikey
Password: [Your SendGrid API key]
```

### Office 365
```
SMTP Server: smtp.office365.com:587
Username: your-email@company.com
Password: [Your password]
```

## Alert Routing

### Default Behavior
- **All Alerts** → Team email
- **Critical Alerts** → On-call email (+ team email)
- **Warning Alerts** → Team email only

### Email Format

**Critical Alerts:**
```
Subject: 🔴 CRITICAL: HighErrorRate - titanic-api-prod
Body: HTML formatted with red header, alert details, action required
```

**Warning Alerts:**
```
Subject: ⚠️ WARNING: HighLatency - titanic-api-prod
Body: HTML formatted with orange header, alert details
```

**Resolved Alerts:**
```
Subject: [RESOLVED] HighErrorRate - titanic-api-prod
Body: Alert has been resolved
```

## Testing

### 1. Check AlertManager Config
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Visit http://localhost:9093/#/status
```

### 2. Trigger Test Alert
```bash
# Create a test alert
kubectl run test-crash --image=busybox --restart=Never -n titanic-api-dev -- sh -c "exit 1"

# Wait 5 minutes for PodCrashLooping alert
# Check email inbox
```

### 3. Send Test Notification
```bash
# Port forward to AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Send test alert via API
curl -X POST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "warning",
    "namespace": "titanic-api-dev"
  },
  "annotations": {
    "summary": "This is a test alert",
    "description": "Testing email notifications"
  }
}]'
```

## Troubleshooting

### No Emails Received

1. **Check AlertManager logs:**
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager
```

2. **Verify SMTP credentials:**
```bash
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o yaml
```

3. **Test SMTP connection:**
```bash
# From a pod
kubectl run smtp-test --rm -it --image=alpine -- sh
apk add curl
curl -v --url 'smtp://smtp.gmail.com:587' --mail-from 'from@example.com' --mail-rcpt 'to@example.com' --user 'user:pass'
```

### Gmail Blocking Emails

- Ensure 2FA is enabled
- Use App Password, not account password
- Check "Less secure app access" is OFF (use App Password instead)
- Check Gmail spam folder

### Rate Limiting

AlertManager groups alerts to prevent spam:
- `group_wait: 10s` - Wait before sending first alert
- `group_interval: 10s` - Wait between grouped alerts
- `repeat_interval: 12h` - Don't repeat same alert for 12 hours

## Security Best Practices

1. **Credentials stored in AWS Secrets Manager**
```bash
# Secret path: <env>/titanic/alertmanager-smtp
# Managed by Terraform
```

2. **Never commit SMTP credentials to Git**
```bash
echo "values-*-email.yaml" >> .gitignore
```

3. **Sync secrets workflow**
```bash
# Store in AWS
./store-smtp-secret.sh dev

# Sync to Kubernetes
./sync-alertmanager-secrets.sh dev

# Configure AlertManager
./configure-email-alerts.sh dev
```

4. **Rotate credentials regularly**
```bash
# Update in AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id dev/titanic/alertmanager-smtp \
  --secret-string '{...}'

# Re-sync
./sync-alertmanager-secrets.sh dev
./configure-email-alerts.sh dev
```

## Advanced Configuration

### Multiple Recipients
```yaml
receivers:
  - name: 'email-notifications'
    email_configs:
      - to: 'team@example.com, dev@example.com, ops@example.com'
```

### Time-based Routing
```yaml
route:
  routes:
    - match:
        severity: critical
      receiver: 'email-critical'
      active_time_intervals:
        - business_hours
```

### Custom Templates
See `alertmanager-config.yaml` for template examples.

## Cost Considerations

- **Gmail**: Free (500 emails/day limit)
- **AWS SES**: $0.10 per 1,000 emails
- **SendGrid**: Free tier (100 emails/day)
- **Office 365**: Included with subscription
