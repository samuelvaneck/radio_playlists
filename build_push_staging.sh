echo $CR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker build -t ghrc.io/samuelvaneck/radio_playlists:arm-latest --platform linux/arm64 .
docker push ghcr.io/samuelvaneck/radio_playlists:arm-latest
