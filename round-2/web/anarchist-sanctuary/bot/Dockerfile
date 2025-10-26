FROM ghcr.io/puppeteer/puppeteer@sha256:f61e044d6cb79f49104c59f8e34423b07e4c78d7350e08bbd5d51bc63dfc2a4d
WORKDIR /app

RUN npm install express puppeteer

COPY index.js .
CMD ["node", "index.js"]
