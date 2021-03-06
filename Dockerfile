FROM ubuntu:20.04
MAINTAINER Arthur Caranta <arthu@caranta.com>

RUN apt-get update && \
    apt-get install rsyslog sysvinit-utils --no-install-recommends -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY rsyslog.conf /etc/
RUN mkdir -p /etc/rsyslogdocker.d
#COPY 1-send_log_to_console.conf /etc/rsyslogdocker.d

EXPOSE 514/tcp 514/udp

CMD kill -9 $(cat /run/rsyslogd.pid) ; rm /run/rsyslogs.pid ;rsyslogd -n
