FROM node:20-bookworm-slim AS build

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    g++ \
    make \
    git \
    && rm -rf /var/lib/apt/lists/*

USER node
WORKDIR /app

# Create Backstage app
RUN npx @backstage/create-app@latest --skip-install

WORKDIR /app/backstage

# Copy production config
COPY --chown=node:node app-config.production.yaml ./

# Install dependencies and build
RUN yarn install --frozen-lockfile --network-timeout 600000
RUN yarn build:backend

# --- Production stage ---
FROM node:20-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r backstage && useradd -r -g backstage -m backstage

USER backstage
WORKDIR /app

COPY --from=build --chown=backstage:backstage /app/backstage/packages/backend/dist ./packages/backend/dist
COPY --from=build --chown=backstage:backstage /app/backstage/app-config*.yaml ./
COPY --from=build --chown=backstage:backstage /app/backstage/package.json ./
COPY --from=build --chown=backstage:backstage /app/backstage/node_modules ./node_modules

ENV NODE_ENV=production

EXPOSE 7007

CMD ["node", "packages/backend/dist/index.cjs.js"]
