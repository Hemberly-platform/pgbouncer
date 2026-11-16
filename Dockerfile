FROM alpine:3.22 AS build
ARG VERSION=1.26.1

# Inspiration from https://github.com/gmr/alpine-pgbouncer/blob/master/Dockerfile
# hadolint ignore=DL3003,DL3018
RUN apk add --no-cache autoconf automake curl gcc libc-dev libevent-dev libtool make openssl-dev pkgconfig

# build version for release
RUN curl -sS -o /pgbouncer.tar.gz -L https://www.pgbouncer.org/downloads/files/$VERSION/pgbouncer-$VERSION.tar.gz && \
  echo "00886a2994b4844cd37110970df777772cfc42a74c400522c82fba509a3f42d9  /pgbouncer.tar.gz" | sha256sum -c - && \
  tar -xzf /pgbouncer.tar.gz && mv /pgbouncer-$VERSION /pgbouncer

RUN cd /pgbouncer && ./configure --prefix=/usr && make -j$(nproc) pgbouncer && strip pgbouncer

FROM alpine:3.23

RUN apk add --no-cache libevent openssl postgresql-client && \
  mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer && \
  touch /etc/pgbouncer/userlist.txt && \
  chown -R postgres /var/log/pgbouncer /var/run/pgbouncer /etc/pgbouncer

COPY entrypoint.sh /entrypoint.sh
COPY --from=build /pgbouncer/pgbouncer /usr/bin
COPY --from=build /pgbouncer/etc/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini.example
COPY --from=build /pgbouncer/etc/userlist.txt /etc/pgbouncer/userlist.txt.example
EXPOSE 5432
USER postgres
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
