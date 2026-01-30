# docker-rsyslog

Docker image running rsyslog with Prometheus metrics support.

## Features

- Based on Ubuntu 22.04
- Supports TCP (514) and UDP (514) syslog reception
- Unix socket at `/var/run/rsyslog/dev/log` for container sharing
- Includes [rsyslog_exporter](https://github.com/prometheus-community/rsyslog_exporter) for Prometheus metrics
- Easy configuration through volume mounts

## Quick Start

```bash
docker run -d --name syslog -p 514:514 -p 514:514/udp acaranta/docker-rsyslog
```

## How It Works

This image was inspired by [jpetazzo's syslogdocker](http://jpetazzo.github.io/2014/08/24/syslog-docker/), but avoids the explicit host bind-mount to `/dev`. Instead, rsyslog creates the socket in `/var/run/rsyslog/dev/log` rather than the default `/dev/log`. This allows using `--volumes-from` without conflict by creating a symbolic link from `/dev/log` to the socket in the shared volume.

To view logs with `docker logs syslog` instead of using `docker exec`, you can configure rsyslog to send specific facilities to stderr:

```
# /etc/rsyslog.d/20-user.conf

local1.*  {
    /proc/self/fd/2
    stop
}
```

## Usage Examples

### 1. Symlink to /dev/log

If you need to use `/dev/log`, start any container with:

```bash
docker run -it --rm --volumes-from syslog debian:bookworm \
  bash -c "ln -sf /var/run/rsyslog/dev/log /dev/log && logger -p local1.notice This is a notice!"
```

For production use, create the symlink in your Dockerfile or entrypoint script.

### 2. Use the Custom Socket Location Directly

If your application can send logs to a custom socket:

```bash
docker run -it --rm --volumes-from syslog debian:bookworm \
  logger -u /var/run/rsyslog/dev/log -t myapp -p local1.error This is an error!
```

### 3. Use a Remote TCP Connection

Send logs over TCP to port 514:

```bash
docker run -it --rm --link syslog debian:bookworm \
  logger -n syslog -T -P 514 -p local1.error This is a remote error!
```

### 4. Use socat to Connect Local Socket to Remote Host

```bash
socat UNIX-LISTEN:/dev/log,reuseaddr,fork TCP:syslog:514
```

## Configuration

### Adding Custom Configuration

Create configuration files and mount them to `/etc/rsyslog.d/` or `/etc/rsyslogdocker.d/`:

- `/etc/rsyslogdocker.d/*.conf` - Loaded first
- `/etc/rsyslog.d/*.conf` - Loaded second

### Docker Compose Example

```yaml
services:
  rsyslog:
    image: acaranta/docker-rsyslog:latest
    volumes:
      - logs:/var/log
      - /etc/localtime:/etc/localtime:ro
      - ./rsyslog/conf.d:/etc/rsyslog.d
      # Optionally override main config:
      # - ./rsyslog/rsyslog.conf:/etc/rsyslog.conf
    ports:
      - "514:514"
      - "514:514/udp"

volumes:
  logs:
```

### Environment and Timezone

Mount `/etc/localtime` read-only to sync the container timezone with your host:

```yaml
volumes:
  - /etc/localtime:/etc/localtime:ro
```

## Prometheus Metrics with rsyslog_exporter

This image includes [rsyslog_exporter](https://github.com/prometheus-community/rsyslog_exporter), a Prometheus exporter for rsyslog metrics maintained by the Prometheus community.

### About rsyslog_exporter

The exporter parses rsyslog's `impstats` output and exposes metrics including:
- Messages processed per action/input
- Queue sizes and operations
- Resource utilization (memory, file descriptors)
- Error counts and retries

For full documentation on available metrics and configuration options, see the [rsyslog_exporter GitHub repository](https://github.com/prometheus-community/rsyslog_exporter).

### Enabling Prometheus Metrics

1. **Configure rsyslog to output stats** by adding to your rsyslog config:

   ```
   # Enable impstats module
   module(load="impstats"
          interval="10"
          format="json"
          resetCounters="on"
          ruleset="stats")

   # Create ruleset to write stats to a file
   ruleset(name="stats") {
       action(type="omfile" file="/var/log/rsyslog-stats.log")
   }
   ```

2. **Run the exporter** (located at `/usr/local/bin/rsyslog_exporter`):

   ```bash
   /usr/local/bin/rsyslog_exporter --rsyslog.stats-file=/var/log/rsyslog-stats.log
   ```

   The exporter listens on port `9104` by default.

3. **Docker Compose example with metrics**:

   ```yaml
   services:
     rsyslog:
       image: acaranta/docker-rsyslog:latest
       volumes:
         - logs:/var/log
         - ./rsyslog-stats.conf:/etc/rsyslog.d/stats.conf
       ports:
         - "514:514"
         - "514:514/udp"
         - "9104:9104"  # Prometheus metrics
       command: >
         bash -c "rsyslogd -n &
                  /usr/local/bin/rsyslog_exporter --rsyslog.stats-file=/var/log/rsyslog-stats.log"

   volumes:
     logs:
   ```

### Prometheus Scrape Configuration

```yaml
scrape_configs:
  - job_name: 'rsyslog'
    static_configs:
      - targets: ['rsyslog:9104']
```

## Building

```bash
docker build -t docker-rsyslog .
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
