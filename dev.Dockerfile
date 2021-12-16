FROM ruby:3.0.3-alpine3.15

RUN apk --update add --virtual build-dependencies \
    build-base \
    ruby-dev \
    postgresql-dev \
    libxml2 libxml2-dev libxslt libxslt-dev libc-dev linux-headers \
    libcurl curl curl-dev less \
    nodejs yarn tzdata bash \
      && rm -rf /var/cache/lists/*_*

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
RUN bundle exec rake assets:precompile --jobs "$(nproc --all)"
