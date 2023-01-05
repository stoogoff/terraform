
data "aws_availability_zones" "available" {
	state = "available"
}

resource "aws_vpc" "vpc" {
	cidr_block = var.cidr_block

	enable_dns_support   = true
	enable_dns_hostnames = true

	tags = {
		Name = "${var.vpc_name}-vpc"
	}
}

resource "aws_internet_gateway" "gateway" {
	vpc_id = aws_vpc.vpc.id

	tags = {
		Name = "${var.vpc_name}-ig"
	}
}

/*resource "aws_eip" "ip" {
	vpc        = true
	depends_on = [aws_internet_gateway.gateway]

	tags = {
		Name =  "${var.vpc_name}-eip"
	}
}*/

/*resource "aws_nat_gateway" "gateway" {
	allocation_id = aws_eip.ip.id
	subnet_id     = aws_subnet.public[0].id

	tags = {
		Name =  "${var.vpc_name}-nat"
	}
}*/

resource "aws_subnet" "public" {
	count                   = length(var.public_cidr_block)
	vpc_id                  = aws_vpc.vpc.id
	cidr_block              = var.public_cidr_block[count.index]
	availability_zone       = element(data.aws_availability_zones.available.names, count.index)
	map_public_ip_on_launch = true

	tags = {
		Name = "${var.vpc_name}-net-public-${count.index}"
	}
}

resource "aws_subnet" "private" {
	count                   = length(var.private_cidr_block)
	vpc_id                  = aws_vpc.vpc.id
	cidr_block              = var.private_cidr_block[count.index]
	availability_zone       = element(data.aws_availability_zones.available.names, count.index)
	map_public_ip_on_launch = false

	tags = {
		Name = "${var.vpc_name}-net-private-${count.index}"
	}
}

resource "aws_route_table" "public" {
	vpc_id = aws_vpc.vpc.id

	tags = {
		Name = "${var.vpc_name}-rt-public"
	}
}

resource "aws_route" "public" {
	route_table_id         = aws_route_table.public.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.gateway.id
}

/*resource "aws_route" "private" {
	route_table_id         = aws_vpc.vpc.main_route_table_id
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id         = aws_nat_gateway.gateway.id
}*/

resource "aws_route_table_association" "public" {
	count          = length(aws_subnet.public)
	subnet_id      = aws_subnet.public[count.index].id
	route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
	count          = length(aws_subnet.private)
	subnet_id      = aws_subnet.private[count.index].id
	route_table_id = aws_vpc.vpc.main_route_table_id
}
