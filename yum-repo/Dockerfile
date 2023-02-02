FROM fedora:37

ARG RELEASE_VERSION=6.1.8-f37

WORKDIR /var/repo

RUN dnf -y install \
    createrepo \
    wget \
    yum-utils \
    nginx \
    gettext \
  && dnf clean all

ADD provision.sh /usr/bin/provision.sh

RUN /usr/bin/provision.sh

RUN createrepo /var/repo

COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx

USER nginx

ENV PORT=8080
EXPOSE ${PORT}

CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/nginx.conf > /tmp/nginx.conf; cat /tmp/nginx.conf > /etc/nginx/nginx.conf" && nginx -g 'daemon off;'
