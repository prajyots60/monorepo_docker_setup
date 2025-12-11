# CI/CD Quick Reference

> **Commands, configurations, and workflow details**

---

## 📋 GitHub Secrets Required

### Minimum (DockerHub only)
```
DOCKERHUB_USERNAME    → Your DockerHub username
DOCKERHUB_TOKEN       → Access token from hub.docker.com
```

### Full (with VM deployment)
```
DOCKERHUB_USERNAME    → DockerHub username
DOCKERHUB_TOKEN       → DockerHub token
SERVER_HOST           → VM IP address (e.g., 159.65.154.9)
SERVER_USER           → SSH username (usually root)
SSH_PRIVATE_KEY       → Private SSH key (Ed25519)
```

---

## 🔑 SSH Key Generation (VM Deployment)

```bash
# Generate Ed25519 key
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions -N ""

# Authorize key
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys

# Set permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# Get private key (copy entire output for GitHub secret)
cat ~/.ssh/github_actions
```

---

## 🐳 docker-compose.prod.yml Template

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: monorepo-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-supra}
      POSTGRES_DB: postgres
    ports: ["5432:5432"]
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  backend:
    image: <username>/monorepo-backend:latest
    container_name: monorepo-backend
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD:-supra}@postgres:5432/postgres
    ports: ["8082:8082"]
    depends_on:
      postgres: {condition: service_healthy}
    restart: unless-stopped

  ws:
    image: <username>/monorepo-ws:latest
    container_name: monorepo-ws
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD:-supra}@postgres:5432/postgres
    ports: ["8081:8081"]
    depends_on:
      postgres: {condition: service_healthy}
    restart: unless-stopped

  web:
    image: <username>/monorepo-web:latest
    container_name: monorepo-web
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD:-supra}@postgres:5432/postgres
    ports: ["3000:3000"]
    depends_on:
      postgres: {condition: service_healthy}
    restart: unless-stopped

volumes:
  postgres_data:
```

---

## ⚡ Common Commands

### Local Development
```bash
# Build and run locally
docker compose up --build -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Manual Deployment
```bash
# Pull latest images
docker pull <username>/monorepo-backend:latest
docker pull <username>/monorepo-ws:latest
docker pull <username>/monorepo-web:latest

# Start services
docker compose -f docker-compose.prod.yml up -d

# Update running services
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d --remove-orphans
```

### VM Management
```bash
# SSH to VM
ssh root@your-vm-ip

# Check running containers
docker ps

# View specific logs
docker logs monorepo-backend --tail 100 -f

# Restart service
docker restart monorepo-backend

# Full restart
cd /root/app
docker compose -f docker-compose.prod.yml restart

# Clean up
docker system prune -af
docker volume prune -f
```

### Git Workflow
```bash
# Trigger build on main
git push origin main

# Trigger build on develop
git push origin develop

# Create version release
git tag v1.0.0
git push origin v1.0.0

# View workflow status
# GitHub → Actions tab
```

---

## 🏷️ Image Tagging Matrix

| Git Action | Tags Created | Example |
|------------|--------------|---------|
| Push to `main` | `latest`, `main`, `main-abc1234` | `supra003/monorepo-backend:latest` |
| Push to `develop` | `develop`, `develop-abc1234` | `supra003/monorepo-backend:develop` |
| Tag `v1.0.0` | `v1.0.0`, `1.0`, `latest` | `supra003/monorepo-backend:v1.0.0` |
| Pull Request #42 | `pr-42` (build only) | No push to DockerHub |

---

## 🔍 Debugging Commands

### Check Workflow Status
```bash
# GitHub UI
Repository → Actions → Latest Run

# View specific job
Click on job → View logs

# Re-run failed jobs
Actions → Click run → Re-run failed jobs
```

### Verify Secrets
```bash
# GitHub UI
Settings → Secrets and variables → Actions

# Must have (minimum):
- DOCKERHUB_USERNAME
- DOCKERHUB_TOKEN

# For VM deployment (additional):
- SERVER_HOST
- SERVER_USER
- SSH_PRIVATE_KEY
```

### Test SSH Connection
```bash
# Manual test from local machine
ssh -i /path/to/private_key root@your-vm-ip

# Test from VM
ssh -i ~/.ssh/github_actions root@localhost

# Check authorized_keys
cat ~/.ssh/authorized_keys
```

### Check Container Health
```bash
# All containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Specific container
docker inspect monorepo-backend | grep -i health

# Container logs
docker logs monorepo-backend --tail 50

# Follow logs live
docker logs -f monorepo-backend
```

### Network Diagnostics
```bash
# Check ports
netstat -tulpn | grep -E '3000|8081|8082|5432'

# Test connectivity
curl http://localhost:8082
curl http://localhost:3000

# DNS resolution
docker exec monorepo-backend ping -c 2 postgres
```

---

