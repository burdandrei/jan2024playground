data "aws_ami" "base" {
  most_recent = true

  # If we change the AWS Account in which test are run, update this value.
  owners = ["099720109477"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "tls_private_key" "playground" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.playground.private_key_openssh
  filename        = "id_rsa.playground"
  file_permission = "0600"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "playground"
  public_key = tls_private_key.playground.public_key_openssh
}

resource "aws_security_group" "public_worker" {
  name        = "public_worker"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "public worker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_worker_allow_in" {
  security_group_id = aws_security_group.public_worker.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "public_worker_allow_out" {
  security_group_id = aws_security_group.public_worker.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_instance" "public_worker" {
  ami                         = data.aws_ami.base.image_id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public_worker.id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  tags = {
    Name = "boundary public worker"
  }
}

output "ssh_to_public_worker" {
  value = "\nssh -i id_rsa.playground ubuntu@${aws_instance.public_worker.public_ip}\n"
}


resource "aws_security_group" "private_worker" {
  name        = "private_worker"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "private worker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_worker_allow_in" {
  security_group_id            = aws_security_group.private_worker.id
  referenced_security_group_id = aws_security_group.public_worker.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "private_worker_allow_out" {
  security_group_id = aws_security_group.private_worker.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "private_worker" {
  ami                         = data.aws_ami.base.image_id
  instance_type               = "t3.micro"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.private_worker.id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = module.vpc.private_subnets[0]
  tags = {
    Name = "boundary private worker"
  }
}



resource "aws_security_group" "innocent_target" {
  name        = "innocent_target"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "private worker"
  }
}

resource "aws_vpc_security_group_ingress_rule" "innocent_target_allow_in" {
  security_group_id            = aws_security_group.innocent_target.id
  referenced_security_group_id = aws_security_group.private_worker.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "innocent_target_allow_out" {
  security_group_id = aws_security_group.innocent_target.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "innocent_target" {
  ami                         = data.aws_ami.base.image_id
  instance_type               = "t3.micro"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.innocent_target.id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = module.vpc.private_subnets[1]
  tags = {
    Name = "innocent target"
  }
}
