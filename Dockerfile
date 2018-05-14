FROM ubuntu:16.04

ARG DEBIAN_FRONTEND=noninteractive

# Prepare common utilities
##########################
RUN apt-get -q update && apt-get install -q -y --no-install-recommends \
  curl \
  expect \
  git \
  software-properties-common \
  ssh-client \
  sudo \
  wget

# Prepare APT package repositories
##################################

# Ansible
RUN apt-add-repository ppa:ansible/ansible

## NodeSource
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

## Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

## PHP
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php

# Install APT packages
######################

RUN apt-get -q update && apt-get install -q -y --no-install-recommends \
  ## Ansible
  ansible \
  ## NodeJS & yarn
  nodejs \
  yarn \
  ## PHP 7.2
  php7.2-cli \
  php7.2-common \
  php7.2-curl \
  php7.2-dev \
  php7.2-fpm \
  php7.2-gd \
  php7.2-mbstring \
  php7.2-mysql \
  php7.2-opcache \
  php7.2-xml \
  php7.2-xmlrpc \
  php7.2-zip

# Install Composer
#####################

RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet

# Set up GitHub host key and SSH key
#####################

RUN mkdir ~/.ssh
RUN chmod 700 ~/.ssh
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN chmod 600 ~/.ssh/*

COPY *.sh /root/
RUN chmod 500 ~/*.sh

# Clean up APT when done
#########################

RUN apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define default command
########################

CMD ["bash"]
