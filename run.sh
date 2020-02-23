#!/bin/bash

# Start influx
/usr/bin/influxd -config /etc/influxdb/influxdb.conf &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start influxd: $status"
  exit $status
fi

# Start telegraf:
/usr/bin/telegraf --config /etc/telegraf/telegraf.conf --config-directory /etc/telegraf/telegraf.d &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start telegraf: $status"
  exit $status
fi

set -a; . /etc/sysconfig/grafana-server; set +a

cd /usr/share/grafana

# Preconfigure grafana with required plugins and dashboards
mkdir -p /var/lib/grafana/dashboards
grafana-cli plugins install grafana-piechart-panel
curl ${GRAFANA_DASHBOARD_URL} > /var/lib/grafana/dashboards/grafana_powerwall.json
chown -R grafana:grafana /var/lib/grafana

/usr/sbin/grafana-server \
	--config=${CONF_FILE}                                   \
	--pidfile=${PID_FILE_DIR}/grafana-server.pid            \
	--packaging=deb                                         \
	cfg:default.paths.logs=${LOG_DIR}                       \
	cfg:default.paths.data=${DATA_DIR}                      \
	cfg:default.paths.plugins=${PLUGINS_DIR}                \
	cfg:default.paths.provisioning=${PROVISIONING_CFG_DIR}

while sleep 60; do
  ps aux |grep influxd |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep telegraf |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done
