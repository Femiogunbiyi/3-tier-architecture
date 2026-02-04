# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.project_name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-igw"
    }
  )
}

# Public Subnets (Web Tier)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-public-subnet-${count.index +1}"
      Tier = "Public"
    }
  )
}

# Frontend Private Subnets (APP Tier - Frontend)
resource "aws_subnet" "frontend" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = var.frontend_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-frontend-subnet-${count.index +1}"
      Tier = "Frontend"
    }
  )
}

# Backend Private Subnets (APP Tier - Backend)
resource "aws_subnet" "backend" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = var.backend_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-Backend-subnet-${count.index +1}"
      Tier = "Backend"
    }
  )
}

# Database Isolated Subnets (Data Tier)
resource "aws_subnet" "database" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-database-subnet-${count.index +1}"
      Tier = "Database"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : lenght(var.availability_zones)) : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-nat-eip-${count.index +1}"
    }
  )
  depends_on = [ aws_internet_gateway.main ]
}

# NAT Gateways
resource "aws_nat_gateway" "main"{
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  subnet_id = aws_subnet.public.id
  allocation_id = aws_eip.nat[count.index].id

  tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-nat-gw-${count.index +1}"
    }
  )
depends_on = [ aws_internet_gateway.main ]
}
  


# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name =  "${var.environment}-${var.project_name}-public-rt"
      Tier = "Public"
    }
  )
}

# Route for Public Subnets to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Frontend Private Subnets
resource "aws_route_table" "frontend" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-frontend-rt-${count.index +1}"
       Tier = "frontend"
    }
  )
}

# Route for Frontend Subnets to NAT Gateway
resource "aws_route" "frontend_nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  route_table_id = aws_route_table.frontend[count.index].index
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

# Associate Frontend Subnets with Frontend Route Tables
resource "aws_route_table_association" "frontend" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.frontend[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.frontend[count.index].id : null
}

# Route Tables for Backend Private Subnets
resource "aws_route_table" "backend" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-backend-rt-${count.index +1}"
       Tier = "backend"
    }
  )
}

# Route for Frontend Subnets to NAT Gateway
resource "aws_route" "backend_nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  route_table_id = aws_route_table.backend[count.index].index
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
}

# Associate Backend Subnets with Backend Route Tables
resource "aws_route_table_association" "backend" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.backend[count.index].id
  route_table_id = var.enable_nat_gateway ? aws_route_table.backend[count.index].id : null
}

# Route Table for Database Subnets (No internet Access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-database-rt"
       Tier = "database"
    }
  )
}

# Associate Database Subnets with Route table
resource "aws_route_table_association" "database" {
  count = length(var.availability_zones)
  subnet_id = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}