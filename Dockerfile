FROM node:20-alpine AS deps

WORKDIR /app

COPY package*.json ./

RUN npm ci


FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules

COPY package*.json ./

COPY tsconfig.json tsconfig.build.json nest-cli.json ./

COPY src ./src

RUN npm run build

RUN npm prune --omit=dev


FROM gcr.io/distroless/nodejs20-debian12:nonroot AS runner

WORKDIR /app

ARG VERSION=dev
ARG COMMIT_SHA=unknown
ARG BUILD_DATE=unknown

ENV APP_VERSION=$VERSION
ENV COMMIT_SHA=$COMMIT_SHA
ENV BUILD_DATE=$BUILD_DATE

LABEL org.opencontainers.image.version="$VERSION"
LABEL org.opencontainers.image.revision="$COMMIT_SHA"
LABEL org.opencontainers.image.created="$BUILD_DATE"

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

USER nonroot

EXPOSE 3000

CMD ["dist/main.js"]