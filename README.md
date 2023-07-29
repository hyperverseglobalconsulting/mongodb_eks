# MongoDB on AWS EKS Cluster

## Overview
This project automates the deployment of MongoDB on an AWS EKS cluster. By utilizing Terraform for infrastructure provisioning and Ansible for configuration management, we've streamlined the process to ensure a smooth and efficient deployment. Once set up, users can access the MongoDB instance either through the mongosh shell from a bastion instance or programmatically via the pymongo Python library.

## Prerequisites
- AWS Account
- Terraform installed
- Ansible installed
- Access to AWS S3 bucket for Terraform state management

## Setup Instructions
### 1. Infrastructure Setup:
- #### Modify Bucket Names:
Edit the bucket names specified in main.tf and variables.tf to fit your desired AWS environment.

- #### Initialize Terraform:
Navigate to the project's root directory and run:
`terraform init`

- #### Apply Terraform Configuration
Deploy the AWS resources:
`terraform apply`

- #### Retrieve Bastion Host IP
Once Terraform has finished provisioning the resources, get the public IP of the bastion instance:
`terraform output bastion_public_ip`

- #### Accessing Key Pair
Terraform script will create a key pair and save the private key as `mongodb-in-eks.pem` in the current directory. Ensure you keep this key secure.

### 2. Accessing MongoDB:

-   **Via `mongosh`**:
    
    -   SSH into the bastion host:
`ssh -i mongodb-in-eks.pem ec2-user@$(terraform output bastion_public_ip)`

    - Extract the MongoDB root password:
    `password=$(kubectl get secret mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 --decode)`    
    - Access the MongoDB instance using the extracted password:
    `mongosh --host localhost --port 27017 --username root --password $password --authenticationDatabase admin`
- **Via `pymongo`**:

Make sure your Python script is equipped with the `get_mongodb_password` function to pull the root password from Kubernetes secret:

    from pymongo import MongoClient
    from kubernetes import client, config
    import base64
    
    def get_mongodb_password():
        config.load_kube_config()
        v1 = client.CoreV1Api()
        secret = v1.read_namespaced_secret(name="mongodb", namespace="default")
        encoded_password = secret.data["mongodb-root-password"]
        decoded_password = base64.b64decode(encoded_password).decode('utf-8')
        client.ApiClient().close()
        return decoded_password
  

Use the extracted password to establish a connection:

    password = get_mongodb_password()
    mongo_client = MongoClient('localhost', 27017,
                              username='root',
                              password=password,
                              authSource='admin')
    db = mongo_client[<dbname>]
    
  ## Conclusion

This automated setup aids in deploying a MongoDB instance on an AWS EKS cluster efficiently. The integration of Terraform and Ansible ensures that infrastructure and configuration management are handled seamlessly.
