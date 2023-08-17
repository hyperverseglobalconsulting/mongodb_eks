#!/bin/bash

# Script name: rebuild_bastion_server.sh

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

terraform taint aws_instance.bastion

# Ask for the sudo password
read -s -p "Enter the sudo password: " SUDO_PASSWORD
echo

# Run Terraform commands, passing the password as a variable
terraform plan -out=tfplan.out -var "sudo_password=$SUDO_PASSWORD"
terraform apply "tfplan.out"

BASTION_IP=$(terraform output -raw bastion_public_ip)
ssh -i mongodb-in-eks.pem -L 27017:localhost:27017 ec2-user@$BASTION_IP -N &
