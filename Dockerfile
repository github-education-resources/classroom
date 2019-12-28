FROM ruby:2.6.3

# set up nodejs
ENV VERSION=v8.9.4
ENV DISTRO=linux-x64
ADD https://nodejs.org/dist/$VERSION/node-$VERSION-$DISTRO.tar.xz .
RUN mkdir -p /usr/local/lib/nodejs
RUN tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /usr/local/lib/nodejs
ENV PATH=/usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin:$PATH

# copy in some dependencies from apt
RUN apt-get update -qq && \
    apt-get install -y npm

# Yarn
RUN curl -o- -L https://yarnpkg.com/install.sh | bash
ENV PATH="/root/.yarn/bin:/root/.config/yarn/global/node_modules/.bin:$PATH"

# set working directory
WORKDIR /app

# set up gems
COPY Gemfile* /app/
COPY .ruby-version /app/

# set up gems
COPY vendor/cache /app/vendor/cache
RUN gem install bundler:2.0.2
RUN bundle install --local --deployment --jobs=3 --retry=3

# yarn install
COPY package* /app/
RUN yarn install

# copy app in
COPY . /app/

# expose port we'll be using
EXPOSE 8080

# precompile assets
RUN bundle exec rake assets:precompile
