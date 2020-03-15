//connections.tf
provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}

//network.tf
resource "aws_vpc" "test-env" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

//gateways.tf
resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = aws_vpc.test-env.id
}

output "instance_ip_addr" {
  value = aws_eip.ide.public_ip
}

resource "aws_key_pair" "deployer" {
  key_name   = "ide-deployer"
  public_key = file("dist/id_rsa.pub")
}

//subnets.tf
resource "aws_subnet" "subnet-uno" {
  cidr_block        = cidrsubnet(aws_vpc.test-env.cidr_block, 3, 1)
  vpc_id            = aws_vpc.test-env.id
  availability_zone = "eu-west-1a"
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = aws_vpc.test-env.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-env-gw.id
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.subnet-uno.id
  route_table_id = aws_route_table.route-table-test-env.id
}

//security.tf
resource "aws_security_group" "ingress-all-test" {
  name   = "allow-all-sg"
  vpc_id = aws_vpc.test-env.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    // go convey
    from_port = 8787
    to_port   = 8787
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    // golem
    from_port = 8989
    to_port   = 8989
    protocol  = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
  }

  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-18.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

//servers.tf
resource "aws_instance" "ide" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.xlarge"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.ingress-all-test.id]
  subnet_id       = aws_subnet.subnet-uno.id
}

resource "aws_eip" "ide" {
  instance = aws_instance.ide.id
  vpc      = true
}

resource "aws_volume_attachment" "ide_docker" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ide_docker.id
  instance_id = aws_instance.ide.id
}

resource "aws_ebs_volume" "ide_docker" {
  availability_zone = "eu-west-1a"
  size              = 40

  encrypted = true
  type      = "gp2"

  tags = {
    Name = "tests.ide_docker"
  }
}
