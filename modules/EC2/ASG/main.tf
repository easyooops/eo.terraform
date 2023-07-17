# ./modules/EC2/ASG/main.tf

#########################################################
## 05_05. Auto Scaling Group
#########################################################
resource "aws_autoscaling_group" "autoscaling_group_template" {

  for_each  = { for e in local.asg_list : e["name"] => e }

  name                        = format("%s-asg-%s",local.tag_name, each.value["name"])
  desired_capacity            = each.value["desired_capacity"]
  max_size                    = each.value["max_size"]
  min_size                    = each.value["min_size"]
#  vpc_zone_identifier         = each.value["subnet_ids"] == [] ? [for ids in local.subnet_ids : ids["id"] if contains(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
  vpc_zone_identifier         = each.value["subnet_ids"] == [] ? [for ids in local.subnet_ids : ids["id"] if startswith(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
#  target_group_arns           = each.value["target_group"] == "" ? "" : join("",[for e in local.lb_target_group_ids : e["arn"] if replace(e["tags"]["Name"],format("%s-tg-",local.tag_name),"") == each.value["target_group"]])
  target_group_arns           = each.value["target_group"] == [] ? [] : [for e in local.lb_target_group_ids : e["arn"] if replace(e["tags"]["Name"],format("%s-tg-",local.tag_name),"") == each.value["target_group"]]
  health_check_grace_period   = 300
  health_check_type           = "ELB"

  launch_template {
    id      = each.value["launch_template"] == "" ? "" : element([for e in local.launch_template_ids : e["id"] if replace(e["tags"]["Name"],format("%s-lt-",local.tag_name),"") == each.value["launch_template"]], 0)
    version = "$Latest"
  }
  tag {
    key   = "Name"
    value = format("%s-instance-%s",local.tag_name, each.value["name"])
    propagate_at_launch = false
  }
  dynamic "tag" {
    for_each  = { for e in each.value["tags"] : e["key"] => e }

    content {
      key                 = tag.value["key"]
      value               = tag.value["value"]
      propagate_at_launch = tag.value["propagate_at_launch"]
    }
  }
}

#resource "aws_autoscaling_attachment" "autoscaling_attachment_template" {
#
#  for_each  = { for e in local.asg_list : e["name"] => e }
#
#  autoscaling_group_name  = aws_autoscaling_group.autoscaling_group_template[each.key].id
#  alb_target_group_arn    = each.value["target_group"] == "" ? "" : join("",[for e in local.lb_target_group_ids : e["arn"] if replace(e["tags"]["Name"],format("%s-tg-",local.tag_name),"") == each.value["target_group"]])
#}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "subnet_ids" {
  type        = list(any)
}
variable "lb_target_group_ids" {
  type        = list(any)
}
variable "launch_template_ids" {
  type        = list(any)
}
variable "asg_list" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable         = var.default["module_enable_asg"]
  subnet_ids            = local.module_enable ? [for e in var.subnet_ids : e] : []
  launch_template_ids   = local.module_enable ? [for e in var.launch_template_ids : e] : []
  lb_target_group_ids   = local.module_enable ? [for e in var.lb_target_group_ids : e] : []
  asg_list              = local.module_enable ? var.asg_list : []

  subnet_az = ["a","b","c","d","e","f"]
}

#### output ####
output "autoscaling_group_ids" {
  value = local.module_enable ? [for e in aws_autoscaling_group.autoscaling_group_template : e] : []
}