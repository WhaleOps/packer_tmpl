#!/bin/bash

# -------------------------------------------------------------------------------------------------------------------
# CLUSTER MACHINE CONFIGRATION
# Config mechine related information, like EC2 instances Public IPv4 DNS or address, ssh user a EC2 instance key pair
# -------------------------------------------------------------------------------------------------------------------
# The user can connect EC2 instance, if you do not chagne the default user, it is  `ubuntu` and you should set not thing to it
export INSTANCE_USER=${INSTANCE_USER:-"ubuntu"}

# The path of key pair to connect your EC2 instances
export INSTANCE_KEY_PAIR=${INSTANCE_KEY_PAIR:-"/path/to/your/key/pair"}

# A comma separated list of EC2 instances Public IPv4 DNS or Public IPv4 address would be installed DolphinScheduler, including master, worker, api, alert, database(if you want to start base on provided AMI)
# and zookeeper(if you want to start base on provided AMI). These instances are must launch by dolphinscheudler AMI.
# Example for hostnames: ips="ds1,ds2,ds3,ds4,ds5", Example for IPs: ips="192.168.8.1,192.168.8.2,192.168.8.3,192.168.8.4,192.168.8.5"
export ips=${ips:-"ds1,ds2,ds3,ds4,ds5,ds6"}

# Port of SSH protocol, default value is 22. For now we only support same port in all `ips` EC2 instances, modify it if you use different ssh port
export sshPort=${sshPort:-"22"}

# A comma separated list of EC2 instances Public IPv4 DNS or Public IPv4 address would be installed Master server, it must be a subset of configuration `ips`.
# Example for hostnames: masters="ds1,ds2", Example for IPs: masters="192.168.8.1,192.168.8.2"
export masters=${masters:-"ds1,ds2"}

# A comma separated list of EC2 instances Public IPv4 DNS or Public IPv4 address <hostname>:<workerGroup> or <IP>:<workerGroup>. All hostname or IP must be a subset of configuration `ips`,
# And workerGroup have default value as `default`, but we recommend you declare behind the hosts
# Example for hostnames: workers="ds1:default,ds2:default,ds3:default", Example for IPs: workers="192.168.8.1:default,192.168.8.2:default,192.168.8.3:default"
export workers=${workers:-"ds3:default,ds4:default,ds5:default"}

# A comma separated list of EC2 instances Public IPv4 DNS or Public IPv4 address would be installed Alert server, it must be a subset of configuration `ips`.
# Example for hostname: alertServer="ds3", Example for IP: alertServer="192.168.8.3"
export alertServer=${alertServer:-"ds2"}

# A comma separated list of EC2 instances Public IPv4 DNS or Public IPv4 address would be installed API server, it must be a subset of configuration `ips`.
# Example for hostname: apiServers="ds1", Example for IP: apiServers="192.168.8.1"
export apiServers=${apiServers:-"ds1"}

# Database related configuration, set database type, username and password, this instance must launch by dolphinscheudler AMI, **Private IP DNS name or Private IPv4 addresses is encouraged to use here**
# NOTE: You should comment config `export DATABASE_SERVER=${DATABASE_SERVER:-"ds6"}` and change `SPRING_DATASOURCE_URL` to your own connect string if you want to use already DATABASE_SERVER. But you have to make sure
# your `SPRING_DATASOURCE_URL` have dolphinscheudler metadata init on it.
export DATABASE_SERVER=${DATABASE_SERVER:-"ds6"}
export DATABASE=postgresql
export SPRING_PROFILES_ACTIVE=${DATABASE}
export SPRING_DATASOURCE_URL="jdbc:postgresql://${DATABASE_SERVER}:5432/dolphinscheduler"
export SPRING_DATASOURCE_USERNAME="dolphinscheduler"
export SPRING_DATASOURCE_PASSWORD="dolphinscheduler"

# Registry center configuration, determines the type and link of the registry center, this instance must launch by dolphinscheudler AMI, **Private IP DNS name or Private IPv4 addresses is encouraged to use here**.
# NOTE: You should comment config `export REGISTRY_SERVER=${REGISTRY_SERVER:-"ds6"}` and change `REGISTRY_ZOOKEEPER_CONNECT_STRING` to your own connect string if you want to use already REGISTRY_SERVER.
export REGISTRY_SERVER=${REGISTRY_SERVER:-"ds6"}
export REGISTRY_TYPE=${REGISTRY_TYPE:-zookeeper}
export REGISTRY_ZOOKEEPER_CONNECT_STRING=${REGISTRY_ZOOKEEPER_CONNECT_STRING:-${REGISTRY_SERVER}:2181}

# ---------------------------------------------------------
# CLUSTER RUNTIME CONFIGRATION
# Overwirte dolphinscheduler runtime configuration, to reduce resource requirements, if you start the EC2 instance with larget instance type or runing in production,
# you can set to bigger value
# ---------------------------------------------------------
# All service default JAVA opts, will source on this before start each server
export JAVA_OPTS=${JAVA_OPTS:-"-server -Duser.timezone=UTC -Xms256m -Xmx1g -Xmn128m -XX:+PrintGCDetails -Xloggc:gc.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dump.hprof"}

# Add this part of config to run dolphinscheudler in AWS EC2 without too many resource, if you use performance mechine or in prod enviroment, please change below config for better performance
# master prepare execute thread number to limit handle commands in parallel, will overwrite config `master.exec-threads`
export MASTER_EXECTHREADS=${MASTER_EXECTHREADS:-10}
# master max cpuload avg, only higher than the system cpu load average, master server can schedule. will overwrite config `master.exec-threads`
export MASTER_MAXCPULOADAVG=${MASTER_MAXCPULOADAVG:-1000}
# master reserved memory, only lower than system available memory, master server can schedule. The unit is G, will overwrite config `master.reserved-memory`
export MASTER_RESERVEDMEMORY=${MASTER_RESERVEDMEMORY:-0.01}
# worker prepare execute thread number to limit handle commands in parallel, will overwrite config `worker.exec-threads`
export WORKER_EXECTHREADS=${WORKER_EXECTHREADS:-10}
# worker max cpuload avg, only higher than the system cpu load average, worker server can schedule. will overwrite config `worker.exec-threads`
export WORKER_MAXCPULOADAVG=${WORKER_MAXCPULOADAVG:-1000}
# worker reserved memory, only lower than system available memory, worker server can schedule. The unit is G, will overwrite config `worker.reserved-memory`
export WORKER_RESERVEDMEMORY=${WORKER_RESERVEDMEMORY:-0.01}
