#!/bin/bash
set -e

IMAGE="ghcr.io/samuelvaneck/radio_playlists:latest"
PLATFORM="linux/amd64"

echo "=== Radio Playlists Docker Build & Push ==="
echo ""

# Check for required environment variable
if [ -z "$GHCR_PAT" ]; then
  echo "Error: GHCR_PAT environment variable is not set"
  exit 1
fi

# Login to GitHub Container Registry
echo "[1/3] Logging in to GitHub Container Registry..."
echo "$GHCR_PAT" | docker login ghcr.io --username samuelvaneck --password-stdin
echo "Login successful"
echo ""

# Build the Docker image
echo "[2/3] Building Docker image ($PLATFORM)..."
echo "Image: $IMAGE"
docker build -t "$IMAGE" --platform "$PLATFORM" .
echo "Build successful"
echo ""

# Push the Docker image
echo "[3/3] Pushing Docker image..."
docker push "$IMAGE"
echo "Push successful"
echo ""

echo "=== Done ==="
