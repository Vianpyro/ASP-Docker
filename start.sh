#!/bin/bash

set -e

# Set the default values for the environment variables
: "${MC_VERSION:='latest'}"
: "${ASP_BUILD:='latest'}"
: "${ASP_PROJECT_ID:='latest'}"
: "${ASP_FILE_ID:='latest'}"

# Get the latest version of the Minecraft server if 'latest' is specified
if [ "$MC_VERSION" = "latest" ]; then
    MC_VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
fi

# Get the latest version of the ASP build if 'latest' is specified
if [ "$ASP_BUILD" = "latest" ]; then
    build_json=$(curl -s "https://api.infernalsuite.com/v1/projects/asp/mcVersion/$MC_VERSION")
    latest_build=$(echo "$build_json" | jq 'sort_by(.date) | last')
    asp_file=$(echo "$latest_build" | jq -r '.files[] | select(.fileName == "asp-server.jar")')
    ASP_FILE_ID=$(echo "$asp_file" | jq -r '.id')
    FILE_NAME=$(echo "$asp_file" | jq -r '.fileName')
    ASP_PROJECT_ID=$(echo "$latest_build" | jq -r '.id')
    BUILD_DATE=$(echo "$latest_build" | jq -r '.date')
    BRANCH=$(echo "$latest_build" | jq -r '.branch')
    MC_VERSION_EXACT=$(echo "$latest_build" | jq -r '.mcVersion[0]')
    SHA1=$(echo "$asp_file" | jq -r '.sha1Hash')
    SHA256=$(echo "$asp_file" | jq -r '.sha256Hash')
fi

# Verify that an ASP build was found for the specified Minecraft version
if [ -z "$ASP_BUILD" ] || [ "$ASP_BUILD" = "null" ]; then
    echo "No ASP build found for Minecraft version $MC_VERSION"
    exit 1
fi

echo "Using Minecraft version: $MC_VERSION"
echo "Using ASP Project ID: $ASP_PROJECT_ID"
echo "Using ASP File ID: $ASP_FILE_ID"

# Define the JAR file name and download URL
JAR_NAME="asp-${MC_VERSION}-${ASP_PROJECT_ID}-${ASP_FILE_ID}-server.jar"
JAR_URL="https://api.infernalsuite.com/v1/projects/asp/$ASP_PROJECT_ID/download/$ASP_FILE_ID"

# Remove old JARs
rm -f *.jar

# Download the latest server jar if it doesn't already exist
if [ ! -f "$JAR_NAME" ]; then
    echo "Downloading ASP server jar..."
    curl -L -o "$JAR_NAME" "$JAR_URL"
else
    echo "Using existing server jar: $JAR_NAME"
fi

# Write the EULA acceptance to the eula.txt file
echo "eula=${EULA:-false}" > eula.txt

# Build Java options array
JAVA_OPTS_ARRAY=()

# Append user-defined Java options
if [[ -n $JAVA_OPTS ]]; then
    read -r -a USER_OPTS <<< "$JAVA_OPTS"
    JAVA_OPTS_ARRAY+=("${USER_OPTS[@]}")
fi

# Append memory settings
if [[ -n $MC_RAM ]]; then
    JAVA_OPTS_ARRAY+=("-Xms${MC_RAM}" "-Xmx${MC_RAM}")
fi

# Start the Minecraft server
echo "Starting Minecraft server with options: ${JAVA_OPTS_ARRAY[*]}"
exec java -server "${JAVA_OPTS_ARRAY[@]}" -jar "$JAR_NAME" nogui
