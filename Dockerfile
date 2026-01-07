FROM ghcr.io/tursodatabase/libsql-server:latest

USER root

# Install gosu to handle user switching safely
RUN apt-get update && apt-get install -y gosu && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Ensure the script runs as root initially
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
