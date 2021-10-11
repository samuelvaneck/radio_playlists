FROM ruby:3.0.2-alpine3.14

RUN apk --update add --virtual build-dependencies build-base \
    ruby-dev \
    postgresql-dev \
    libxml2 libxml2-dev libxslt libxslt-dev libc-dev linux-headers \
    libcurl curl curl-dev \
    nodejs yarn tzdata bash \
      && rm -rf /var/cache/lists/*_*

ARG RAILS_ENV=production
ENV RUBYOPT='-W0' \
    RAILS_ENV=$RAILS_ENV

ENV INSTALL_PATH=/app
RUN mkdir $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . $INSTALL_PATH
RUN rm -rf "${INSTALL_PATH}/tmp"

RUN gem install bundler
RUN bundle config set deployment 'true'
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config set --local without 'development test'
RUN bundle install --jobs "$(nproc --all)" --retry 3
RUN bundle exec rails assets:precompile --jobs "$(nproc --all)"
