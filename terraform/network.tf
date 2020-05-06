resource "aws_vpc" "ggjam" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = merge (
    {
      Name = "ggjam"
    },
    var.base_tags
  )
}

resource "aws_vpc_dhcp_options" "ggjam" {
  domain_name          = "ggjam"
  domain_name_servers  = ["10.0.0.2"]

  tags = merge (
    {
      Name = "ggjam"
    },
    var.base_tags
  )
}

resource "aws_vpc_dhcp_options_association" "ggjam" {
  vpc_id          = aws_vpc.ggjam.id
  dhcp_options_id = aws_vpc_dhcp_options.ggjam.id
}

resource "aws_internet_gateway" "ggjam-igw" {
  vpc_id = aws_vpc.ggjam.id

  tags = merge (
    {
      Name = "ggjam-igw"
    },
    var.base_tags
  )
}

resource "aws_subnet" "public-a" {
  vpc_id     = aws_vpc.ggjam.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = merge (
    {
      Name = "public-a"
    },
    var.base_tags
  )
}

resource "aws_subnet" "public-b" {
  vpc_id     = aws_vpc.ggjam.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = merge (
    {
      Name = "public-b"
    },
    var.base_tags
  )
}

resource "aws_eip" "nat-eip" {
  vpc      = true

  tags = merge (
    {
      Name = "nat-eip"
    },
    var.base_tags
  )
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-a.id
  
  tags = merge (
    {
      Name = "nat-eip"
    },
    var.base_tags
  )
}

resource "aws_subnet" "private-a" {
  vpc_id     = aws_vpc.ggjam.id
  cidr_block = "10.0.3.0/24"

  tags = merge (
    {
      Name = "private-a"
    },
    var.base_tags
  )
}

resource "aws_subnet" "private-b" {
  vpc_id     = aws_vpc.ggjam.id
  cidr_block = "10.0.4.0/24"

  tags = merge (
    {
      Name = "private-b"
    },
    var.base_tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ggjam.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ggjam-igw.id
  }

  tags = merge (
    {
      Name = "public-rt"
    },
    var.base_tags
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ggjam.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = merge (
    {
      Name = "private-rt"
    },
    var.base_tags
  )
}

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.public-a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.public-b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.private-a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.private-b.id
  route_table_id = aws_route_table.private.id
}