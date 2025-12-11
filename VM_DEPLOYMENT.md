# VM Deployment Guide - DigitalOcean

Quick guide for deploying to a DigitalOcean VM with automated CI/CD.

---

## 🚀 One-Time VM Setup (15 minutes)

### Step 1: Install Docker

```bash
# SSH to your VM
ssh root@your-vm-ip

# Install Docker (one command)
curl -fsSL https://get.docker.com | sh

# Verify
docker --version
docker compose version
```

### Step 2: Create docker-compose.prod.yml

```bash
# Create app directory
mkdir -p /root/app
cd /root/app

# Create docker-compose.prod.yml
nano docker-compose.prod.yml
```

**Paste your `docker-compose.prod.yml` content** (copy from your repo), then save (Ctrl+X, Y, Enter).

### Step 3: Generate SSH Key for GitHub Actions

**This allows GitHub to automatically deploy to your VM.**

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions -N ""

# Add to authorized_keys (allows GitHub to login)
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys

# Set permissions
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# Display PRIVATE key (copy ENTIRE output)
cat ~/.ssh/github_actions
```

**Important:** Copy the entire output including:
- `-----BEGIN OPENSSH PRIVATE KEY-----`
- All the middle content
- `-----END OPENSSH PRIVATE KEY-----`

### Step 4: Add GitHub Secrets

Go to: **GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

Add these 5 secrets:

| Secret Name | Value | Example |
|------------|-------|---------|
| `DOCKERHUB_USERNAME` | Your DockerHub username | `supra003` |
| `DOCKERHUB_TOKEN` | DockerHub access token | `dckr_pat_xxxxx` |
| `SERVER_HOST` | Your VM IP address | `159.65.154.9` |
| `SERVER_USER` | SSH username | `root` |
| `SSH_PRIVATE_KEY` | Entire private key from Step 3 | `-----BEGIN OPENSSH...` |

### Step 5: Deploy!

```bash
# Push to main branch
git add .
git commit -m "feat: setup vm deployment"
git push origin main
```

**GitHub Actions will automatically:**
1. ✅ Build Docker images
2. ✅ Push to DockerHub
3. ✅ SSH to your VM
4. ✅ Pull latest images
5. ✅ Restart all services

**Total time:** ~30-40 seconds ⚡

### Step 6: Verify

```bash
# Check containers running
ssh root@your-vm-ip
docker ps

# Should see 4 containers:
# - monorepo-postgres
# - monorepo-backend
# - monorepo-ws
# - monorepo-web
```

**Access your app:**
- 🌐 Web: http://your-vm-ip:3000
- 🔌 Backend: http://your-vm-ip:8082
- 💬 WebSocket: ws://your-vm-ip:8081

---

## 🐛 Troubleshooting

### Issue: SSH Authentication Failed

**Error:** `ssh: no key found` or `ssh: handshake failed`

**Fix:**
- Ensure you copied the ENTIRE private key (including BEGIN/END lines)
- No extra spaces or line breaks
- Check permissions: `chmod 600 ~/.ssh/authorized_keys`

### Issue: docker-compose.prod.yml Not Found

**Error:** `No such file or directory`

**Fix:**
```bash
# On your VM
cd /root/app
ls -la  # Check if file exists

# If missing, recreate it (Step 2)
```

### Issue: Containers Not Starting

**Fix:**
```bash
# Check logs
docker logs monorepo-backend --tail 50
docker logs monorepo-postgres --tail 50

# Restart services
docker compose -f docker-compose.prod.yml restart
```

### Issue: Port Already in Use

**Fix:**
```bash
# Check what's using the port
netstat -tulpn | grep -E '3000|8081|8082'

# Stop old containers
docker compose -f docker-compose.prod.yml down

# Start fresh
docker compose -f docker-compose.prod.yml up -d
```

---

## 🔄 Manual Deployment (Backup Method)

If CI/CD fails, deploy manually:

```bash
# SSH to VM
ssh root@your-vm-ip
cd /root/app

# Pull latest images
docker compose -f docker-compose.prod.yml pull

# Restart services
docker compose -f docker-compose.prod.yml up -d --remove-orphans

# Check status
docker ps
```

---

## ✅ Success Checklist

- [ ] Docker installed on VM
- [ ] `/root/app/docker-compose.prod.yml` exists
- [ ] SSH key generated and added to authorized_keys
- [ ] 5 GitHub secrets added correctly
- [ ] CI/CD workflow runs successfully (check Actions tab)
- [ ] `docker ps` shows 4 running containers
- [ ] App accessible on ports 3000, 8081, 8082

---

## 📝 Key Points

- **No repo cloning needed** - Docker Compose pulls pre-built images from DockerHub
- **One-time setup** - After this, just push code to deploy
- **Automatic deployment** - Every push to `main` triggers deployment
- **Zero-downtime** - Docker Compose handles graceful restarts
- **Rollback safe** - If deployment fails, old containers keep running

---

## 🎯 How CI/CD Works

```
Push to main → GitHub Actions Triggers
  ↓
Build 3 Docker Images (parallel)
  ↓
Push to DockerHub
  ↓
SSH to Your VM
  ↓
Pull Latest Images
  ↓
Restart Services
  ↓
✅ Deployed!
```

**See `.github/workflows/docker-build-push.yml` for full workflow.**

---

**Questions?** Check `CI_CD_SETUP.md` for detailed CI/CD configuration.
