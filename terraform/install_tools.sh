#!/bin/bash

set -e # This will make the script exit if any command fails

if [ $# -ne 5 ]; then
  echo "Usage: $0 <AWS_REGION> <EKS_CLUSTER_ARN> <AWS_ACCESS_ID> <AWS_SECRET_ACCESS_KEY> <AWS_ACCOUNT_ID>"
  exit 1
fi


AWS_REGION="$1"
EKS_CLUSTER_ARN="$2"
AWS_ACCESS_KEY_ID="$3"
AWS_SECRET_ACCESS_KEY="$4"
AWS_ACCOUNT_ID="$5"
EKS_CLUSTER_NAME=$(echo "$EKS_CLUSTER_ARN" | awk -F '/' '{print $2}')
CHART_VERSION="13.10.2"

echo "EKS_CLUSTER_NAME=$EKS_CLUSTER_NAME"
echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"

if [ -z "$AWS_REGION" ] || [ -z "$EKS_CLUSTER_NAME" ] || [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Please provide the AWS_REGION, EKS_CLUSTER_ARN, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY as script arguments."
  exit 1
fi

# Configure AWS CLI
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

sudo yum update -y
sudo yum install -y unzip
sudo yum install -y git
echo AWS_REGION=$AWS_REGION
echo AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
echo AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

# Install kubectl
curl --location https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.4/2023-05-11/bin/linux/amd64/kubectl \
  --remote-name --progress-bar
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install aws-iam-authenticator
curl --location https://amazon-eks.s3.us-west-2.amazonaws.com/1.26.4/2023-05-11/bin/linux/amd64/aws-iam-authenticator \
  --remote-name --progress-bar
chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin/

# Install eksctl
curl --location https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz \
  --output eksctl.tar.gz --progress-bar
tar -zxvf eksctl.tar.gz
sudo mv eksctl /usr/local/bin/
rm -f eksctl.tar.gz

export PATH="/usr/local/bin:$PATH"
ls /usr/local/bin

# Verify installations
kubectl version --client --output=yaml
aws-iam-authenticator version
eksctl version 

# Update kubeconfig
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

sed -i 's/client.authentication.k8s.io\/v1alpha1/client.authentication.k8s.io\/v1beta1/g' ~/.kube/config

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Enable Debug Logging for AWS Node
kubectl -n kube-system patch ds aws-node -p '{"spec":{"template":{"spec":{"containers":[{"name":"aws-node","env":[{"name":"AWS_VPC_K8S_CNI_LOGLEVEL","value":"DEBUG"}]}]}}}}'

# Print logs from aws-node pods
kubectl -n kube-system logs -l k8s-app=aws-node

sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

