FROM heroku/heroku:16

RUN touch /etc/app-env

RUN apt-get update -qq && \
    apt-get install -y \
    netcat \
    build-essential \
    ruby-all-dev \
    libreadline-dev \
    libpq-dev \
    nodejs \
    sudo \
    chrpath \
    libssl-dev \
    libxft-dev \
    libfreetype6-dev \
    libfreetype6 \
    libfontconfig1-dev \
    libfontconfig1

WORKDIR /app

# install rbenv and validate
ENV RBENV_ROOT="/opt/rbenv"
ENV PATH=$PATH:$RBENV_ROOT/bin
RUN git clone git://github.com/sstephenson/rbenv.git $RBENV_ROOT && \
    _cwd=$(pwd) && \
    cd $RBENV_ROOT && src/configure && make -C src && \
    cd $_cwd && \
    echo 'eval "$(rbenv init -)"' > $RBENV_ROOT/rbenv.env && \
    chmod +x $RBENV_ROOT/rbenv.env && \
    . $RBENV_ROOT/rbenv.env && \
    mkdir -p "$(rbenv root)"/plugins && \
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build && \
    curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

# install nodenv
ENV NODENV_ROOT="/opt/nodenv"
ENV PATH=$PATH:$NODENV_ROOT/bin
RUN git clone https://github.com/nodenv/nodenv.git $NODENV_ROOT && \
    git clone https://github.com/nodenv/node-build.git "$NODENV_ROOT"/plugins/node-build && \
    _cwd=$(pwd) && \
    cd $NODENV_ROOT && src/configure && make -C src && \
    cd $_cwd && \
    echo 'eval "$(nodenv init -)"' > $NODENV_ROOT/nodenv.env && \
    . $NODENV_ROOT/nodenv.env

COPY Gemfile* /app/
COPY vendor/assets /app/vendor/assets
RUN gem install bundler -v '1.12.5' && \
    bundle install --local

RUN mkdir /app/log

COPY . /app/

EXPOSE 3000