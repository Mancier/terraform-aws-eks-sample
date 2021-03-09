provider "kubernetes" {
  host                    = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate  = base64decode(data.aws_eks_cluster.cluster.certficate_authority[0].data)
  token                   = data.aws_eks_cluster_auth.cluster.token
  load_config_file        = false
  version                 = "~^1.10"
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.id
}