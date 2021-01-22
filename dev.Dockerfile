FROM ruby:2.7.2

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb [trusted=yes] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn libnss3-dev sendmail

ARG RAILS_ENV=development
ENV RUBYOPT='-W0' \
    RAILS_ENV=$RAILS_ENV

ENV INSTALL_PATH=/app
RUN mkdir $INSTALL_PATH
WORKDIR $INSTALL_PATH
COPY . $INSTALL_PATH

RUN echo "### RAILS ENV ${RAILS_ENV} ###"

RUN gem update --system
RUN gem install bundler
RUN yarn install --check-files
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install \
        --jobs "$(nproc --all)" \
        --retry 3 --quiet
RUN bundle exec rake assets:precompile \
        --quiet --silent \
        --jobs "$(nproc --all)" \
        RAILS_ENV=${RAILS_ENV}}
