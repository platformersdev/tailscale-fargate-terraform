locals {
  up_args = "--advertise-exit-node"
  authkey = "tskey-TBD"
  vpc_id = "vpc-TBD"
  state_parameter_arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/tailscale-vpn-state"
}
module "tailscale" {
  source = "../.."

  subnets = data.aws_subnets.subnets.ids

  image_name = "tailscale/tailscale"
  container_command = [
    "tailscaled",
    "-tun=userspace-networking",
    "-state=${local.state_parameter_arn}",
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

resource "time_sleep" "wait" {
  create_duration = "10s"
  depends_on = [
    module.tailscale
  ]
}
resource "null_resource" "tailscale_up" {
  triggers = {
    name         = module.tailscale.name
    cluster_name = module.tailscale.name
    authkey      = local.authkey
  }
  depends_on = [
    time_sleep.wait
  ]
  provisioner "local-exec" {
    command = "aws ecs execute-command --cluster '${module.tailscale.name}' --task $(aws ecs list-tasks --cluster '${module.tailscale.name}' --service '${module.tailscale.name}' | jq -r '.taskArns[]' | head -n1) --interactive --command 'tailscale up --authkey ${local.authkey} --hostname=${module.tailscale.name} ${local.up_args}'"
  }
}
