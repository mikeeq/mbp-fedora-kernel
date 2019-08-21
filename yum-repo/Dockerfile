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

RUN for rpm in $(curl -s https://github.com/mikeeq/mbp-fedora-kernel/releases/latest -L | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1); do \
      wget https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/$rpm; \
    done && \
    chown -R nginx:nginx /var/repo

RUN createrepo /var/repo

COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

ENV PORT=8080
EXPOSE ${PORT}

CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/nginx.conf > /etc/nginx/nginx.conf" && nginx -g 'daemon off;'
