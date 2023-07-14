# ./modules/Security/SG/main.tf

#########################################################
## 03_02. Security Group
#########################################################
### 03-02-00. Default Security Group in/out bound 삭제. 보안.
resource "aws_default_security_group" "default_security_group_template" {

  count     = local.module_enable ? 1 : 0

  vpc_id    = var.vpc_id
}
### 03-02-01. Security Group, SG 연결을 위해 SG ID 필요.
resource "aws_security_group" "security_group_template" {

  for_each  = { for e in local.sg_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-sg-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  vpc_id        = var.vpc_id
  name          = each.key
  description   = each.value["description"]
}

### 03-02-02. Security Group Rule Ingress, SG / Prefix 연결. CIDR 권장 하지 않음.
resource "aws_security_group_rule" "security_group_rule_ingress_prefix_template" {

  for_each  = { for i, e in local.ingress_list : i => e if e["pf"] != "" }

  security_group_id         = aws_security_group.security_group_template[each.value["name"]].id
  type                      = "ingress"

  protocol                  = each.value["protocol"]
  prefix_list_ids           = each.value["pf"] == "" ? [] : [for pf in local.prefix_ids : pf["id"] if pf["name"] == each.value["pf"]]
  from_port                 = each.value["from_port"]
  to_port                   = each.value["to_port"]
  description               = each.value["description"]
}
resource "aws_security_group_rule" "security_group_rule_ingress_sg_template" {

  for_each  = { for i, e in local.ingress_list : i => e if e["sg"] != "" }

  security_group_id         = aws_security_group.security_group_template[each.value["name"]].id
  type                      = "ingress"

  protocol                  = each.value["protocol"]
  source_security_group_id  = each.value["sg"] == "" ? "" : element([for sg in aws_security_group.security_group_template : sg["id"] if sg["name"] == each.value["sg"]], 0)
  from_port                 = each.value["from_port"]
  to_port                   = each.value["to_port"]
  description               = each.value["description"]
}
resource "aws_security_group_rule" "security_group_rule_ingress_cidr_template" {

  for_each  = { for i, e in local.ingress_list : i => e if e["cidr"] != "" }

  security_group_id         = aws_security_group.security_group_template[each.value["name"]].id
  type                      = "ingress"

  protocol                  = each.value["protocol"]
  cidr_blocks               = each.value["cidr"] == [] ? "" : each.value["cidr"]
  from_port                 = each.value["from_port"]
  to_port                   = each.value["to_port"]
  description               = each.value["description"]
}
resource "aws_security_group_rule" "security_group_rule_egress_prefix_template" {

  for_each  = { for i, e in local.egress_list : i => e if e["pf"] != "" }

  security_group_id         = aws_security_group.security_group_template[each.value["name"]].id
  type                      = "egress"

  protocol                  = each.value["protocol"]
  prefix_list_ids           = each.value["pf"] == "" ? [] : [for pf in local.prefix_ids : pf["id"] if pf["name"] == each.value["pf"]]
  from_port                 = each.value["from_port"]
  to_port                   = each.value["to_port"]
  description               = each.value["description"]
}
resource "aws_security_group_rule" "security_group_rule_egress_sg_template" {

  for_each  = { for i, e in local.egress_list : i => e if e["sg"] != "" }

  security_group_id         = aws_security_group.security_group_template[each.value["name"]].id
  type                      = "egress"

  protocol                  = each.value["protocol"]
  source_security_group_id  = each.value["sg"] == "" ? "" : element([for sg in aws_security_group.security_group_template : sg["id"] if sg["name"] == each.value["sg"]], 0)
  from_port                 = each.value["from_port"]
  to_port                   = each.value["to_port"]
  description               = each.value["description"]
}
resource "aws_security_group_rule" "security_group_rule_egress_cidr_template" {

  for_each  = { for i, e in local.egress_list : i => e if e["cidr"] != "" }

  security_group_id         = aws_security_group.security_group_template[each.value["name"]].id
  type                      = "egress"

  protocol                  = each.value["protocol"]
  cidr_blocks               = each.value["cidr"] == [] ? "" : each.value["cidr"]
  from_port                 = each.value["from_port"]
  to_port                   = each.value["to_port"]
  description               = each.value["description"]
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "sg_list" {
  type        = list(any)
}
variable "vpc_id" {
  type        = string
}
variable "prefix_ids" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable   = var.default["module_enable_security_group"]
  sg_list         = !local.module_enable ? [] : var.sg_list
  prefix_ids      = !local.module_enable ? [] : [for e in var.prefix_ids : e]
  ingress_list    = !local.module_enable ? [] : flatten([
    for sg in local.sg_list : [
      for ingress in sg["ingress"] : {
        name        = sg["name"],
        from_port   = ingress["from_port"],
        to_port     = ingress["to_port"],
        protocol    = ingress["protocol"],
        cidr        = ingress["cidr"],
        sg          = ingress["sg"],
        pf          = ingress["pf"],
        description = ingress["description"]
      }
    ]
  ])
  egress_list     = !local.module_enable ? [] : flatten([
    for sg in local.sg_list : [
      for egress in sg["egress"] : {
        name        = sg["name"],
        from_port   = egress["from_port"],
        to_port     = egress["to_port"],
        protocol    = egress["protocol"],
        cidr        = egress["cidr"],
        sg          = egress["sg"],
        pf          = egress["pf"],
        description = egress["description"]
      }
    ]
  ])
}

#### output ####
output "security_group_ids" {
  value = local.module_enable ? [for e in aws_security_group.security_group_template : {
            id = e["id"]
            tag = e["tags"]["Name"]
            name = replace(e["tags"]["Name"], format("%s-sg-",local.tag_name), "")
          }] : []
}