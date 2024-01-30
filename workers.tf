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

resource "aws_security_group_rule" "allow_inbound_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = module.vpc.default_security_group_id
}

resource "aws_security_group_rule" "allow_inbound_boundary" {
  type        = "ingress"
  from_port   = 9200
  to_port     = 9202
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = module.vpc.default_security_group_id
}

resource "aws_instance" "public_worker" {
  ami                         = data.aws_ami.base.image_id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.vpc.default_security_group_id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  tags = {
    Name = "boundary public worker"
  }
}

resource "aws_instance" "private_worker" {
  ami                         = data.aws_ami.base.image_id
  instance_type               = "t3.micro"
  associate_public_ip_address = false
  vpc_security_group_ids      = [module.vpc.default_security_group_id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = module.vpc.private_subnets[0]
  tags = {
    Name = "boundary private worker"
  }
}


resource "aws_instance" "innocent_target" {
  ami                         = data.aws_ami.base.image_id
  instance_type               = "t3.micro"
  associate_public_ip_address = false
  vpc_security_group_ids      = [module.vpc.default_security_group_id]
  key_name                    = aws_key_pair.generated_key.key_name
  subnet_id                   = module.vpc.private_subnets[1]
  tags = {
    Name = "innocent target"
  }
}
