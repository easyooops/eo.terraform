#########################################################
## Guide
## 1. [key] 내부 사용 되는 Key(name) 이며, 신규 인프라 생성시 리소스들의 연결을 위해 필요.
## 2. tags 는 "공통", "리소스" 두가지 분류 관리.
## 3. Subnet IPv6 주소 생성시, 첫번쨰(vpc enable, 나머지 disable) > 두번쨰(필요 리소스 enable, cidr_ipv6_block 설정.)
## 4. Prefix List, Target Group, LaunchTemplates 명시적 지정 미구현.
## 5. AWS 정책상 CloudWatch Log group 삭제 되지 않음. 직접 삭제 필요.
## 6. AWS 정책상 IGW/ALB 트래픽이 종료 될떄까지 삭제 되지 않음. 오류 확인 후 재삭제 진행.
#########################################################
#########################################################
## 01. Default
#########################################################
default_tags = {        ## 공통 태그
  PROJECT   : "EasyOoops"
}
default = {
  region                    : "ap-northeast-2",            ## 리전
  project_name              : "easyooops",                 ## 프로젝트명
  env                       : "dev-new",                   ## 프로덕션 환경
  cidr_ipv4_block           : "10.10.0.0/16",              ## IPv4 - 생성 참고 : https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-cidr-blocks.html
  cidr_ipv6_block           : "",                          ## IPv6 - 절차 : 1. VPC 만 생성(true) 나머지 false 2. VPC IPv6 확인 후 지정 3. 나머지 생성(true)
  vpc_id                    : "vpc-05abcb0ba9197103a",     ## 기존 VPC 활용

  # 모듈 활성화 여부 선택
  # [VPC]
  module_enable_vpc               : false,
  module_enable_subnets           : false,   # VPC 필수
  module_enable_internet_gateway  : false,   # VPC 필수
  module_enable_nat_gateway       : false,   # [비용 발생] Subnets 필수
  module_enable_routes            : false,   # VPC 필수
  module_enable_prefix_list       : false,
  module_enable_acl               : false,   # VPC 필수
  module_enable_security_group    : false,   # VPC 필수
  # [Storage]
  module_enable_s3_bucket         : true,    # [비용 발생]
  module_enable_rds               : false,   # [비용 발생]
  module_enable_elasticache       : false,   # [비용 발생]
  # [EC2]
  module_enable_instances         : true,   # [비용 발생] Subnets 필수
  module_enable_launch_template   : true,
  module_enable_target_group      : true,   # VPC 필수
  module_enable_load_balancer     : true,   # [비용 발생] Subnets 필수, target_group 필수(nlb 경우)
  module_enable_asg               : true,   # [비용 발생] Subnets 필수, launch_template 필수, target_group 필수(nlb 경우)

  # 기능 활성하 여부 선택
  fnc_vpc_flow_logging            : false,          # [비용 발생] VPC 트래픽 로그 분석 가능, AWS 정책상 CloudWatch Log group 삭제 되지 않음. 직접 삭제 필요.
  fnc_s3_access_logging           : false,          # [비용 발생] 보안 기능. S3 접근 로그 분석 가능
  access_logs_bucket              : "access-logs",  # Bucket Name, 공백시 임의 설정 "access-logs"
  fun_elb_access_logging          : true,           # [비용 발생] L4/L7 계층 트래픽 로그 분석 가능
  elb_logs_bucket                 : "elb-logs"      # Bucket Name, 공백시 임의 설정 "elb-logs"
}

#########################################################
## 02. VPC
#########################################################
## 02_01. VPCs
#########################################################
vpc_list = []

#########################################################
### 02-02. Subnets, (name 유니크 해야 함.)
#########################################################
subnet_list = []
##########################################################
#### 02-03. Internet Gateway (IGW)
##########################################################

##########################################################
#### 02-04. NAT Gateway
##########################################################
nat_list = []

##########################################################
#### 02-05. Route
##########################################################
route_list =  []

