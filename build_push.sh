#!/bin/bash
set -xe

echo $CR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker build -t ghcr.io/samuelvaneck/radio_playlists:latest .
docker push ghcr.io/samuelvaneck/radio_playlists:latest
