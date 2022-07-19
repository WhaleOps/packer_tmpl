#!/bin/env bash

unset HISTFILE
history -cw

echo "=== Waiting for Cloud-Init ==="
timeout 180 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished &>/dev/null; do echo waiting...; sleep 6; done'

echo "=== Export Setting ==="
export ZOOKEEPER_VERSION=${ZOOKEEPER_VERSION:-3.6.3}
export ZOOKEEPER_HOME="/srv/zookeeper"
export DOLPHINSCHEDULER_VERSION="${DOLPHINSCHEDULER_VERSION:-3.0.0-beta-2}
export DOLPHINSCHEDULER_HOME="/srv/dolphinscheduler"
export TMP_DIST_HOME="/srv/dist"

echo "=== Prepare ==="
echo "dolphinscheduler" | passwd --stdin dolphinscheduler
sudo sed -i '$adolphinscheduler  ALL=(ALL)  NOPASSWD: NOPASSWD: ALL' /etc/sudoers
sudo sed -i 's/Defaults    requirett/#Defaults    requirett/g' /etc/sudoers

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo mkdir -p "${DOLPHINSCHEDULER_HOME}"
sudo mkdir -p "${ZOOKEEPER_HOME}"
sudo mkdir -p "${TMP_DIST_HOME}"

wget --directory-prefix=${TMP_DIST_HOME} https://dlcdn.apache.org/zookeeper/zookeeper-"${ZOOKEEPER_VERSION}"/apache-zookeeper-"${ZOOKEEPER_VERSION}"-bin.tar.gz 
wget --directory-prefix=${TMP_DIST_HOME} https://www.apache.org/dyn/closer.lua/dolphinscheduler/"${DOLPHINSCHEDULER_VERSION}"/apache-dolphinscheduler-"${DOLPHINSCHEDULER_VERSION}"-bin.tar.gz


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

echo "=== Services ==="
sudo mkdir -p "${ZOOKEEPER_HOME}"/data
sudo cp "${ZOOKEEPER_HOME}"/conf/zoo_sample.cfg "${ZOOKEEPER_HOME}"/conf/zoo.cfg
sudo sed -i -r -e '/^dataDir/s/=.*/=\\/srv\\/zookeeper\\/data' /srv/zookeeper/conf/zoo.cfg

echo "=== Poster ==="
sudo cp /tmp/zookeeper.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-alter.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-api.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-master.service /lib/systemd/system/
sudo cp /tmp/dolphinscheduler-worker.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable zookeeper.service
sudo systemctl enable dolphinscheduler-alter.service
sudo systemctl enable dolphinscheduler-api.service
sudo systemctl enable dolphinscheduler-master.service
sudo systemctl enable dolphinscheduler-worker.service

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