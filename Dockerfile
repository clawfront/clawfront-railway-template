## syntax=docker/dockerfile:1

# ── Stage 1: Clone ClawFront source ─────────────────────────────────────
FROM alpine:3.21 AS source

RUN apk add --no-cache git

ARG CLAWFRONT_REGISTRY_TOKEN
ARG CLAWFRONT_VERSION=main
RUN git clone --depth 1 --branch "${CLAWFRONT_VERSION}" \
    "https://x-access-token:${CLAWFRONT_REGISTRY_TOKEN}@github.com/clawfront/clawfront.git" /src

# ── Stage 2: Build frontend assets ──────────────────────────────────────
FROM node:22-alpine AS frontend

WORKDIR /build
COPY --from=source /src/frontend/package.json frontend/
COPY --from=source /src/package.json /src/pnpm-lock.yaml /src/pnpm-workspace.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile --filter @clawfront/clawfront-frontend

COPY --from=source /src/frontend/ frontend/
COPY --from=source /src/tailwind.config.cjs ./
RUN cd frontend && npx vite build

# ── Stage 3: Build Rust binary ───────────────────────────────────────────
FROM rust:1.85-alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /build
COPY --from=source /src/backend/ .

RUN cargo build --release && strip target/release/clawfront

# ── Stage 4: Install OpenClaw via npm ────────────────────────────────────
FROM node:22-slim AS openclaw

WORKDIR /openclaw
COPY package.json ./
RUN npm install --omit=dev

# ── Stage 5: Minimal runtime ────────────────────────────────────────────
FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl cron ca-certificates chromium && \
    rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV CHROMIUM_PATH=/usr/bin/chromium

WORKDIR /app

COPY --from=builder /build/target/release/clawfront /usr/local/bin/clawfront
COPY --from=frontend /build/frontend/dist /app/frontend/dist
COPY --from=source /src/frontend/public /app/frontend/public
COPY --from=openclaw /openclaw/node_modules /app/node_modules

ENV PATH="/app/node_modules/.bin:$PATH"
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["clawfront"]
CMD ["start", "--port", "3000", "--root-dir", "/data"]