##########################################################
#### 02-06. Prefix List, IP 그룹 별 관리
##########################################################
prefix_list =  []

#########################################################
## 03. Security
#########################################################
## 03_01. ACLs, VPC 네트워크 단 방화벽 설정
#########################################################
acl_map = {}

#########################################################
## 03_02. Security Group, 인스턴스(with ENI) 단 방화벽 설정정, 보안상 IP 보다는 Prefix 사용 권장.
########################################################
sg_list = []

#########################################################
## 04. Storage
#########################################################
## 04_01. S3 Bucket
#########################################################
s3_bucket_list = []
#########################################################
## 04_02. RDS
#########################################################
rds_list = []
#########################################################
## 04_03. ElastiCache - Encryption in transit 지원 안함
#########################################################
elasticache_list = []

#########################################################
## 05. EC2
#########################################################
## 05_01. Instances
#########################################################
instances_list = [
  { // bastion server 2
    name                        : "bastion-2",                # (Required) [key]
    description                 : "default bastion server 2",
    ami                         : "ami-0006be3056c2e5779",    # (Required) 표준 지원 ami 검색. 참고 : https://cloud-images.ubuntu.com/locator/ec2/
    cpu_core_count              : 1                           # (Required) ami spec 에 따라 cpu 지원이 다름.
    threads_per_core            : 1                           # (Required) ami spec 에 따라 cpu 지원이 다름.
    instance_type               : "t3.micro",                 # (Required) 인스턴스 유형. 참고 : https://aws.amazon.com/ko/ec2/instance-types/
    associate_public_ip_address : false,                      # (Required) 인스턴스 자동 생성 Public IP. Public IP 필요시 associate_public_ip_address or public_ip 선택.
    public_ip                   : true                        # (Required) EIP 생성 후 연결. Public IP 필요시 associate_public_ip_address or public_ip 선택.
    user_data                   : "./data/user_data.sh",      # 인스턴스 시작 된 후 실행 될 Script
    iam_instance_profile        : "",                         # VPC 내부 리소스 접근을 위한 Role 지정
    security_group_ids          : ["sg-06de51abb01a75373"],            # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name         : [],                         # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    subnet_ids                  : "subnet-0815f3ae9dfdcaa41", # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_name                 : "",                         # (Required) Subnet [Key] 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_az                   : "a"                         # (Required) 가용 영역. a, b, c, d, e, f
    root_block_device           : [                           # EBS, snapshot_id 지정 불가
      { name : "root" ,device_name : "/dev/sda1"  ,volume_size : 30   }
    ],
    ebs_block_device            : [                           # EBS, snapshot_id 공백일 경우 자동 생성.
      { name : "home" ,snapshot_id : "" ,device_name : "/dev/sdb" ,volume_size : 30   }
    ],
    tags  : {                                                 # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "INSTANCE"
    }
  }
]

#########################################################
## 05_02. Launch templates
#########################################################
launch_template_list = [
  {
    name                    : "svc-2",                            # (Required) [key]
    description             : "service was auto-scale template",
    image_id                : "ami-0006be3056c2e5779",            # (Required) 표준 지원 ami 검색 > https://cloud-images.ubuntu.com/locator/ec2/
    cpu_core_count          : 1                                   # (Required) ami spec 에 따라 cpu 지원이 다름.
    threads_per_core        : 1                                   # (Required) ami spec 에 따라 cpu 지원이 다름.
    instance_type           : "t3.micro",                         # (Required) 인스턴스 유형. 참고 : https://aws.amazon.com/ko/ec2/instance-types/
    user_data               : "./data/user_data.sh",              # 인스턴스 시작 된 후 실행 될 Script
    iam_instance_profile    : "",                                 # VPC 내부 리소스 접근을 위한 Role 지정
    security_group_ids      : ["sg-0fa2527fb4f39a974"],                                 # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name     : [],                                 # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    block_device_mappings   : [                                   # (Required) EBS
    ],
    tags  : {                                                     # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "LT"
    }
  }
]

