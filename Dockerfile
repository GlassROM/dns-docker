FROM ghcr.io/glassrom/os-image-updater:master

RUN mv /etc/ld.so.preload /etc/ld.so.preload.bak

RUN pacman-key --init && pacman-key --populate archlinux

RUN set -x \
    && groupadd --system --gid 970 unbound \
    && useradd --system -g unbound -M --shell /bin/nologin --uid 970 unbound \
    && pacman -S --noconfirm unbound

STOPSIGNAL SIGQUIT

RUN yes | pacman -Scc

RUN curl -fSL --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache
COPY unbound.conf /etc/unbound/unbound.conf
RUN chown -R unbound:unbound /etc/unbound

RUN rm -rf /etc/pacman.d/gnupg

RUN mv /etc/ld.so.preload.bak /etc/ld.so.preload

EXPOSE 53/tcp 53/udp

USER unbound

CMD ["/seccomp-strict", "/usr/bin/unbound", "-d"]
