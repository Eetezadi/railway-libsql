FROM ghcr.io/tursodatabase/libsql-server:latest

USER root

# Copy our script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create the data directory and ensure permissions
RUN mkdir -p /var/lib/sqld && chown -R sqld:sqld /var/lib/sqld

# Switch back to the non-root user provided by the base image
USER sqld

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
