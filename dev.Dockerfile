FROM ruby:4.0.2-slim-bookworm

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libyaml-dev \
      libicu-dev \
      zlib1g-dev \
      pkg-config \
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

ENV RUBYOPT='-W0'

WORKDIR /app
COPY . /app

RUN gem install bundler && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle install --jobs "$(nproc --all)"

# Enable jemalloc for reduced memory fragmentation (set after bundle install)
ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
    MALLOC_ARENA_MAX=2
