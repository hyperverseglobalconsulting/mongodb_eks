#!/bin/bash

# Script name: destroy_infrastructure.sh

# Find the PID of the SSH tunnel
PID=$(ps aux | grep "ssh -i mongodb-in-eks.pem -L 27017:localhost:27017" | grep -v "grep" | awk '{print $2}')

# If PID is not empty, then kill the process
if [ ! -z "$PID" ]; then
    kill $PID
    if [ $? -eq 0 ]; then
        echo "Successfully killed the SSH tunnel process with PID: $PID"
    else
        echo "Error killing process with PID: $PID"
    fi
else
    echo "SSH tunnel process not found. Nothing to kill."
fi

# Run the Ansible playbook to uninstall ingress-nginx
BASTION_HOST=$(terraform output -raw bastion_public_ip)
VPC_ID=$(terraform output -raw vpc_id)
ansible-playbook -vvv -i "$BASTION_HOST," uninstall_ingress_nginx.yaml -u ec2-user --private-key=mongodb-in-eks.pem -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' -e "vpc_id=$VPC_ID"

# Check if the Ansible playbook command was successful
if [ $? -ne 0 ]; then
    echo "Error: Ansible playbook failed. Not proceeding with terraform destroy."
    exit 1
fi

# Now, run terraform destroy if the Ansible playbook command was successful
terraform destroy -auto-approve

