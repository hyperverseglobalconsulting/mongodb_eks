#!/bin/bash

# Ask for the sudo password
read -s -p "Enter the sudo password: " SUDO_PASSWORD
echo

# Run Terraform commands, passing the password as a variable
terraform plan -out=tfplan.out -var "sudo_password=$SUDO_PASSWORD"
terraform apply "tfplan.out"

#BASTION_IP=$(terraform output -raw bastion_public_ip)
#ssh -i concourse-k8s.pem -L 8080:localhost:8080 ec2-user@$BASTION_IP -N &
