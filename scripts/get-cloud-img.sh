#!/usr/bin/env bash

set -o errexit
set -o pipefail

# cloud img download 

IMAGE=bionic-server-cloudimg-amd64.img
IMAGE_PATH=./
IMAGE_NAME=bionic
IMAGE_URL=https://cloud-images.ubuntu.com/bionic/current/


# https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

echo Checking for locally available $IMAGE image.
# Let's first try to see if the image is available locally
# nodepool nodes caches them in $IMAGE_PATH
if ! [ -f "${IMAGE_PATH}/${IMAGE}" ]; then
    IMAGE_PATH='./'
    if ! [ -f "${IMAGE_PATH}/${IMAGE}" ]; then
        echo "None found, downloading image $IMAGE."
        curl --fail --location --output ${IMAGE_PATH}/${IMAGE} ${IMAGE_URL}/${IMAGE}
    fi
else
    echo Using cached cirros image from the nodepool node.
fi


# Test to ensure configure script is run only once
if openstack image list | grep -q "$IMAGE_NAME"; then
    echo "Image '$IMAGE' already exists."
    exit
else
    echo "Creating glance image $IMAGE."
    openstack image create --disk-format qcow2 --container-format bare --public --property os_type=linux --file ${IMAGE_PATH}/${IMAGE} ${IMAGE_NAME}
fi


