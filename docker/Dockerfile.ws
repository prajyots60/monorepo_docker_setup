FROM oven/bun:1-alpine

WORKDIR /app

COPY package.json bun.lock* ./
COPY turbo.json ./

COPY packages/db/package.json ./packages/db/
COPY apps/ws/package.json ./apps/ws/

RUN bun install

COPY packages/db ./packages/db/
COPY apps/ws ./apps/ws/

# Build argument for DATABASE_URL (can be overridden at build time)
ARG DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"
ENV DATABASE_URL=$DATABASE_URL

WORKDIR /app/packages/db
RUN bunx prisma generate

WORKDIR /app/apps/ws
RUN bun run build

EXPOSE 8081

CMD ["bun", "run", "start"]


