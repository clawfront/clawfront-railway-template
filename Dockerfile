FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Build with: DOCKER_BUILDKIT=1 docker build --secret id=clawfront_registry_token,env=CLAWFRONT_REGISTRY_TOKEN .
COPY package.json .npmrc ./
RUN --mount=type=secret,id=clawfront_registry_token \
    CLAWFRONT_REGISTRY_TOKEN="$(cat /run/secrets/clawfront_registry_token)" \
    pnpm install --prod --frozen-lockfile=false && \
    rm -f .npmrc

ENV NODE_ENV=production

EXPOSE 3000

CMD ["pnpm", "exec", "clawfront", "start"]
