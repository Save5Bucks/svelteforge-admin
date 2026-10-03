FROM node:22-slim AS builder

# Install build dependencies for native modules
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

COPY package.json pnpm-lock.yaml .npmrc ./
RUN pnpm install --frozen-lockfile
RUN cd node_modules/.pnpm/better-sqlite3@12.6.2/node_modules/better-sqlite3 && npm run build-release

COPY . .
RUN DATABASE_URL=:memory: pnpm build

FROM node:22-slim AS runner

# Install runtime dependencies for native modules
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

COPY package.json pnpm-lock.yaml .npmrc ./
RUN pnpm install --frozen-lockfile --prod

# Copy the compiled better-sqlite3 binary from builder
COPY --from=builder /app/node_modules/.pnpm/better-sqlite3@12.6.2/node_modules/better-sqlite3/build ./node_modules/.pnpm/better-sqlite3@12.6.2/node_modules/better-sqlite3/build

COPY --from=builder /app/build ./build
COPY drizzle ./drizzle

ENV NODE_ENV=production
ENV PORT=3000
ENV ORIGIN=http://localhost:3000

EXPOSE 3000

CMD ["node", "build/index.js"]
