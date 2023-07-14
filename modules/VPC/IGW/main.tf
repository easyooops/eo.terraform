# ./modules/VPC/IGW/main.tf

#########################################################
### 02-03. Internet Gateway (IGW)
#########################################################
resource "aws_internet_gateway" "internet_gateway_template" {

  count   = local.module_enable ? 1 : 0

  tags      = merge(
                { Name : format("%s-igw",local.tag_name)  },
                var.default_tags
              )

  vpc_id  = var.vpc_id
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
locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable   = var.default["module_enable_internet_gateway"]
}

#### output ####
output "internet_gateway_id" {
  value = local.module_enable ? element(aws_internet_gateway.internet_gateway_template[*].id, 0) : ""
}

