
provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "tictactoe_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "tictactoe_vpc"
  }
}


resource "aws_subnet" "tictactoe_sn" {
  vpc_id                  = aws_vpc.tictactoe_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-subnet1"
  }
}



resource "aws_internet_gateway" "tictactoe_igw" {
  vpc_id = aws_vpc.tictactoe_vpc.id
  tags = {
    Name = "tictactoe_igw"
  }
}


resource "aws_route_table" "tictactoe_rt" {
  vpc_id = aws_vpc.tictactoe_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tictactoe_igw.id
  }
  tags = {
    Name = "tictactoe_rt"
  }
}


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tictactoe_sn.id
  route_table_id = aws_route_table.tictactoe_rt.id
}


resource "aws_security_group" "tictactoe_sg" {
  name        = "tictactoe_sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.tictactoe_vpc.id
  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #backend
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #frontend
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all ports
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tictactoe_sg"
  }
}



resource "aws_ecs_cluster" "docker_cluster" {
  name = "docker-cluster"
}

#Tworzymy klaster o nazwie docker-cluster

resource "aws_ecs_task_definition" "docker_td" {
  family                   = "docker-task"
  network_mode             = "awsvpc" 
  #Określamy tryb sieciowy jako VPC czyli umożliwia on kontenerom uzyskiwanie własnego adresu IP wewnątrz VPC
  requires_compatibilities = ["FARGATE"]
  #Wybieramy tytułową usługę Fargate
  cpu    = "2048" 
  memory = "4096" 

  task_role_arn            = "arn:aws:iam::339713161833:role/LabRole" 
  execution_role_arn       = "arn:aws:iam::339713161833:role/LabRole"

  container_definitions = file("${path.module}/docker-compose.json")
  }


resource "aws_ecs_service" "docker_service" {
  name            = "docker-service"
  #nazwa serwisu
  cluster         = aws_ecs_cluster.docker_cluster.id
  #id klastra
  task_definition = aws_ecs_task_definition.docker_td.arn
  #definicja zasobu
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.tictactoe_sn.id]
    security_groups = [aws_security_group.tictactoe_sg.id]
    assign_public_ip = true
  }  #ustawienia sieciowe
}