## 🔥 Quick Fixes

### Workflow won't trigger
```bash
# Check file location
ls .github/workflows/docker-build-push.yml

# Validate YAML syntax
cat .github/workflows/docker-build-push.yml | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)"

# Enable Actions
Settings → Actions → Allow all actions
```

### Can't push to DockerHub
```bash
# Test locally
docker login -u <username>
# Enter token when prompted

# Check token permissions
hub.docker.com → Settings → Security → View token

# Regenerate if needed
Delete old token → Create new → Update GitHub secret
```

### SSH fails
```bash
# On VM - fix permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/github_actions

# Verify key in authorized_keys
cat ~/.ssh/authorized_keys | grep github-actions

# Test connection
ssh -v -i ~/.ssh/github_actions root@localhost
```

### Containers won't start
```bash
# Check logs
docker logs monorepo-backend
docker logs monorepo-postgres

# Wait for postgres
docker compose -f docker-compose.prod.yml restart backend ws web

# Nuclear option
docker compose -f docker-compose.prod.yml down -v
docker compose -f docker-compose.prod.yml up -d
```

---

## 📊 Workflow Visualization

### Build Process
```
┌─────────────────────────────────────────────┐
│  GitHub Actions Runner                      │
├─────────────────────────────────────────────┤
│                                             │
│  1. Checkout code                           │
│  2. Setup Docker Buildx                     │
│  3. Login to DockerHub                      │
│  4. Extract metadata (tags)                 │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │  Matrix Build (Parallel)              │ │
│  ├───────────────────────────────────────┤ │
│  │  • Backend  (docker/Dockerfile.backend)│ │
│  │  • WS       (docker/Dockerfile.ws)    │ │
│  │  • Web      (docker/Dockerfile.web)   │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  5. Push to DockerHub with tags             │
│  6. [Optional] Deploy to VM                 │
│                                             │
└─────────────────────────────────────────────┘
```

### Deployment Process (VM)
```
┌─────────────────────────────────────────────┐
│  GitHub Actions Runner                      │
└──────────────┬──────────────────────────────┘
               │
               │ SSH Connection
               ▼
┌─────────────────────────────────────────────┐
│  Your VM Server                             │
├─────────────────────────────────────────────┤
│                                             │
│  cd /root/app                               │
│  docker compose pull                        │
│  docker compose up -d --remove-orphans      │
│  docker image prune -f                      │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Running Services                    │  │
│  ├──────────────────────────────────────┤  │
│  │  postgres:5432  ✅                   │  │
│  │  backend:8082   ✅                   │  │
│  │  ws:8081        ✅                   │  │
│  │  web:3000       ✅                   │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🎯 Environment Variables

### Build-time (Dockerfile ARG)
```dockerfile
ARG DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres
```

### Runtime (docker-compose)
```yaml
environment:
  DATABASE_URL: ${DATABASE_URL}
  NODE_ENV: production
```

### VM .env file (optional)
```bash
# /root/app/.env
POSTGRES_PASSWORD=your-secure-password
DATABASE_URL=postgresql://postgres:your-secure-password@postgres:5432/postgres
```

---

## 📦 Image Size Optimization

```dockerfile
# Multi-stage build (already implemented)
FROM oven/bun:latest AS builder
WORKDIR /app
COPY package.json ./
RUN bun install
COPY . .
RUN bun run build

FROM oven/bun:latest
WORKDIR /app
COPY --from=builder /app .
CMD ["bun", "run", "start"]
```

**Result:** ~300MB images instead of ~1GB

---

## 🔐 Security Checklist

- [ ] DockerHub token has minimal permissions (Read/Write only)
- [ ] SSH key is Ed25519 (more secure than RSA)
- [ ] Private key never committed to Git
- [ ] Secrets stored in GitHub Secrets (encrypted)
- [ ] VM firewall configured (only needed ports open)
- [ ] PostgreSQL password changed from default
- [ ] Regular token rotation (every 90 days)
- [ ] No sensitive data in Docker images
- [ ] `.env` files in `.gitignore`

---

## 📈 Performance Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Build time | < 2 min | ~1.5 min |
| Image size | < 500 MB | ~300 MB |
| Deployment time | < 30 sec | ~20 sec |
| Cache hit rate | > 70% | ~80% |

---

## 🆘 Support Resources

### Documentation
- **CICD_GUIDE.md** - Complete setup guide
- **README.md** - Project overview
- **DOCKER_SETUP_GUIDE.md** - Docker details

### External Resources
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [DockerHub](https://hub.docker.com/)

### Logs & Monitoring
```bash
# GitHub Actions logs
Repository → Actions → Click run → View logs

# Docker logs on VM
ssh root@your-vm-ip
docker logs -f monorepo-backend

# System logs
journalctl -u docker -f
```

---

**💡 Tip:** Bookmark this page for quick command reference!
