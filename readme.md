# Openstack installation workflow

Openstack is open source cloud platform.  
It virtualises compute, network and storage resources, and enables multi-tenant usage of those resources based on self-service model.   

In general, Openstack cluster consists of :  
- control plane nodes,  
- network nodes,  
- compute nodes,  
- storage nodes  

It is possible to have fully functional Openstack cluster running on single node.  
This guide shows how to setup Openstack cluster on single node by using kolla-ansible. Kolla-ansible is a deployment tool which installs Openstack components as Docker containers. 

Before starting any work we have to decide on network layout first.  

Openstack cluster makes use of many networking planes, for example, API network, cluster network, storage network, tenant traffic network (Neutron network), etc.  
In a production setup these networks should be dedicated networks. Our node will have only one physical interface, so we will create additional virtual interface for Neutron network, and will collocate all other networks on single physical interface.


This guide is based on deployment docs described at https://docs.openstack.org/project-deploy-guide/kolla-ansible/yoga


The steps we need to perform are:

1. Prepare deployment host
2. Configure deployment
3. Initiate cluster deployment
4. Verify Openstack operation

These guide has been tested on Ubuntu 20.04. Clone this repository and cd into it. It contains these shell scripts we will work on:
```
$ ls *sh
openstack-get-images.sh
prepare-kolla-hosts.sh
run-local-registry.sh
run-my-init.sh
```

Here is a short explanation of what each script does :
- run-local-registry.sh  
runs local docker registry
- openstack-get-images.sh  
populate local docker registry with container images
- prepare-kolla-hosts.sh  
this is main installation script, performs many steps as per the docs, setup venv environment, download system dependencies, download Ansible/Galaxy dependencies ...
- run-my-init.sh  
performs post-install creation of public/private networks, router, and uploads Cirros image to the cluster. 

# Prepare deployment host

Deployment hosts' purpose is to :
- store and run Ansible playbooks against target nodes (control plane nodes, compute nodes, network nodes), including cluster installation, cluster node additions/removals
- run a local docker registry to store Openstack container images

On deployment host, first we will install local docker registry.  
We will assume these IP addresses,
- local docker registry: 10.10.10.50
- Openstack VIP address: 10.10.30.55

Run the script ` run-local-registry.sh ` or simply execute 
```
docker run --detach --publish 5000:5000 --restart=always --name registry registry:2 
```

Next, populate the file ` openstack-image-names ` with docker image names of the Openstack services you want to include, otherwise leave it intact as it is already pre-populated with core services.

```
$ head openstack-image-names
# names of container images
ubuntu-source-base
ubuntu-source-fluentd
ubuntu-source-kolla-toolbox
ubuntu-source-haproxy
ubuntu-source-keepalived
ubuntu-source-mariadb-server
...
```

Next, set Openstack release tag on the script ` openstack-get-images.sh ` and run it (currently set to "yoga" Openstack release).  
```./openstack-get-images.sh```

This script will :
- download Openstack container images
- re-tag for local registry
- push to local registry

Query your local docker registry to confirm that it has been populated with docker images :
```
demo@deploy-0:~$ curl --silent http://10.30.1.10:5000/v2/_catalog | jq
{
  "repositories": [
    "kolla/ubuntu-source-base",
    "kolla/ubuntu-source-cron",
    "kolla/ubuntu-source-designate-api",
    "kolla/ubuntu-source-designate-backend-bind9",
    "kolla/ubuntu-source-designate-central",
    "kolla/ubuntu-source-designate-mdns",
    "kolla/ubuntu-source-designate-producer",
    "kolla/ubuntu-source-designate-sink",
    "kolla/ubuntu-source-designate-worker",
    "kolla/ubuntu-source-fluentd",
    "kolla/ubuntu-source-glance-api",
    ...
  ]
}

```

Next, generate SSH keys on deployment host and copy the keys to the target nodes :

```
ssh-keygen -t rsa -N '' -f ~/.ssh/deploy-key

# copy ssh key to all remote hosts
ssh-copy-id -i ~/.ssh/deploy-key.pub vagrant@10.10.10.51
...

```

Kolla-ansible needs passwordless login to remote Openstack nodes, so it can execute Ansible playbooks on them.

# Configure deployment

These are a series of steps needed to be executed on deployment node, prior to starting with cluster deployment.

- Install dependencies
- Install Kolla-Ansible
- Install Ansible Galaxy requirements
- Configure Ansible
- Prepare initial configuration

All these steps are contained in the script ` prepare-kolla-hosts.sh `.  
If you need to change Openstack release in the script, you also need to adjust Ansible dependencies for your Openstack release, according to official installation documents. Current script is configured for "yoga" Openstack release  

This script containes the following customizations:

