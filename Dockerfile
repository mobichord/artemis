FROM debian:bullseye-slim as builder

WORKDIR /dist

ENV ARTEMIS_VERSION=2.22.0

RUN set -xe \
    && apt-get -qq update \
    && apt-get -qq -y --no-install-recommends install ca-certificates curl \
    && curl "$(curl -s https://www.apache.org/dyn/closer.cgi\?preferred=true)"activemq/activemq-artemis/${ARTEMIS_VERSION}/apache-artemis-${ARTEMIS_VERSION}-bin.tar.gz --output artemis.tar.gz \
    && tar xzf artemis.tar.gz --strip 1 \
    && rm -rf artemis.tar.gz


FROM azul/zulu-openjdk-debian:18

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt

ENV ARTEMIS_VERSION=2.22.0
ENV ARTEMIS_USER artemis
ENV ARTEMIS_PASSWORD artemis
ENV ANONYMOUS_LOGIN true
ENV EXTRA_ARGS --http-host 0.0.0.0 --relax-jolokia

# Web Server
EXPOSE 8161 \
# JMX Exporter
    9404 \
# Port for CORE,MQTT,AMQP,HORNETQ,STOMP,OPENWIRE
    61616 \
# Port for HORNETQ,STOMP
    5445 \
# Port for AMQP
    5672 \
# Port for MQTT
    1883 \
#Port for STOMP
    61613

RUN  groupadd -g 1000 -r artemis \
  && useradd -r -u 1000 -g artemis artemis \
  && apt-get -qq -o=Dpkg::Use-Pty=0 update \
  && apt-get -qq -o=Dpkg::Use-Pty=0 install -y libaio1 \
  && rm -rf /var/lib/apt/lists/*

USER artemis

COPY --from=builder /dist /opt/activemq-artemis

USER root

RUN mkdir /var/lib/artemis-instance && chown -R artemis.artemis /var/lib/artemis-instance

COPY ./docker-run.sh /

USER artemis

# Expose some outstanding folders
VOLUME ["/var/lib/artemis-instance"]
WORKDIR /var/lib/artemis-instance

ENTRYPOINT ["/docker-run.sh"]
CMD ["run"]