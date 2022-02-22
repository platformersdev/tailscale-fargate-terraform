locals {
  up_args = "--advertise-exit-node"
  authkey = "tskey-TBD"
  vpc_id  = "vpc-TBD"
  image   = "TBD.dkr.ecr.us-east-1.amazonaws.com/tailscale:TBD"
  state_parameter_arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tailscale-vpn-state"
}

module "tailscale" {
  source = "../.."

  subnets = data.aws_subnets.subnets.ids

  image_name = local.image

  container_environment = [
    { name = "TAILSCALE_UP_ARGS", value = local.up_args },
    { name = "TAILSCALE_STATE_PARAMETER_ARN", value = local.state_parameter_arn },
    { name = "TAILSCALE_AUTHKEY", value = local.authkey },
  ]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}