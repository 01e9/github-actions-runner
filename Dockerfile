FROM ubuntu:20.04

ARG TINI_VERSION='0.19.0'
ARG RUNNER_VERSION=2.277.1

ARG TZ_CONTINENT='Europe'
ARG TZ_CITY='Chisinau'
ENV TS='Europe/Chisinau'

ENV RUNNER_CONFIG_ARGS="--url https://github.com/foo/bar --token BAZ"

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt update \
  # tzdata
  && truncate -s0 /tmp/preseed.cfg \
      && echo "tzdata tzdata/Areas select ${TZ_CONTINENT}" >> /tmp/preseed.cfg \
      && echo "tzdata tzdata/Zones/${TZ_CONTINENT} select ${TZ_CITY}" >> /tmp/preseed.cfg \
      && debconf-set-selections /tmp/preseed.cfg \
      && rm -f /etc/timezone /etc/localtime \
      && apt-get install -y tzdata \
  && apt install -y \
  	curl wget htop ssh iputils-ping git nano sudo ca-certificates apt-transport-https gnupg-agent software-properties-common \
  && (curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -) \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && apt update \
  && apt install -y docker-ce docker-ce-cli containerd.io \
  && apt clean && rm -rf /var/lib/apt/lists/* /tmp/*

ADD https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN adduser --disabled-password --gecos '' github \
    # allow docker without sudo
    && usermod -aG docker github \
    && usermod -aG sudo github \
    # allow sudo without password
    && sed -i 's/%sudo\s.*/%sudo ALL=(ALL:ALL) NOPASSWD : ALL/g' /etc/sudoers

RUN mkdir -p /home/github/runner

WORKDIR /home/github/runner

RUN wget https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
        -O runner.tar.gz -q \
    && tar -xf runner.tar.gz \
    && rm runner.tar.gz \
    && chown -R github:github *

RUN ./bin/installdependencies.sh \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* \
    && chown github:github /home/github/runner

USER github

RUN mkdir -p ~/.ssh \
    && ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

USER root

COPY docker-entrypoint.sh /usr/bin/

VOLUME [ "/home/github/runner" ]

ENTRYPOINT ["/tini", "docker-entrypoint.sh", "--"]
CMD []
