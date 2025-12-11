# Docker Quick Reference

> **Essential commands and configurations at your fingertips**

---

## ⚡ Quick Commands

### Start/Stop Services

```bash
# Start all services
docker compose up -d

# Start with rebuild
docker compose up --build -d

# Stop all services
docker compose down

# Stop + remove volumes
docker compose down -v

# Restart single service
docker compose restart backend

# View status
docker compose ps
```

### View Logs

```bash
# All services
docker compose logs

# Follow logs
docker compose logs -f

# Specific service
docker compose logs backend

# Last 50 lines
docker compose logs --tail 50 backend

# With timestamps
docker compose logs -t backend
```

### Build Images

```bash
# Build all
docker compose build

# Build specific service
docker compose build backend

# No cache
docker compose build --no-cache

# Parallel build
docker compose build --parallel
```

---

## 🏗️ Dockerfile Templates

### Backend/WebSocket (Bun)

```dockerfile
FROM oven/bun:latest AS builder
WORKDIR /app

# Dependencies (cached layer)
COPY package.json ./
COPY packages/db/package.json ./packages/db/
RUN bun install

# Source code
COPY . .
RUN bunx prisma generate
RUN bun run build

# Production
FROM oven/bun:latest
WORKDIR /app
COPY --from=builder /app .
CMD ["bun", "run", "start"]
```

### Next.js (Web)

```dockerfile
FROM oven/bun:latest AS builder
WORKDIR /app

# Install dependencies
COPY package.json ./
COPY packages/*/package.json ./packages/
RUN bun install

# Build
COPY . .
RUN bunx prisma generate
RUN bunx next build

# Production
FROM oven/bun:latest
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
CMD ["bunx", "next", "start"]
```

---

## 📋 docker-compose.yml Template

visit `docker-compose.yml` file

---

## 🐛 Debugging Commands

### Container Inspection

```bash
# Enter container shell
docker compose exec backend sh

# Run command in container
docker compose exec backend env
docker compose exec backend ls -la
docker compose exec backend bun --version

# Container details
docker inspect monorepo-backend

# Container processes
docker top monorepo-backend

# Resource usage
docker stats
docker stats monorepo-backend
```

### Network Debugging

```bash
# List networks
docker network ls

# Inspect network
docker network inspect my_app_default

# Test connectivity
docker compose exec backend ping postgres
docker compose exec backend curl http://web:3000

# Check DNS
docker compose exec backend nslookup postgres
```

### Health Checks

```bash
# Check service health
docker compose ps

# Inspect health
docker inspect --format='{{.State.Health.Status}}' monorepo-backend

# View health log
docker inspect --format='{{json .State.Health}}' monorepo-backend | jq
```

---

## 🔧 Troubleshooting

### Port Conflicts

```bash
# Find process using port
lsof -i :3000
netstat -tulpn | grep 3000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "3001:3000"
```

### Database Issues

```bash
# Check postgres is ready
docker compose exec postgres pg_isready -U postgres

# Connect to database
docker compose exec postgres psql -U postgres -d postgres

# View tables
docker compose exec postgres psql -U postgres -d postgres -c "\dt"

# Run migrations
docker compose exec backend bun run migrate
```

### Container Crashes

```bash
# View crash logs
docker compose logs backend --tail 100

# Restart with rebuild
docker compose up -d --build backend

# Check exit code
docker inspect monorepo-backend --format='{{.State.ExitCode}}'
```

### Disk Space

```bash
# Check usage
docker system df

# Clean up
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Remove stopped containers
docker container prune

# Remove unused volumes
docker volume prune
```

---

## 📦 Image Management

### List Images

```bash
# All images
docker images

# Filter by name
docker images monorepo-*

# Show sizes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Dangling images
docker images -f "dangling=true"
```

### Remove Images

```bash
# Remove specific image
docker rmi monorepo-backend:latest

# Remove multiple
docker rmi $(docker images -q monorepo-*)

# Remove dangling
docker image prune

# Remove all unused
docker image prune -a
```

### Tag Images

```bash
# Tag for registry
docker tag monorepo-backend:latest username/monorepo-backend:v1.0.0

# Push to registry
docker push username/monorepo-backend:v1.0.0

# Pull from registry
docker pull username/monorepo-backend:v1.0.0
```

---

## 🔍 Useful Docker Compose Commands

