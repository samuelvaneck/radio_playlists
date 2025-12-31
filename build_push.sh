echo $GHCR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker build -t ghcr.io/samuelvaneck/radio_playlists:latest --platform linux/amd64 .
docker push ghcr.io/samuelvaneck/radio_playlists:latest
