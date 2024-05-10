#!/usr/bin/env bash

set -e
set -u
set -o pipefail

TAG="2023.1-ubuntu-jammy"
REMOTE_REGISTRY="quay.io"
REMOTE_NAMESPACE="openstack.kolla"
LOCAL_REGISTRY="127.0.0.1:5000"
LOCAL_NAMESPACE="openstack.kolla"

images=(\
        base \
        fluentd \
        kolla-toolbox \
        cron \
        haproxy \
        keepalived \
        mariadb-server \
        mariadb-clustercheck \
        memcached \
        rabbitmq \
        keystone \
        keystone-ssh \
        keystone-fernet \
        glance-api \
        placement-api \
        nova-api \
        nova-scheduler \
        nova-libvirt \
        nova-ssh \
        nova-novncproxy \
        nova-conductor \
        nova-compute \
        openvswitch-db-server \
        openvswitch-vswitchd \
        neutron-server \
        neutron-openvswitch-agent \
        neutron-dhcp-agent \
        neutron-l3-agent \
        neutron-metadata-agent \
        heat-api \
        heat-api-cfn \
        heat-engine \
        horizon \
        octavia-api \
        octavia-health-manager \
        octavia-housekeeping \
        octavia-worker )

for IMAGE in "${images[@]}"; do

    echo -e "\n\npulling : $REMOTE_NAMESPACE/$f:$TAG"
    sudo docker run --rm --net=host  \
         $REMOTE_REGISTRY/skopeo/stable copy --dest-tls-verify=false docker://$REMOTE_REGISTRY/$REMOTE_NAMESPACE/$IMAGE:$TAG docker://$LOCAL_REGISTRY/$LOCAL_NAMESPACE/$IMAGE:$TAG

done
