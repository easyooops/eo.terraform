# ./modules/VPC/PrefixLists/main.tf

##########################################################
## 02-06. Prefix List
##########################################################
resource "aws_ec2_managed_prefix_list" "prefix_list_template" {

  for_each  = { for e in local.prefix_list : e["name"] => e }

  tags      = merge(
    { Name : format("%s-prefix-%s",local.tag_name, each.value["name"])  },
    var.default_tags,
    each.value["tags"]
  )

  name            = format("%s-prefix-%s",local.tag_name, each.value["name"])
  address_family  = each.value["address_family"]
  max_entries     = length(each.value["entry"])

  dynamic "entry" {
    for_each = { for i, entry in each.value["entry"] : i => entry }

    content {
      cidr        = entry.value["cidr"]
      description = entry.value["description"]
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
variable "prefix_list" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable   = var.default["module_enable_prefix_list"]
  prefix_list     = local.module_enable ? var.prefix_list : []
}

#### output ####
output "prefix_ids" {
  value = local.module_enable ? [for e in aws_ec2_managed_prefix_list.prefix_list_template : {
            id = e["id"]
            tag = e["tags"]["Name"]
            name = replace(e["tags"]["Name"], format("%s-prefix-",local.tag_name), "")
          }] : []
}