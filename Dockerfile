# Use Alpine as the base image for smaller size and performance
FROM alpine:latest

# Environment variables for configuration
ENV MC_VERSION="latest" \
    ASP_BUILD="latest" \
    ASP_PROJECT_ID="latest" \
    ASP_FILE_ID="latest" \
    EULA="false" \
    MC_RAM="6G" \
    JAVA_OPTS=""

# Uncomment the following line to set a specific timezone
# ENV TZ="Europe/Paris"

# Copy the startup script to the container root
COPY start.sh /start.sh

# Create non-root user and group
RUN addgroup -S minecraft && adduser -S minecraft -G minecraft && \
    mkdir -p /server && \
    chown -R minecraft:minecraft /server && \
    chmod +x /start.sh

# Install dependencies
RUN apk add --no-cache \
    libstdc++ \
    openjdk21-jre \
    bash \
    curl \
    jq \
    tzdata

# Set the working directory
WORKDIR /server

# Switch to the non-root user
USER minecraft

# Make the script the entrypoint
ENTRYPOINT ["/start.sh"]

# Expose the default Minecraft port
EXPOSE 25565

# Define the volume for server data
VOLUME ["/server"]

# Healthcheck to ensure the server is running
HEALTHCHECK --interval=5m --timeout=3s --start-period=90s --retries=3 \
    CMD nc -z 0.0.0.0 25565 || exit 1
