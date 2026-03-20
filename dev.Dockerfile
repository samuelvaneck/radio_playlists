FROM ruby:4.0.1-slim-bookworm

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      software-properties-common \
      ffmpeg \
      libchromaprint-tools \
      tesseract-ocr \
      tesseract-ocr-eng \
      tesseract-ocr-nld \
      libjemalloc2 \
      curl \
      wget \
      gnupg \
      python3-launchpadlib && \
    wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | tee /etc/apt/trusted.gpg.d/songrec.asc && \
    add-apt-repository 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main' && \
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
