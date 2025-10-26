FROM node:24-alpine AS build
WORKDIR /app

RUN corepack enable pnpm
COPY package.json pnpm-lock.yaml ./

RUN pnpm i --frozen-lockfile

COPY . ./
RUN pnpm run build

FROM node:24-alpine
WORKDIR /app

COPY --from=build /app/.output/ ./

RUN corepack enable pnpm && pnpm add @libsql/linux-x64-musl
COPY drizzle ./drizzle

CMD ["node", "/app/server/index.mjs"]
