# ./modules/Storage/RDS/main.tf

#########################################################
## 04_02. RDS
#########################################################
resource "aws_db_subnet_group" "db_subnet_group_template" {

  for_each  = { for e in local.rds_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-db-sg-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  name        = format("%s-db-sg-%s",local.tag_name, each.value["name"])
  description = format("%s-db-sg-%s",local.tag_name, each.value["name"])
#  subnet_ids  = each.value["subnet_ids"] == [] ? each.value["subnet_name"] == [] ? [] : [for ids in local.subnet_ids : ids["id"] if contains(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
  subnet_ids  = each.value["subnet_ids"] == [] ? each.value["subnet_name"] == [] ? [] : [for ids in local.subnet_ids : ids["id"] if startswith(ids["name"], each.value["subnet_name"])] : each.value["subnet_ids"]
}

resource "aws_db_instance" "db_instance_template" {

  for_each  = { for e in local.rds_list : e["name"] => e }

  tags      = merge(
                      { Name : format("%s-db-%s",local.tag_name, each.value["name"])  },
                      var.default_tags,
                      each.value["tags"]
                    )

  identifier                  = each.value["name"]
  allocated_storage           = each.value["allocated_storage"]
  auto_minor_version_upgrade  = false                             # Custom for Oracle not support minor version upgrades
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group_template[each.key].name
  backup_retention_period     = 7
  multi_az                    = each.value["multi_az"]            # Custom for Oracle does not support multi-az
  engine                      = each.value["engine"]
  engine_version              = each.value["engine_version"]      # MySQL 최신 버전으로 업데이트해주세요.
  instance_class              = each.value["instance_class"]
  storage_type                = "gp2"
  username                    = each.value["username"]
  password                    = each.value["password"]
  vpc_security_group_ids      = each.value["security_group_ids"] == [] ? [for ids in local.security_group_ids : ids["id"] if contains(each.value["security_group_name"], ids["name"])] : each.value["security_group_ids"]
#  parameter_group_name        = each.value["parameter_group_name"]
#  option_group_name           = each.value["option_group_name"]
  storage_encrypted           = true
  port                        = each.value["port"]

  skip_final_snapshot         = true
  delete_automated_backups    = false

  depends_on = [aws_db_subnet_group.db_subnet_group_template]
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "rds_list" {
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

  module_enable       = var.default["module_enable_rds"]
  rds_list            = local.module_enable ? var.rds_list : []
  security_group_ids  = local.module_enable ? [for e in var.security_group_ids : e] : []
  subnet_ids          = local.module_enable ? [for e in var.subnet_ids : e] : []
}

#### output ####
output "db_subnet_group_ids" {
  value = local.module_enable ? [for e in aws_db_subnet_group.db_subnet_group_template : e] : []
}
