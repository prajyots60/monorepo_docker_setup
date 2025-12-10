# Full-Stack Monorepo with Docker & CI/CD

> **A production-ready microservices application** built with Turborepo, Bun, Next.js, Express, WebSocket, PostgreSQL, Docker, and automated CI/CD pipeline.

---

## 🏗️ Architecture Overview

This project demonstrates a **complete end-to-end microservices architecture** with real-time capabilities, containerization, and automated deployment.

```
┌─────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS CI/CD                     │
│  (Build → Test → Push to DockerHub → Deploy)               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       DOCKERHUB REGISTRY                     │
│  monorepo-backend:latest | monorepo-ws:latest | monorepo-web│
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    DOCKER COMPOSE ORCHESTRATION             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Next.js    │  │   Express    │  │  WebSocket   │     │
│  │   Frontend   │  │   REST API   │  │    Server    │     │
│  │  (port 3000) │  │  (port 8082) │  │  (port 8081) │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         └──────────────────┼──────────────────┘             │
│                            ↓                                │
│                  ┌─────────────────┐                        │
│                  │  Shared DB Pkg  │                        │
│                  │ Prisma Client   │                        │
│                  └────────┬────────┘                        │
│                            ↓                                │
│                  ┌─────────────────┐                        │
│                  │   PostgreSQL    │                        │
│                  │  (port 5432)    │                        │
│                  └─────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Project Structure

```
my_app/
├── apps/                      # Microservices
│   ├── backend/               # Express REST API
│   │   ├── index.ts          # User & Todo CRUD endpoints
│   │   └── Dockerfile        # Backend container
│   ├── web/                   # Next.js frontend
│   │   ├── app/page.tsx      # Server-side rendering with Prisma
│   │   └── Dockerfile        # Frontend container
│   └── ws/                    # WebSocket server
│       ├── index.ts          # Real-time user creation
│       └── Dockerfile        # WebSocket container
│
├── packages/                  # Shared libraries
│   ├── db/                    # Database package
│   │   ├── index.ts          # Prisma singleton with PrismaPg adapter
│   │   └── prisma/
│   │       └── schema.prisma # Database schema (User, Todo models)
│   ├── ui/                    # Shared React components
│   ├── eslint-config/         # Shared ESLint configs
│   └── typescript-config/     # Shared TypeScript configs
│
├── docker/                    # Docker configurations
│   ├── Dockerfile.backend
│   ├── Dockerfile.ws
│   └── Dockerfile.web
│
├── .github/workflows/         # CI/CD pipeline
│   └── docker-build-push.yml # Automated builds & deployments
│
├── docker-compose.yml         # Development orchestration
├── docker-compose.prod.yml    # Production orchestration
├── deploy.sh                  # Deployment automation script
└── .env                       # Environment variables
```

---

## 🚀 Technology Stack

### **Runtime & Frameworks**
- **Bun** - Ultra-fast JavaScript runtime (3x faster than Node.js)
- **Next.js 16** - React framework with Turbopack
- **Express 5.2** - Minimal REST API framework
- **Bun Native WebSocket** - Built-in WebSocket support

### **Database & ORM**
- **PostgreSQL 16** - Reliable relational database
- **Prisma** - Type-safe database ORM
- **PrismaPg Adapter** - Connection pooling for PostgreSQL

### **DevOps & Infrastructure**
- **Docker** - Container runtime
- **Docker Compose** - Multi-container orchestration
- **GitHub Actions** - CI/CD automation
- **DockerHub** - Container registry

### **Monorepo Management**
- **Turborepo** - High-performance build system
- **Shared packages** - Code reusability across services

---

## 🎯 What We Achieved

### 1. **Microservices Architecture**
- ✅ **Backend API**: REST endpoints for users and todos
- ✅ **WebSocket Server**: Real-time bidirectional communication
- ✅ **Frontend**: Server-side rendered Next.js app
- ✅ **Database Layer**: Centralized Prisma client shared across services

### 2. **Environment Variable Management**
- ✅ **Local Development**: Root `.env` file loaded by `db` package
- ✅ **Docker Containers**: Environment variables passed via `docker-compose.yml`
- ✅ **No Hardcoding**: All secrets configurable at runtime

### 3. **Docker Optimization**
- ✅ **Multi-stage Builds**: Smaller production images
- ✅ **Layer Caching**: Faster rebuilds (copy `package.json` first)
- ✅ **Health Checks**: Auto-restart unhealthy containers
- ✅ **Networking**: Services communicate via Docker network

### 4. **CI/CD Pipeline**
- ✅ **Automated Builds**: Push to GitHub → Builds Docker images
- ✅ **Parallel Execution**: 3 services build simultaneously
- ✅ **Smart Tagging**: `latest`, `branch`, `SHA`, semantic versions
- ✅ **DockerHub Integration**: Automatic push to registry
- ✅ **Production Ready**: Pull and deploy anywhere

### 5. **Development Experience**
- ✅ **One Command Deploy**: `./deploy.sh dev build`
- ✅ **Hot Reload**: All services support live reloading
- ✅ **Clean Scripts**: `bun run start`, `bun run migrate`
- ✅ **Comprehensive Docs**: Step-by-step guides for everything

---

## 🔄 Application Flow

### **User Creation Flow (Real-time)**
```
1. Client connects to WebSocket (ws://localhost:8081)
   ↓
2. WebSocket server receives connection
   ↓
3. Server creates user in PostgreSQL via Prisma
   await prismaClient.user.create({ ... })
   ↓
4. User data persisted to database
   ↓
5. Frontend fetches users via REST API
   GET http://localhost:8082/app/user
   ↓
6. Next.js page displays users (SSR)
```

### **REST API Flow**
```
Client Request → Express Server → Prisma Client → PostgreSQL
                      ↓
                 JSON Response
```

### **CI/CD Flow**
```
Code Push → GitHub Actions Trigger → Build Docker Images →
Push to DockerHub → Deploy to Production → Health Checks
```

---

## 🛠️ Key Learnings

### **1. Monorepo Benefits**
- **Code Sharing**: Single `db` package used by all services
- **Consistent Tooling**: Shared ESLint, TypeScript configs
- **Atomic Changes**: Update schema once, affects all apps
- **Faster Development**: No need to publish packages to npm

### **2. Docker Best Practices**
- **Layer Caching**: Copy dependencies before source code
  ```dockerfile
  COPY package.json ./  # ← Changes rarely
  RUN bun install
  COPY . .              # ← Changes often
  ```
- **ARG vs ENV**: `ARG` for build-time, `ENV` for runtime
- **Health Checks**: Ensure services are ready before accepting traffic
- **Multi-stage Builds**: Separate build and runtime stages

### **3. Database Connection Pooling**
- **Problem**: Multiple services = multiple connections
- **Solution**: PrismaPg adapter with connection pooling
  ```typescript
  const adapter = new PrismaPg(connectionString, { max: 10 })
  new PrismaClient({ adapter })
  ```
- **Benefit**: Efficient resource usage, prevents connection exhaustion

### **4. Environment Variable Strategy**
- **Local**: Load from root `.env` in `db` package
  ```typescript
  dotenv.config({ path: path.resolve(__dirname, '../../.env') })
  ```
- **Docker**: Pass via `docker-compose.yml`
  ```yaml
  environment:
    - DATABASE_URL=${DATABASE_URL}
  ```
- **Production**: Use secrets management (GitHub Secrets, AWS Secrets Manager)

### **5. CI/CD Pipeline Design**
- **Matrix Strategy**: Build multiple services in parallel
  ```yaml
  strategy:
    matrix:
      service: [backend, ws, web]
  ```
- **Caching**: Docker layer cache speeds up builds by 70%
- **Smart Tagging**: Version control for images
  - `latest`: Always use latest
  - `main-abc123`: Specific commit
  - `v1.0.0`: Semantic versioning

### **6. Next.js with Database**
- **Problem**: Static generation fails with database queries
- **Solution**: Force dynamic rendering
  ```typescript
  export const dynamic = 'force-dynamic'
  ```
- **Why**: Server components need runtime database access

### **7. Async/Await in Event Handlers**
- **Problem**: WebSocket messages weren't persisting users
- **Root Cause**: Missing `await` keyword
  ```typescript
  // ❌ Wrong
  message(ws, message) { prismaClient.user.create(...) }
  
  // ✅ Correct
  async message(ws, message) { await prismaClient.user.create(...) }
  ```
- **Lesson**: Always await database operations in event handlers

---

## 🚦 Quick Start

### **Development**
```bash
# Start all services
docker compose up --build -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### **Production**
```bash
# Pull images from DockerHub
docker compose -f docker-compose.prod.yml pull

# Start production services
docker compose -f docker-compose.prod.yml up -d
```

### **Using Deploy Script**
```bash
chmod +x deploy.sh

# Development mode
./deploy.sh dev build

# Production mode
./deploy.sh prod pull
```

---

## 📊 Service Endpoints

| Service | Port | Endpoint | Description |
|---------|------|----------|-------------|
| **Web** | 3000 | http://localhost:3000 | Next.js frontend |
| **Backend** | 8082 | http://localhost:8082 | REST API |
| **WebSocket** | 8081 | ws://localhost:8081 | Real-time server |
| **PostgreSQL** | 5432 | localhost:5432 | Database |

### **API Routes**

#### Users
- `GET /app/user` - Get all users
- `POST /app/user` - Create user
- `GET /app/user/:id` - Get user by ID
- `PUT /app/user/:id` - Update user
- `DELETE /app/user/:id` - Delete user

#### Todos
- `GET /app/todo` - Get all todos
- `POST /app/todo` - Create todo
- `GET /app/todo/:id` - Get todo by ID
- `PUT /app/todo/:id` - Update todo
- `DELETE /app/todo/:id` - Delete todo

---

## 🔧 Configuration Files

### **Environment Variables (.env)**
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mydb
```

### **Docker Compose (docker-compose.yml)**
- 4 services: postgres, backend, ws, web
- Health checks for all services
- Automatic restart on failure
- Shared network for inter-service communication

### **GitHub Actions (.github/workflows/docker-build-push.yml)**
- Triggers: Push to `main`/`develop`, pull requests
- Jobs: Build 3 Docker images in parallel
- Output: Images pushed to DockerHub with tags

---

## 📚 Documentation

Comprehensive guides are available:

- **[DOCKER_SETUP_GUIDE.md](./DOCKER_SETUP_GUIDE.md)** - Complete Docker setup walkthrough
- **[DOCKER_QUICK_REFERENCE.md](./DOCKER_QUICK_REFERENCE.md)** - Common Docker commands
- **[CI_CD_SETUP.md](./CI_CD_SETUP.md)** - CI/CD pipeline configuration
- **[CI_CD_COMPLETE.md](./CI_CD_COMPLETE.md)** - CI/CD quick summary

---

## 🎓 Lessons Learned

1. **Monorepos are powerful** - Shared packages eliminate code duplication
2. **Docker is essential** - Consistent environments across dev/staging/prod
3. **Layer caching matters** - Proper Dockerfile order = 10x faster builds
4. **Health checks save time** - Catch issues before they reach users
5. **CI/CD automates everything** - Push code, get deployed containers
6. **Environment variables are tricky** - Local vs Docker vs Production strategies differ
7. **Async/await is critical** - Event handlers must await database operations
8. **Connection pooling is necessary** - Multiple services need efficient DB access
9. **Documentation is worth it** - Future you will thank present you
10. **Automation beats manual work** - Scripts like `deploy.sh` prevent human error

---

## 🐛 Troubleshooting

### **Database connection issues**
```bash
# Check if PostgreSQL is running
docker compose ps postgres

# View database logs
docker compose logs postgres

# Restart database
docker compose restart postgres
```

### **Service not starting**
```bash
# Check service logs
docker compose logs [backend|ws|web]

# Rebuild specific service
docker compose up --build [service_name]
```

### **Port conflicts**
```bash
# Stop old containers
docker compose down

# Remove all containers
docker compose down -v
```

---

## 🚀 Next Steps

- [ ] Add authentication (JWT, OAuth)
- [ ] Implement Redis caching
- [ ] Add Kubernetes deployment
- [ ] Set up monitoring (Prometheus, Grafana)
- [ ] Add E2E tests (Playwright, Cypress)
- [ ] Implement rate limiting
- [ ] Add API documentation (Swagger)
- [ ] Set up staging environment
- [ ] Add database backups
- [ ] Implement blue-green deployments

---

## 🤝 Contributing

This project is a learning resource. Feel free to:
- Fork and experiment
- Report issues
- Suggest improvements
- Share your learnings

---

## 📄 License

MIT - Do whatever you want with this code!

---

## 🙏 Acknowledgments

Built with ❤️ using modern tools:
- Turborepo team for the monorepo starter
- Bun team for the blazing-fast runtime
- Vercel for Next.js
- Prisma team for the amazing ORM
- Docker team for containerization
- GitHub team for CI/CD tools

---

**⭐ Star this repo if you found it helpful!**

**📖 Check the documentation folder for detailed guides on every aspect of this project.**
