# ./modules/EC2/TargetGroups/main.tf

#########################################################
## 05_03. Target Group
#########################################################
resource "aws_lb_target_group" "lb_target_group_template" {

  for_each  = { for e in local.target_group_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-tg-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  name        = format("%s-tg-%s",local.tag_name, each.value["name"])
  port        = each.value["port"]
  protocol    = each.value["protocol"]
  target_type = each.value["target_type"]
  vpc_id      = var.default["vpc_id"] == "" ? var.vpc_id : var.default["vpc_id"]

  health_check {
    path                = each.value["health_check_path"]
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 300
    timeout             = 5
    matcher             = "200"
    protocol            = each.value["target_type"] == "alb" && each.value["port"] == "443" ? "HTTPS" : "HTTP"
  }
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "vpc_id" {
  type        = string
}
variable "target_group_list" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable         = var.default["module_enable_target_group"]
  target_group_list     = local.module_enable ? var.target_group_list : []
}

#### output ####
output "lb_target_group_ids" {
  value = local.module_enable ? [for e in aws_lb_target_group.lb_target_group_template : e] : []
}