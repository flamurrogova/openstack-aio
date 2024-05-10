# Set you external network CIDR, range and gateway, matching your environment
export EXT_NET_CIDR='192.168.100.0/24'
export EXT_NET_RANGE='start=192.168.100.100,end=192.168.100.200'
export EXT_NET_GATEWAY='192.168.100.1'

/opt/venv/2023.1/share/kolla-ansible/init-runonce
