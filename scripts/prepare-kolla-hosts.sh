#!/usr/bin/env bash

# install kolla-openstack on ubuntu 2004

set -e
set -u
set -o pipefail

VENV_BASE=/opt/venv
OPENSTACK_RELEASE=yoga

# uncomment/configure this line if you use apt cache
#echo -n "\n\nconfigure apt-cacher\n" && echo "Acquire::http::Proxy \"http://192.168.1.227:3142\";" | sudo tee /etc/apt/apt.conf.d/00aptproxy

# 1. For Debian or Ubuntu, update the package index.
sudo apt update

# 2. Install Python build dependencies:
sudo apt install --yes python3-dev libffi-dev gcc libssl-dev sshpass

# Install dependencies using a virtual environment

# 1. Install the virtual environment dependencies.
sudo apt install --yes python3-venv

# 2. Create a virtual environment and activate it:
sudo mkdir -p $VENV_BASE/$OPENSTACK_RELEASE
sudo chown -R $USER:$USER $VENV_BASE/$OPENSTACK_RELEASE


python3 -m venv $VENV_BASE/$OPENSTACK_RELEASE
source $VENV_BASE/$OPENSTACK_RELEASE/bin/activate


# 3. Ensure the latest version of pip is installed:
pip install -U pip

# 4. Install Ansible. Kolla Ansible requires at least Ansible 4 and supports up to 5. - wallaby
pip install 'ansible>=4,<6'


# Install Kolla-ansible

# 1. Install kolla-ansible and its dependencies using pip.
# pip install git+https://opendev.org/openstack/kolla-ansible@stable/$OPENSTACK_RELEASE
pip install --upgrade git+https://github.com/openstack/kolla-ansible.git@stable/$OPENSTACK_RELEASE

pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/$OPENSTACK_RELEASE
pip install python-designateclient -c https://releases.openstack.org/constraints/upper/$OPENSTACK_RELEASE
pip install python-masakariclient  -c https://releases.openstack.org/constraints/upper/$OPENSTACK_RELEASE
pip install python-octaviaclient   -c https://releases.openstack.org/constraints/upper/$OPENSTACK_RELEASE
    
# 2. Create the /etc/kolla directory.
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla

# 3. Copy globals.yml and passwords.yml to /etc/kolla directory.
cp -r $VENV_BASE/$OPENSTACK_RELEASE/share/kolla-ansible/etc_examples/kolla/* /etc/kolla

# 4. Copy all-in-one and multinode inventory files to the current directory.
cp $VENV_BASE/$OPENSTACK_RELEASE/share/kolla-ansible/ansible/inventory/* .

# Install Ansible Galaxy dependencies (Yoga release onwards) 
kolla-ansible install-deps

# create root ssh keys
#ssh-keygen -b 2048 -t rsa -f /home/$USER/.ssh/id_rsa -q -N "" && \

sudo mkdir -p /etc/ansible
cat <<EOF | sudo tee /etc/ansible/ansible.cfg
[defaults]
host_key_checking=False
pipelining=True
forks=100
timeout=60
EOF

# generate passwords
kolla-genpwd



#
# This is the static IP we created initially
VIP_ADDR=10.10.30.55
# management interface 
MGMT_IFACE=eth1
# This is the dummy interface used for OpenVswitch
EXT_IFACE=eth3
# local docker registry
MY_REGISTRY="10.10.10.50:5000"

# now use the information above to write it to Kolla configuration file
sudo tee -a /etc/kolla/globals.yml << EOT
kolla_base_distro: "ubuntu"
kolla_internal_vip_address: "$VIP_ADDR"
network_interface: "$MGMT_IFACE"
neutron_external_interface: "$EXT_IFACE"

docker_registry: "$MY_REGISTRY"
docker_registry_insecure: "yes"


EOT



