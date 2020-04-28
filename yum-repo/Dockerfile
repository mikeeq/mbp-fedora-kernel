FROM fedora:32

ARG RELEASE_VERSION=5.6.7-f32

WORKDIR /var/repo

RUN dnf -y install \
    createrepo \
    wget \
    yum-utils \
    nginx \
    gettext \
  && dnf clean all

RUN wget -A rpm -r http://fedora-mbp-repo.herokuapp.com/ \
    # && wget -A xml -r http://fedora-mbp-repo.herokuapp.com/ \
    # && wget -A xml.gz -r http://fedora-mbp-repo.herokuapp.com/ \
    && mv -f ./fedora-mbp-repo.herokuapp.com/*.rpm ./ \
    # && mv -f ./fedora-mbp-repo.herokuapp.com/repodata ./ \
    && rm -rfv fedora-mbp-repo.herokuapp.com \
    ; rm -rfv *.1 \
    ; chown -R nginx:nginx /var/repo

RUN for rpm in $(curl -s https://github.com/mikeeq/mbp-fedora-kernel/releases/latest -L | grep rpm | grep span | cut -d'>' -f2 | cut -d'<' -f1); do \
      wget --backups=1 https://github.com/mikeeq/mbp-fedora-kernel/releases/download/v${RELEASE_VERSION}/$rpm; \
    done \
    ; rm -rfv *.1 \
    ; chown -R nginx:nginx /var/repo

RUN createrepo /var/repo

COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

ENV PORT=8080
EXPOSE ${PORT}

CMD /bin/bash -c "envsubst '\$PORT' < /etc/nginx/nginx.conf > /tmp/nginx.conf; cat /tmp/nginx.conf > /etc/nginx/nginx.conf" && nginx -g 'daemon off;'
