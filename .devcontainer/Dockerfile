FROM python:3.9-slim-buster

ARG UID=1000
ARG GID=1000
ARG USER="cairo"

# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
    sudo \
    iproute2 \
  && python -m pip install --upgrade pip \
  && sudo apt install -y libgmp3-dev \
  && pip3 install ecdsa fastecdsa sympy \
  && pip3 install cairo-lang openzeppelin-cairo-contracts \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log
  # && addgroup --gid $APP_GROUP_GID --system $APP_GROUP \
  # && adduser --system --shell /sbin/nologin -u $APP_USER_UID $APP_USER \
  # && adduser $APP_USER $APP_GROUP 


# Install dependencies
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Configure non-root user based on https://hint.io/blog/rails-development-with-docker
RUN groupadd -g $GID $USER && \
useradd -u $UID -g $USER -m $USER && \
usermod -p "*" $USER && \
usermod -aG sudo $USER && \
echo "$USER ALL=NOPASSWD: ALL" >> /etc/sudoers.d/50-$USER

USER cairo

#Install software-properties-common to allow the command apt-add-repository to work
# RUN sudo apt-get update -qq \
# && sudo apt-get install -yq --no-install-recommends \
#   software-properties-common \
#   openssh-client \
# && sudo apt-get clean \
# && sudo rm -rf /var/cache/apt/archives/* \
# && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# && sudo truncate -s 0 /var/log/*log

# Install Git Cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install -y gh

# Install zsh
RUN sudo apt install -y zsh imagemagick jq \
&& sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Enabling Virtual Environment as recommended in https://www.cairo-lang.org/docs/quickstart.html
RUN python -m venv ~/cairo_venv && mkdir ~/.starknet_accounts && chown $USER:$USER ~/.starknet_accounts
# && source ~/cairo_venv/bin/activate

ENV PATH /app/bin:$PATH
# ENV PATH /home/cairo/.local/bin:$PATH