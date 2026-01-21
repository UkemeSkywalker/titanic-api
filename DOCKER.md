# Docker Setup Guide

## Quick Start

### Using Docker Compose (Recommended)

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Build and start services:**
   ```bash
   docker-compose up -d --build
   ```

3. **Check service health:**
   ```bash
   docker-compose ps
   ```

4. **View logs:**
   ```bash
   docker-compose logs -f app
   ```

5. **Stop services:**
   ```bash
   docker-compose down
   ```

6. **Stop and remove volumes:**
   ```bash
   docker-compose down -v
   ```

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

## Manual Docker Build

```bash
docker build -t titanic-api:latest .
docker run -p 5000:5000 -e DATABASE_URL=postgresql+psycopg2://user:password@host:5432/postgres titanic-api:latest
```

## Image Size Verification

```bash
docker images titanic-api:latest
```

Expected size: < 200MB
