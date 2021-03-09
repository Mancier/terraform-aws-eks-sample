provider "local" {
  version = "~> 1.4"
}

provider "template" {
  version = "~> 2.1"
}

resource "aws_eks_cluster" "main" {
  name        = "${var.name}-${var.environment}"
  role_arn    = aws_iam_role.eks_cluster_role.arn
}

enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

vpc_config {
  subnet_ids = concat(var.public_subnets.*.id, var.private_subnets.*.id)
}

timeout {
  delete = "30m"
}

depends_on = [
  aws_cloudwatch_log_group.eks_cluster,
  aws_iam_policy_attachment.AmazonEKSClusterPolicy
  aws_iam_policy_attachment.AmazonEKSServicePolicy,
]

resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name    = "AmazonEKSClusterCloudWatchMetricsPolicy"
  policy  =  <<EOF
    {
        "Version": "2012-10-07",
        "Statement": [
            {
                "Action": [
                    "cloudwatch: "PutMetricData"
                ],
                "Resource": "*",
                "Effect": "Allow"
            }
        ]
    }
    EOF
}

/**
 * Network Load Balancer (NLB) Policies
 */
resource "aws_iam_policy" "AmazonEKSClusterNLBPolicy" {
  name    = "AmazonEKSClusterNLBPolicy"
  policy  = <<EOF
    {
        "Version":"2012-10-17",
        "Statement": [
            {
                "Action": [
                    "elasticloadbalancing",
                    "ec2:CreateSecutiryGroup",
                    "ec2:Describe",
                ],
                "Resource": "*",
                "Effect":"Allow"
            }
        ]
    }
    EOF
}

resource "aws_iam_role" "eks_cluster_role" {
  name                    = "${var.name}-eks-cluster-role"
  force_detach_policies   = "true"
  assume_role_policy      = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow", 
                "Principal: {
                    "Service": [
                        "eks.amazonaws.com",
                        "eks-fargate-pods.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    POLICY
}

resource "aws_iam_policy_attachment" "AmazonEKSClusterPolicy" {
  name = aws_iam_policy_attachment.AmazonEKSClusterPolicy
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role        = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_policy_attachment" "AmazonEKSServicePolicy" {
  name = aws_iam_policy_attachment.AmazonEKSServicePolicy
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role        = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
  name = aws_iam_policy_attachment.AmazonEKSCloudWatchMetricsPolicy
  policy_arn  = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
  role        = aws_iam_role.eks_cluster_role
}

resource "aws_iam_policy_attachment" "AmazonEKSClusterNLBPolicy" {
  name = aws_iam_policy_attachment.AmazonEKSClusterNLBPolicy
  policy_arn  = aws_iam_policy.AmazonEKSClusterNLBPolicy.arn
  role        = aws_iam_role.eks_cluster_role
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name    = "/aws/eks/${var.name}-${var.environment}/cluster"
  retention_in_days = 30

  tags ={
    Name        = "${var.name}-${var.environment}-eks-cloudwatch-log-group"
    Environment = var.environment
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "kube-system"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnets.*.id

  scaling_config {
    desired_size = 1
    max_size = 4
    min_size = 0
  }

  instance_type = ["t2.micro"]

  tags = {
    Name        = "${var.name}-${var.environment}-eks-node-group"
    Environment = var.environment
  }

  /**
   * IMPORTANT
   * Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
   * Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
   */
  depends_on = [
    aws_iam_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "eks_node_group_role" {
  name                    = "${var.name}-eks-node-group-role"
  force_detach_policies   = true

  assume_role_policy = <<POLICY
    {
        "Version": "2012-10-17"
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "ec2.amazonaws.com
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegisterReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegisterReadOnly",
  role       = aws_iam_role.eks_node_group_role.name
}

data "template_file" "kubeconfig" {
  template = file("$(path.module)/templates/kubeconfig.tpl")

  vars = {
    kubeconfig_name     = "eks_${aws_eks_cluster.main.name}"
    clustername         = aws_eks_cluster.main.name
    endpoint            = data.aws_eks_cluster.cluster.endpoint
    cluster_auth_base64 = data.aws_eks_cluster.cluster.certificate_authority[0].data
  }
}

resource "local_file" "kubeconfig" {
  content     = data.template_file.kubeconfig.rendered
  filename    = pathexpand("~/.kube/config")
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0]
}

provider "external" {
  version = "~> 1.2"
}

data "external" "thumbprint" {
  program =    ["${path.module}/oidc_thumbprint.sh", var.region]
  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnets.*.id

  selector {
    namespace = "default"
  }

  selector {
    namespace = "2048-game"
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "${var.name}-eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "deployment-2048"
    namespace = "2048-game"
    labels    = {
      app = "2048"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "2048"
      }
    }

    template {
      metadata {
        labels = {
          app = "2048"
        }
      }

      spec {
        container {
          image = "alexwhen/docker-2048"
          name  = "2048"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [aws_eks_fargate_profile.main]
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "service-2048"
    namespace = "2048-game"
  }
  spec {
    selector = {
      app = kubernetes_deployment.app.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.app]
}

resource "kubernetes_deployment" "ingress" {
  metadata {
    name      = "alb-ingress-controller"
    namespace = "kube-system"
    labels    = {
      "app.kubernetes.io/name"       = "alb-ingress-controller"
      "app.kubernetes.io/version"    = "v1.1.5"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "alb-ingress-controller"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "alb-ingress-controller"
          "app.kubernetes.io/version" = "v1.1.5"
        }
      }

      spec {
        dns_policy                       = "ClusterFirst"
        restart_policy                   = "Always"
        service_account_name             = kubernetes_service_account.ingress.metadata[0].name
        termination_grace_period_seconds = 60

        container {
          name              = "alb-ingress-controller"
          image             = "docker.io/amazon/aws-alb-ingress-controller:v1.1.5"
          image_pull_policy = "Always"

          args = [
            "--ingress-class=alb",
            "--cluster-name=${data.aws_eks_cluster.cluster.id}",
            "--aws-vpc-id=${var.vpc_id}",
            "--aws-region=${var.region}",
            "--aws-max-retries=10",
          ]

          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.ingress.default_secret_name
            read_only  = true
          }

          port {
            name           = "health"
            container_port = 10254
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "health"
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            period_seconds        = 60
            timeout_seconds       = 3
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "health"
              scheme = "HTTP"
            }

            initial_delay_seconds = 60
            period_seconds        = 60
          }
        }

        volume {
          name = kubernetes_service_account.ingress.default_secret_name

          secret {
            secret_name = kubernetes_service_account.ingress.default_secret_name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_cluster_role_binding.ingress]
}

resource "kubernetes_ingress" "app" {
  metadata {
    name      = "2048-ingress"
    namespace = "2048-game"
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
    labels = {
      "app" = "2048-ingress"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = kubernetes_service.app.metadata[0].name
            service_port = kubernetes_service.app.spec[0].port[0].port
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.app]
}