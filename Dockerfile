FROM --platform=linux/amd64 ruby:3.4.3-bookworm

RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && \
    apt-get install -y build-essential \
                       libpq-dev \
                       software-properties-common \
                       ffmpeg \
                       libpq-dev \
                       yarn \
                       python3-launchpadlib

RUN wget -qO- 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6888550b2fc77d09' | tee /etc/apt/trusted.gpg.d/songrec.asc
RUN add-apt-repository 'deb http://ppa.launchpad.net/marin-m/songrec/ubuntu jammy main'
# RUN apt update --allow-insecure-repositories
# RUN apt install songrec -y --allow-unauthenticated
RUN apt update
RUN apt install songrec -y
RUN apt auto-clean && apt auto-remove

ARG RAILS_ENV=production
ENV RUBYOPT='-W0' \
    RAILS_ENV=$RAILS_ENV

ENV INSTALL_PATH=/app
RUN mkdir $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . $INSTALL_PATH
RUN rm -rf "${INSTALL_PATH}/tmp"

RUN gem update --system
RUN gem install bundler
RUN bundle config set deployment 'true'
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config set --local without 'development test'
RUN bundle install --jobs "$(nproc --all)" --retry 3
