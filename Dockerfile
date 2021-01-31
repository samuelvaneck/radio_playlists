FROM ruby:2.7.2

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb [trusted=yes] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn libnss3-dev

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



