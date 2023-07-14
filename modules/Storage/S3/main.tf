# ./modules/Storage/S3/main.tf

#########################################################
## 04_01. S3 Bucket
#########################################################
### 04_01_01. bucket
resource "aws_s3_bucket" "s3_access_log_bucket_template" {

  count     = local.fnc_s3_access_logging ? 1 : 0

  tags      = merge(
                    { Name : format("%s-s3-%s",local.tag_name, local.access_logs_bucket)  },
                    var.default_tags
                  )

  bucket            = format("%s-s3-%s",local.tag_name, local.access_logs_bucket)
  force_destroy     = true
}
resource "aws_s3_bucket" "elb_access_log_bucket_template" {

  count     = local.fun_elb_access_logging ? 1 : 0

  tags      = merge(
                    { Name : format("%s-s3-%s",local.tag_name, local.elb_logs_bucket)  },
                    var.default_tags
                  )

  bucket            = format("%s-s3-%s",local.tag_name, local.elb_logs_bucket)
  force_destroy     = true
}
resource "aws_s3_bucket" "s3_bucket_template" {

  for_each  = { for e in local.s3_bucket_list : e["name"] => e }

  tags      = merge(
                    { Name : format("%s-s3-%s",local.tag_name, each.key)  },
                    var.default_tags,
                    each.value["tags"]
                  )

  bucket            = format("%s-s3-%s",local.tag_name, each.key)
  force_destroy     = true
}
### 04_01_02. access logging
resource "aws_s3_bucket_logging" "s3_access_log_bucket_logging_template" {

  count     = local.fnc_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.s3_access_log_bucket_template[count.index].id

  target_bucket = format("%s-s3-%s",local.tag_name, local.access_logs_bucket)
  target_prefix = format("%s-s3-%s/",local.tag_name, local.access_logs_bucket)
}
resource "aws_s3_bucket_logging" "elb_access_log_bucket_logging_template" {

  count     = local.fun_elb_access_logging && local.fnc_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.elb_access_log_bucket_template[count.index].id

  target_bucket = format("%s-s3-%s",local.tag_name, local.access_logs_bucket)
  target_prefix = format("%s-s3-%s/",local.tag_name, local.elb_logs_bucket)

  depends_on = [aws_s3_bucket_logging.s3_access_log_bucket_logging_template]
}
resource "aws_s3_bucket_logging" "s3_bucket_logging_template" {

  for_each  = { for e in local.s3_bucket_list : e["name"] => e if local.fnc_s3_access_logging }

  bucket        = aws_s3_bucket.s3_bucket_template[each.key].id

  target_bucket = format("%s-s3-%s",local.tag_name, local.access_logs_bucket)
  target_prefix = format("%s-s3-%s/",local.tag_name, each.key)

  depends_on = [aws_s3_bucket_logging.s3_access_log_bucket_logging_template]
}
### 04_01_03. lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "s3_access_log_bucket_lifecycle_configuration_template" {

  count     = local.fnc_s3_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.s3_access_log_bucket_template[count.index].id

  rule {
    id          = format("%s-lc-365",local.tag_name)
    expiration {
      days      = "365"
    }
    status      = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "elb_access_log_bucket_lifecycle_configuration_template" {

  count     = local.fun_elb_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.elb_access_log_bucket_template[count.index].id

  rule {
    id          = format("%s-lc-365",local.tag_name)
    expiration {
      days      = "365"
    }
    status      = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_configuration_template" {

  for_each  = { for e in local.s3_bucket_list : e["name"] => e if local.fnc_s3_access_logging }

  bucket        = aws_s3_bucket.s3_bucket_template[each.key].id

  dynamic "rule" {

    for_each  = { for i, lifecycle in each.value["lifecycle"] : i => lifecycle }


    content {
      id          = format("%s-lc-%s-%s",local.tag_name,rule.value["expiration"],rule.key)
      filter {
        prefix    = rule.value["prefix"]
      }
      expiration {
        days      = rule.value["expiration"]
      }
      status      = "Enabled"
    }
  }
}
### 04_01_04. policy
resource "aws_s3_bucket_policy" "elb_access_bucket_policy_template" {

  count     = local.fun_elb_access_logging ? 1 : 0

  bucket    = aws_s3_bucket.elb_access_log_bucket_template[count.index].id
  policy    = data.aws_iam_policy_document.data_elb_access_policy.json
}

#### variable ####
variable "default" {
  type        = map(any)
}
variable "default_tags" {
  type        = map(any)
}
variable "s3_bucket_list" {
  type        = list(any)
}

locals {
  tag_name  = format("%s-%s",var.default["project_name"],var.default["env"])

  module_enable               = var.default["module_enable_s3_bucket"]
  s3_bucket_list              = local.module_enable ? var.s3_bucket_list : []

  fun_elb_access_logging      = local.module_enable ? var.default["fun_elb_access_logging"] : local.module_enable
  fnc_s3_access_logging       = local.module_enable ? var.default["fnc_s3_access_logging"] : local.module_enable
  access_logs_bucket          = var.default["access_logs_bucket"] == "" ? "access-logs" : var.default["access_logs_bucket"]
  elb_logs_bucket             = var.default["elb_logs_bucket"] == "" ? "elb-logs" : var.default["elb_logs_bucket"]

  region_account              = {
      us-east-1       : "127311923021",
      us-east-2       : "033677994240",
      us-west-1       : "027434742980",
      us-west-2       : "797873946194",
      af-south-1      : "098369216593",
      ap-east-1       : "754344448648",
      ap-southeast-3  : "589379963580",
      ap-south-1      : "718504428378",
      ap-northeast-3  : "383597477331",
      ap-northeast-2  : "600734575887",
      ap-southeast-1  : "114774131450",
      ap-southeast-2  : "783225319266",
      ap-northeast-1  : "582318560864",
      ca-central-1    : "985666609251",
      eu-central-1    : "054676820928",
      eu-west-1       : "156460612806",
      eu-west-2       : "652711504416",
      eu-south-1      : "635631232127",
      eu-west-3       : "009996457667",
      eu-north-1      : "897822967062",
      me-south-1      : "076674570225",
      sa-east-1       : "507241528517",
      eu-west-3       : "048591011584",
      eu-west-3t      : "190560391635"
    }
}

#### output ####
data "aws_iam_policy_document" "data_elb_access_policy" {
  version     = "2012-10-17"
  statement {
    sid       = "AllowALBAccess"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.region_account[var.default["region"]]}:root"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.tag_name}-s3-${local.elb_logs_bucket}/*"]
  }
  statement {
    sid       = "AllowNLBAccess"
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.tag_name}-s3-${local.elb_logs_bucket}/*"]
  }
}

#### output ####
output "s3_access_log_bucket_ids" {
  value = local.fnc_s3_access_logging ? element(aws_s3_bucket.s3_access_log_bucket_template[*].id, 0) : ""
}
output "elb_access_log_bucket_ids" {
  value = local.fun_elb_access_logging ? element(aws_s3_bucket.elb_access_log_bucket_template[*].id, 0) : ""
}
output "s3_bucket_ids" {
  value = local.module_enable ? [for e in aws_s3_bucket.s3_bucket_template : e] : []
}
