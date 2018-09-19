# Based on https://hub.docker.com/r/vanityshed/charybdis/~/dockerfile/
FROM alpine:3.8
LABEL maintainer="Greg Feigenson <kog@epiphanic.org>"

ENV CONFIGUREFLAGS="--enable-openssl --prefix=/irc"
ENV CHARYBDIS_RELEASE 4.1.1

# Build Charybdis
RUN set -x \
    && apk add --no-cache --virtual runtime-dependencies \
    automake \
    autoconf \
    libtool \
	openssl \
	openssl-dev \
        build-base \
        curl \
	bison \
	flex \
    && mkdir /charybdis-src && cd /charybdis-src \
    && curl -fsSL "https://github.com/charybdis-ircd/charybdis/archive/charybdis-${CHARYBDIS_RELEASE}.tar.gz" -o charybdis.tar.gz \
    && tar -zxf charybdis.tar.gz --strip-components=1 \
    && mkdir /irc \
    && ./autogen.sh \
    && ./configure ${CONFIGUREFLAGS} \
    && make \
    && make install \
    && apk del --purge build-dependencies openssl-dev \
    && cd /root \
    && rm -rf /charybdis-src \
    && rm -rf /src; exit 0

# Chary won't let us run as root, so let's add another user.
RUN adduser -u 1000 -S ircd \
    && addgroup -g 1000 -S ircd \
    && chown -R ircd:ircd /irc

# Take care of configuration.
RUN cp /irc/etc/reference.conf /irc/etc/ircd.conf \
    && sed -i '/^.*havent_read_conf.*$/d' /irc/etc/ircd.conf

# The user that we enter the container as, and that everything runs as
USER ircd
ENTRYPOINT ["/irc/bin/charybdis", "-pidfile", "/irc/ircd.pid", "-foreground"]
