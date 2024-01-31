module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "playground"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  # default_security_group_egress = [
  #   {
  #     protocol    = "All"
  #     from_port   = 0
  #     to_port     = 0
  #     cidr_blocks = "0.0.0.0/0"
  #   }
  # ]

  # default_security_group_ingress = [
  #   {
  #     protocol    = "tcp"
  #     from_port   = 22
  #     to_port     = 22
  #     cidr_blocks = "0.0.0.0/0"
  #     description = "SSH"
  #   },
  #   {
  #     protocol    = "tcp"
  #     from_port   = 9200
  #     to_port     = 9202
  #     cidr_blocks = "0.0.0.0/0"
  #     description = "Boundary"
  # }]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
