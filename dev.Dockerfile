FROM ruby:4.0.1-bookworm

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && \
    apt-get install -y build-essential \
                       libpq-dev \
                       software-properties-common \
                       ffmpeg \
                       libchromaprint-tools \
                       libpq-dev \
                       yarn \
                       python3-launchpadlib

RUN wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | tee /etc/apt/trusted.gpg.d/songrec.asc
RUN add-apt-repository 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main'
RUN apt update
RUN apt install songrec -y
RUN apt auto-clean && apt auto-remove

# Install yt-dlp for YouTube audio downloads (AcoustID population)
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

ENV RUBYOPT='-W0'

ENV INSTALL_PATH=/app
RUN mkdir $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . $INSTALL_PATH

RUN gem update --system
RUN gem install bundler
RUN yarn install --check-files
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install  --jobs "$(nproc --all)"
