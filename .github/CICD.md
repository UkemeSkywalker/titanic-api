# CI/CD Pipeline Documentation

## Overview

Automated CI/CD pipeline using GitHub Actions with testing, security scanning, Docker image building, and email notifications.

## Pipeline Stages

### 1. Test & Lint
- Python linting with flake8
- Code formatting check with black
- Unit tests with pytest
- Code coverage (70% threshold)
- Runs on every push and PR

### 2. Security Scan
- Trivy vulnerability scanner for filesystem
- Results uploaded to GitHub Security tab
- Runs after successful tests

### 3. Build & Push
- Multi-platform Docker build (amd64, arm64)
- Semantic versioning tags
- Push to GitHub Container Registry (ghcr.io)
- Image vulnerability scanning
- Build cache optimization
- Only runs on push to main/develop

### 4. Notify
- Email notifications on pipeline completion
- Includes status, commit info, and run link

## Setup Instructions

### 1. Repository Secrets

Add these secrets in GitHub: Settings → Secrets and variables → Actions

```
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_TO=recipient@example.com
```

**Gmail App Password Setup:**
1. Enable 2FA on your Google account
2. Go to: https://myaccount.google.com/apppasswords
3. Generate app password for "Mail"
4. Use this password in `EMAIL_PASSWORD` secret

### 2. Enable GitHub Packages

The pipeline pushes images to GitHub Container Registry (ghcr.io):
- No additional setup needed
- Uses `GITHUB_TOKEN` automatically
- Images: `ghcr.io/YOUR_USERNAME/titanic-api`

### 3. Image Tagging Strategy

Images are tagged with:
- `latest` - Latest main branch build
- `main` - Main branch builds
- `develop` - Develop branch builds
- `v1.2.3` - Semantic version tags (on releases)
- `1.2` - Major.minor version
- `1` - Major version
- `main-abc1234` - Branch + commit SHA

### 4. Local Testing

```bash
# Install dev dependencies
pip install -r requirements.txt -r requirements-dev.txt

# Run linting
flake8 src/
black --check src/

# Run tests
pytest tests/ --cov=src --cov-report=term

# Format code
black src/
```

### 5. Pull Docker Images

```bash
# Pull latest image
docker pull ghcr.io/YOUR_USERNAME/titanic-api:latest

# Pull specific version
docker pull ghcr.io/YOUR_USERNAME/titanic-api:v1.0.0

# Run container
docker run -p 5000:5000 \
  -e DATABASE_URL=postgresql+psycopg2://user:password@host:5432/postgres \
  ghcr.io/YOUR_USERNAME/titanic-api:latest
```

## Triggering the Pipeline

### Automatic Triggers
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Creating a release

### Manual Trigger
Go to Actions tab → Select workflow → Run workflow

## Monitoring

- **Actions Tab**: View pipeline runs and logs
- **Security Tab**: View vulnerability scan results
- **Packages**: View published Docker images
- **Email**: Receive notifications on completion

## Best Practices Implemented

✅ Parallel job execution (test, security run independently)  
✅ Build caching (pip cache, Docker layer cache)  
✅ Semantic versioning for releases  
✅ Multi-platform builds (amd64, arm64)  
✅ Security scanning (code + container images)  
✅ Code quality gates (coverage threshold)  
✅ Secrets management via GitHub Secrets  
✅ Non-root container execution  
✅ Minimal base images  
✅ Email notifications  

## Troubleshooting

### Tests Failing
- Check database connection in workflow
- Verify `titanic.sql` is in repository root
- Review test logs in Actions tab

### Build Failing
- Verify Dockerfile syntax
- Check all dependencies in requirements.txt
- Review build logs for errors

### Email Not Sending
- Verify Gmail app password is correct
- Check email secrets are set correctly
- Ensure 2FA is enabled on Gmail account

### Image Not Pushing
- Verify GitHub Packages is enabled
- Check `GITHUB_TOKEN` permissions
- Ensure workflow has `packages: write` permission
