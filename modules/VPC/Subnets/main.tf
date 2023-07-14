# ./modules/VPC/Subnets/main.tf

#########################################################
### 02-02. Subnets
#########################################################
#### resource ####
resource "aws_subnet" "subnet_template" {

  for_each  = { for e in local.subnet_list : e["name"] => e if var.default["cidr_ipv6_block"] == "" }

  tags      = merge(
                    { Name : format("%s-subnet-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  vpc_id                            = var.vpc_id
  cidr_block                        = each.value["cidr_block"]
  availability_zone                 = each.value["availability_zone"]
  assign_ipv6_address_on_creation   = false
}
resource "aws_subnet" "subnet_ipv6_template" {

  for_each  = { for e in local.subnet_list : e["name"] => e if var.default["cidr_ipv6_block"] != "" }

  tags      = merge(
                    { Name : format("%s-subnet-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  vpc_id                            = var.vpc_id
  cidr_block                        = each.value["cidr_block"]
  availability_zone                 = each.value["availability_zone"]
  assign_ipv6_address_on_creation   = true
  ipv6_cidr_block                   = each.value["ipv6_cidr_block"]
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
variable "ipv6_association_id" {
  type        = string
}
variable "subnet_list" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable   = var.default["module_enable_subnets"]
  region_az       = {
    us-east-1       : ["a","b","c","d","e","f"],
    us-east-2       : ["a","b","c"],
    us-west-1       : ["b","c"],
    us-west-2       : ["a","b","c","d"],
    af-south-1      : ["a","b","c"],      # AWS was not able to validate the provided access credentials
    ap-east-1       : ["a","b","c"],      # AWS was not able to validate the provided access credentials
    ap-southeast-3  : ["a","b","c"],      # AWS was not able to validate the provided access credentials
    ap-south-1      : ["a","b","c"],
    ap-northeast-3  : ["a","b","c"],
    ap-northeast-2  : ["a","b","c","d"],
    ap-southeast-1  : ["a","b","c"],
    ap-southeast-2  : ["a","b","c"],
    ap-northeast-1  : ["a","b","c","d"],
    ca-central-1    : ["a","b","c"],
    eu-central-1    : ["a","b","c"],
    eu-west-1       : ["a","b","c"],
    eu-west-2       : ["a","b","c"],
    eu-south-1      : ["a","b","c"],      # AWS was not able to validate the provided access credentials
    eu-west-3       : ["a","b","c"],
    eu-north-1      : ["a","b","c"],
    me-south-1      : ["a","b","c"],      # AWS was not able to validate the provided access credentials
    sa-east-1       : ["a","b","c"],
    eu-west-3       : ["a","b","c"],
    eu-west-3t      : ["a","b","c"]       # AWS was not able to validate the provided access credentials
  }

  subnet_list    = !local.module_enable ? [] : flatten([
      for r in range(length(local.region_az[var.default["region"]])) : [
        for s in range(length(var.subnet_list)) : {
          name              = format("%s-%s",var.subnet_list[s]["name"],local.region_az[var.default["region"]][r]),
          cidr_block        = var.default["cidr_ipv4_block"] == "" ? "" : cidrsubnet(var.default["cidr_ipv4_block"], 8, (s * 10) + r + 1),
          availability_zone = format("%s%s",var.default["region"],local.region_az[var.default["region"]][r]),
          ipv6_cidr_block   = var.default["cidr_ipv6_block"] == "" ? "" : cidrsubnet(var.default["cidr_ipv6_block"], 8, (s * 10) + r + 1),
          route             = var.subnet_list[s]["route"]
          tags              = var.subnet_list[s]["tags"]
        }
      ]
  ])
}

#### output ####
output "subnet_ids" {
  value = local.module_enable ? var.default["cidr_ipv6_block"] == "" ? [
                for e in aws_subnet.subnet_template : {
                  id = e["id"]
                  tag = e["tags"]["Name"]
                  name = replace(e["tags"]["Name"], format("%s-subnet-",local.tag_name), "")
                  route = element([for s in local.subnet_list : s["route"] if s["cidr_block"] == e["cidr_block"]], 0)
              }] : [
                for e in aws_subnet.subnet_ipv6_template : {
                  id = e["id"]
                  tag = e["tags"]["Name"]
                  name = replace(e["tags"]["Name"], format("%s-subnet-",local.tag_name), "")
                  route = element([for s in local.subnet_list : s["route"] if s["cidr_block"] == e["cidr_block"]], 0)
                }] : []
}