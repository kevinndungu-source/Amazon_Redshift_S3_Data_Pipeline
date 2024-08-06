provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.80.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "RedshiftProjectVPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "RedshiftProjectIGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "RedshiftProjectPublicRouteTable"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "RedshiftProjectPrivateRouteTable"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.80.101.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "RedshiftPrivateSubnet01"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.80.102.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "RedshiftPrivateSubnet02"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "redshift-database-demo-255"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [
    aws_route_table.private.id
  ]
}

resource "aws_iam_role" "redshift_role" {
  name = "RedshiftDemoProject"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "RedshiftDemoProject"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:*"
          ]
          Resource = "arn:aws:s3:::redshift-database-demo-255/*"
        }
      ]
    })
  }
}

resource "aws_security_group" "redshift_ec2_sg" {
  name_prefix = "RedshiftEC2SecurityGroup"
  description = "EC2 access for Redshift Project"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redshift_sg" {
  name_prefix = "RedshiftSecurityGroup"
  description = "Access to Redshift"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port                = 5439
    to_port                  = 5439
    protocol                 = "tcp"
    security_groups          = [aws_security_group.redshift_ec2_sg.id]
  }
}

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "redshift-subnet-group"
  description = "Private subnet access for Redshift"
  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]
}
