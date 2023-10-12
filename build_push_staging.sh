echo $CR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker build -t ghcr.io/samuelvaneck/radio_playlists:arm-latest -f arm.Dockerfile .
docker push ghcr.io/samuelvaneck/radio_playlists:arm-latest
