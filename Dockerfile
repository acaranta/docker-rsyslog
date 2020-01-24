FROM ubuntu:18.10
MAINTAINER Arthur Caranta <arthu@caranta.com>

RUN apt-get update && \
    apt-get install rsyslog --no-install-recommends -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY rsyslog.conf /etc/
RUN mkdir -p /etc/rsyslogdocker.d
COPY 1-send_log_to_console.conf /etc/rsyslogdocker.d

EXPOSE 514/tcp 514/udp

CMD ["rsyslogd", "-n"]
