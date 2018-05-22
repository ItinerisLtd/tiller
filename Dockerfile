FROM ubuntu:16.04

ENV HOME=/root
ARG DEBIAN_FRONTEND=noninteractive

# Prepare required utilities for APT packages installation
##########################################################

RUN apt-get -q update && \
  apt-get install -q -y --no-install-recommends \
    curl \
    software-properties-common \
    sudo &&  \
  # Clean up APT when done
  apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare APT package repositories
##################################

# Ansible
RUN apt-add-repository ppa:ansible/ansible

## NodeSource
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

## Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install APT packages
######################

RUN apt-get -q update &&  \
  apt-get install -q -y --no-install-recommends \
    ## Ansible
    ansible \
    rsync \
    ## NodeJS & yarn
    nodejs \
    yarn \
    ## Sage
    libpng-dev \
    ## Misc
    expect \
    git \
    ssh-client && \
  # Clean up APT when done
  apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare SSH
#############

RUN mkdir -m 700 ~/.ssh

## Add host keys
RUN ssh-keyscan github.com bitbucket.org gitlab.com bastion.itineris.co.uk 35.176.46.36 >> ~/.ssh/known_hosts

## Copy ssh-add helper script
COPY *.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

CMD ["bash"]
