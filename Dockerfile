FROM ruby:3.0.2-alpine3.14

# RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
# RUN echo "deb [trusted=yes] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn libnss3-dev

# Install system dependencies and remove the cache to free up space afterwards
RUN apk --update add --virtual build-dependencies \
    build-base \
    ruby-dev \
    postgresql-dev \
    libxml2 libxml2-dev libxslt libxslt-dev libc-dev linux-headers \
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
RUN gem update --system && \
    gem install bundler && \
    bundle update rake && \
    yarn install --check-files && \
    bundle config build.nokogiri --use-system-libraries && \
    bundle config --global frozen 1 && \
    bundle config set --local without 'development test' && \
    bundle install \
        --jobs "$(nproc --all)" \
        --retry 3 --quiet && \
    bundle exec rake assets:precompile \
        --quiet --silent \
        --jobs "$(nproc --all)" \
        RAILS_ENV=${RAILS_ENV}



