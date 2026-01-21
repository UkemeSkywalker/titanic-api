# titanic-api: Flask

Implemented using [Flask][] microframework.

![Titanic API](images/image.png)

## Docker Setup (Recommended)

### Development Workflow

#### Start Development Environment (with hot-reload)

1. **Clone and setup:**
   ```bash
   git clone https://github.com/PipeOpsHQ/titanic-api.git
   cd titanic-api
   cp .env.example .env
   ```

2. **Start services:**
   ```bash
   docker-compose up -d --build
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f app
   ```

4. **Make code changes** - Flask will auto-reload!

#### Production Deployment

1. **Update .env for production:**
   ```bash
   FLASK_ENV=production
   ```

2. **Start production services:**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

#### Database Initialization

Database is automatically initialized on first run via `titanic.sql`

#### Testing the API

1. **Check database:**
   ```bash
   curl http://localhost:5000/people
   ```

2. **Add a person:**
   ```bash
   curl -H "Content-Type: application/json" -X POST localhost:5000/people \
   -d '{"survived": 2,"passengerClass": 2,"name": "Mr. Owen Harris Braund","sex": "male","age": 22.0,"siblingsOrSpousesAboard": 4,"parentsOrChildrenAboard": 5,"fare": 7.25}'
   ```

3. **Verify:**
   ```bash
   curl http://localhost:5000/people
   ```

#### Stop Services

```bash
docker-compose down
# Remove volumes: docker-compose down -v
```

### Image Optimization & Security

#### Multi-stage Build
- **Builder stage**: Compiles dependencies with build tools (gcc, libpq-dev)
- **Production stage**: Only runtime dependencies (libpq5), reducing image size by ~60%
- Final image: < 200MB

#### Security Features
- **Non-root user**: Application runs as `appuser` (UID 1000), not root
- **Minimal base**: python:3.11-slim reduces attack surface
- **No cache**: `--no-cache-dir` prevents storing sensitive data
- **Layer optimization**: Dependencies installed before code for better caching

#### Health Checks
- Database: `pg_isready` every 10s
- Application: HTTP endpoint check every 30s
- Automatic restart on failure

#### Verify Image Size
```bash
docker images titanic-api:latest
```

## Manual Installation

### Clone

Clone the repo:

``` bash
git clone https://github.com/PipeOpsHQ/titanic-api.git
cd titanic-api
```

### Install

Use [venv][] or any other ([Pipenv][], [Poetry][], etc) [environment management][] tool to install dependencies in the same folder.
Activate virtual environment and run:

``` bash
pip install -r requirements.txt
```

### Launch

This API was tested using postgres. In order to bring it up, the following commands are needed:

1) Start postgres locally with `docker run --net=host --name titanic-db -e POSTGRES_PASSWORD=password -e POSTGRES_USER=user -d postgres`
for macbook use `docker run -p 5432:5432 --name titanic-db -e POSTGRES_PASSWORD=password -e POSTGRES_USER=user -d postgres`
3) Run the sql file with the database definition `docker cp titanic.sql titanic-db:/`
4) Run the sql file with `docker exec -it titanic-db psql -U user -d postgres -f titanic.sql`


After you have database server deployed and running, use environment variable `DATABASE_URL` to provide database connection string.

``` bash
DATABASE_URL=postgresql+psycopg2://user:password@127.0.0.1:5432/postgres python run.py
```

Go to <http://127.0.0.1:5000/> in your browser.

Test it by:
1) See the database is currently empty with: `http://127.0.0.1:5000/people`
2) Add a new user with `curl -H "Content-Type: application/json" -X POST localhost:5000/people -d'{"survived": 2,"passengerClass": 2,"name": "Mr. Owen Harris Braund","sex": "male","age": 22.0,"siblingsOrSpousesAboard": 4,"parentsOrChildrenAboard": 5,"fare": 7.25}'`
3) Check out if the user was added with `http://127.0.0.1:5000/people`

[Flask]: http://flask.pocoo.org/
[venv]: https://docs.python.org/3/tutorial/venv.html
[Pipenv]: https://pipenv.pypa.io/en/latest/
[Poetry]: https://python-poetry.org/docs/
[environment management]: http://docs.python-guide.org/en/latest/dev/virtualenvs/
