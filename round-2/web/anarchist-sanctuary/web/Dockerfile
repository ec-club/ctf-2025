# 😭
FROM node@sha256:775ba24d35a13e74dedce1d2af4ad510337b68d8e22be89e0ce2ccc299329083 AS builder
WORKDIR /app
COPY package*.json pnpm-*.yaml ./
RUN corepack enable pnpm && pnpm i --frozen-lockfile
COPY . .
RUN corepack enable pnpm && pnpm run build
RUN corepack enable pnpm && pnpm prune --prod

FROM node@sha256:775ba24d35a13e74dedce1d2af4ad510337b68d8e22be89e0ce2ccc299329083
WORKDIR /app

COPY --from=builder /app/build build/
COPY --from=builder /app/node_modules node_modules/
COPY drizzle drizzle/

COPY package.json .
EXPOSE 3000
ENV NODE_ENV=production
CMD [ "node", "build" ]
