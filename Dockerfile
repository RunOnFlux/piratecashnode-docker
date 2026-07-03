FROM ubuntu:22.04
LABEL com.centurylinklabs.watchtower.enable="true"

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates wget curl jq pwgen supervisor cron tar gzip xz-utils bzip2 unzip procps \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /root/.piratecore /var/log/supervisor

# Install PirateCash Core (Dash v21 base). Asset extracts flat to
# piratecashd/piratecash-cli (no piratecashcore-<ver>/bin/ prefix).
ARG PIRATE_VERSION=21.1.1
RUN set -eux; \
    wget -qO /tmp/pirate.tbz2 \
      "https://github.com/piratecash/piratecash/releases/download/v${PIRATE_VERSION}-pirate/piratecashcore-${PIRATE_VERSION}-x86_64-pc-linux-gnu.tar.bz2"; \
    mkdir -p /tmp/pc; tar xjf /tmp/pirate.tbz2 -C /tmp/pc; \
    ( cp /tmp/pc/piratecashd /tmp/pc/piratecash-cli /usr/local/bin/ 2>/dev/null \
      || cp /tmp/pc/*/piratecashd /tmp/pc/*/piratecash-cli /usr/local/bin/ ); \
    chmod +x /usr/local/bin/piratecashd /usr/local/bin/piratecash-cli; \
    rm -rf /tmp/pc /tmp/pirate.tbz2

COPY coin.env /usr/local/bin/coin.env
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY node_initialize.sh /usr/local/bin/node_initialize.sh
COPY mn-autoheal.sh /usr/local/bin/mn-autoheal.sh
COPY check-health.sh /usr/local/bin/check-health.sh
RUN chmod 755 /usr/local/bin/node_initialize.sh /usr/local/bin/mn-autoheal.sh \
              /usr/local/bin/check-health.sh /usr/local/bin/coin.env

VOLUME /root/.piratecore
EXPOSE 63636
HEALTHCHECK --start-period=20m --interval=10m --retries=3 --timeout=15s CMD /usr/local/bin/check-health.sh
ENTRYPOINT ["/usr/bin/supervisord"]
