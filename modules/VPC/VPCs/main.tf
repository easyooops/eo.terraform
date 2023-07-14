# ./modules/VPC/Subnets/main.tf

#########################################################
## 02_01. VPCs
#########################################################
### 02_01_01. VPC
resource "aws_vpc" "vpc_template" {

  count     = local.module_enable ? 1 : 0

  tags      = merge(
                { Name : format("%s-vpc-%s",local.tag_name, local.vpc_list[count.index]["name"])  },
                var.default_tags,
                local.vpc_list[count.index]["tags"]
              )
  cidr_block                            = var.default["cidr_ipv4_block"]
  assign_generated_ipv6_cidr_block      = true
  enable_dns_hostnames                  = local.vpc_list[count.index]["enable_dns_hostnames"]
  enable_dns_support                    = local.vpc_list[count.index]["enable_dns_support"]
}
### 02_01_02. VPC Flow Log
resource "aws_flow_log" "flow_log_template" {

  count     = local.fnc_vpc_flow_logging ? 1 : 0

  iam_role_arn    = element(aws_iam_role.iam_role_template[*].arn, 0)
  log_destination = element(aws_cloudwatch_log_group.cloudwatch_log_group_template[*].arn, 0)
  traffic_type    = "ALL"
  vpc_id          = element(aws_vpc.vpc_template[*].id, 0)
}
resource "aws_cloudwatch_log_group" "cloudwatch_log_group_template" {

  count     = local.fnc_vpc_flow_logging ? 1 : 0

  name              = format("%s-lg-flow-log",local.tag_name)
  retention_in_days = 365
}
resource "aws_iam_role" "iam_role_template" {

  count     = local.fnc_vpc_flow_logging ? 1 : 0

  name                = format("%s-role-flow-log",local.tag_name)
  description         = "Cloud watch log group role for flow log"
  assume_role_policy  = data.aws_iam_policy_document.iam_policy_assume_document_template.json
  managed_policy_arns = aws_iam_policy.iam_policy_template[*].arn
}
resource "aws_iam_policy" "iam_policy_template" {

  count     = local.fnc_vpc_flow_logging ? 1 : 0

  name        = format("%s-policy-flow-log",local.tag_name)
  path        = "/"
  description = "Cloud watch log group policy for flow log"
  policy      = data.aws_iam_policy_document.iam_policy_document_template.json
}
#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "vpc_list" {
  type        = list(any)
}
locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable         = var.default["module_enable_vpc"]
  fnc_vpc_flow_logging  = local.module_enable ? var.default["fnc_vpc_flow_logging"] : local.module_enable

  vpc_list              = local.module_enable ? var.vpc_list : []
}
#### data ####
data "aws_iam_policy_document" "iam_policy_assume_document_template" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "iam_policy_document_template" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}
#### output ####
output "vpc_id" {
  value = local.module_enable ? element(aws_vpc.vpc_template[*].id, 0) : ""
}
output "ipv6_association_id" {
  value = local.module_enable ? element(aws_vpc.vpc_template[*].ipv6_cidr_block_network_border_group, 0) : ""
}
output "default_network_acl_id" {
  value = local.module_enable ? element(aws_vpc.vpc_template[*].default_network_acl_id, 0) : ""
}
output "iam_role_id" {
  value = local.fnc_vpc_flow_logging ? element(aws_iam_role.iam_role_template[*].id, 0) : ""
}
output "iam_role_policy_id" {
  value = local.fnc_vpc_flow_logging ? element(aws_iam_policy.iam_policy_template[*].id, 0) : ""
}
output "cloudwatch_log_group_id" {
  value = local.fnc_vpc_flow_logging ? element(aws_cloudwatch_log_group.cloudwatch_log_group_template[*].id, 0) : ""
}