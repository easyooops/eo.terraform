#########################################################
## 01. Default
#########################################################
#### provider ####
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
#      version = "~> 3.76.1"
      version = "~> 5.8.0"      # https://registry.terraform.io/providers/hashicorp/aws/latest
    }
  }
}
provider "aws" {
  region = var.default["region"]
}
#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
#########################################################
## 02. VPC
#########################################################
#########################################################
## 02_01. VPCs
#########################################################
#### module ####
module "VPC_VPCs" {
  source = "./modules/VPC/VPCs"

  default       = var.default
  default_tags  = var.default_tags

  vpc_list      = var.vpc_list
}
#### variable ####
variable "vpc_list" {
  type        = list(any)
}

#########################################################
### 02-02. Subnets
#########################################################
#### module ####
module "VPC_Subnets" {
  source = "./modules/VPC/Subnets"

  default             = var.default
  default_tags        = var.default_tags

  vpc_id              = module.VPC_VPCs.vpc_id
  ipv6_association_id = module.VPC_VPCs.ipv6_association_id

  subnet_list         = var.subnet_list
}
#### variable ####
variable "subnet_list" {
  type        = list(any)
}

#########################################################
### 02-03. Internet Gateway (IGW)
#########################################################
#### module ####
module "VPC_IGW" {
  source = "./modules/VPC/IGW"

  default             = var.default
  default_tags        = var.default_tags

  vpc_id              = module.VPC_VPCs.vpc_id
}

##########################################################
#### 02-04. NAT Gateway
##########################################################
#### module ####
module "VPC_NAT" {
  source = "./modules/VPC/NAT"

  default             = var.default
  default_tags        = var.default_tags

  subnet_ids          = module.VPC_Subnets.subnet_ids

  nat_list            = var.nat_list
}
#### variable ####
variable "nat_list" {
  type        = list(any)
}

##########################################################
#### 02-05. Route
##########################################################
#### module ####
module "VPC_Routes" {
  source = "./modules/VPC/Routes"

  default             = var.default
  default_tags        = var.default_tags

  vpc_id              = module.VPC_VPCs.vpc_id
  subnet_ids          = module.VPC_Subnets.subnet_ids
  internet_gateway_id = module.VPC_IGW.internet_gateway_id
  nat_gateway_id      = module.VPC_NAT.nat_gateway_id

  route_list          = var.route_list
}
#### variable ####
variable "route_list" {
  type        = list(any)
}

##########################################################
#### 02-06. Prefix List
##########################################################
#### module ####
module "VPC_Prefix_List" {
  source = "./modules/VPC/PrefixLists"

  default             = var.default
  default_tags        = var.default_tags

  prefix_list         = var.prefix_list
}
#### variable ####
variable "prefix_list" {
  type        = list(any)
}

#########################################################
## 03. Security
#########################################################
## 03_01. ACLs, VPC 생성시 Default ACL 이 생성 되므로, 특별한 규칙이 필요할 경우 추가 생성.
#########################################################
#### module ####
module "Security_ACLs" {
  source = "./modules/Security/ACLs"

  default                 = var.default
  default_tags            = var.default_tags

  default_network_acl_id  = module.VPC_VPCs.default_network_acl_id

  acl_map                 = var.acl_map
}
#### variable ####
variable "acl_map" {
  type        = map(any)
}

#########################################################
## 03_02. Security Group
#########################################################
#### module ####
module "Security_SG" {
  source = "./modules/Security/SG"

  default             = var.default
  default_tags        = var.default_tags

  vpc_id              = module.VPC_VPCs.vpc_id
  prefix_ids          = module.VPC_Prefix_List.prefix_ids

  sg_list             = var.sg_list
}
#### variable ####
variable "sg_list" {
  type        = list(any)
}
#########################################################
## 04. Storage
#########################################################
## 04_01. S3 Bucket
#########################################################
#### module ####
module "Storage_S3" {
  source = "./modules/Storage/S3"

  default           = var.default
  default_tags      = var.default_tags

  s3_bucket_list    = var.s3_bucket_list
}
#### variable ####
variable "s3_bucket_list" {
  type        = list(any)
}
#########################################################
## 04_02. RDS
#########################################################
#### module ####
module "Storage_RDS" {
  source = "./modules/Storage/RDS"

  default             = var.default
  default_tags        = var.default_tags

  subnet_ids          = module.VPC_Subnets.subnet_ids
  security_group_ids  = module.Security_SG.security_group_ids

  rds_list        = var.rds_list
}
#### variable ####
variable "rds_list" {
  type        = list(any)
}
#########################################################
## 04_03. ElastiCache
#########################################################
#### module ####
module "Storage_ElastiCache" {
  source = "./modules/Storage/ElastiCache"

  default             = var.default
  default_tags        = var.default_tags

  subnet_ids          = module.VPC_Subnets.subnet_ids
  security_group_ids  = module.Security_SG.security_group_ids

  elasticache_list    = var.elasticache_list
}
#### variable ####
variable "elasticache_list" {
  type        = list(any)
}
#########################################################
## 05. EC2
#########################################################
## 05_01. Instances
#########################################################
#### module ####
module "EC2_Instances" {
  source = "./modules/EC2/Instances"

  default               = var.default
  default_tags          = var.default_tags

  subnet_ids            = module.VPC_Subnets.subnet_ids
  security_group_ids    = module.Security_SG.security_group_ids

  instances_list        = var.instances_list
}
#### variable ####
variable "instances_list" {
  type        = list(any)
}

#########################################################
## 05_02. Launch templates
#########################################################
#### module ####
module "EC2_Launch_Template" {
  source = "./modules/EC2/LaunchTemplates"

  default               = var.default
  default_tags          = var.default_tags

  security_group_ids    = module.Security_SG.security_group_ids

  launch_template_list  = var.launch_template_list
}
#### variable ####
variable "launch_template_list" {
  type        = list(any)
}

#########################################################
## 05_03. Target Group
#########################################################
#### module ####
module "EC2_Target_Group" {
  source = "./modules/EC2/TargetGroups"

  default               = var.default
  default_tags          = var.default_tags

  vpc_id                = module.VPC_VPCs.vpc_id

  target_group_list     = var.target_group_list
}
#### variable ####
variable "target_group_list" {
  type        = list(any)
}

#########################################################
## 05_04. Load Balancer
#########################################################
#### module ####
module "EC2_Load_Balancer" {
  source = "./modules/EC2/LoadBalancers"

  default                   = var.default
  default_tags              = var.default_tags

  subnet_ids                = module.VPC_Subnets.subnet_ids
  security_group_ids        = module.Security_SG.security_group_ids
  lb_target_group_ids       = module.EC2_Target_Group.lb_target_group_ids
  elb_access_log_bucket_ids = module.Storage_S3.elb_access_log_bucket_ids

  load_balancer_list    = var.load_balancer_list
}
#### variable ####
variable "load_balancer_list" {
  type        = list(any)
}

#########################################################
## 05_05. Auto Scaling Group
#########################################################
#### module ####
module "EC2_ASG" {
  source = "./modules/EC2/ASG"

  default               = var.default
  default_tags          = var.default_tags

  subnet_ids            = module.VPC_Subnets.subnet_ids
  launch_template_ids   = module.EC2_Launch_Template.launch_template_ids
  lb_target_group_ids   = module.EC2_Target_Group.lb_target_group_ids

  asg_list              = var.asg_list
}
#### variable ####
variable "asg_list" {
  type        = list(any)
}