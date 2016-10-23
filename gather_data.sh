#!/bin/bash

command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed.  Aborting."; exit 1; }

if [ -z "${1}" ]; then
    echo "Please specify the IP of the leading mesos-master. Aborting." && exit 1
fi

get_and_write() {
    # $1 = Path to write logs
    # $2 = Array of logs URI's to get
    # $3 = Base URL including port
    curl -s "${3}" > /dev/null && (
        mkdir -p "${1}"
        for LOG in "${!2}"; do
            FILENAME=$(echo "$LOG" | cut -c 2- | sed 's/\//-/g')
            FILEPATH="${1}/${FILENAME}.log"
            curl -sf "${3}${LOG}" | jq . > "${FILEPATH}" || echo "Could not write ${LOG}"
        done
        ) || echo "Could not reach ${3}"
}

TIMESTAMP=$(date "+%Y%m%d%H%M%S")
TMPDIR="/tmp/${TIMESTAMP}"

MESOS_MASTER_LOGS=(
    '/__processes__'
    '/metrics/snapshot'
    '/system/stats.json'
    '/state.json'
)
MARATHON_LOGS=(
    '/v2/apps'
    '/v2/groups'
    '/v2/tasks'
    '/v2/deployments'
    '/v2/queue'
    '/v2/eventSubscriptions'
    '/v2/info'
    '/v2/leader'
    '/metrics'
)
EXHIBITOR_LOGS=(
    '/cluster/status'
    '/cluster/state'
    '/cluster/log'
    '/config/get-state'
)
AGENT_LOGS=(
    '/system/stats.json'
    '/slave(1)/state.json'
    '/__processes__'
    '/metrics/snapshot'
)
LOCAL_SERVICES=(
    'dcos-exhibitor.service'
    'dcos-gen-resolvconf'
    'dcos-history-service.service'
    'dcos-logrotate'
    'dcos-marathon.service'
    'dcos-mesos-dns.service'
    'dcos-mesos-master.service'
    'dcos-nginx-reload'
    'dcos-nginx.service'
    'dcos-signal'
    'dcos-signal.service'
)
# Get master, marathon and exhibitor endpoints
get_and_write "${TMPDIR}/mesos-master" MESOS_MASTER_LOGS[@] "http://${1}:5050"
get_and_write "${TMPDIR}/marathon" MARATHON_LOGS[@] "http://${1}:8080"
get_and_write "${TMPDIR}/exhibitor" EXHIBITOR_LOGS[@] "http://${1}:8181"    

STATE=$(curl -s "http://${1}:5050/state.json")

# Get agent endpoints
AGENTS=$(echo "${STATE}" | jq -r '.slaves[].hostname')
for AGENT in $AGENTS; do
    get_and_write "${TMPDIR}/mesos-agent/${AGENT}" AGENT_LOGS[@] "http://${AGENT}:5051"
done

# Get marathon app configs
mkdir -p "${TMPDIR}/marathon/apps"
APPS=$(curl -s "http://${1}:8080/v2/apps" | jq -r '.apps[].id')
for APP in $APPS; do
    curl -s "http://${1}:8080/v2/apps$APP" | jq . > "${TMPDIR}/marathon/apps$APP.log"
done

# Get systemd logs
mkdir -p "${TMPDIR}/systemd"
for SERVICE in "${LOCAL_SERVICES[@]}"; do
    journalctl -u "${SERVICE}" --no-pager -n 100000 > "${TMPDIR}/systemd/${SERVICE}.log"
done

# Dump system info
df -h > "${TMPDIR}/df.log"
free -h > "${TMPDIR}/free.log"
lsof > "${TMPDIR}/lsof.log"
netstat -anp > "${TMPDIR}/netstat.log"
dmesg > "${TMPDIR}/dmesg.log"
top -d 1 -n 5 > "${TMPDIR}/top.log"
ifconfig > "${TMPDIR}/ifconfig.log"
journalctl -xn 1000000 > "${TMPDIR}/journalctl.log"
cat /proc/meminfo > "${TMPDIR}/meminfo.log"
cat /proc/cpuinfo > "${TMPDIR}/cpuinfo.log"

# Build cluster summary
TOT_CPU=$(echo "${STATE}" | jq '.slaves[].resources.cpus' | awk '{ SUM += $1} END { print SUM }')
TOT_DISK=$(echo "${STATE}" | jq '.slaves[].resources.disk' | awk '{ SUM += $1} END { print SUM }')
TOT_MEM=$(echo "${STATE}" | jq '.slaves[].resources.mem' | awk '{ SUM += $1} END { print SUM }')
cat <<EOF > "${TMPDIR}/cluster_summary"
----- CLUSTER SUMMARY -----
Number of Masters: $(curl -s "${1}:8181/exhibitor/v1/cluster/status" | jq '.[].hostname' | wc -l)
Number of Agents: $(echo "${STATE}" | jq '.slaves[].hostname' | wc -l)
OS Version: $(uname -srvmo)
Cluster Name: $(echo "${STATE}" | jq -r '.cluster')
Number of CPU's: $(echo "${TOT_CPU}")
Total Disk Space: $(echo "${TOT_DISK}")MB
Total Memory: $(echo "${TOT_MEM}")MB
Total Frameworks: $(echo "${STATE}" | jq '.frameworks[]' | grep framework_id | sort | uniq | wc -l)
Active Frameworks: $(echo "${STATE}" | jq '.frameworks[].tasks[].framework_id' | sort | uniq | wc -l)
Total Marathon Apps: $(echo "${APPS}" | wc -w)
Total Mesos Tasks: $(echo "${STATE}" | jq ".frameworks[].tasks[].id" | wc -l)
Mesos Version: $(echo "${STATE}" | jq -r '.version')
Marathon Version: $(curl -s "http://${1}:8080/v2/info" | jq -r '.version')
EOF

# Copy DCOS configs
mkdir -p "${TMPDIR}/opt/mesosphere"
cp -rL /opt/mesosphere/etc "${TMPDIR}/opt/mesosphere/"

# Create tarball
tar -czf "/tmp/dcos-${TIMESTAMP}.tar.gz" -C "${TMPDIR}" . && rm -rf "${TMPDIR}" && echo "Created /tmp/dcos-${TIMESTAMP}.tar.gz" || echo "Could not create .tar.gz.  Check ${TMPDIR}."
