FROM ghcr.io/glassrom/os-image-docker:latest AS builder

#LABEL maintainer=""

RUN pacman-key --init && pacman-key --populate archlinux
RUN pacman -S base-devel git --noconfirm

RUN useradd -m user \
    && echo 'user ALL=(ALL) NOPASSWD:ALL' | tee -a /etc/sudoers

USER user

WORKDIR /home/user
RUN git clone https://github.com/GlassROM/unbound-pkgbuild.git unbound
WORKDIR /home/user/unbound
RUN makepkg -sf --noconfirm --skippgpcheck

RUN rm *debug* && mv *.tar.zst unbound.tar.zst

FROM ghcr.io/glassrom/os-image-docker:latest

RUN pacman-key --init && pacman-key --populate archlinux

RUN set -x \
    && groupadd --system --gid 970 unbound \
    && useradd --system -g unbound -M --shell /bin/nologin --uid 970 unbound \
    && pacman -S --noconfirm unbound

COPY --from=builder /home/user/unbound/unbound.tar.zst /
RUN pacman -U --noconfirm /unbound.tar.zst && rm /unbound.tar.zst

STOPSIGNAL SIGQUIT

RUN yes | pacman -Scc

RUN curl -fSL --output /etc/unbound/root.hints https://www.internic.net/domain/named.cache
COPY unbound.conf /etc/unbound/unbound.conf
RUN chown -R unbound:unbound /etc/unbound

RUN rm -rf /etc/pacman.d/gnupg

EXPOSE 53/tcp 53/udp

USER unbound

CMD ["/seccomp-strict", "/usr/bin/unbound", "-d"]
