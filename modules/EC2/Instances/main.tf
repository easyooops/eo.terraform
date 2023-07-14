# ./modules/EC2/Instances/main.tf

#########################################################
## 05_01. Instances
#########################################################
### 05_01_01. Instances
resource "aws_instance" "instance_template" {

  for_each  = { for e in local.instances_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-instance-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  ami                         = each.value["ami"]
  associate_public_ip_address = each.value["associate_public_ip_address"]
  disable_api_termination     = false
  ebs_optimized               = false
  instance_type               = each.value["instance_type"]
  user_data                   = filebase64(each.value["user_data"])
  instance_initiated_shutdown_behavior = "terminate"
  subnet_id                   = each.value["subnet_ids"] == "" ? each.value["subnet_name"] == "" ? "" : element([for ids in local.subnet_ids : ids["id"] if format("%s-%s",each.value["subnet_name"], each.value["subnet_az"]) == ids["name"]], 0) : each.value["subnet_ids"]
  security_groups             = each.value["security_group_ids"] == [] ? [for ids in local.security_group_ids : ids["id"] if contains(each.value["security_group_name"], ids["name"])] : each.value["security_group_ids"]
  iam_instance_profile        = each.value["iam_instance_profile"]
#  private_ip                  = each.value["private_ip"]

  cpu_options {
    core_count       = each.value["cpu_core_count"]
    threads_per_core = each.value["threads_per_core"]
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  root_block_device {
    encrypted     = true
    volume_size   = each.value["root_block_device"][0]["volume_size"]
    volume_type   = "gp2"
    tags          = merge(
                      { Name : format("%s-ebs-%s-%s",local.tag_name, each.value["name"], each.value["root_block_device"][0]["name"])  },
                      var.default_tags,
                      each.value["tags"]
                    )
  }
  dynamic "ebs_block_device" {  # snapshot_id 가 없는 경우, 자동 생성

    for_each = { for i, e in each.value["ebs_block_device"] : i => e if e["snapshot_id"] == "" }

    content {
      device_name = ebs_block_device.value["device_name"]
      encrypted   = true
      volume_size = ebs_block_device.value["volume_size"]
      volume_type = "gp2"
      tags        = merge(
                          { Name : format("%s-ebs-%s-%s",local.tag_name, each.value["name"], ebs_block_device.value["name"])  },
                          var.default_tags,
                          each.value["tags"]
                        )
    }
  }
  dynamic "ebs_block_device" {  # snapshot_id 가 있는 경우

    for_each = { for i, e in each.value["ebs_block_device"] : i => e if e["snapshot_id"] != "" }

    content {
      device_name = ebs_block_device.value["device_name"]
      snapshot_id = ebs_block_device.value["snapshot_id"]
      volume_size = ebs_block_device.value["volume_size"]
      volume_type = "gp2"
      tags        = merge(
                          { Name : format("%s-ebs-%s-%s",local.tag_name, each.value["name"], ebs_block_device.value["name"])  },
                          var.default_tags,
                          each.value["tags"]
                        )
    }
  }
  metadata_options {    # v2
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  monitoring = false
}
### 05_01_02. EIP
resource "aws_eip" "instance_eip_template" {

  for_each  = { for e in local.instances_list : e["name"] => e if e["public_ip"] }

  tags      = merge(
    { Name : format("%s-ec2-eip-%s",local.tag_name, each.value["name"])  },
    var.default_tags
  )

  domain                    = "vpc"
  instance                  = aws_instance.instance_template[each.key].id
#  associate_with_private_ip = each.value["private_ip"]
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "instances_list" {
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

  module_enable       = var.default["module_enable_instances"]
  instances_list      = local.module_enable ? var.instances_list : []
  security_group_ids  = local.module_enable ? [for e in var.security_group_ids : e] : []
  subnet_ids          = local.module_enable ? [for e in var.subnet_ids : e] : []
}

#### output ####
output "instance_ids" {
  value = local.module_enable ? [for e in aws_instance.instance_template : e] : []
}