#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Nat Gateway
#  * Route Table
#

resource "aws_vpc" "vpc" {
  cidr_block            = var.cidr
  enable_dns_hostnames  = true
  enable_dns_support    = true 

  tags = map(
    "Name", "${var.cluster_name}-${var.environment}-vpc",
    "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
    Enviroment = "${var.environment}"
  }
}

resource "aws_eip" "eip" {
  vpc         = true
  depends_on  = [ aws_internet_gateway.igw ]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id   = "${aws_eip.eip.id}"
  subnet_id       = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on      = [ aws_internet_gateway.igw ]
  tags = {
    "Name" = "${var.cluster_name}-${var.environment}-ngw"
    "Environment" = "${var.environment}"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidr)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = element(var.public_subnet_cidr, count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = map(
    "Name", "${var.cluster_name}-${var.environment}-sbn-public-${count.index}",
    "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}


resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnet_cidr)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = element(var.private_subnet_cidr, count.index)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.vpc.id

  tags = map(
    "Name", "${var.cluster_name}-${var.environment}-sbn-public-${count.index}",
    "kubernetes.io/cluster/${var.cluster_name}", "shared",
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public_igw" {
  route_table_id          = "${aws_route_table.public.id}"
  gateway_id              = "${aws_internet_gateway.igw.id}"
  # destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_route" "private_igw" {
  route_table_id          = "${aws_route_table.private.id}"
  nat_gateway_id          = "${aws_nat_gateway.ngw.id}"
  destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_route_table_association" "public_rta" {
  count           = length(var.public_subnet_cidr)
  subnet_id       = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id  = aws_route_table.public.id
}

resource "aws_route_table_association" "private_rta" {
  count           = length(var.private_subnet_cidr)
  subnet_id       = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id  = aws_route_table.private.id
}
