FROM ubuntu:16.04

ENV HOME=/root
ARG DEBIAN_FRONTEND=noninteractive

# Prepare required utilities for APT packages installation
##########################################################

RUN apt-get -q update && \
  apt-get install -q -y --no-install-recommends \
    curl \
    software-properties-common \
    sudo && \
  # Clean up APT when done
  apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare APT package repositories
##################################

RUN \
  ## Ansible
  apt-add-repository ppa:ansible/ansible && \
  ## NodeSource
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && \
  ## Yarn
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
  # Clean up APT when done
  apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install APT packages
######################

RUN apt-get -q update && \
  apt-get install -q -y --no-install-recommends \
    ## Ansible
    ansible \
    rsync \
    ## NodeJS & yarn
    nodejs \
    yarn \
    ## Sage
    libpng-dev \
    libpng16-16 \
    ## Misc
    expect \
    git \
    ssh-client && \
  # Clean up APT when done
  apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare SSH
#############

COPY ./home/ $HOME/
RUN ln -s $HOME/bin/* /usr/local/bin/

CMD ["bash"]
