curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - ;\
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" ;\
sudo apt-get update && sudo apt-get install boundary-enterprise -y


#!/bin/bash
# This script is meant to be run in the User Data of the Boundary Instance while it's booting.
echo "Determining public IP address"
PUBLIC_IPV4=$(ec2metadata --public-ipv4)


cat << EOCSU >/etc/boundary.d/boundary.hcl
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr = "${PUBLIC_IPV4}"
  initial_upstreams = [""]
  auth_storage_path = "/tmp"
  tags {
    type = ["worker2", "downstream"]
  }

}
EOCSU
