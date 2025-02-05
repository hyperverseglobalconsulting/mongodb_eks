# MongoDB on AWS EKS Cluster - Project Documentation  
**A Terraform & Ansible Automation for Scalable MongoDB Deployment**  

---

## Table of Contents  
1. [Introduction](#introduction)  
2. [Architecture Overview](#architecture-overview)  
3. [Detailed Components](#detailed-components)  
4. [Workflow](#workflow)  
5. [Accessing MongoDB](#accessing-mongodb)  
6. [Repository Structure](#repository-structure)  
7. [Conclusion](#conclusion)  

---

## Introduction  
This project automates the deployment of a highly available MongoDB instance on AWS Elastic Kubernetes Service (EKS) using Terraform for infrastructure provisioning and Ansible for configuration management. The solution includes secure access via a bastion host, dynamic storage provisioning with AWS EBS, and integration with AWS Secrets Manager for credential management.  

**Key Features**:  
- Infrastructure-as-Code (IaC) with Terraform  
- Kubernetes-native MongoDB deployment  
- Secure access via SSH tunneling and RBAC  
- Automated secrets management  

---

## Architecture Overview  
### High-Level Infrastructure Diagram 
```mermaid
%% Updated MongoDB on AWS EKS Architecture
graph TD
    subgraph AWS_VPC[VPC - 10.0.0.0/16]
        subgraph Public_Subnet[Public Subnet]
            Bastion[EC2 Bastion Host]
            IGW[Internet Gateway]
        end
        
        subgraph EKS_Public_Subnets[EKS Public Subnets]
            EKS_Control_Plane[[EKS Control Plane]]
            Node_Group[Worker Node Group]
            MongoDB_Pod[(MongoDB Pod)]
            EBS_CSI_Driver[AWS EBS CSI Driver]
        end
        
        Bastion -->|Ansible Provisioning| Node_Group
        EBS_CSI_Driver -->|Dynamic Provisioning| EBS_Volumes[(EBS Volumes)]
    end
    
    SecretsManager[(AWS Secrets Manager)] -->|Store/Retrieve| MongoDB_Pod
    User[User] -->|SSH| Bastion
    User -->|mongosh/pymongo| MongoDB_Pod
    Node_Group -->|IAM Roles| EKS_Policies[EKS Policies]
    
    classDef aws fill:#FF9900,color:black;
    classDef k8s fill#326ce5,color:white;
    classDef secret fill#795da3,color:white;
    classDef storage fill#21b0cb,color:black;
    
    class Bastion,IGW,EBS_Volumes aws;
    class EKS_Control_Plane,Node_Group,MongoDB_Pod,EBS_CSI_Driver k8s;
    class SecretsManager secret;
    class EBS_Volumes storage;
```

#### Components:  
1. **AWS EKS Cluster**: Hosts MongoDB pods in a managed Kubernetes environment.  
2. **EC2 Bastion Host**: Secure jump server for SSH access and port forwarding.  
3. **MongoDB Pod**: Deployed as a stateful set with persistent EBS volumes.  
4. **AWS Secrets Manager**: Stores and retrieves MongoDB root credentials securely.  
5. **VPC & Subnets**: Isolated network with public/private subnets for security.  

1. **Terraform Provisions Infrastructure**:  
   - EKS Cluster  
   - Bastion Host  
   - Networking (VPC, Subnets, Security Groups)  
2. **Ansible Configures Kubernetes**:  
   - Deploys MongoDB with Helm/Manifests  
   - Sets up storage classes for EBS  
3. **Access Management**:  
   - Port forwarding via bastion  
   - Secrets retrieval from AWS Secrets Manager  

### Repository Structure Diagram
```mermaid
%% File Tree
graph TD
    Root[.] --> Terraform
    Root --> Kubernetes
    Root --> Scripts
    Root --> Ansible
    Root --> Docs
    
    Terraform --> main.tf
    Terraform --> eks.tf
    Terraform --> bastion.tf
    Terraform --> ebs.tf
    
    Kubernetes --> ebs-storage-class.yaml
    Kubernetes --> ebs-pvc.yaml
    
    Scripts --> apply.infrastructure.sh
    Scripts --> destroy.infrastructure.sh
    
    Ansible --> install_tools.yaml
    
    Docs --> project.md
    Docs --> architecture-diagram.png
```

---

## Detailed Components  
### 1. Terraform Infrastructure  
- **EKS Cluster** (`eks.tf`): Configures node groups and IAM roles.  
- **Bastion Host** (`bastion.tf`): Public EC2 instance with strict security group rules.  
- **EBS Storage** (`ebs.tf`): Defines storage classes and persistent volume claims.  
- **Secrets Manager** (`variables.tf`): Stores MongoDB credentials securely.  

### 2. Kubernetes Configuration  
- **MongoDB StatefulSet**: Ensures persistent storage and high availability.  
- **StorageClass** (`ebs-storage-class.yaml`): Dynamically provisions EBS volumes.  
- **Security**:  
  - Kubernetes Secrets for MongoDB passwords  
  - Network policies to restrict pod communication

### 3. Access Methods  
- **Bastion Host SSH**:  
  ```bash
  ssh -i mongodb-in-eks.pem ec2-user@$(terraform output bastion_public_ip)

## Workflow  
### End-to-End Deployment Process  
The workflow follows a strict Infrastructure-as-Code (IaC) sequence:  

```mermaid
sequenceDiagram
    participant User
    participant Terraform
    participant AWS
    participant Ansible
    participant Kubernetes
    participant Bastion
    participant MongoDB

    User->>Terraform: Run apply.infrastructure.sh
    activate Terraform
        Terraform->>AWS: 1. Create VPC/Subnets
        Terraform->>AWS: 2. Provision EKS Cluster
        Terraform->>AWS: 3. Deploy Bastion Host
        Terraform->>AWS: 4. Create EBS Volumes (3x5GB)
        Terraform->>AWS: 5. Store KeyPair in S3
        AWS-->>Terraform: Infrastructure Ready
    deactivate Terraform

    User->>Ansible: Execute install_tools.yaml
    activate Ansible
        Ansible->>Bastion: 6. Install Tools: kubectl/helm, AWS CLI, Docker
        Ansible->>Kubernetes: 7. Deploy EBS CSI Driver
        Ansible->>Kubernetes: 8. Create StorageClass/PVC
        Ansible->>Kubernetes: 9. Install MongoDB via Helm
        Ansible->>Kubernetes: 10. Configure Port Forwarding
        Ansible->>AWS: 11. Store Password in Secrets Manager
        Kubernetes-->>Ansible: MongoDB Operational
    deactivate Ansible

    User->>Bastion: 12. SSH Access
    activate Bastion
        Bastion->>Kubernetes: 13. Port Forward 27017→localhost
        Bastion-->>User: Tunnel Established
    deactivate Bastion

    loop Access Methods
        User->>MongoDB: 14a. Connect via mongosh
        User->>MongoDB: 14b. Connect via pymongo
        User->>MongoDB: 14c. Use Studio3T
    end

    User->>Terraform: Run destroy.infrastructure.sh
    activate Terraform
        Terraform->>AWS: 15. Terminate All Resources
        AWS-->>Terraform: Clean State
    deactivate Terraform
```
  
### Phases Breakdown

#### Infrastructure Provisioning
- Creates VPC with public subnets (CIDR: 10.0.0.0/16)
- Deploys EKS cluster with 3 t3.small worker nodes
- Provisions bastion host with strict IP-based SSH access
- Creates 3x5GB GP2 EBS volumes

#### Kubernetes Configuration
- Installs AWS EBS CSI Driver v1.26.4
- Configures StorageClass with `volumeBindingMode: WaitForFirstConsumer`
- Deploys MongoDB using Bitnami Helm chart v13.7.0

#### Access Automation
- Auto-generates MongoDB root password (base64 encoded)
- Syncs credentials to AWS Secrets Manager
- Persistent port forwarding via `nohup` daemon

---

## Accessing MongoDB  
### Connection Methods

#### 1. Direct Shell Access (mongosh)
```bash
# SSH to bastion
ssh -i mongodb-in-eks.pem ec2-user@$(terraform output bastion_public_ip)

# Decode password from Kubernetes secret
MONGODB_PWD=$(kubectl get secret mongodb -o jsonpath='{.data.mongodb-root-password}' | base64 -d)

# Connect using mongosh
mongosh "mongodb://root:${MONGODB_PWD}@localhost:27017/admin?authSource=admin"
```

### Connection Methods

#### 2. Programmatic Access (Python)
```python
from pymongo import MongoClient
from kubernetes import config, client
import base64

def get_mongodb_password():
    config.load_kube_config()
    v1 = client.CoreV1Api()
    secret = v1.read_namespaced_secret("mongodb", "default")
    return base64.b64decode(secret.data["mongodb-root-password"]).decode('utf-8')

client = MongoClient(
    host='localhost',
    port=27017,
    username='root',
    password=get_mongodb_password(),
    authSource='admin'
)
```
#### 3. GUI Client (Studio 3T/Robo3T)
``` bash
# Retrieve password from AWS Secrets Manager
MONGODB_PWD=$(aws secretsmanager get-secret-value \
  --secret-id MongoDBPassword \
  --region us-east-2 \
  --query SecretString --output text)

# Connection string:
mongodb://root:${MONGODB_PWD}@localhost:27017/?directConnection=true&authSource=admin
```
## Repository Structure
### Code Organization
```mermaid
graph TD
    ROOT[.] --> TF[terraform/]
    ROOT --> K8S[kubernetes/]
    ROOT --> SCRIPTS[scripts/]
    ROOT --> ANSIBLE[ansible/]
    ROOT --> DOCS[docs/]
    
    TF --> main.tf
    TF --> eks.tf
    TF --> bastion.tf
    TF --> ebs.tf
    TF --> variables.tf
    
    K8S --> ebs-storage-class.yaml
    K8S --> ebs-pvc.yaml
    
    SCRIPTS --> apply.infrastructure.sh
    SCRIPTS --> destroy.infrastructure.sh
    SCRIPTS --> rebuild_bastion_server.sh
    
    ANSIBLE --> install_tools.yaml
    ANSIBLE --> uninstall_ingress_nginx.yaml
    
    DOCS --> project.md
    DOCS --> architecture-diagram.png
```
### Key Components
| Directory       | Purpose                                  |
|-----------------|------------------------------------------|
| `terraform/`    | AWS infrastructure definitions          |
| `kubernetes/`   | Storage manifests for EBS integration   |
| `scripts/`      | One-click apply/destroy automation      |
| `ansible/`      | Bastion host configuration playbooks    |
| `docs/`         | Architecture diagrams & documentation   |

---

## Conclusion
### Implementation Highlights
```markdown
- **Infrastructure as Code**: Complete AWS environment provisioned through Terraform  
- **Secure Access**: Bastion host with IP-restricted SSH + IAM role-based access  
- **Persistent Storage**: EBS volumes dynamically provisioned via CSI driver  
- **Automated Secrets**: Kubernetes Secrets ↔ AWS Secrets Manager synchronization
```
### Future Improvements
```markdown
1. **High Availability**  
   - Multi-AZ deployment for MongoDB replica sets  
   - EKS node auto-scaling policies  

2. **Monitoring**  
   - CloudWatch integration for MongoDB metrics  
   - Prometheus stack for Kubernetes monitoring  

3. **CI/CD Pipeline**  
   - Automated testing with `mongodb_sanity_test.py`  
   - GitOps workflow using ArgoCD  

4. **Security Enhancements**  
   - Network policies for pod communication  
   - IAM role for service accounts (IRSA)
```
### Final Note
``` markdown
This project demonstrates a production-ready pattern for stateful workloads on Kubernetes while maintaining infrastructure reproducibility and security best practices.
```
