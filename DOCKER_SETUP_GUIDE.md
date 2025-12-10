# Docker Monorepo Setup Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Environment Variables Strategy](#environment-variables-strategy)
4. [Dockerfile Best Practices](#dockerfile-best-practices)
5. [Common Issues & Solutions](#common-issues--solutions)
6. [Build & Run Commands](#build--run-commands)
7. [Docker Compose Setup](#docker-compose-setup)
8. [Optimization Techniques](#optimization-techniques)

---

## Overview

This monorepo contains 4 services:
- **PostgreSQL** - Database (Port 5432)
- **Backend API** - Express server (Port 8082)
- **WebSocket Server** - Bun WebSocket (Port 8081)
- **Next.js Web** - Frontend (Port 3000)

**Tech Stack:**
- Runtime: Bun
- Database: PostgreSQL + Prisma
- Frontend: Next.js 16
- Backend: Express
- WebSocket: Bun native WebSocket

---

## Architecture

### Project Structure
```
my_app/
├── apps/
│   ├── backend/         # Express API
│   ├── ws/              # WebSocket server
│   └── web/             # Next.js frontend
├── packages/
│   ├── db/              # Prisma schema & client
│   ├── ui/              # Shared UI components
│   ├── eslint-config/   # Shared ESLint config
│   └── typescript-config/ # Shared TS config
├── docker/
│   ├── Dockerfile.backend
│   ├── Dockerfile.ws
│   └── Dockerfile.web
├── docker-compose.yml
└── .env                 # Root environment variables
```

### Service Dependencies
```
PostgreSQL (postgres)
    ↓
    ├── Backend API (depends on postgres)
    ├── WebSocket (depends on postgres)
    └── Next.js Web (depends on postgres)
```

---

## Environment Variables Strategy

### Problem: Multiple .env Files vs Single Source of Truth

**❌ Bad Approach:**
```
apps/backend/.env
apps/ws/.env
apps/web/.env
packages/db/.env
```
**Issues:** Duplication, inconsistency, maintenance nightmare

**✅ Good Approach:**
```
my_app/.env  (single source of truth)
```

### Solution Implementation

**1. Root `.env` file:**
```bash
# /my_app/.env
DATABASE_URL="postgresql://postgres:supra@localhost:5432/postgres"
```

**2. Updated `packages/db/index.ts`:**
```typescript
import dotenv from 'dotenv';
import path from 'path';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';

// Load .env from monorepo root (2 levels up)
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const connectionString = process.env.DATABASE_URL as string;

console.log("db url from client", connectionString);

const pgPool = new pg.Pool({ connectionString });
const adapter = new PrismaPg(pgPool);
const prismaClient = new PrismaClient({ adapter });

export default prismaClient;
```

**3. For Next.js (requires `.env.local`):**
```bash
# apps/web/.env.local
DATABASE_URL="postgresql://postgres:supra@localhost:5432/postgres"
```

**Why Next.js needs separate file:**
- Next.js has built-in env loading (doesn't use dotenv)
- Automatically loads `.env.local`, `.env`, etc.
- `.env.local` is git-ignored and takes precedence

### Docker Environment Variables

**Build Time vs Runtime:**

| Phase | Purpose | Method |
|-------|---------|--------|
| **Build Time** | Prisma generate, Next.js build | `ARG` + `ENV` in Dockerfile |
| **Runtime** | App execution | `docker run -e` or docker-compose `environment` |

**Example:**
```dockerfile
# Build time
ARG DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"
ENV DATABASE_URL=$DATABASE_URL

# Runtime (overrides build-time value)
docker run -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres"
```

---

## Dockerfile Best Practices

### 1. Layer Caching Optimization

**Problem:** Changing code forces reinstalling all dependencies

**❌ Bad - No Caching:**
```dockerfile
COPY . .
RUN bun install  # Runs every time ANY file changes
```

**✅ Good - Optimal Caching:**
```dockerfile
# Step 1: Copy only dependency files
COPY package.json bun.lock* ./
COPY packages/db/package.json ./packages/db/
COPY apps/backend/package.json ./apps/backend/

# Step 2: Install (cached if package.json unchanged)
RUN bun install

# Step 3: Copy source code (changes frequently)
COPY packages/db ./packages/db/
COPY apps/backend ./apps/backend/
```

**How it works:**
1. First build: Install everything (slow)
2. Code change: Skip install, reuse cache (fast ⚡)
3. Dependency change: Reinstall (slow, but necessary)

### 2. Why Copy Package.json First?

Docker builds in **layers**. Each layer is cached:

```
Layer 1: COPY package.json     ← Cached (rarely changes)
Layer 2: RUN bun install       ← Cached (depends on Layer 1)
Layer 3: COPY source code      ← Always runs (changes often)
```

**Real-world example:**
```bash
# First build
docker build .  # 60 seconds

# Change index.ts (no dependency changes)
docker build .  # 5 seconds (bun install skipped!)

# Add new package
docker build .  # 60 seconds (bun install runs again)
```

### 3. Complete Dockerfile Pattern

```dockerfile
FROM oven/bun:1-alpine

WORKDIR /app

# 1. Copy root workspace files
COPY package.json bun.lock* ./
COPY turbo.json ./

# 2. Copy all package.json files (for dependency resolution)
COPY packages/db/package.json ./packages/db/
COPY apps/backend/package.json ./apps/backend/

# 3. Install dependencies (cached if no package.json changes)
RUN bun install

# 4. Copy source code
COPY packages/db ./packages/db/
COPY apps/backend ./apps/backend/

# 5. Copy .env for build-time Prisma generation
COPY .env ./

# 6. Generate Prisma Client
WORKDIR /app/packages/db
RUN bunx prisma generate

# 7. Build the application
WORKDIR /app/apps/backend
RUN bun run build

# 8. Expose port
EXPOSE 8082

# 9. Start command
CMD ["bun", "run", "start"]
```

---

## Common Issues & Solutions

### Issue 1: DATABASE_URL is undefined in apps

**Symptom:**
```
db url from client undefined
```

**Root Cause:**
- The db package loads `.env` from monorepo root
- Apps running in their own directories can't find `../../.env`

**Solution:**
Update `packages/db/index.ts` to use absolute path:
```typescript
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
```

---

### Issue 2: WebSocket user creation not persisting

**Symptom:**
```typescript
prismaClient.user.create({ data: {...} })  // Not saving
```

**Root Cause:**
Missing `await` - promise never executes

**Solution:**
```typescript
// ❌ Wrong
message(ws, message) {
    prismaClient.user.create({...})  // Promise created but not awaited
}

// ✅ Correct
async message(ws, message) {
    await prismaClient.user.create({...})  // Actually executes
}
```

---

### Issue 3: Server exits immediately after starting

**Symptom:**
```
Server is running on http://localhost:8080
[returns to prompt]
```

**This is NORMAL!** The server is running in the background. Test with:
```bash
curl http://localhost:8080/
```

To see it "actively running" without returning prompt:
```bash
bun run index.ts  # Blocks terminal until Ctrl+C
```

---

### Issue 4: Dockerfile copies .env but still uses wrong DATABASE_URL

**Understanding Build vs Runtime:**

```dockerfile
COPY .env ./  # For build-time (Prisma generate)
```

This `.env` is used during `docker build` for Prisma generation. At runtime, you can override:

```bash
docker run -e DATABASE_URL="different-url" my-image
```

**Runtime value always wins!**

---

### Issue 5: Next.js fails during build - "Can't reach database"

**Symptom:**
```
Error occurred prerendering page "/"
Can't reach database server at build time
```

**Root Cause:**
Next.js tries to statically pre-render pages at build time. If page uses database, build fails.

**Solutions:**

**Option 1: Force Dynamic Rendering**
```tsx
// app/page.tsx
export const dynamic = 'force-dynamic';  // Skip static generation

export default async function Home() {
  const users = await prismaClient.user.findMany();
  // ...
}
```

**Option 2: Use Build-Time Database**
```bash
docker build --network=host \
  --build-arg DATABASE_URL="postgresql://localhost:5432/db" \
  -t app .
```

**Option 3: Use ISR (Incremental Static Regeneration)**
```tsx
export const revalidate = 60;  // Regenerate every 60 seconds

export default async function Home() {
  const users = await prismaClient.user.findMany();
  // ...
}
```

---

### Issue 6: `bun install --frozen-lockfile` fails in Docker

**Symptom:**
```
error: lockfile had changes, but lockfile is frozen
```

**Root Cause:**
Lockfile is out of sync with package.json

**Solutions:**

**Option 1: Update lockfile locally**
```bash
bun install  # Updates bun.lock
git add bun.lock
git commit -m "Update lockfile"
```

**Option 2: Remove flag in Dockerfile**
```dockerfile
RUN bun install  # Instead of bun install --frozen-lockfile
```

---

### Issue 7: Prisma migrations fail - "schema not found"

**Symptom:**
```
Error: Could not find Prisma Schema
Checked: schema.prisma, prisma/schema.prisma
```

**Root Cause:**
Running migrations from wrong directory

**Solution:**
Update package.json scripts:
```json
{
  "scripts": {
    "migrate": "cd ../../packages/db && bunx prisma migrate deploy",
    "start": "bun run migrate && bun run dist/index.js"
  }
}
```

---

## Build & Run Commands

### Local Development (Without Docker)

```bash
# Install dependencies
bun install

# Run database migrations
cd packages/db && bunx prisma migrate dev

# Start services
cd apps/backend && bun run dev    # Port 8082
cd apps/ws && bun run dev         # Port 8081
cd apps/web && bun run dev        # Port 3000
```

### Docker Build Commands

**Backend:**
```bash
docker build -t monorepo-backend:latest -f docker/Dockerfile.backend .
```

**WebSocket:**
```bash
docker build -t monorepo-ws:latest -f docker/Dockerfile.ws .
```

**Next.js Web:**
```bash
docker build -t monorepo-web:latest -f docker/Dockerfile.web .
```

### Docker Run Commands

**Important:** Replace `172.17.0.2` with your actual PostgreSQL container IP.

Find your PostgreSQL IP:
```bash
docker inspect <postgres-container-name> --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

**Backend:**
```bash
docker run -d -p 8082:8082 \
  --name monorepo-backend \
  -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres" \
  monorepo-backend:latest
```

**WebSocket:**
```bash
docker run -d -p 8081:8081 \
  --name monorepo-ws \
  -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres" \
  monorepo-ws:latest
```

**Next.js Web:**
```bash
docker run -d -p 3000:3000 \
  --name monorepo-web \
  -e DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres" \
  monorepo-web:latest
```

### Docker Management Commands

**View logs:**
```bash
docker logs <container-name>
docker logs -f <container-name>  # Follow logs
```

**Stop containers:**
```bash
docker stop monorepo-backend monorepo-ws monorepo-web
```

**Remove containers:**
```bash
docker rm monorepo-backend monorepo-ws monorepo-web
```

**View running containers:**
```bash
docker ps
docker ps -a  # Include stopped containers
```

**Remove images:**
```bash
docker rmi monorepo-backend:latest monorepo-ws:latest monorepo-web:latest
```

---

## Docker Compose Setup

**File: `docker-compose.yml`**

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: monorepo-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: supra
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Backend API
  backend:
    build:
      context: .
      dockerfile: docker/Dockerfile.backend
    container_name: monorepo-backend
    environment:
      DATABASE_URL: "postgresql://postgres:supra@postgres:5432/postgres"
      NODE_ENV: production
    ports:
      - "8082:8082"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  # WebSocket Server
  ws:
    build:
      context: .
      dockerfile: docker/Dockerfile.ws
    container_name: monorepo-ws
    environment:
      DATABASE_URL: "postgresql://postgres:supra@postgres:5432/postgres"
      NODE_ENV: production
    ports:
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  # Next.js Web App
  web:
    build:
      context: .
      dockerfile: docker/Dockerfile.web
    container_name: monorepo-web
    environment:
      DATABASE_URL: "postgresql://postgres:supra@postgres:5432/postgres"
      NODE_ENV: production
    ports:
      - "3000:3000"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

volumes:
  postgres_data:
```

### Docker Compose Commands

```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Build and start
docker-compose up --build

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs
docker-compose logs -f backend  # Follow specific service

# Restart a service
docker-compose restart backend
```

### Key Docker Compose Features

**1. Service Discovery:**
- Services can communicate using service names
- Example: `postgres` as hostname instead of IP address

**2. Health Checks:**
```yaml
depends_on:
  postgres:
    condition: service_healthy
```
- Backend waits for PostgreSQL to be ready before starting

**3. Networking:**
- All services on same network automatically
- Can communicate: `backend → postgres`, `ws → postgres`, etc.

**4. Volume Persistence:**
```yaml
volumes:
  postgres_data:/var/lib/postgresql/data
```
- Database data survives container restarts

---

## Optimization Techniques

### 1. Multi-Stage Builds (Advanced)

**Purpose:** Smaller final images, separate build and runtime dependencies

```dockerfile
# Stage 1: Builder
FROM oven/bun:1-alpine AS builder

WORKDIR /app

# Copy and install
COPY package.json bun.lock* ./
COPY packages/ ./packages/
COPY apps/backend ./apps/backend/

RUN bun install
RUN cd packages/db && bunx prisma generate
RUN cd apps/backend && bun run build

# Stage 2: Runtime
FROM oven/bun:1-alpine

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app/apps/backend/dist ./apps/backend/dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/db ./packages/db

WORKDIR /app/apps/backend

CMD ["bun", "run", "start:prod"]
```

**Benefits:**
- 50-70% smaller images
- No build tools in production image
- More secure (fewer attack vectors)

### 2. .dockerignore File

**File: `.dockerignore`**

```
# Dependencies
node_modules
npm-debug.log
yarn-error.log
bun.lock

# Build outputs
dist
.next
.turbo
*.tsbuildinfo

# Environment
.env
.env*.local

# Git
.git
.gitignore

# IDE
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Testing
coverage
*.test.ts
*.spec.ts

# Docs
README.md
*.md
```

**Benefits:**
- Faster builds (less context to send)
- Smaller images
- Prevents accidental secret leakage

### 3. Production Dependencies Only

```dockerfile
RUN bun install --production
```

**Consideration:** TypeScript build needs dev dependencies, so:
- Build with dev dependencies
- Install production-only in final stage (multi-stage build)

### 4. Leverage Build Cache

**Use BuildKit (Docker 18.09+):**
```bash
DOCKER_BUILDKIT=1 docker build .
```

**Cache mounts:**
```dockerfile
RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install
```

---

## Package.json Scripts Pattern

### Backend / WebSocket

```json
{
  "scripts": {
    "dev": "bun --watch index.ts",
    "build": "bun build ./index.ts --target bun --outfile dist/index.js",
    "migrate": "cd ../../packages/db && bunx prisma migrate deploy",
    "start": "bun run migrate && bun run dist/index.js",
    "start:prod": "bun run dist/index.js"
  }
}
```

### Next.js Web

```json
{
  "scripts": {
    "dev": "next dev --port 3000",
    "build": "next build",
    "migrate": "cd ../../packages/db && bunx prisma migrate deploy",
    "start": "bun run migrate && next start",
    "start:prod": "next start"
  }
}
```

**Why separate `start` and `start:prod`?**
- `start`: Runs migrations + server (for Docker)
- `start:prod`: Server only (for environments with separate migration jobs)

---

## Networking in Docker

### Container-to-Container Communication

**Scenario:** Backend container needs to connect to PostgreSQL container

**Option 1: Use Container IP**
```bash
# Find IP
docker inspect postgres-container --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
# Output: 172.17.0.2

# Use in DATABASE_URL
DATABASE_URL="postgresql://postgres:supra@172.17.0.2:5432/postgres"
```

**Option 2: Use Docker Network (Better)**
```bash
# Create network
docker network create myapp-network

# Run containers on same network
docker run --network=myapp-network --name postgres postgres
docker run --network=myapp-network --name backend \
  -e DATABASE_URL="postgresql://postgres:supra@postgres:5432/postgres" \
  backend-image
```

**Option 3: Docker Compose (Best)**
- Automatic network creation
- Use service names as hostnames
- Example: `@postgres:5432` instead of `@172.17.0.2:5432`

### Host-to-Container

**Access from host machine:**
- Use `localhost` with mapped port
- Example: `http://localhost:8082`

**Container-to-Host:**
- Linux: `host.docker.internal` or `172.17.0.1`
- Example: Connect to host PostgreSQL from container

---

## Security Best Practices

### 1. Don't Commit Secrets

```bash
# .gitignore
.env
.env.local
.env*.local
```

### 2. Use Build Arguments for Sensitive Data

```dockerfile
ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL
```

```bash
docker build --build-arg DATABASE_URL=$DATABASE_URL .
```

### 3. Run as Non-Root User (Production)

```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

### 4. Use Specific Image Tags

```dockerfile
# ❌ Bad
FROM bun:latest

# ✅ Good
FROM oven/bun:1-alpine
```

---

## Debugging Tips

### 1. Check Container Logs

```bash
docker logs <container-name>
docker logs -f <container-name>  # Follow
docker logs --tail 100 <container-name>  # Last 100 lines
```

### 2. Execute Commands Inside Container

```bash
docker exec -it <container-name> sh
docker exec <container-name> ls -la /app
docker exec <container-name> env  # View environment variables
```

### 3. Inspect Container

```bash
docker inspect <container-name>
docker inspect <container-name> --format='{{.NetworkSettings.IPAddress}}'
```

### 4. Check Port Bindings

```bash
docker port <container-name>
netstat -tulpn | grep <port>
```

### 5. Test Database Connection

```bash
# From inside container
docker exec -it <container-name> sh
bun -e "console.log(process.env.DATABASE_URL)"
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Backend
        run: |
          docker build -t backend:${{ github.sha }} \
            -f docker/Dockerfile.backend .
      
      - name: Build WebSocket
        run: |
          docker build -t ws:${{ github.sha }} \
            -f docker/Dockerfile.ws .
      
      - name: Build Web
        run: |
          docker build -t web:${{ github.sha }} \
            -f docker/Dockerfile.web .
      
      - name: Push to Registry
        run: |
          docker push backend:${{ github.sha }}
          docker push ws:${{ github.sha }}
          docker push web:${{ github.sha }}
```

---

## Performance Metrics

### Build Times (Approximate)

| Service | First Build | Cached Build | With Code Change |
|---------|-------------|--------------|------------------|
| Backend | ~60s | ~5s | ~10s |
| WebSocket | ~55s | ~5s | ~8s |
| Next.js | ~120s | ~5s | ~45s |

### Image Sizes

| Service | Size (Single-Stage) | Size (Multi-Stage) |
|---------|---------------------|---------------------|
| Backend | ~450MB | ~180MB |
| WebSocket | ~430MB | ~170MB |
| Next.js | ~780MB | ~320MB |

---

## Troubleshooting Checklist

- [ ] PostgreSQL container is running
- [ ] DATABASE_URL is correct for environment
- [ ] Ports are not already in use
- [ ] Prisma schema is in `packages/db/prisma/schema.prisma`
- [ ] Migrations are up to date
- [ ] `.env` file exists at monorepo root
- [ ] `bun.lock` is committed and up to date
- [ ] All package.json files are copied before `bun install`
- [ ] Source code is copied after `bun install`
- [ ] Container has network access to database
- [ ] Logs don't show errors (`docker logs <container>`)

---

## Quick Reference

### Ports
- PostgreSQL: 5432
- Backend API: 8082
- WebSocket: 8081
- Next.js: 3000

### Database Credentials
- User: postgres
- Password: supra
- Database: postgres

### Important Paths
- Prisma Schema: `packages/db/prisma/schema.prisma`
- Migrations: `packages/db/prisma/migrations/`
- Root .env: `my_app/.env`
- Dockerfiles: `docker/Dockerfile.*`

---

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Bun Documentation](https://bun.sh/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Changelog

- **2025-12-10**: Initial setup with backend, ws, and web Dockerfiles
- **2025-12-10**: Implemented centralized .env strategy
- **2025-12-10**: Fixed Next.js static generation with database
- **2025-12-10**: Optimized layer caching in all Dockerfiles

---

**Created by:** Prajyot  
**Date:** December 10, 2025  
**Last Updated:** December 10, 2025
