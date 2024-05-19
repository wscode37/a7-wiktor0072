provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "app_vpc"
  }
}

resource "aws_internet_gateway" "app_gw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "app_gw"
  }
}

resource "aws_subnet" "backend_subnet" {
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "backend_subnet"
  }
}

resource "aws_subnet" "frontend_subnet" {
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "frontend_subnet"
  }
}

resource "aws_route_table" "app_rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gw.id
  }
  tags = {
    Name = "app_rt"
  }
}

resource "aws_route_table_association" "backend_rta" {
  subnet_id = aws_subnet.backend_subnet.id
  route_table_id = aws_route_table.app_rt.id
}

resource "aws_route_table_association" "frontend_rta" {
  subnet_id = aws_subnet.frontend_subnet.id
  route_table_id = aws_route_table.app_rt.id
}

resource "aws_security_group" "backend_sg" {
  name = "backend_sg"
  description = "Allow backend traffic"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend_sg"
  }
}

resource "aws_security_group" "frontend_sg" {
  name = "frontend_sg"
  description = "Allow frontend traffic"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "frontend_sg"
  }
}

resource "aws_elastic_beanstalk_application" "backend_app" {
  name        = "Backend-app"
  description = "Backend application"
}

resource "aws_elastic_beanstalk_application" "frontend_app" {
  name        = "Frontend-app"
  description = "Frontend application"
}

resource "aws_elastic_beanstalk_environment" "backend_env" {
  name                = "Backend-app-env"
  application         = aws_elastic_beanstalk_application.backend_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Docker"
  version_label = aws_elastic_beanstalk_application_version.backend_version.name
  cname_prefix = "tictactoe266577"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.app_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.backend_subnet.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "EnvironmentType"
    value = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "arn:aws:iam::339713161833:role/LabRole"
  }

  setting {
    namespace = "aws:ec2:instances"
    name = "SupportedArchitectures"
    value = "x86_64"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.small"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = aws_security_group.backend_sg.id
  }
}

resource "aws_elastic_beanstalk_environment" "frontend_env" {
  name                = "Front-app-env"
  application         = aws_elastic_beanstalk_application.frontend_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Docker"
  version_label = aws_elastic_beanstalk_application_version.frontend_version.name
  cname_prefix = "266577tictactoefront"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.app_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.frontend_subnet.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "EnvironmentType"
    value = "SingleInstance"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "arn:aws:iam::339713161833:role/LabRole"
  }

  setting {
    namespace = "aws:ec2:instances"
    name = "SupportedArchitectures"
    value = "x86_64"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.small"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = aws_security_group.frontend_sg.id
  }
}

resource "aws_elastic_beanstalk_application_version" "backend_version" {
  name        = "backend-v1"
  application = aws_elastic_beanstalk_application.backend_app.name
  description = "Backend application version created by Terraform"
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = aws_s3_object.backend_s3o.key
}

resource "aws_elastic_beanstalk_application_version" "frontend_version" {
  name        = "frontend-v1"
  application = aws_elastic_beanstalk_application.frontend_app.name
  description = "Frontend application version created by Terraform"
  bucket      = aws_s3_bucket.app_bucket.bucket
  key         = aws_s3_object.frontend_s3o.key
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "tictactoeb1"
}

resource "aws_s3_object" "backend_s3o" {
  bucket = aws_s3_bucket.app_bucket.bucket
  key = "backend.zip"
  source = "backend.zip"
}

resource "aws_s3_object" "frontend_s3o" {
  bucket = aws_s3_bucket.app_bucket.bucket
  key = "frontend.zip"
  source = "frontend.zip"
}

