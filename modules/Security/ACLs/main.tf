# ./modules/Security/ACLs/main.tf

#########################################################
## 03_01. ACLs
#########################################################
resource "aws_default_network_acl" "network_acl_template" {

  count     = local.module_enable ? 1 : 0

  tags      = merge(
                    { Name : format("%s-acl",local.tag_name)  },
                    var.default_tags
                  )

  default_network_acl_id  = var.default_network_acl_id

  dynamic "ingress" {
    for_each = { for i, ingress in local.acl_ingress : i => ingress if ingress["cidr_block"] != "" }

    content {
      protocol          = ingress.value["protocol"]
      rule_no           = ingress.value["rule_no"]
      action            = ingress.value["action"]
      cidr_block        = ingress.value["cidr_block"] == "" ? local.default_cidr_block : ingress.value["cidr_block"]
      from_port         = ingress.value["from_port"]
      to_port           = ingress.value["to_port"]
    }
  }
  dynamic "ingress" {
    for_each = { for i, ingress in local.acl_ingress : i => ingress if ingress["cidr_block"] == "" }

    content {
      protocol          = ingress.value["protocol"]
      rule_no           = ingress.value["rule_no"]
      action            = ingress.value["action"]
      ipv6_cidr_block   = ingress.value["ipv6_cidr_block"] == "" ? local.default_ipv6_cidr_block : ingress.value["ipv6_cidr_block"]
      from_port         = ingress.value["from_port"]
      to_port           = ingress.value["to_port"]
    }
  }
  dynamic "egress" {
    for_each = { for i, egress in local.acl_egress : i => egress if egress["cidr_block"] != "" }

    content {
      protocol          = egress.value["protocol"]
      rule_no           = egress.value["rule_no"]
      action            = egress.value["action"]
      cidr_block        = egress.value["cidr_block"] == "" ? local.default_cidr_block : egress.value["cidr_block"]
      from_port         = egress.value["from_port"]
      to_port           = egress.value["to_port"]
    }
  }
  dynamic "egress" {
    for_each = { for i, egress in local.acl_egress : i => egress if egress["cidr_block"] == "" }

    content {
      protocol          = egress.value["protocol"]
      rule_no           = egress.value["rule_no"]
      action            = egress.value["action"]
      ipv6_cidr_block   = egress.value["ipv6_cidr_block"] == "" ? local.default_ipv6_cidr_block : egress.value["ipv6_cidr_block"]
      from_port         = egress.value["from_port"]
      to_port           = egress.value["to_port"]
    }
  }
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "acl_map" {
  type        = map(any)
}
variable "default_network_acl_id" {
  type        = string
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable   = var.default["module_enable_acl"]
  acl_map         = local.module_enable ? var.acl_map : {}
  acl_ingress     = local.module_enable ? local.acl_map["ingress"] : []
  acl_egress      = local.module_enable ? local.acl_map["egress"] : []

  default_cidr_block      = "0.0.0.0/0"
  default_ipv6_cidr_block = "::/0"
}