# What a journey this Dockerfile has been!
# My time and patience ran out as I was trying to build and push this
# thing. Note to self and reviewers, let's talk about this exciting
# journey I've had with `docker push` in the interview

FROM node:lts as build

WORKDIR /app

COPY package.json ./
COPY package-lock.json ./
COPY apps/web/package.json ./apps/web/package.json

RUN npm ci

COPY . .


WORKDIR /app/apps/web

RUN npm run build

CMD ["npx", "vite", "preview"]
