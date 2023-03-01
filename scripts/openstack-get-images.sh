#!/usr/bin/env bash

set -e
set -u
set -o pipefail

REMOTE_REGISTRY="quay.io"
REMOTE_NAMESPACE="openstack.kolla"
TAG="yoga"
LOCAL_REGISTRY="127.0.0.1:5000"
LOCAL_NAMESPACE="openstack.kolla"
OPENSTACK_IMAGE_NAMES="$1"

for f in $(grep -v '^#' $OPENSTACK_IMAGE_NAMES); do
    
    echo -e "\n\npulling : $f"
    #sudo docker run --rm --net=host  quay.io/skopeo/stable copy --dest-tls-verify=false docker://quay.io/openstack.kolla/$f:yoga docker://127.0.0.1:5000/openstack.kolla/$f:yoga
    sudo docker run --rm --net=host  \
         $REMOTE_REGISTRY/skopeo/stable copy --dest-tls-verify=false docker://$REMOTE_REGISTRY/$REMOTE_NAMESPACE/$f:$TAG docker://$LOCAL_REGISTRY/$LOCAL_NAMESPACE/$f:$TAG

done
