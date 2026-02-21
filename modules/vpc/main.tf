locals {
  az = sort(distinct([
    for az in data.aws_availability_zones.available.names :
    regex("[a-z]$", az)
  ]))
}

resource "aws_vpc" "this" {
  cidr_block           = var.config.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = { Name = var.config.name }
}

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.config.private_subnet_cidrs : idx => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[tonumber(each.key)]
  map_public_ip_on_launch = false

  tags = { Name = "${var.config.name}-private" }
}


resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id

  tags = { Name = "${var.config.name}-rtb-private" }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# resource "aws_vpc_endpoint" "s3_gateway" {
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${var.common.region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [for r in aws_route_table.private : r.id]

#   tags = { Name = "${var.config.name}-vpce-s3" }
# }

# --- Interface VPC Endpoints for SSM / Session Manager ---
resource "aws_security_group" "vpce" {
  name        = "${var.config.name}-vpce-sg"
  description = "Allow HTTPS from VPC to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  ssm_interface_services = [
    "com.amazonaws.${var.common.region}.ssm",
    "com.amazonaws.${var.common.region}.ssmmessages",
    "com.amazonaws.${var.common.region}.ec2messages",
  ]
}

resource "aws_vpc_endpoint" "ssm_interfaces" {
  for_each            = toset(local.ssm_interface_services)
  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpce.id]
  tags                = { Name = "${var.config.name}-vpce-${replace(each.value, "/.*\\./", "")}" }
}
