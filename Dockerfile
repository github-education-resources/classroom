FROM heroku/heroku:16

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Update packages and install deps
RUN apt-get update && apt-get install -yq autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev libpq-dev

ENV INSTALL_PATH /usr/src/app
RUN mkdir -p $INSTALL_PATH

WORKDIR $INSTALL_PATH

################
## Setup Ruby ##
################

# Download rbenv and set the the paths
ENV RBENV_ROOT="/usr/local/rbenv"
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT
RUN echo '# rbenv setup' > /etc/profile.d/rbenv.sh
RUN echo 'export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"' >> /etc/profile.d/rbenv.sh
RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
RUN chmod +x /etc/profile.d/rbenv.sh

# Get ruby-build and install it
RUN mkdir -p $RBENV_ROOT/plugins
RUN git clone https://github.com/rbenv/ruby-build.git $RBENV_ROOT/plugins/ruby-build --branch v20170523
RUN $RBENV_ROOT/plugins/ruby-build/install.sh

# Add it to our current $PATH
ENV PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"

# Figure out what the local version is an install it
COPY .ruby-version $INSTALL_PATH/
RUN rbenv install

RUN gem update --system
RUN gem install bundler --no-ri --no-rdoc

###############
## Setup NPM ##
###############

# nvm environment variables
ENV NVM_DIR="/usr/local/nvm"
ENV NODE_VERSION="6.11.0"

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH="$NVM_DIR/v$NODE_VERSION/lib/node_modules"
ENV PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

RUN npm install -g yarn

#################
## Environment ##
#################

ENV RAILS_ENV="development"
ENV RACK_ENV="development"

######################################
## Copy and install the application ##
######################################

COPY Gemfile* $INSTALL_PATH/
RUN bundle install --without production --jobs 2

COPY . $INSTALL_PATH/

RUN ./bin/yarn
