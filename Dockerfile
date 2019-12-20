FROM ruby:2.6.3

RUN touch /etc/app-env

WORKDIR /app

RUN git clone https://github.com/education/classroom.git /app
RUN gem install bundler:2.0.2
RUN bundle install

# Node
ENV VERSION=v8.9.4
ENV DISTRO=linux-x64
ADD https://nodejs.org/dist/$VERSION/node-$VERSION-$DISTRO.tar.xz .
RUN mkdir -p /usr/local/lib/nodejs
RUN tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /usr/local/lib/nodejs 
ENV PATH=/usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin:$PATH

# Yarn
RUN curl -o- -L https://yarnpkg.com/install.sh | bash
ENV PATH="/root/.yarn/bin:/root/.config/yarn/global/node_modules/.bin:$PATH"

EXPOSE 8080

COPY . .

RUN bundle exec rake assets:precompile
