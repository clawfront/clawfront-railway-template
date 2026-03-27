FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends git curl cron ca-certificates chromium && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV CHROMIUM_PATH=/usr/bin/chromium

WORKDIR /app

# Railway-compatible auth path using build arg
ARG CLAWFRONT_REGISTRY_TOKEN
RUN test -n "$CLAWFRONT_REGISTRY_TOKEN" || (echo "ERROR: CLAWFRONT_REGISTRY_TOKEN build arg is required" && exit 1)

ENV CLAWFRONT_REGISTRY_TOKEN=${CLAWFRONT_REGISTRY_TOKEN}

COPY package.json .npmrc ./
RUN npm install --omit=dev && \
    rm -f .npmrc

ENV PATH="/app/node_modules/.bin:$PATH"    
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "exec", "clawfront", "start"]