```bash
# View config
docker compose config

# Validate config
docker compose config --quiet

# List services
docker compose ps --services

# Scale service
docker compose up -d --scale backend=3

# Run one-off command
docker compose run --rm backend bun run migrate

# Execute in running container
docker compose exec backend sh

# Pull latest images
docker compose pull

# Push images
docker compose push
```

---

## 🌐 Networking

### Access Services

| Service | Container Name | Internal | External |
|---------|---------------|----------|----------|
| PostgreSQL | `monorepo-postgres` | `postgres:5432` | `localhost:5432` |
| Backend | `monorepo-backend` | `backend:8082` | `localhost:8082` |
| WebSocket | `monorepo-ws` | `ws:8081` | `localhost:8081` |
| Web | `monorepo-web` | `web:3000` | `localhost:3000` |

### Connection Strings

```bash
# From host machine
DATABASE_URL=postgresql://postgres:supra@localhost:5432/postgres

# From another container
DATABASE_URL=postgresql://postgres:supra@postgres:5432/postgres

# From backend to web
curl http://web:3000
```

---

## 📊 Monitoring

### Resource Usage

```bash
# All containers
docker stats

# Specific container
docker stats monorepo-backend

# No stream (one-time)
docker stats --no-stream

# Format output
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Logs

```bash
# Recent logs
docker compose logs --since 30m

# Until timestamp
docker compose logs --until 2024-12-11T10:00:00

# Specific time range
docker compose logs --since 2024-12-11T09:00:00 --until 2024-12-11T10:00:00

# Grep logs
docker compose logs | grep ERROR
```

---

## 🔐 Security

### Scan for Vulnerabilities

```bash
# Scan image
docker scan monorepo-backend:latest

# Scan with Trivy
trivy image monorepo-backend:latest

# Scan Dockerfile
hadolint docker/Dockerfile.backend
```

### Best Practices

```dockerfile
# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Specific versions
FROM oven/bun:1.0.0  # Not :latest

# Minimal base
FROM alpine:3.18

# No secrets in layers
RUN --mount=type=secret,id=github_token \
    git clone https://$(cat /run/secrets/github_token)@github.com/...
```

---

## 📁 Volume Management

### List Volumes

```bash
# All volumes
docker volume ls

# Find specific
docker volume ls | grep postgres

# Inspect volume
docker volume inspect my_app_postgres_data
```

### Backup/Restore

```bash
# Backup volume
docker run --rm -v my_app_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz /data

# Restore volume
docker run --rm -v my_app_postgres_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-backup.tar.gz -C /
```

### Clean Up

```bash
# Remove specific volume
docker volume rm my_app_postgres_data

# Remove unused volumes
docker volume prune

# Remove with confirmation
docker volume prune -f
```

---

## 🚀 Performance

### BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Use build cache
docker compose build --cache-from monorepo-backend:latest

# Parallel builds
docker compose build --parallel
```

### .dockerignore

```
node_modules
.next
.turbo
dist
build
.git
.env
*.log
.DS_Store
coverage
```

---

## 📝 Environment Variables

### Load from File

```yaml
# docker-compose.yml
services:
  backend:
    env_file:
      - .env
      - .env.local
```

### Override

```bash
# Command line
docker compose up -d -e DATABASE_URL=postgresql://...

# Environment file
echo "DATABASE_URL=postgresql://..." > .env.prod
docker compose --env-file .env.prod up -d
```

---

## ✅ Quick Checklist

### Daily Development

- [ ] `docker compose up -d` - Start services
- [ ] `docker compose ps` - Check status
- [ ] `docker compose logs -f backend` - Monitor logs
- [ ] Make code changes
- [ ] `docker compose restart backend` - Apply changes
- [ ] `docker compose down` - Stop when done

### Troubleshooting

- [ ] `docker compose ps` - Check health
- [ ] `docker compose logs <service>` - View errors
- [ ] `docker compose exec <service> sh` - Debug inside
- [ ] `docker compose restart <service>` - Restart failed service
- [ ] `docker compose up -d --build` - Rebuild if needed

### Cleanup

- [ ] `docker compose down` - Stop services
- [ ] `docker system prune` - Remove unused data
- [ ] `docker volume prune` - Remove unused volumes
- [ ] `docker image prune -a` - Remove unused images

---

**💡 Tip:** Bookmark this page for instant command lookup!
