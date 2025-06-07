# Use Crystal base image
FROM crystallang/crystal:1.14.0-alpine AS builder

# Install build dependencies including SQLite development libraries
RUN apk add --no-cache \
    build-base \
    git \
    openssl-dev \
    postgresql-dev \
    libxml2-dev \
    libxslt-dev \
    yaml-dev \
    sqlite-dev

# Set working directory
WORKDIR /app

# Copy shard files
COPY shard.yml shard.lock ./

# Install dependencies (without --production flag)
RUN shards install

# Copy source code
COPY . .

# Build the application
RUN crystal build src/agentc_app_template_oss.cr -o agentc_app_template_oss --release --static

# Production stage
FROM alpine:latest

# Install runtime dependencies with PostgreSQL 17 client
RUN apk add --no-cache \
    openssl \
    ca-certificates \
    tzdata \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
    postgresql17-client

# Create app directory
WORKDIR /app

# Copy the built application
COPY --from=builder /app/agentc_app_template_oss .

# Copy sam binary for migrations
COPY --from=builder /app/sam .

# Copy migration script and make it executable
COPY migrate.sh /app/migrate.sh
RUN chmod +x /app/migrate.sh

# Copy other necessary files
COPY --from=builder /app/config ./config
COPY --from=builder /app/public ./public
COPY --from=builder /app/src/views ./src/views
COPY --from=builder /app/src/locales ./src/locales
COPY --from=builder /app/src/models ./src/models
COPY --from=builder /app/db ./db

# Expose port
EXPOSE 3000

# Note: CMD is intentionally omitted to let DigitalOcean App Platform control the run command 