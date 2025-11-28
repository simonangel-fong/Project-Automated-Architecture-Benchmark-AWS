# Lightweight image with psql client
FROM python:3.11-slim

# Install PostgreSQL client
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy SQL scripts into the image
COPY init ./init

# Copy entrypoint script
COPY run-init.sh ./run-init.sh
RUN chmod +x ./run-init.sh

# Default envs (override in docker-compose or ECS)
ENV DB_HOST=postgres \
    DB_PORT=5432 \
    DB_NAME=appdb \
    DB_USER=appuser \
    DB_PASSWORD=changeme

ENTRYPOINT ["./run-init.sh"]
