FROM oven/bun:1-alpine

WORKDIR /app

COPY package.json bun.lock* ./
COPY turbo.json ./

COPY packages/db/package.json ./packages/db/
COPY apps/ws/package.json ./apps/ws/

RUN bun install

COPY packages/db ./packages/db/
COPY apps/ws ./apps/ws/

COPY .env ./

WORKDIR /app/packages/db
RUN bunx prisma generate

WORKDIR /app/apps/ws
RUN bun run build

EXPOSE 8081

CMD ["bun", "run", "start"]


