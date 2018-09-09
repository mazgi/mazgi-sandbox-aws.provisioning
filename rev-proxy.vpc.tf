resource "aws_vpc" "rev-proxy" {
  cidr_block           = "10.0.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags {
    "Name" = "rev-proxy"
  }
}

resource "aws_vpc_dhcp_options" "rev-proxy" {
  domain_name         = "ec2.internal rev-proxy.us-east-1.mazgi-sandbox-aws.mazgi.app"
  domain_name_servers = ["AmazonProvidedDNS"]

  tags {
    "Name" = "rev-proxy.us-east-1.mazgi-sandbox-aws.mazgi.app"
  }
}

resource "aws_vpc_dhcp_options_association" "rev-proxy" {
  vpc_id          = "${aws_vpc.rev-proxy.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.rev-proxy.id}"
}

resource "aws_internet_gateway" "rev-proxy" {
  vpc_id = "${aws_vpc.rev-proxy.id}"

  tags {
    "Name" = "rev-proxy"
  }
}

resource "aws_subnet" "rev-proxy-subnet-public" {
  count                   = "${length(var.az_cider_blocks)}"
  vpc_id                  = "${aws_vpc.rev-proxy.id}"
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "us-east-1${element(var.az_cider_blocks, count.index)}"
  map_public_ip_on_launch = true

  tags {
    "Name" = "rev-proxy-subnet-public-us-east-1${element(var.az_cider_blocks, count.index)}"
  }
}

resource "aws_subnet" "rev-proxy-subnet-private" {
  count                   = "${length(var.az_cider_blocks)}"
  vpc_id                  = "${aws_vpc.rev-proxy.id}"
  cidr_block              = "10.0.${count.index + 8}.0/24"
  availability_zone       = "us-east-1${element(var.az_cider_blocks, count.index)}"
  map_public_ip_on_launch = true

  tags {
    "Name" = "rev-proxy-subnet-private-us-east-1${element(var.az_cider_blocks, count.index)}"
  }
}

resource "aws_eip" "rev-proxy-nat_gateway-eip" {
  count = "${length(var.az_cider_blocks)}"
  vpc   = true
}

resource "aws_nat_gateway" "rev-proxy" {
  count         = "${length(var.az_cider_blocks)}"
  subnet_id     = "${element(aws_subnet.rev-proxy-subnet-private.*.id, count.index)}"
  allocation_id = "${element(aws_eip.rev-proxy-nat_gateway-eip.*.id, count.index)}"
}

resource "aws_route_table" "rev-proxy-default" {
  vpc_id = "${aws_vpc.rev-proxy.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.rev-proxy.id}"
  }

  tags {
    "Name" = "rev-proxy-default"
  }
}

resource "aws_main_route_table_association" "rev-proxy-default" {
  vpc_id         = "${aws_vpc.rev-proxy.id}"
  route_table_id = "${aws_route_table.rev-proxy-default.id}"
}

resource "aws_route_table" "rev-proxy-private" {
  count  = "${length(var.az_cider_blocks)}"
  vpc_id = "${aws_vpc.rev-proxy.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${element(aws_nat_gateway.rev-proxy.*.id, count.index)}"
  }

  tags {
    "Name" = "rev-proxy-private-us-east-1${element(var.az_cider_blocks, count.index)}"
  }
}

resource "aws_main_route_table_association" "rev-proxy-private" {
  count          = "${length(var.az_cider_blocks)}"
  vpc_id         = "${aws_vpc.rev-proxy.id}"
  route_table_id = "${element(aws_route_table.rev-proxy-private.*.id, count.index)}"
}

resource "aws_security_group" "rev-proxy-default" {
  name        = "rev-proxy-default"
  description = "rev-proxy default security group"
  vpc_id      = "${aws_vpc.rev-proxy.id}"

  tags {
    "Name" = "rev-proxy-default"
  }
}

resource "aws_security_group_rule" "rev-proxy-default-rule-0" {
  security_group_id = "${aws_security_group.rev-proxy-default.id}"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "rev-proxy-vpc" {
  name        = "rev-proxy-vpc"
  description = "rev-proxy VPC security group"
  vpc_id      = "${aws_vpc.rev-proxy.id}"

  tags {
    "Name" = "rev-proxy-vpc"
  }
}

resource "aws_security_group_rule" "rev-proxy-vpc-rule-0" {
  security_group_id = "${aws_security_group.rev-proxy-vpc.id}"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

resource "aws_security_group" "rev-proxy-allow-ssh" {
  name        = "rev-proxy-allow-ssh"
  description = "rev-proxy SSH security group"
  vpc_id      = "${aws_vpc.rev-proxy.id}"

  tags {
    "Name" = "rev-proxy-allow-ssh"
  }
}

resource "aws_security_group_rule" "rev-proxy-allow-ssh-rule-0" {
  security_group_id = "${aws_security_group.rev-proxy-allow-ssh.id}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "rev-proxy-allow-http" {
  name        = "rev-proxy-http"
  description = "rev-proxy HTTP/HTTPS security group"
  vpc_id      = "${aws_vpc.rev-proxy.id}"

  tags {
    "Name" = "rev-proxy-allow-http"
  }
}

resource "aws_security_group_rule" "rev-proxy-allow-http-rule-0" {
  security_group_id = "${aws_security_group.rev-proxy-allow-http.id}"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "rev-proxy-allow-http-rule-1" {
  security_group_id = "${aws_security_group.rev-proxy-allow-http.id}"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
