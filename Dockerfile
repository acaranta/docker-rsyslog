FROM golang:alpine AS build-exporter

WORKDIR /build

RUN apk add --no-cache git
RUN git clone https://github.com/prometheus-community/rsyslog_exporter.git .

RUN go mod download
RUN CGO_ENABLED=0 go build -o rsyslog_exporter -trimpath -ldflags "-s -w"


FROM ubuntu:22.04
MAINTAINER Arthur Caranta <arthu@caranta.com>

RUN apt-get update && \
    apt-get install rsyslog sysvinit-utils --no-install-recommends -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build-exporter /build/rsyslog_exporter /usr/local/bin/rsyslog_exporter

COPY rsyslog.conf /etc/
RUN mkdir -p /etc/rsyslogdocker.d

EXPOSE 514/tcp 514/udp

CMD kill -9 $(cat /run/rsyslogd.pid) ; rm /run/rsyslogs.pid ;rsyslogd -n
