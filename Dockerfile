FROM ruby:2.3.1

RUN apt-get update && apt-get install -y \
  libpq-dev \
  nodejs \
  sudo \
  vim

ENV TERM xterm

ARG DEV_USER
ARG DEV_USER_ID
RUN useradd -u $DEV_USER_ID -m -r $DEV_USER && \
  echo "$DEV_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
USER $DEV_USER

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
WORKDIR /usr/src/app
RUN gem install bundler && \
  bundle

CMD sleep infinity
