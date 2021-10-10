# FROM ruby:3.0.2

# RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
# RUN echo "deb [trusted=yes] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn libnss3-dev
FROM ruby:3.0.2-alpine3.14

RUN apk --update add --virtual build-dependencies \
    build-base \
    ruby-dev \
    postgresql-dev \
    libxml2 libxml2-dev libxslt libxslt-dev libc-dev linux-headers \
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