- set Openstack virtual IP (IP address shared by Openstack services)  
VIP_ADDR=10.10.30.55
-  set Openstack API interface  
MGMT_IFACE=eth1 (network 10.10.10.x)
- set Neutron network interface  
EXT_IFACE=eth3 (network 192.168.100.x)

You may need to edit Openstack VIP address and network interfaces to adjust to your environment, do so by editing the file ` prepare-kolla-host.sh `.  
```
$ tail -n20 prepare-kolla-hosts.sh

# This is the static IP we created initially
VIP_ADDR=10.10.30.55
# VM interface is ens1
MGMT_IFACE=ens1
# This is the interface used for Neutron network
EXT_IFACE=eth3

# now use the information above to write it to Kolla configuration file
sudo tee -a /etc/kolla/globals.yml << EOT
kolla_base_distro: "ubuntu"
kolla_internal_vip_address: "$VIP_ADDR"
network_interface: "$MGMT_IFACE"
neutron_external_interface: "$EXT_IFACE"
EOT
```

Now you can run 
```./prepare-kolla-hosts.sh```
and upon successful finish you are ready to start deploying the cluster.

Also, to make use of local docker registry, we will add these variables to /etc/kolla/globals.yml.
```
sudo tee -a /etc/kolla/globals.yml << EOT
docker_registry: 10.10.10.50:5000
docker_registry:_insecure: "yes"
EOT
```


# Initiate cluster deployment

We are using Python virtual environments, so first we need to activate virtual environment created by the script above.

- Activate Python virtual environment:
```
source /opt/venv/yoga/bin/activate
```

- Perform cluster bootstrap  
Depending on your environment you may need to adjust Ansible inventory file, which specifies the hosts by their Openstack function

For example, inventory file ` all-in-one ` deploys everything to localhost.
```
$ head all-in-one
# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
localhost       ansible_connection=local

[network]
localhost       ansible_connection=local

[compute]
localhost       ansible_connection=local
...
```


While inventory file ` multinode ` specifies more nodes, three for control nodes in this case: 
```
$ head multinode
# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
# These hostname must be resolvable from your deployment host
control01
control02
control03

# The above can also be specified as follows:
#control[01:03]     ansible_user=kolla
...

```


we have to edit all-in-one inventory file, we need to specify ssh key created earlier, and api interface, which in my case is eth2 (network 10.10.30.x)
```
[control]
10.10.10.51 api_interface=eth2 ansible_private_key_file=/home/vagrant/.ssh/deploy-key

[network]
10.10.10.51 api_interface=eth2 ansible_private_key_file=/home/vagrant/.ssh/deploy-key
```


We will continue with all-in-one approach.

```
kolla-ansible -i all-in-one bootstrap-servers
```

- Perform container image pull
```
kolla-ansible -i all-in-one pull
```

- Perform cluster prechecks
```
kolla-ansible -i all-in-one prechecks
```

- Perform cluster deploy
```
kolla-ansible -i all-in-one deploy
```

- Perform cluster post-deploy
```
kolla-ansible -i all-in-one post-deploy
```


The last step will create cluster admin credentials file.  
At this point the cluster will not contain any networks, routers, OS images so we need to create them as well.  


We will :
- create one external network
- create one internal network (for our VMs)
- upload cirros image (lightweight OS image)  


Adjust IP range for our public network :

```
$ head run-my-init.sh
# Set you external network CIDR, range and gateway, matching your environment, e.g.:
export EXT_NET_CIDR='192.168.100.0/24'
export EXT_NET_RANGE='start=192.168.100.100,end=192.168.100.200'
export EXT_NET_GATEWAY='192.168.100.1'
/opt/venv/yoga/share/kolla-ansible/init-runonce
```

and run the script :
```
$ ./run-my-init.sh
```

Before running ```run-my-init.sh``` we need to make ```aio``` node reachable from ```deploy``` node. simply add this route
```ip ro add 10.10.30.0/24 via 10.10.10.50``` to ```deploy``` node.


At this point you will have a functional cluster with one router, public/private network and cirros image.  
Admin password is stored in the file /etc/kolla/admin-rc.sh, you can login via GUI or openstack console client which was installed during previous steps. 

# Verify Openstack operation

We will create one VM instance, login to it and check networking

```
. /opt/venv/yoga/bin/activate # activate our python virtual environment
. /etc/kolla/admin-openrc.sh  # source our admin credentials

# 
openstack server create \\
    --image cirros \\
    --flavor m1.tiny \\
    --key-name mykey \\
    --network demo-net \\
    demo1
```

We can open Horizon (openstack GUI) and get console login to our instance.  
Also, on network node (our aio node) we can list our virtual router, implemented as Linux network namespace,

```
vagrant@aio:~$ sudo ip netns ls
qrouter-43d2c840-93b1-455b-93d1-276230253821 (id: 1)
qdhcp-f16f9fa9-a96a-4564-a023-7d7af2aee152 (id: 0)
````
