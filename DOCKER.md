# Docker Setup Guide

## Development Workflow

### Start Development Environment (with hot-reload)

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Start services:**
   ```bash
   docker-compose up -d --build
   ```
   or explicitly:
   ```bash
   docker-compose -f docker-compose.dev.yml up -d --build
   ```

3. **View logs with hot-reload:**
   ```bash
   docker-compose logs -f app
   ```

4. **Make code changes** - Flask will auto-reload!

### Production Deployment

1. **Update .env for production:**
   ```bash
   FLASK_ENV=production
   ```

2. **Start production services:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

3. **Check service health:**
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   ```

## Database Initialization

Database is automatically initialized on first run via `titanic.sql` mounted to `/docker-entrypoint-initdb.d/`

## Testing the API

1. **Check empty database:**
   ```bash
   curl http://localhost:5000/people
   ```

2. **Add a person:**
   ```bash
   curl -H "Content-Type: application/json" -X POST localhost:5000/people \
   -d '{"survived": 2,"passengerClass": 2,"name": "Mr. Owen Harris Braund","sex": "male","age": 22.0,"siblingsOrSpousesAboard": 4,"parentsOrChildrenAboard": 5,"fare": 7.25}'
   ```

3. **Verify addition:**
   ```bash
   curl http://localhost:5000/people
   ```

## Stop Services

```bash
# Development
docker-compose down

# Production
docker-compose -f docker-compose.prod.yml down

# Remove volumes
docker-compose down -v
```

## Image Size Verification

```bash
docker images titanic-api:latest
```

Expected size: < 200MB
