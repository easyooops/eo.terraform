# ./modules/EC2/LaunchTemplates/main.tf

#########################################################
## 05_02. Launch templates
#########################################################
resource "aws_launch_template" "launch_template" {

  for_each  = { for e in local.launch_template_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-lt-%s",local.tag_name, each.value["name"])  },
                    var.default_tags,
                    each.value["tags"]
                  )

  name                    = format("%s-lt-%s",local.tag_name, each.value["name"])
  description             = each.value["description"]
  default_version         = "1"
  image_id                = each.value["image_id"]
  instance_type           = each.value["instance_type"]
  disable_api_termination = false
  user_data               = filebase64(each.value["user_data"])
  instance_initiated_shutdown_behavior = "terminate"
  ebs_optimized           = false

  cpu_options {
    core_count       = each.value["cpu_core_count"]
    threads_per_core = each.value["threads_per_core"]
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  placement {
    tenancy = "default"
  }
  iam_instance_profile {
    arn    = each.value["iam_instance_profile"]
  }
  dynamic "block_device_mappings" { # snapshot_id 가 없는 경우, 자동 생성

    for_each = { for i, e in each.value["block_device_mappings"] : i => e if e["snapshot_id"] == "" }

    content {
      device_name = block_device_mappings.value["device_name"]
      ebs {
        delete_on_termination = true
        encrypted             = true         # snapshot_id or encrypted 둘 중 하나 사용 가능
        volume_size           = block_device_mappings.value["volume_size"]
        volume_type           = "gp2"
      }
    }
  }
  dynamic "block_device_mappings" { # snapshot_id 가 없는 경우, 자동 생성

    for_each = { for i, e in each.value["block_device_mappings"] : i => e if e["snapshot_id"] != "" }

    content {
      device_name = block_device_mappings.value["device_name"]
      ebs {
        delete_on_termination = true
        snapshot_id           = block_device_mappings.value["snapshot_id"]
        volume_size           = block_device_mappings.value["volume_size"]
        volume_type           = "gp2"
      }
    }
  }
  network_interfaces {
    delete_on_termination = true
    description           = "Primary network interface"
    security_groups       = each.value["security_group_ids"] == [] ? [for ids in local.security_group_ids : ids["id"] if contains(each.value["security_group_name"], ids["name"])] : each.value["security_group_ids"]
    device_index          = 0
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  monitoring {
    enabled = false
  }
  tag_specifications {
    resource_type = "instance"
    tags          = merge(
                          { Name : format("%s-instance-%s",local.tag_name, each.value["name"])  },
                          var.default_tags,
                          each.value["tags"]
                        )
  }
  tag_specifications {
    resource_type = "volume"
    tags          = merge(
                          { Name : format("%s-ebs-%s",local.tag_name, each.value["name"])  },
                          var.default_tags,
                          each.value["tags"]
                        )
  }
  tag_specifications {
    resource_type = "network-interface"
    tags          = merge(
                          { Name : format("%s-eni-%s",local.tag_name, each.value["name"])  },
                          var.default_tags,
                          each.value["tags"]
                        )
  }
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "launch_template_list" {
  type        = list(any)
}
variable "security_group_ids" {
  type          = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable         = var.default["module_enable_launch_template"]
  launch_template_list  = local.module_enable ? var.launch_template_list : []
  security_group_ids    = local.module_enable ? [for e in var.security_group_ids : e] : []
}
#### output ####
output "launch_template_ids" {
  value = local.module_enable ? [for e in aws_launch_template.launch_template : e] : []
}