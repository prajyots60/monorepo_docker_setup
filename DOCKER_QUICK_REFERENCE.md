# Docker Monorepo - Quick Reference

## 🚀 Quick Start

```bash
# Start all services with Docker Compose
docker-compose up -d

# Or build and start
docker-compose up --build -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## 🏗️ Build Images

```bash
# Backend
docker build -t monorepo-backend:latest -f docker/Dockerfile.backend .

# WebSocket
docker build -t monorepo-ws:latest -f docker/Dockerfile.ws .

# Next.js Web
docker build -t monorepo-web:latest -f docker/Dockerfile.web .
```

## ▶️ Run Containers

**Get PostgreSQL IP first:**
```bash
docker inspect <postgres-container> --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

**Run services:**
```bash
# Backend
docker run -d -p 8082:8082 --name monorepo-backend \
  -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres" \
  monorepo-backend:latest

# WebSocket
docker run -d -p 8081:8081 --name monorepo-ws \
  -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres" \
  monorepo-ws:latest

# Web
docker run -d -p 3000:3000 --name monorepo-web \
  -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres" \
  monorepo-web:latest
```

## 🛑 Stop & Clean

```bash
# Stop containers
docker stop monorepo-backend monorepo-ws monorepo-web

# Remove containers
docker rm monorepo-backend monorepo-ws monorepo-web

# Remove images
docker rmi monorepo-backend:latest monorepo-ws:latest monorepo-web:latest

# Docker Compose cleanup
docker-compose down
docker-compose down -v  # Also remove volumes
```

## 📊 Monitoring

```bash
# View logs
docker logs monorepo-backend
docker logs -f monorepo-ws  # Follow logs
docker logs --tail 50 monorepo-web  # Last 50 lines

# Container status
docker ps
docker ps -a  # Include stopped

# Resource usage
docker stats

# Inspect container
docker inspect monorepo-backend
```

## 🐛 Debugging

```bash
# Enter container shell
docker exec -it monorepo-backend sh

# Run command in container
docker exec monorepo-backend env  # View environment variables
docker exec monorepo-backend ls -la /app

# Check database connection
docker exec monorepo-backend bun -e "console.log(process.env.DATABASE_URL)"

# Restart container
docker restart monorepo-backend
```

## 📝 Common Tasks

### Update Code and Rebuild

```bash
# 1. Stop containers
docker-compose down

# 2. Rebuild images
docker-compose build

# 3. Start again
docker-compose up -d
```

### Run Migrations Manually

```bash
# From host
cd packages/db
bunx prisma migrate deploy

# Inside container
docker exec monorepo-backend sh -c "cd /app/packages/db && bunx prisma migrate deploy"
```

### Test Endpoints

```bash
# Backend API
curl http://localhost:8082/

# Next.js Web
curl http://localhost:3000/

# Check health
curl -I http://localhost:8082/
```

## 🔑 Environment Variables

### Local Development
```bash
# Root .env
DATABASE_URL="postgresql://postgres:supra@localhost:5432/postgres"

# apps/web/.env.local (for Next.js)
DATABASE_URL="postgresql://postgres:supra@localhost:5432/postgres"
```

### Docker
```bash
# Use container IP or service name
DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres"

# With Docker Compose (use service name)
DATABASE_URL="postgresql://postgres:supra@postgres:5432/postgres"
```

## 🐳 Docker Compose Commands

```bash
# Start
docker-compose up                    # Foreground
docker-compose up -d                 # Background
docker-compose up --build            # Build and start

# Stop
docker-compose stop                  # Stop services
docker-compose down                  # Stop and remove
docker-compose down -v               # Stop, remove, and delete volumes

# Logs
docker-compose logs                  # All services
docker-compose logs -f backend       # Follow specific service
docker-compose logs --tail=100       # Last 100 lines

# Individual services
docker-compose restart backend       # Restart one service
docker-compose stop web              # Stop one service
docker-compose build ws              # Rebuild one service
```

## 🎯 Port Mapping

| Service | Container Port | Host Port | Access URL |
|---------|---------------|-----------|------------|
| PostgreSQL | 5432 | 5432 | `localhost:5432` |
| Backend | 8082 | 8082 | `http://localhost:8082` |
| WebSocket | 8081 | 8081 | `ws://localhost:8081` |
| Next.js | 3000 | 3000 | `http://localhost:3000` |

## ⚠️ Common Issues

### Issue: Port already in use
```bash
# Find process using port
lsof -i :8082
netstat -tulpn | grep 8082

# Kill process
kill -9 <PID>

# Or use different port
docker run -p 8083:8082 ...
```

### Issue: Container exits immediately
```bash
# Check logs for errors
docker logs <container-name>

# Check exit code
docker ps -a  # Look at STATUS column
```

### Issue: Can't connect to database
```bash
# 1. Check if PostgreSQL is running
docker ps | grep postgres

# 2. Verify DATABASE_URL
docker exec <container> env | grep DATABASE_URL

# 3. Test connection
docker exec <container> sh -c "cd /app/packages/db && bunx prisma db pull"
```

### Issue: Image build fails
```bash
# Clear cache and rebuild
docker build --no-cache -t myimage .

# Check build logs carefully
docker build -t myimage . 2>&1 | tee build.log
```

## 📦 Package.json Scripts

### Backend / WebSocket
```json
{
  "dev": "bun --watch index.ts",
  "build": "bun build ./index.ts --target bun --outfile dist/index.js",
  "migrate": "cd ../../packages/db && bunx prisma migrate deploy",
  "start": "bun run migrate && bun run dist/index.js",
  "start:prod": "bun run dist/index.js"
}
```

### Next.js Web
```json
{
  "dev": "next dev --port 3000",
  "build": "next build",
  "migrate": "cd ../../packages/db && bunx prisma migrate deploy",
  "start": "bun run migrate && next start",
  "start:prod": "next start"
}
```

## 🔄 Workflow

### Development
```bash
# 1. Install dependencies
bun install

# 2. Run migrations
cd packages/db && bunx prisma migrate dev

# 3. Start services locally
cd apps/backend && bun run dev
cd apps/ws && bun run dev
cd apps/web && bun run dev
```

### Docker Build & Run
```bash
# 1. Build images
docker-compose build

# 2. Start services
docker-compose up -d

# 3. Check logs
docker-compose logs -f

# 4. Test
curl http://localhost:8082/
curl http://localhost:3000/
```

### Deploy
```bash
# 1. Tag images
docker tag monorepo-backend:latest registry.example.com/backend:v1.0

# 2. Push to registry
docker push registry.example.com/backend:v1.0

# 3. Deploy to server
docker pull registry.example.com/backend:v1.0
docker run -d -p 8082:8082 registry.example.com/backend:v1.0
```

## 💡 Pro Tips

1. **Use BuildKit for faster builds:**
   ```bash
   DOCKER_BUILDKIT=1 docker build .
   ```

2. **Prune unused resources regularly:**
   ```bash
   docker system prune -a
   docker volume prune
   ```

3. **Use .dockerignore to speed up builds:**
   - Exclude `node_modules`, `dist`, `.git`, etc.

4. **Layer caching saves time:**
   - Copy `package.json` before source code
   - Only rebuild layers that changed

5. **Check image sizes:**
   ```bash
   docker images
   ```

6. **Use specific tags, not `latest`:**
   ```dockerfile
   FROM oven/bun:1-alpine  # Good
   FROM bun:latest         # Bad
   ```

---

**Need more details?** See `DOCKER_SETUP_GUIDE.md` for comprehensive documentation.