#########################################################
## 05_03. Target Group
#########################################################
target_group_list = [
  {
    name : "svc-2-ec2",                   # (Required) [key]
    target_type : "instance",             # (Required) instance or alb
    port : "8080",                        # (Required) PORT
    protocol  : "HTTP",                   # (Required) HTTP or TCP
    health_check_path : "/",              # (Required) Health Check Path. 인스턴스 내 서버 필요.
    tags  : {                             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "TG"
    }
  },
  {
    name : "svc-2-alb",
    target_type : "alb",
    port : "80",
    protocol  : "TCP",
    health_check_path : "/",
    tags  : {                             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "TG"
    }
  }
]

#########################################################
## 05_04. Load Balancer
#########################################################
load_balancer_list = [
  {
    name                    : "nlb-svc-2",        # (Required) [key]
    load_balancer_type      : "network",          # (Required) network or application 지정.
    security_group_ids      : [],                 # SG ID 명시적 지정. security_group_ids or security_group_name
    security_group_name     : [],                 # SG [Key] 지정. security_group_ids or security_group_name
    subnet_ids              : ["subnet-0815f3ae9dfdcaa41","subnet-08def832c4444acc2"],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name
    subnet_name             : [],                 # (Required) Subnet [Key] 지정. subnet_ids or subnet_name
    ip_address_type         : "ipv4",             # (Required) "ipv4" or "dualstack"(Subnet IPv6 지원시 가능)
    target_group            : "svc-2-alb",        # (Required) Target Group Key(name) 지정.
    alb_target_group        : "alb-svc-2",        # (Required) NLB 리스너의 경우, ALB 의 Key(name) 지정 필요.
    certificate_arn         : "",                 # ALB 리스너의 경우, HTTPS 통신을 위한 SSL
    tags                    : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "ELB"
    }
  },
  {
    name                    : "alb-svc-2",        # (Required) [key]
    load_balancer_type      : "application",      # (Required) network or application 지정.
    security_group_ids      : ["sg-085a820f94a446f79"],                 # SG ID 명시적 지정. security_group_ids or security_group_name
    security_group_name     : [],                 # SG [Key] 지정. security_group_ids or security_group_name
    subnet_ids              : ["subnet-09c59d82ce9d0af23","subnet-00326c4bb54cc294c"],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name
    subnet_name             : [],                 # (Required) Subnet [Key] 지정. subnet_ids or subnet_name
    ip_address_type         : "ipv4",             # (Required) "ipv4" or "dualstack"(Subnet IPv6 지원시 가능)
    target_group            : "svc-2-ec2",        # (Required) Target Group Key(name) 지정.
    alb_target_group        : "",                 # (Required) NLB 리스너의 경우, ALB 의 Key(name) 지정 필요.
    certificate_arn         : "",                 # ALB 리스너의 경우, HTTPS 통신을 위한 SSL
    tags                    : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "ELB"
    }
  }
]

#########################################################
## 05_05. Auto Scaling Group
#########################################################
asg_list = [
  {
    name                    : "svc-2",        # (Required) [key]
    desired_capacity        : 2,              # (Required) 인스턴스 개수.
    max_size                : 2,              # (Required) 최대 수 지정. 자동 Scale out 시 필요.
    min_size                : 1,              # (Required) 최소 수 지정. 자동 Scale out 시 필요.
    subnet_ids              : ["subnet-09c59d82ce9d0af23","subnet-00326c4bb54cc294c"],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name
    subnet_name             : "",             # (Required) Subnet [Key] 지정. subnet_ids or subnet_name
    target_group            : "svc-2-ec2",    # (Required) Target Group Key(name) 지정.
    launch_template         : "svc-2",        # (Required) Launch Template Key(name) 지정.
    tags                    : [
      { key   : "TYPE_1", value : "COMMON", propagate_at_launch : false },
      { key   : "TYPE_2", value : "ASG", propagate_at_launch : false }
    ]
  }
]