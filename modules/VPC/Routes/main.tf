# ./modules/VPC/Routes/main.tf

#########################################################
## 02-05. Route
#########################################################
### 02-05-01. Route Tables
resource "aws_route_table" "route_table_template" {

  for_each  = { for e in local.route_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-rt-tbl-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  vpc_id    = var.vpc_id
}
### 02-05-02. Routes
resource "aws_route" "igw_route_template" {

  for_each = { for e in local.route_list : e["name"] => e if e["is_igw"] }

  route_table_id          = aws_route_table.route_table_template[each.key].id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = var.internet_gateway_id

  lifecycle {
    ignore_changes = [
      destination_cidr_block,
      gateway_id
    ]
    create_before_destroy = true
  }
}
resource "aws_route" "nat_route_template" {

  for_each = { for e in local.nat_route_list : e["name"] => e if e["is_nat"] }

  route_table_id          = aws_route_table.route_table_template[each.key].id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = var.nat_gateway_id

  lifecycle {
    ignore_changes = [
      destination_cidr_block,
      nat_gateway_id
    ]
    create_before_destroy = true
  }
}
### 02-04-03. Subnet Association
resource "aws_route_table_association" "route_table_association_template" {

  for_each        = { for i, e in local.subnet_ids : i => e }

  subnet_id       = each.value["id"]
  route_table_id  = element([for rt in aws_route_table.route_table_template : rt["id"] if replace(rt["tags"]["Name"], format("%s-rt-tbl-",local.tag_name), "") == each.value["route"]], 0)
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "route_list" {
  type        = list(any)
}
variable "vpc_id" {
  type        = string
}
variable "internet_gateway_id" {
  type        = string
}
variable "nat_gateway_id" {
  type        = string
}
variable "subnet_ids" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable     = var.default["module_enable_routes"]
  nat_module_enable = local.module_enable ? var.default["module_enable_nat_gateway"] : local.module_enable
  subnet_ids        = local.module_enable ? [for e in var.subnet_ids : e] : []
  route_list        = local.module_enable ? var.route_list : []
  nat_route_list    = local.nat_module_enable ? var.route_list : []
}

#### output ####
output "route_table_ids" {
  value = local.module_enable ? [for e in aws_route_table.route_table_template : e] : []
}
