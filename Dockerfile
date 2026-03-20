# ============================================
# Stage 1: Build dependencies
# ============================================
FROM ruby:4.0.1-slim-bookworm AS builder

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      software-properties-common \
      wget \
      curl \
      gnupg \
      python3-launchpadlib && \
    rm -rf /var/lib/apt/lists/*

# Install SongRec from PPA
RUN wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | tee /etc/apt/trusted.gpg.d/songrec.asc && \
    add-apt-repository 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main' && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends songrec && \
    rm -rf /var/lib/apt/lists/*

ARG RAILS_ENV=production
ENV RAILS_ENV=$RAILS_ENV \
    RUBYOPT='-W0'

WORKDIR /app

# Install gems (cached unless Gemfile changes)
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle config set deployment 'true' && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle config set --local without 'development test' && \
    bundle lock --add-platform ruby && \
    bundle install --jobs "$(nproc --all)" --retry 3

COPY . .
RUN rm -rf tmp spec .rspec .rubocop.yml .claude coverage

# ============================================
# Stage 2: Runtime image
# ============================================
FROM ruby:4.0.1-slim-bookworm

# Install jemalloc and runtime dependencies only
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      ffmpeg \
      libchromaprint-tools \
      tesseract-ocr \
      tesseract-ocr-eng \
      tesseract-ocr-nld \
      libjemalloc2 \
      curl \
      software-properties-common \
      wget \
      gnupg \
      python3-launchpadlib && \
    wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | tee /etc/apt/trusted.gpg.d/songrec.asc && \
    add-apt-repository 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main' && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends songrec && \
    apt-get purge -y software-properties-common wget gnupg python3-launchpadlib && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Enable jemalloc for reduced memory fragmentation
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
    MALLOC_ARENA_MAX=2 \
    RAILS_ENV=production \
    RUBYOPT='-W0'

WORKDIR /app

# Copy built app and gems from builder
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
