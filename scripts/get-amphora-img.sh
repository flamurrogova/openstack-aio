#!/usr/bin/env bash

set -o errexit
set -o pipefail

# auto created by kolla
# openstack flavor create --vcpus 1 --ram 1024 --disk 2 "amphora" --private

# Amphora image - build from source
sudo apt --yes install debootstrap qemu-utils git kpartx

# Acquire the Octavia source code
git clone https://opendev.org/openstack/octavia -b stable/2023.1

# Install diskimage-builder, ideally in a virtual environment:
python3 -m venv dib-venv
source dib-venv/bin/activate

pip install diskimage-builder

# Create the Amphora image
cd octavia/diskimage-create
./diskimage-create.sh

# Source octavia user openrc
source /etc/kolla/octavia-openrc.sh

# Register the image in Glance
openstack image create amphora-x64-haproxy.qcow2 --container-format bare --disk-format qcow2 --private --tag amphora --file amphora-x64-haproxy.qcow2 --property hw_architecture='x86_64' --property hw_rng_model=virtio

# leave python venv
deactivate

