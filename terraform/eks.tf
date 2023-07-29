resource "aws_security_group" "eks_cluster_mgmt_one" {
  name_prefix = "eks_cluster_mgmt_one"
  vpc_id      = aws_vpc.k8s.id
}

resource "aws_security_group_rule" "eks_cluster_mgmt_one" {
  security_group_id = aws_security_group.eks_cluster_mgmt_one.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  source_security_group_id = aws_security_group.sg.id
#  depends_on = [
#    aws_security_group.sg,
#  ]
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.21-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI account ID
}

resource "aws_iam_role" "eks_cluster" {
  name = "eks_cluster_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_eks_cluster" "cluster" {
  name     = "mongodb-in-eks"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = values(aws_subnet.public).*.id

    endpoint_private_access = true
    endpoint_public_access  = true

    security_group_ids = [aws_security_group.eks_cluster_mgmt_one.id]
  }

#  depends_on = [
#    aws_subnet.public
#  ]
}

resource "aws_iam_role" "node_group" {
  name = "eks_node_group_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "eks_worker_group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = values(aws_subnet.public).*.id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t3.small"]

  disk_size = 20

  remote_access {
    ec2_ssh_key =  aws_key_pair.kp.key_name
  }
  
  ami_type = "AL2_x86_64"

  tags = {
    Terraform = "true"
    EKS       = "mongodb-in-eks"
  }

#  depends_on = [
#    aws_eks_cluster.cluster,
#    aws_key_pair.kp
#  ]
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_1" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_2" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach the AmazonEKS_CNI_Policy to the node group IAM role
resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_cni" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach the AmazonEC2FullAccess policy to the node group IAM role
resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment_ec2_full_access" {
  role       = aws_iam_role.node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attach" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = data.aws_iam_policy.AmazonEKSClusterPolicy.arn
}

output "aws_region" {
  description = "The AWS region used for resources."
  value       = var.aws_region
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster."
  value       = aws_eks_cluster.cluster.arn
}
