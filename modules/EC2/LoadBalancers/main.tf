# ./modules/EC2/LoadBalancers/main.tf

#########################################################
## 05_04. Load Balancer
#########################################################
### 05_01_01. EIP
resource "aws_eip" "elb_eip_template" {

  for_each  = { for e in local.eip_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-eip-%s",local.tag_name, each.value["name"])  },
                    var.default_tags
                  )

  domain = "vpc"
}
### 05_01_02. Network Load Balancer
resource "aws_lb" "nlb_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "network" }

  tags      = merge(
                    { Name : format("%s-elb-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  name                        = format("%s-elb-%s",local.tag_name, each.value["name"])
  load_balancer_type          = each.value["load_balancer_type"]
  enable_deletion_protection  = false

  dynamic "subnet_mapping" {
    for_each  = { for i, e in local.eip_list : i => e if e["lb_name"] == each.value["name"] }

    content {
#      subnet_id     = subnet_mapping.value["subnet_id"] == "" ? subnet_mapping.value["subnet_name"] == "" ? "" : element([for ids in local.subnet_ids : ids["id"] if contains(ids["name"], format("%s-%s",subnet_mapping.value["subnet_name"],local.subnet_az[subnet_mapping.key]))], 0) : subnet_mapping.value["subnet_id"]
      subnet_id     = subnet_mapping.value["subnet_id"] == "" ? subnet_mapping.value["subnet_name"] == "" ? "" : element([for ids in local.subnet_ids : ids["id"] if startswith(ids["name"], format("%s-%s",subnet_mapping.value["subnet_name"],local.subnet_az[subnet_mapping.key]))], 0) : subnet_mapping.value["subnet_id"]
      allocation_id = aws_eip.elb_eip_template[subnet_mapping.value["name"]].id
    }
  }

  #  S3 Bucket 생성
  access_logs {
    bucket  = local.elb_access_log_bucket_ids
    prefix  = each.value["name"]
    enabled = local.fun_elb_access_logging
  }
}
### 05_01_03. Application Load Balancer
resource "aws_lb" "alb_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "application" }

  tags      = merge(
                    { Name : format("%s-elb-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  name                        = format("%s-elb-%s",local.tag_name, each.value["name"])
  load_balancer_type          = each.value["load_balancer_type"]
  enable_deletion_protection  = false
  security_groups             = each.value["security_group_ids"] == [] ? [for ids in local.security_group_ids : ids["id"] if contains(each.value["security_group_name"], ids["name"])] : each.value["security_group_ids"]
#  subnets                     = each.value["subnet_ids"] == [] ? each.value["subnet_name"] == [] ? [] : [for ids in local.subnet_ids : ids["id"] if contains(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
  subnets                     = each.value["subnet_ids"] == [] ? each.value["subnet_name"] == [] ? [] : [for ids in local.subnet_ids : ids["id"] if startswith(ids["name"], element(each.value["subnet_name"],0))] : each.value["subnet_ids"]
  idle_timeout                = 300
  drop_invalid_header_fields  = true
  ip_address_type             = each.value["ip_address_type"]

  #  S3 Bucket 생성
  access_logs {
    bucket  = local.elb_access_log_bucket_ids
    prefix  = each.key
    enabled = local.fun_elb_access_logging
  }
}
### 05_01_04. Network Load Balancer Listeners
resource "aws_lb_listener" "nlb_listener_443_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "network" }

  tags      = merge(
                    { Name : format("%s-lisener-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  load_balancer_arn = element([for e in aws_lb.nlb_template : e["arn"] if e["tags"]["Name"] == format("%s-elb-%s",local.tag_name, each.value["name"])], 0)
  port              = "443"
  protocol          = "TCP"
  ssl_policy        = ""
  certificate_arn   = ""

  default_action {
    type             = "forward"
    target_group_arn = element([for e in local.lb_target_group_ids : e["arn"] if e["tags"]["Name"] == format("%s-tg-%s",local.tag_name, each.value["target_group"])], 0)
  }
}
resource "aws_lb_listener" "nlb_listener_80_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "network" }

  tags      = merge(
                    { Name : format("%s-lisener-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  load_balancer_arn = element([for e in aws_lb.nlb_template : e["arn"] if e["tags"]["Name"] == format("%s-elb-%s",local.tag_name, each.value["name"])], 0)
  port              = "80"
  protocol          = "TCP"
  ssl_policy        = ""
  certificate_arn   = ""

  default_action {
    type             = "forward"
    target_group_arn = element([for e in local.lb_target_group_ids : e["arn"] if e["tags"]["Name"] == format("%s-tg-%s",local.tag_name, each.value["target_group"])], 0)
  }
}
### 05_01_05. Application Load Balancer Listeners
resource "aws_lb_listener" "alb_listener_443_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "application" && e["certificate_arn"] != "" }

  tags      = merge(
                    { Name : format("%s-lisener-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  load_balancer_arn = element([for e in aws_lb.alb_template : e["arn"] if e["tags"]["Name"] == format("%s-elb-%s",local.tag_name, each.value["name"])], 0)
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = each.value["certificate_arn"]

  default_action {
    type             = "forward"
    target_group_arn = element([for e in local.lb_target_group_ids : e["arn"] if e["tags"]["Name"] == format("%s-tg-%s",local.tag_name, each.value["target_group"])], 0)
  }
}
resource "aws_lb_listener" "alb_listener_80_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "application" }

  tags      = merge(
                    { Name : format("%s-lisener-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  load_balancer_arn = element([for e in aws_lb.alb_template : e["arn"] if e["tags"]["Name"] == format("%s-elb-%s",local.tag_name, each.value["name"])], 0)
  port              = "80"
  protocol          = "HTTP"
  ssl_policy        = ""
  certificate_arn   = ""

  default_action {
    type             = "forward"
    target_group_arn = element([for e in local.lb_target_group_ids : e["arn"] if e["tags"]["Name"] == format("%s-tg-%s",local.tag_name, each.value["target_group"])], 0)
  }
}
### 05_01_06. ALB Target Group Attachment
resource "aws_lb_target_group_attachment" "lb_target_group_attachment_template" {

  for_each  = { for e in local.load_balancer_list : e["name"] => e if e["load_balancer_type"] == "network" }

  target_group_arn  = element([for e in local.lb_target_group_ids : e["arn"] if e["tags"]["Name"] == format("%s-tg-%s",local.tag_name, each.value["target_group"])], 0)
  target_id         = element([for e in aws_lb.alb_template : e["arn"] if e["tags"]["Name"] == format("%s-elb-%s",local.tag_name, each.value["alb_target_group"])], 0)
  port              = 80

  depends_on = [aws_lb_listener.alb_listener_80_template]
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "security_group_ids" {
  type          = list(any)
}
variable "subnet_ids" {
  type        = list(any)
}
variable "lb_target_group_ids" {
  type        = list(any)
}
variable "elb_access_log_bucket_ids" {
  type        = string
}
variable "load_balancer_list" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable         = var.default["module_enable_load_balancer"]
  fun_elb_access_logging= var.default["fun_elb_access_logging"]

  elb_logs_bucket       = var.default["elb_logs_bucket"] == "" ? "elb-logs" : var.default["elb_logs_bucket"]

  load_balancer_list    = local.module_enable ? var.load_balancer_list : []
  security_group_ids    = local.module_enable ? [for e in var.security_group_ids : e] : []
  subnet_ids            = local.module_enable ? [for e in var.subnet_ids : e] : []
  lb_target_group_ids   = local.module_enable ? [for e in var.lb_target_group_ids : e] : []
  elb_access_log_bucket_ids = local.module_enable ? var.elb_access_log_bucket_ids : ""
  subnet_name_list      = !local.module_enable ? [] : flatten([
    for az in local.subnet_az : [
      for nlb in local.load_balancer_list : [
        for subnet_name in nlb["subnet_name"] : {
          lb_name             = nlb["name"]
          name                = format("%s-%s-%s",nlb["name"],subnet_name, az),
          load_balancer_type  = nlb["load_balancer_type"],
          subnet_id           = "",
          subnet_name         = subnet_name
        }
        if nlb["load_balancer_type"] == "network"
      ]
    ]
  ])
  subnet_ids_list       = !local.module_enable ? [] : flatten([
    for nlb in local.load_balancer_list : [
      for subnet_id in nlb["subnet_ids"] : {
        lb_name             = nlb["name"]
        name                = format("%s-%s",nlb["name"],subnet_id),
        load_balancer_type  = nlb["load_balancer_type"],
        subnet_id           = subnet_id,
        subnet_name         = ""
      }
      if nlb["load_balancer_type"] == "network"
    ]
  ])
  eip_list          = local.subnet_ids_list == [] ? local.subnet_name_list : local.subnet_ids_list

  subnet_az = ["a","b"]
}

#### output ####
output "alb_ids" {
  value = local.module_enable ? [for e in aws_lb.alb_template : e] : []
}
output "nlb_ids" {
  value = local.module_enable ? [for e in aws_lb.nlb_template : e] : []
}