#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "eks" {
  name = "${var.cluster_name}-${var.environment}-eks"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "AmazonEKSClusterAutoscalerPolicy" {
  name  = "AmazonEKSClusterAutoscalerPolicy"
  path  = "/"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterAutoscalerPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterAutoscalerPolicy.arn
  role       = aws_iam_role.eks.name
}

resource "aws_security_group" "default" {
  name        = "${var.cluster_name}-${var.environment}-default-sg"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [ aws_vpc.vpc ]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
}

/*resource "aws_security_group_rule" "eks-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.default.id
  to_port           = 443
  type              = "ingress"
}*/

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]


  vpc_config {
    security_group_ids = [aws_security_group.default.id]
    subnet_ids         = aws_subnet.private_subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterAutoscalerPolicy 
  ]
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
  url             = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}
