FROM ghcr.io/tursodatabase/libsql-server:latest

USER root

# Install only what is strictly necessary and clean up cache in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends gosu ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Pre-create data directory with correct permissions
RUN mkdir -p /var/lib/sqld && chown sqld:sqld /var/lib/sqld

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# This ensures the container reacts correctly to stop signals (SIGTERM)
STOPSIGNAL SIGINT

ENTRYPOINT ["entrypoint.sh"]
