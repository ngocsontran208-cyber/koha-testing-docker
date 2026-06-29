FROM ubuntu:24.04

# File Author / Maintainer
LABEL maintainer="tomascohen@theke.io"

ENV PATH=/usr/bin:/bin:/usr/sbin:/sbin
ENV DEBIAN_FRONTEND=noninteractive
ENV REFRESHED_AT=2025-09-19

# Remove the default ubuntu user so the koha user will get UID 1000
# Will avoid permission issues with bind-mounted Koha repository
RUN userdel -r ubuntu 2>/dev/null || true

# Copy package management scripts
COPY files/install-packages /usr/local/bin/
COPY files/package-config.yaml /usr/local/bin/
RUN chmod +x /usr/local/bin/install-packages

# Install dependencies needed by install-packages
RUN apt-get update \
    && apt-get -y install \
    lsb-release \
    libmodern-perl-perl \
    libyaml-libyaml-perl \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install base packages
RUN /usr/local/bin/install-packages base

# Set locales
RUN    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "fi_FI.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && dpkg-reconfigure locales \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8

# Prepare apache configuration
RUN a2dismod mpm_event
RUN a2dissite 000-default
RUN a2enmod rewrite \
    headers \
    proxy_http \
    cgi

# Add Koha development repositories
RUN curl -s http://debian.koha-community.org/koha/gpg.asc | \
    gpg --dearmor -o /etc/apt/trusted.gpg.d/koha.gpg && \
    chmod 644 /etc/apt/trusted.gpg.d/koha.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/koha.gpg] http://debian.koha-community.org/koha-staging dev main" >> /etc/apt/sources.list.d/koha.list

# Install koha-common
RUN apt-get -y update \
    && apt-cache policy koha-common \
    && apt-cache policy libmojolicious-perl \
    && apt-cache policy libjson-validator-perl \
    && apt-cache policy libmojolicious-plugin-openapi-perl \
    && apt-cache policy libyaml-libyaml-perl \
    && apt-get -y install \
    koha-common \
    && /etc/init.d/koha-common stop \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/koha/misc/translator/po/* # Do not embed PO files

RUN mkdir /kohadevbox
WORKDIR /kohadevbox

# Install Koha development packages
RUN /usr/local/bin/install-packages koha-dev

# Add nodejs repo
RUN wget -O- -q https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor \
    | tee /usr/share/keyrings/nodesource.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Add yarn repo
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && wget -O- -q https://dl.yarnpkg.com/debian/pubkey.gpg \
    | gpg --dearmor \
    | tee /usr/share/keyrings/yarnkey.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install Node.js and Yarn
RUN /usr/local/bin/install-packages nodejs

# Install some tool
RUN yarn global add gulp-cli

# Embed /kohadevbox/node_modules
RUN cd /kohadevbox \
    && wget -q https://gitlab.com/koha-community/Koha/-/raw/main/package.json?inline=false -O package.json \
    && wget -q https://gitlab.com/koha-community/Koha/-/raw/main/yarn.lock?inline=false -O yarn.lock \
    && yarn cache clean \
    && yarn install --modules-folder /kohadevbox/node_modules \
    && mv /root/.cache/Cypress /kohadevbox && chown -R 1000 /kohadevbox/Cypress \
    && rm -f package.json yarn.lock

# Add perl-git-bz
RUN cd /kohadevbox \
    && git clone --depth 1 https://gitlab.com/koha-community/perl-git-bz.git \
    && cd perl-git-bz && cpanm --installdeps . \
    && ln -s /kohadevbox/perl-git-bz/bin/git-bz /usr/bin/git-bz

# Clone helper repositories
RUN cd /kohadevbox \
    && git clone https://gitlab.com/koha-community/koha-misc4dev.git   misc4dev \
    && git clone https://gitlab.com/koha-community/koha-gitify.git     gitify \
    && git clone https://gitlab.com/koha-community/qa-test-tools.git   qa-test-tools \
    && chown -R 1000 misc4dev \
    gitify \
    qa-test-tools

# How-to and utility packages
RUN cd /kohadevbox \
    && git clone https://gitlab.com/koha-community/koha-howto.git howto

# Install utility packages
RUN /usr/local/bin/install-packages utility

# Install Cypress testing packages
RUN /usr/local/bin/install-packages cypress

# download koha-reload-starman
RUN cd /kohadevbox \
    && wget https://gitlab.com/mjames/koha-reload-starman/-/raw/master/koha-reload-starman \
    && chmod 755 koha-reload-starman

# Install temporary packages
RUN /usr/local/bin/install-packages temp

# Install CPAN modules
RUN /usr/local/bin/install-packages cpan

VOLUME /kohadevbox/koha

COPY files/run.sh /kohadevbox
COPY files/templates /kohadevbox/templates
COPY env/defaults.env /kohadevbox/templates/defaults.env
COPY files/git_hooks /kohadevbox/git_hooks

EXPOSE 6001 8080 8081

CMD ["/bin/bash", "/kohadevbox/run.sh"]
