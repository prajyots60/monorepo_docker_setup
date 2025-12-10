# CI/CD Setup Guide

## Prerequisites

1. **DockerHub Account**
   - Sign up at https://hub.docker.com/
   - Create an access token

2. **GitHub Repository**
   - Push your code to GitHub
   - Configure repository secrets

---

## Setup Instructions

### 1. Create DockerHub Access Token

1. Go to https://hub.docker.com/settings/security
2. Click **"New Access Token"**
3. Name: `github-actions-monorepo`
4. Permissions: **Read, Write, Delete**
5. Click **"Generate"**
6. **Copy the token** (you won't see it again!)

### 2. Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DOCKERHUB_USERNAME` | Your DockerHub username | e.g., `prajyots60` |
| `DOCKERHUB_TOKEN` | Your DockerHub access token | The token from step 1 |

### 3. How It Works

The CI/CD pipeline automatically:

**On Push to `main` or `develop`:**
- ✅ Builds all 3 Docker images (backend, ws, web)
- ✅ Pushes to DockerHub with tags:
  - `latest` (only on main)
  - `main` or `develop` (branch name)
  - `main-<sha>` (commit SHA)

**On Pull Request:**
- ✅ Builds images (doesn't push)
- ✅ Validates Dockerfiles

**On Git Tag (e.g., `v1.0.0`):**
- ✅ Builds and pushes with version tags:
  - `v1.0.0`
  - `1.0`
  - `latest`

### 4. Trigger the Pipeline

```bash
# Commit and push to trigger the workflow
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

### 5. Monitor the Workflow

1. Go to your GitHub repository
2. Click on **"Actions"** tab
3. You'll see the workflow running
4. Click on a workflow run to see details

### 6. Pull Images from DockerHub

Once the workflow completes, your images are available:

```bash
# Pull images
docker pull <your-username>/monorepo-backend:latest
docker pull <your-username>/monorepo-ws:latest
docker pull <your-username>/monorepo-web:latest

# Run containers
docker run -d -p 8082:8082 \
  -e DATABASE_URL="postgresql://postgres:supra@postgres:5432/postgres" \
  <your-username>/monorepo-backend:latest
```

---

## Image Tags Explained

### Branch-based Tags
```
main → latest, main, main-abc1234
develop → develop, develop-abc1234
```

### Version Tags (Git Tags)
```
v1.0.0 → v1.0.0, 1.0, latest
v2.1.3 → v2.1.3, 2.1, latest
```

### Pull Request Tags
```
PR #42 → pr-42
```

---

## Using in Docker Compose

Update your `docker-compose.yml` to use DockerHub images:

```yaml
services:
  backend:
    image: <your-username>/monorepo-backend:latest
    # Remove build section
    environment:
      DATABASE_URL: "postgresql://postgres:supra@postgres:5432/postgres"
    ports:
      - "8082:8082"
    depends_on:
      postgres:
        condition: service_healthy

  ws:
    image: <your-username>/monorepo-ws:latest
    environment:
      DATABASE_URL: "postgresql://postgres:supra@postgres:5432/postgres"
    ports:
      - "8081:8081"

  web:
    image: <your-username>/monorepo-web:latest
    environment:
      DATABASE_URL: "postgresql://postgres:supra@postgres:5432/postgres"
    ports:
      - "3000:3000"
```

Then just:
```bash
docker compose pull  # Pull latest images
docker compose up -d # Start services
```

---

## Workflow Features

### ✅ Matrix Strategy
- Builds all services in parallel
- Faster CI/CD execution

### ✅ Layer Caching
- Uses registry cache for faster rebuilds
- Significant time savings on subsequent builds

### ✅ Multi-platform Support (Optional)
To build for multiple platforms, add to workflow:
```yaml
platforms: linux/amd64,linux/arm64
```

### ✅ Automatic Tagging
- No manual version management
- Git tags automatically become Docker tags

---

## Deployment Options

### Option 1: SSH to Server

Add to the `deploy` job:

```yaml
- name: Deploy to server
  uses: appleboy/ssh-action@master
  with:
    host: ${{ secrets.SERVER_HOST }}
    username: ${{ secrets.SERVER_USER }}
    key: ${{ secrets.SSH_PRIVATE_KEY }}
    script: |
      cd /path/to/app
      docker compose pull
      docker compose up -d
```

**Required secrets:**
- `SERVER_HOST`
- `SERVER_USER`
- `SSH_PRIVATE_KEY`

### Option 2: Kubernetes

```yaml
- name: Deploy to Kubernetes
  run: |
    kubectl set image deployment/backend \
      backend=${{ secrets.DOCKERHUB_USERNAME }}/monorepo-backend:${{ github.sha }}
    kubectl set image deployment/ws \
      ws=${{ secrets.DOCKERHUB_USERNAME }}/monorepo-ws:${{ github.sha }}
    kubectl set image deployment/web \
      web=${{ secrets.DOCKERHUB_USERNAME }}/monorepo-web:${{ github.sha }}
```

### Option 3: AWS ECS

```yaml
- name: Deploy to ECS
  uses: aws-actions/amazon-ecs-deploy-task-definition@v1
  with:
    task-definition: task-definition.json
    service: my-service
    cluster: my-cluster
```

---

## Troubleshooting

### Error: "denied: requested access to the resource is denied"

**Solution:** Check that:
1. DOCKERHUB_USERNAME is correct
2. DOCKERHUB_TOKEN is valid
3. Token has Write permissions

### Error: "build failed"

**Solution:**
1. Check workflow logs in GitHub Actions
2. Test build locally: `docker build -f docker/Dockerfile.backend .`
3. Ensure all dependencies are available

### Images not updating

**Solution:**
```bash
# Force pull latest
docker compose pull
docker compose up -d --force-recreate
```

---

## Best Practices

1. **Use specific tags in production:**
   ```bash
   image: username/monorepo-backend:v1.0.0  # Good
   image: username/monorepo-backend:latest  # Risky
   ```

2. **Always pull before deploying:**
   ```bash
   docker compose pull && docker compose up -d
   ```

3. **Monitor image sizes:**
   ```bash
   docker images | grep monorepo
   ```

4. **Clean up old images:**
   ```bash
   docker image prune -a
   ```

5. **Use semantic versioning for releases:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

---

## Cost Considerations

**DockerHub Free Tier:**
- ✅ Unlimited public repositories
- ✅ 1 private repository
- ✅ Unlimited pulls for public images
- ⚠️ Rate limits: 200 pulls/6 hours (authenticated)

**Upgrade if needed:**
- Docker Pro: $5/month
- Docker Team: $7/user/month

---

## Security Best Practices

1. **Never commit secrets:**
   - Use GitHub Secrets
   - Never hardcode passwords

2. **Use minimal base images:**
   - Already using `alpine` ✅

3. **Scan images for vulnerabilities:**
   ```yaml
   - name: Scan image
     uses: aquasecurity/trivy-action@master
     with:
       image-ref: ${{ secrets.DOCKERHUB_USERNAME }}/monorepo-backend:latest
   ```

4. **Sign images (optional):**
   - Use Docker Content Trust
   - Use Cosign for signing

---

## Next Steps

1. ✅ Set up GitHub secrets
2. ✅ Push code to trigger workflow
3. ✅ Monitor workflow execution
4. ✅ Pull images from DockerHub
5. ✅ Set up automatic deployment (optional)

---

**Need help?** Check the workflow logs in GitHub Actions for detailed error messages.
