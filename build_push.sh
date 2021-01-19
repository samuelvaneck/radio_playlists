docker build -t radio_web:latest .
echo $CR_PAT | docker login ghcr.io --username samuelvaneck --password-stdin
docker tag radio_web ghcr.io/samuelvaneck/radio_playlists:latest
docker push ghcr.io/samuelvaneck/radio_playlists:latest
