#!/bin/bash

set -euo pipefail

USAGE="Usage: cluster.sh <start>

    start     Start DolphinScheduler cluster from config EC2 instance.
"

# Confirem from user input with given hint message
function comfire_with_message() {
    echo "  --> ${1}"
    read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
}

# Stop standalone server
function stop_standalone_server() {
    local host=$1
    ssh -i "${INSTANCE_KEY_PAIR}" -o StrictHostKeyChecking=no "${INSTANCE_USER}@${host}" "sudo systemctl disable dolphinscheduler-standalone; sudo systemctl stop dolphinscheduler-standalone"
}

# Start database and zookeeper server
function start_server() {
    local host=$1
    local server=$2
    ssh -i "${INSTANCE_KEY_PAIR}" -o StrictHostKeyChecking=no "${INSTANCE_USER}@${host}" "sudo systemctl start ${server}; sudo systemctl enable ${server}"
}

# Change start-all.sh content
function change_file_start_all() {
    local path=$1
    if [ "$(uname)" == "Darwin" ]; then
        inplace_flag="-i ''"
    else
        inplace_flag="-i"
    fi

    # Add hostname
    # FIXME: Temp add deploy user to start script, using '||' to avid 'sed -i s///g filename' error in macos
    sed ${inplace_flag} 's/ $master / $INSTANCE_USER@$master /g' "${path}"
    sed ${inplace_flag} 's/ $worker / $INSTANCE_USER@$worker /g' "${path}"
    sed ${inplace_flag} 's/ $alertServer / $INSTANCE_USER@$alertServer /g' "${path}"
    sed ${inplace_flag} 's/ $apiServer / $INSTANCE_USER@$apiServer /g' "${path}"
    # Add connect by pem file
    sed ${inplace_flag} "s|ssh -o|ssh -i ${INSTANCE_KEY_PAIR} -o|g" "${path}"
    # Delete check status, comemnt the check
    sed ${inplace_flag} 's/echo "query server status"/#&/g' "${path}"
    sed ${inplace_flag} 's|cd $installPath/; bash bin/status-all.sh|#&|g' "${path}"
    # Source some env define in this script
    sed ${inplace_flag} 's|bash bin/dolphinscheduler-daemon.sh|source /tmp/cluster_env.sh; &|g' "${path}"
}

if test "$#" -ne 1; then
    echo "Illegal number of argument, only accept one but get $#."
    echo
    echo "${USAGE}"
    exit 1
else
    argument=$1
    shift
fi

# Variable declaration
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RUNNER_DIR="${CURRENT_DIR}/runner"
CLUSTER_ENV="${CURRENT_DIR}/cluster_env.sh"
# file from EC2 instances
INSTANCE_DS_HOME="/srv/dolphinscheduler"

source "${CLUSTER_ENV}"

case ${argument} in
    (start)
        echo "==> Get start-all script from one of config 'ips'."
        if [[ ! -d "${RUNNER_DIR}" ]]; then
            mkdir -p "${RUNNER_DIR}"
        fi
        one_ip=$(echo ${ips} | cut -d "," -f 1)
        scp -i "${INSTANCE_KEY_PAIR}" -o StrictHostKeyChecking=no "${INSTANCE_USER}@${one_ip}:${INSTANCE_DS_HOME}/bin/start-all.sh" "${RUNNER_DIR}"

        echo "==> Stop standalone server for all EC2 instances and upload cluster_env.sh."
        hostsArr=($(echo "${ips}" | tr ',' '\n'))
        for host in "${hostsArr[@]}"; do
            echo "--> Operate for host ${host}."
            scp -i "${INSTANCE_KEY_PAIR}" -o StrictHostKeyChecking=no "${CLUSTER_ENV}" "${INSTANCE_USER}@${host}:/tmp"
            stop_standalone_server "${host}"
        done

        echo "==> Start database and zookeeper."
        if [[ ! -z "${DATABASE_SERVER}" ]]; then
            start_server "${DATABASE_SERVER}" "postgresql"
        fi
        if [[ ! -z "${REGISTRY_SERVER}" ]]; then
            start_server "${REGISTRY_SERVER}" "zookeeper"
        fi
        echo "--> Sleep 10s to wait database and zookeeper be prepare."
        sleep 10

        echo "==> Start all others server."
        change_file_start_all "${RUNNER_DIR}/start-all.sh"
        # Need to export install path to avoid No such file or directory error
        export installPath="${INSTANCE_DS_HOME}"
        bash "${RUNNER_DIR}/start-all.sh"
        ;;
    (*)
        echo "${USAGE}"
        exit 1
        ;;
esac
