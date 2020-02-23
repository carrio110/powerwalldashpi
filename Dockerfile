FROM influxdb
MAINTAINER Rich Carr <richardcarr@gmail.com>

ENV POWERWALL_HOST="teslapw"
ENV DATABASE="PowerwallData"

# Defaults for InfluxDB
ENV INFLUXDB_HTTP_ENABLED=true \
    INFLUXDB_HTTP_BIND_ADDRESS="127.0.0.1:8086" \
    INFLUXDB_HTTP_AUTH_ENABLED=false \
    INFLUXDB_HTTP_LOG_ENABLED=true

## InfluxDB stores data by default at /var/lib/influxdb/[data|wal]
## which should be mapped to a docker/podman volume for persistence

# Defaults for Grafana
ENV PROVISIONING_CFG_DIR="/etc/grafana/provisioning/" \
    PLUGINS_DIR="/var/lib/grafana/plugins"

RUN apt-get update

RUN apt-get install -y apt-transport-https software-properties-common wget

RUN wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
RUN wget -qO- https://repos.influxdata.com/influxdb.key | apt-key add -

RUN add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
RUN add-apt-repository "deb https://repos.influxdata.com/debian stretch stable"

RUN apt-get update

RUN apt-get install -y grafana telegraf

ADD powerwall.conf /etc/telegraf/telegraf.d/powerwall.conf
ADD graf_DS.yaml /etc/grafana/provisioning/datasources/graf_DS.yaml
ADD graf_DA.yaml /etc/grafana/provisioning/dashboards/graf_DA.yaml

RUN mkdir -p /var/lib/grafana/dashboards && chown grafana:grafana /var/lib/grafana/dashboards

EXPOSE 3000

ADD run.sh /opt/run.sh
RUN chmod -v +x /opt/run.sh
RUN export $(grep -v "#" /etc/sysconfig/grafana-server | cut -d= -f1)

ENV POWERWALL_LOCATION="lat=36.2452052&lon=-113.7292593"

CMD ["/opt/run.sh"]
