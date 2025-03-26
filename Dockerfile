# Use Node.js base image
FROM node:20-alpine AS deps

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install
# Install the missing pino-pretty dependency
RUN npm install pino-pretty --save-dev

# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Create public directory if it doesn't exist
RUN mkdir -p public

# Build with environment variables from the build args
ARG NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID
ARG NEXT_PUBLIC_APP_NAME
ARG NEXT_PUBLIC_ENS_DOMAIN
ARG NEXT_PUBLIC_APP_DOMAIN
ARG NEXT_PUBLIC_APP_ORIGIN
ARG NEXT_PUBLIC_ENS_API_KEY
ARG NEXT_PUBLIC_MAINNET_RPC_URL
ARG NEXT_PUBLIC_MEMBERS_ONLY

ENV NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID=${NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID}
ENV NEXT_PUBLIC_APP_NAME=${NEXT_PUBLIC_APP_NAME}
ENV NEXT_PUBLIC_ENS_DOMAIN=${NEXT_PUBLIC_ENS_DOMAIN}
ENV NEXT_PUBLIC_APP_DOMAIN=${NEXT_PUBLIC_APP_DOMAIN}
ENV NEXT_PUBLIC_APP_ORIGIN=${NEXT_PUBLIC_APP_ORIGIN}
ENV NEXT_PUBLIC_ENS_API_KEY=${NEXT_PUBLIC_ENS_API_KEY}
ENV NEXT_PUBLIC_MAINNET_RPC_URL=${NEXT_PUBLIC_MAINNET_RPC_URL}
ENV NEXT_PUBLIC_MEMBERS_ONLY=${NEXT_PUBLIC_MEMBERS_ONLY}

RUN npm run build

# Production stage
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create necessary directories
RUN mkdir -p public .next

# Copy build artifacts
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Expose port and start the server
EXPOSE 3000
CMD ["npm", "start"]
