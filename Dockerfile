FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Railway-compatible auth path using build arg
ARG CLAWFRONT_REGISTRY_TOKEN
RUN test -n "$CLAWFRONT_REGISTRY_TOKEN" || (echo "ERROR: CLAWFRONT_REGISTRY_TOKEN build arg is required" && exit 1)

ENV CLAWFRONT_REGISTRY_TOKEN=${CLAWFRONT_REGISTRY_TOKEN}

COPY package.json .npmrc ./
RUN pnpm install --prod --frozen-lockfile=false && \
    rm -f .npmrc

ENV NODE_ENV=production

EXPOSE 3000

CMD ["pnpm", "exec", "clawfront", "start"]
