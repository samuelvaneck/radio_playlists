FROM ruby:4.0.1-slim-bookworm

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      ffmpeg \
      libchromaprint-tools \
      tesseract-ocr \
      tesseract-ocr-eng \
      tesseract-ocr-nld \
      libjemalloc2 \
      curl \
      wget \
      gnupg && \
    wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | gpg --dearmor -o /etc/apt/trusted.gpg.d/songrec.gpg && \
    echo 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main' > /etc/apt/sources.list.d/songrec.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends songrec && \
    rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Enable jemalloc for reduced memory fragmentation
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
    MALLOC_ARENA_MAX=2 \
    RUBYOPT='-W0'

WORKDIR /app
COPY . /app

RUN gem install bundler && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle install --jobs "$(nproc --all)"
