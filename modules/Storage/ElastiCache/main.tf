# ./modules/Storage/ElastiCache/main.tf

#########################################################
## 04_03. ElastiCache
#########################################################
### 04-03-01. Subnet Group
resource "aws_elasticache_subnet_group" "elasticache_subnet_group_template" {

  for_each  = { for e in local.elasticache_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-ec-sg-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  name       = format("%s-ec-sg-%s",local.tag_name, each.value["name"])
#  subnet_ids = each.value["subnet_ids"] == [] ? each.value["subnet_name"] == [] ? [] : [for ids in local.subnet_ids : ids["id"] if contains(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
  subnet_ids = each.value["subnet_ids"] == [] ? each.value["subnet_name"] == [] ? [] : [for ids in local.subnet_ids : ids["id"] if startswith(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
}
### 04-03-01. Cluster
resource "aws_elasticache_cluster" "elasticache_cluster_template" {

  for_each  = { for e in local.elasticache_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-ec-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  engine                        = each.value["engine"]
  node_type                     = each.value["node_type"]
#  parameter_group_name          = each.value["parameter_group_name"]
#  engine_version                = each.value["engine_version"]
  num_cache_nodes               = each.value["num_cache_nodes"]
  az_mode                       = each.value["num_cache_nodes"] > 1 ? "cross-az" : "single-az"        # single-az or cross-az
  security_group_ids            = each.value["security_group_ids"] == [] ? [for ids in local.security_group_ids : ids["id"] if contains(each.value["security_group_name"], ids["name"])] : each.value["security_group_ids"]
  subnet_group_name             = aws_elasticache_subnet_group.elasticache_subnet_group_template[each.key].name
  port                          = each.value["port"]
  cluster_id                    = format("%s-ec-%s",local.tag_name, each.value["name"])

  depends_on = [aws_elasticache_subnet_group.elasticache_subnet_group_template]
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "elasticache_list" {
  type        = list(any)
}
variable "security_group_ids" {
  type          = list(any)
}
variable "subnet_ids" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable       = var.default["module_enable_elasticache"]
  elasticache_list    = local.module_enable ? var.elasticache_list : []
  security_group_ids  = local.module_enable ? [for e in var.security_group_ids : e] : []
  subnet_ids          = local.module_enable ? [for e in var.subnet_ids : e] : []
}

#### output ####
output "elasticache_subnet_group_ids" {
  value = local.module_enable ? [for e in aws_elasticache_subnet_group.elasticache_subnet_group_template : e] : []
}
