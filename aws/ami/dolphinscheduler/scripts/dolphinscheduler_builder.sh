#!/bin/bash

if [[ "${DEBUG}" == "true" ]]; then
    set -euxo pipefail
fi

unset HISTFILE
history -cw

echo "=== Export Setting ==="
export ZOOKEEPER_VERSION=${ZOOKEEPER_VERSION:-3.6.3}
export ZOOKEEPER_HOME="/srv/zookeeper"
export DOLPHINSCHEDULER_VERSION="${DOLPHINSCHEDULER_VERSION:-3.0.0-beta-2}"
export DOLPHINSCHEDULER_HOME="/srv/dolphinscheduler"
export TMP_DIST_HOME="/srv/dist"

echo "=== Prepare ==="
# TODO do not know how to change to default user currently
# sudo useradd dolphinscheduler
# echo "dolphinscheduler" | passwd --stdin dolphinscheduler
sudo sed -i '$adolphinscheduler  ALL=(ALL)  NOPASSWD: NOPASSWD: ALL' /etc/sudoers
sudo sed -i 's/Defaults    requirett/#Defaults    requirett/g' /etc/sudoers

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo mkdir -p "${DOLPHINSCHEDULER_HOME}"
sudo mkdir -p "${ZOOKEEPER_HOME}"
sudo mkdir -p "${TMP_DIST_HOME}"
sudo chown -R ubuntu:ubuntu "${DOLPHINSCHEDULER_HOME}" "${ZOOKEEPER_HOME}" "${TMP_DIST_HOME}"

wget --directory-prefix=${TMP_DIST_HOME} https://dlcdn.apache.org/zookeeper/zookeeper-"${ZOOKEEPER_VERSION}"/apache-zookeeper-"${ZOOKEEPER_VERSION}"-bin.tar.gz 
wget --directory-prefix=${TMP_DIST_HOME} https://dlcdn.apache.org/dolphinscheduler/"${DOLPHINSCHEDULER_VERSION}"/apache-dolphinscheduler-"${DOLPHINSCHEDULER_VERSION}"-bin.tar.gz

echo "=== Install Dependence ==="
sudo apt-get -qq update
sudo apt-get -y -qq install --no-install-recommends \
    psmisc \
    openjdk-8-jdk \
    postgresql \
    postgresql-contrib \
    postgresql-client
tar -xzf ${TMP_DIST_HOME}/apache-dolphinscheduler-"${DOLPHINSCHEDULER_VERSION}"-bin.tar.gz -C "${DOLPHINSCHEDULER_HOME}" --strip-components=1
tar -xzf ${TMP_DIST_HOME}/apache-zookeeper-"${ZOOKEEPER_VERSION}"-bin.tar.gz -C "${ZOOKEEPER_HOME}" --strip-components=1
sudo apt-get -y -qq --purge autoremove
sudo apt-get autoclean
sudo apt-get clean

echo "=== Services Prepare ==="
sudo mkdir -p "${ZOOKEEPER_HOME}"/data
sudo cp "${ZOOKEEPER_HOME}"/conf/zoo_sample.cfg "${ZOOKEEPER_HOME}"/conf/zoo.cfg
sudo chown -R ubuntu:ubuntu "${DOLPHINSCHEDULER_HOME}" "${ZOOKEEPER_HOME}" "${TMP_DIST_HOME}"

sudo cp /tmp/zookeeper.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-standalone.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-alter.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-api.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-master.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-worker.service /lib/systemd/system/

# make system cost less of memory
sudo sed -i -E 's/(max-cpu-load-avg:) (.*?)/\1 1000/g' "${DOLPHINSCHEDULER_HOME}"/standalone-server/conf/application.yaml
sudo sed -i -E 's/(reserved-memory:) (.*?)/\1 0.001/g' "${DOLPHINSCHEDULER_HOME}"/standalone-server/conf/application.yaml
sudo sed -i -E 's/(exec-threads:) (.*?)/\1 5/g' "${DOLPHINSCHEDULER_HOME}"/standalone-server/conf/application.yaml

# Only need to auto restart the standalone server. In cluster deployment we will enable those service to start the cluster we also diable postgresql here,
sudo systemctl daemon-reload
sudo systemctl disable zookeeper
sudo systemctl disable postgresql
sudo systemctl disable dolphinscheduler-alter
sudo systemctl disable dolphinscheduler-api
sudo systemctl disable dolphinscheduler-master
sudo systemctl disable dolphinscheduler-worker
sudo systemctl enable dolphinscheduler-standalone

echo "=== System Cleanup ==="
sudo rm -f /root/.bash_history
sudo rm -f /home/dolphinscheduler/.bash_history
sudo rm -f /var/log/wtmp
sudo rm -f /var/log/btmp
sudo rm -rf "${TMP_DIST_HOME}"
sudo rm -rf /var/log/installer
sudo rm -rf /var/lib/cloud/instances
sudo rm -rf /tmp/* /var/tmp/* /tmp/.*-unix
sudo find /var/cache -type f -delete
sudo find /var/log -type f | while read f; do echo -n '' | sudo tee $f > /dev/null; done;
sudo find /var/lib/apt/lists -not -name lock -type f -delete
sudo sync

echo "=== All Done =="