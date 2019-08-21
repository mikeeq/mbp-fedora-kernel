FROM fedora:30

ARG RELEASE_VERSION=5.1.19-2

WORKDIR /var/repo

RUN dnf -y install \
    createrepo \
    wget \
    yum-utils \
    nginx \
    gettext \
  && dnf clean all

RUN wget https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/kernel-5.1.19-300.wifi.patch.fc30.x86_64.rpm && \
    wget https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/kernel-core-5.1.19-300.wifi.patch.fc30.x86_64.rpm && \
    wget https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/kernel-modules-5.1.19-300.wifi.patch.fc30.x86_64.rpm && \
    wget https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/kernel-modules-extra-5.1.19-300.wifi.patch.fc30.x86_64.rpm && \
    wget https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/kernel-devel-5.1.19-300.wifi.patch.fc30.x86_64.rpm && \
    chown -R nginx:nginx /var/repo

RUN createrepo /var/repo

COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

ENV PORT=8080
EXPOSE ${PORT}

CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/nginx.conf > /etc/nginx/nginx.conf" && nginx -g 'daemon off;'
