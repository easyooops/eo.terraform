# ./modules/VPC/NAT/main.tf

#########################################################
## 02-04. NAT Gateway
#########################################################
### 02-04-01. EIP
resource "aws_eip" "nat_eip_template" {

  count     = local.module_enable ? 1 : 0

  tags      = merge(
                    { Name : format("%s-nat-eip",local.tag_name)  },
                    var.default_tags
                  )

  domain = "vpc"
}
### 02-04-02. NAT Gateway
resource "aws_nat_gateway" "nat_gateway_template" {

  count     = local.module_enable ? 1 : 0

  tags      = merge(
                    { Name : format("%s-nat",local.tag_name)  },
                    var.default_tags,
                    local.nat_map["tags"]
                  )

  allocation_id       = aws_eip.nat_eip_template[0].id
  subnet_id           = local.subnet_id
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "nat_list" {
  type        = list(any)
}
variable "subnet_ids" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable   = var.default["module_enable_nat_gateway"]
  subnet_ids      = local.module_enable ? var.subnet_ids : []
  nat_map         = local.module_enable ? var.nat_list[0] : { subnet_name : "", tags : {} }
  subnet_id       = local.module_enable ? element([for e in local.subnet_ids : e["id"] if e["name"] == format("%s-a",local.nat_map["subnet_name"])], 0) : ""
}

#### output ####
output "nat_gateway_id" {
  value = local.module_enable ? element(aws_nat_gateway.nat_gateway_template[*].id, 0) : ""
}