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
  env                       : "stg",                       ## 프로덕션 환경
  cidr_ipv4_block           : "10.11.0.0/16",              ## IPv4 - 생성 참고 : https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-cidr-blocks.html
  cidr_ipv6_block           : "",                          ## IPv6 - 절차 : 1. VPC 만 생성(true) 나머지 false 2. VPC IPv6 확인 후 지정 3. 나머지 생성(true)
  vpc_id                    : "",                          ## 기존 VPC 활용

  # 모듈 활성화 여부 선택
  # [VPC]
  module_enable_vpc               : true,
  module_enable_subnets           : true,   # VPC 필수
  module_enable_internet_gateway  : true,   # VPC 필수
  module_enable_nat_gateway       : true,   # [비용 발생] Subnets 필수
  module_enable_routes            : true,   # VPC 필수
  module_enable_prefix_list       : true,
  module_enable_acl               : true,   # VPC 필수
  module_enable_security_group    : true,   # VPC 필수
  # [Storage]
  module_enable_s3_bucket         : true,   # [비용 발생]
  module_enable_rds               : false,  # [비용 발생]
  module_enable_elasticache       : false,  # [비용 발생]
  # [EC2]
  module_enable_instances         : true,   # [비용 발생] Subnets 필수
  module_enable_launch_template   : true,
  module_enable_target_group      : true,   # VPC 필수
  module_enable_load_balancer     : true,   # [비용 발생] Subnets 필수, target_group 필수(nlb 경우)
  module_enable_asg               : true,   # [비용 발생] Subnets 필수, launch_template 필수, target_group 필수(nlb 경우)

  # 기능 활성하 여부 선택
  fnc_vpc_flow_logging            : true,           # [비용 발생] VPC 트래픽 로그 분석 가능, AWS 정책상 CloudWatch Log group 삭제 되지 않음. 직접 삭제 필요.
  fnc_s3_access_logging           : true,           # [비용 발생] 보안 기능. S3 접근 로그 분석 가능
  access_logs_bucket              : "access-logs",  # Bucket Name, 공백시 임의 설정 "access-logs"
  fun_elb_access_logging          : true,           # [비용 발생] L4/L7 계층 트래픽 로그 분석 가능
  elb_logs_bucket                 : "elb-logs"      # Bucket Name, 공백시 임의 설정 "elb-logs"
}

#########################################################
## 02. VPC
#########################################################
## 02_01. VPCs
#########################################################
vpc_list = [
  {
    name                  : "service"
    enable_dns_hostnames  : false,
    enable_dns_support    : true,
    tags                  : {
      TYPE_1 : "COMMON",
      TYPE_2 : "VPC"
    }
  }
]

#########################################################
### 02-02. Subnets, (name 유니크 해야 함.)
#########################################################
subnet_list = [
  {
    name  : "pri",          # (Required) [key]
    route : "private",      # (Required) Route 연결. Route [key] 필요.
    tags  : {               # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SUBNET"
    }
  },
  {
    name  : "svc",
    route : "service",
    tags  : {
      TYPE_1 : "COMMON",
      TYPE_2 : "SUBNET"
    }
  },
  {
    name  : "pub",
    route : "public",
    tags  : {
      TYPE_1 : "COMMON",
      TYPE_2 : "SUBNET"
    }
  }
]
##########################################################
#### 02-03. Internet Gateway (IGW)
##########################################################

##########################################################
#### 02-04. NAT Gateway
##########################################################
nat_list = [{
  subnet_name : "pub",    # (Required) subnet 지정. Subnet [key] 필요.
  tags  : {               # 리소스 태그 정책
    TYPE_1 : "COMMON",
    TYPE_2 : "NAT"
  }
}]

##########################################################
#### 02-05. Route
##########################################################
route_list =  [
  {
    name : "private", # (Required) [key]
    is_igw : false,   # (Required) Internet Gateway 연결
    is_nat : false,   # (Required) NAT Gateway 연결
    tags  : {         # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "ROUTE"
    }
  },
  {
    name : "public",
    is_igw : true,
    is_nat : false,
    tags  : {
      TYPE_1 : "COMMON",
      TYPE_2 : "ROUTE"
    }
  },
  {
    name : "service",
    is_igw : false,
    is_nat : true,
    tags  : {
      TYPE_1 : "COMMON",
      TYPE_2 : "ROUTE"
    }
  }
]

##########################################################
#### 02-06. Prefix List, IP 그룹 별 관리
##########################################################
prefix_list =  [
  {
    name : "admin",             # (Required) [key]
    address_family : "IPv4",    # (Required) IPv4 or IPv6
    entry : [                   # IP List
      { cidr : "58.151.93.8/32" ,description : "Bespinglobal"         }
    ],
    tags  : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "PREFIX"
    }
  },
  {
    name : "ingress-svc",
    address_family : "IPv4",
    entry : [
      { cidr : "58.151.93.8/32" ,description : "Bespinglobal"         }
    ],
    tags  : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "PREFIX"
    }
  },
  {
    name : "egress-svc",
    address_family : "IPv4",
    entry : [
      { cidr : "58.151.93.8/32" ,description : "Bespinglobal"         }
    ],
    tags  : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "PREFIX"
    }
  },
  {
    name : "svc-any",
    address_family : "IPv4",
    entry : [
      { cidr : "0.0.0.0/0"  ,description : "Any Open" }
    ],
    tags  : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "PREFIX"
    }
  },

  {
    name : "nlb",
    address_family : "IPv4",
    entry : [
      { cidr : "10.11.21.0/24"   ,description : "nlb health check" },
      { cidr : "10.11.22.0/24"   ,description : "nlb health check" }
    ],
    tags  : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "PREFIX"
    }
  }
]

#########################################################
## 03. Security
#########################################################
## 03_01. ACLs, VPC 네트워크 단 방화벽 설정
#########################################################
acl_map = {
  ingress : [
    {
      protocol        : -1,           # (Required) All(-1)
      rule_no         : 100,          # (Required) 규칙번호. 참고 : https://docs.aws.amazon.com/ko_kr/vpc/latest/userguide/vpc-network-acls.html
      action          : "allow",      # (Required) allow or deny
      cidr_block      : "0.0.0.0/0",  # (Required) IPv4 or IPv6 하나만 작성
      ipv6_cidr_block : "",           # (Required) IPv4 or IPv6 하나만 작성
      from_port       : 0,            # (Required) PORT
      to_port         : 0             # (Required) PORT
    },
    {
      protocol        : -1,
      rule_no         : 101,
      action          : "allow",
      cidr_block      : "",
      ipv6_cidr_block : "::/0",
      from_port       : 0,
      to_port         : 0
    }
  ],
  egress : [
    {
      protocol        : -1,
      rule_no         : 100,
      action          : "allow",
      cidr_block      : "0.0.0.0/0",
      ipv6_cidr_block : "",
      from_port       : 0,
      to_port         : 0
    },
    {
      protocol        : -1,
      rule_no         : 101,
      action          : "allow",
      cidr_block      : "",
      ipv6_cidr_block : "::/0",
      from_port       : 0,
      to_port         : 0
    }
  ]
}

#########################################################
## 03_02. Security Group, 인스턴스(with ENI) 단 방화벽 설정정, 보안상 IP 보다는 Prefix 사용 권장.
########################################################
sg_list = [
  {
    name : "db-rds",      # (Required) [key]
    description : "RDS",
    ingress : [           # Inbound 방화벽 Rule, SG/PF(Prefix) 사용 권장, CIDR 비권장.
      { from_port : 3376  ,to_port : 3376   ,protocol : "tcp"  ,cidr : ""  ,sg : "web-svc"        ,pf : "" ,description : "web(svc)"      },
      { from_port : 3376  ,to_port : 3376   ,protocol : "tcp"  ,cidr : ""  ,sg : "etc-db-bastion" ,pf : "" ,description : "bastion(db)"   }
    ],
    egress : [],          # Outbound 방화벽 Rule
    tags  : {             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SG"
    }
  },
  {
    name : "db-redis",
    description : "REDIS",
    ingress : [
      { from_port : 6480  ,to_port : 6480   ,protocol : "tcp"  ,cidr : ""  ,sg : "web-svc"        ,pf : "" ,description : "web(svc)"   },
      { from_port : 6480  ,to_port : 6480   ,protocol : "tcp"  ,cidr : ""  ,sg : "etc-db-bastion" ,pf : "" ,description : "bastion(db)"  }
    ],
    egress : [],
    tags  : {             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SG"
    }
  },
  {
    name : "elb-svc",
    description : "ELB Service",
    ingress : [
      { from_port : 80    ,to_port : 80     ,protocol : "tcp"  ,cidr : ""   ,sg : ""  ,pf : "admin"     ,description : "administrator"          },
      { from_port : 443   ,to_port : 443    ,protocol : "tcp"  ,cidr : ""   ,sg : ""  ,pf : "admin"     ,description : "administrator"          },
      { from_port : 80    ,to_port : 80     ,protocol : "tcp"  ,cidr : ""   ,sg : ""  ,pf : "nlb"       ,description : "Health Check From NLB"  },
      { from_port : 443   ,to_port : 443    ,protocol : "tcp"  ,cidr : ""   ,sg : ""  ,pf : "nlb"       ,description : "Health Check From NLB"  },
      { from_port : 443   ,to_port : 443    ,protocol : "tcp"  ,cidr : ""   ,sg : ""  ,pf : "svc-any"   ,description : "any open"               }
    ],
    egress : [
      { from_port : 8080  ,to_port : 8080   ,protocol : "tcp"  ,cidr : ""   ,sg : "web-svc"  ,pf : "" ,description : "web(scv)"         }
    ],
    tags  : {             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SG"
    }
  },
  {
    name : "etc-bastion",
    description : "Bastion",
    ingress : [
      { from_port : 70    ,to_port : 70     ,protocol : "tcp"  ,cidr : ""   ,sg : ""          ,pf : "admin" ,description : "administrator"  }
    ],
    egress : [
      { from_port : 70    ,to_port : 70   ,protocol : "tcp"  ,cidr : ""     ,sg : "web-svc"   ,pf : ""      ,description : "web(svc)"    }
    ],
    tags  : {             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SG"
    }
  },
  {
    name : "etc-db-bastion",
    description : "DB Bastion",
    ingress : [
      { from_port : 70      ,to_port : 70     ,protocol : "tcp"  ,cidr : ""  ,sg : ""           ,pf : "admin" ,description : "administrator"  },
    ],
    egress : [
      { from_port : 3376    ,to_port : 3376   ,protocol : "tcp"  ,cidr : ""  ,sg : "db-rds"     ,pf : ""      ,description : "rds"            },
      { from_port : 6480    ,to_port : 6480   ,protocol : "tcp"  ,cidr : ""  ,sg : "db-redis"   ,pf : ""      ,description : "redis"          }
    ],
    tags  : {             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SG"
    }
  },
  {
    name : "web-svc",
    description : "Web Service",
    ingress : [
      { from_port : 8080  ,to_port : 8080   ,protocol : "tcp"  ,cidr : ""   ,sg : "elb-svc"     ,pf : ""        ,description : "elb(svc)"     },
      { from_port : 70    ,to_port : 70     ,protocol : "tcp"  ,cidr : ""   ,sg : "etc-bastion" ,pf : ""        ,description : "bastion"      }
    ],
    egress : [
      { from_port : 3376    ,to_port : 3376   ,protocol : "tcp"  ,cidr : ""   ,sg : "db-rds"     ,pf : ""         ,description : "rds"            },
      { from_port : 6480    ,to_port : 6480   ,protocol : "tcp"  ,cidr : ""   ,sg : "db-redis"   ,pf : ""         ,description : "redis"          },
      { from_port : 443     ,to_port : 443    ,protocol : "tcp"  ,cidr : ""   ,sg : ""           ,pf : "svc-any"  ,description : "any open"       }
    ],
    tags  : {             # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "SG"
    }
  }
]
#########################################################
## 04. Storage
#########################################################
## 04_01. S3 Bucket
#########################################################
s3_bucket_list = [
  {
    name      : "service-logs", # (Required) [key]
    lifecycle : [           # 보관 주기 정책. PII(개인정보) 취급의 경우, 보안상 설정 권장.
      { expiration : "365" ,prefix : "" }
    ],
    tags  : {               # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "S3"
    }
  },
  {
    name      : "service-deploy",
    lifecycle : [
      { expiration : "365" ,prefix : "" }
    ],
    tags  : {               # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "S3"
    }
  }
]
#########################################################
## 04_02. RDS
#########################################################
rds_list = [
  {
    name                  : "EODevDB",                # (Required) [key]
    allocated_storage     : 10,                       # (Required) RDS storage
    engine                : "mysql",                  # (Required) engine , 참고 : https://docs.aws.amazon.com/ko_kr/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
    engine_version        : "8.0.32",                 # (Required) version , 참고 : https://docs.aws.amazon.com/ko_kr/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
    instance_class        : "db.t3.micro",            # (Required) instance , 참고 : https://docs.aws.amazon.com/ko_kr/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
    username              : "admin",                  # (Required) db admin user
    password              : "password",               # (Required) db admin password
    multi_az              : false,                    # (Required) multi
    security_group_ids    : [],                       # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name   : ["db-rds"],               # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    subnet_ids            : [],                       # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_name           : "pri",                    # (Required) Subnet [Key] 지정. subnet_ids or subnet_name 필수 하나만 지정.
    port                  : 3376,                     # (Required) PORT
    tags                  : {                         # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "RDS"
    }
  }
]
#########################################################
## 04_03. ElastiCache - Encryption in transit 지원 안함
#########################################################
elasticache_list = [
  {
    name                  : "redis",            # (Required) [key]
    engine                : "redis",            # (Required) engine
    node_type             : "cache.t2.small",   # (Required) instance , 참고 : https://docs.aws.amazon.com/ko_kr/AmazonElastiCache/latest/red-ug/nodes-select-size.html
    num_cache_nodes       : 1,                  # (Required) Node 수
    security_group_ids    : [],                 # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name   : ["db-redis"],       # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    subnet_ids            : [],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_name           : "svc",              # (Required) Subnet [Key] 지정. subnet_ids or subnet_name 필수 하나만 지정.
    port                  : 6480,               # (Required) PORT
    tags                  : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "REDIS"
    }
  }
]

#########################################################
## 05. EC2
#########################################################
## 05_01. Instances
#########################################################
instances_list = [
  { // bastion server
    name                        : "bastion",                  # (Required) [key]
    description                 : "default bastion server",
    ami                         : "ami-02609ea4f7524ebb6",    # (Required) 표준 지원 ami 검색. 참고 : https://cloud-images.ubuntu.com/locator/ec2/
    cpu_core_count              : 1                           # (Required) ami spec 에 따라 cpu 지원이 다름.
    threads_per_core            : 1                           # (Required) ami spec 에 따라 cpu 지원이 다름.
    instance_type               : "t3.micro",                 # (Required) 인스턴스 유형. 참고 : https://aws.amazon.com/ko/ec2/instance-types/
    associate_public_ip_address : false,                      # (Required) 인스턴스 자동 생성 Public IP. Public IP 필요시 associate_public_ip_address or public_ip 선택.
    public_ip                   : true                        # (Required) EIP 생성 후 연결. Public IP 필요시 associate_public_ip_address or public_ip 선택.
    user_data                   : "./data/user_data_bastion.sh",      # 인스턴스 시작 된 후 실행 될 Script
    iam_instance_profile        : "",                         # VPC 내부 리소스 접근을 위한 Role 지정
    security_group_ids          : [],                         # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name         : ["etc-bastion"],            # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    subnet_ids                  : "",                         # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_name                 : "pub",                      # (Required) Subnet [Key] 지정. subnet_ids or subnet_name 필수 하나만 지정.
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
  },
  { // db bastion server
    name                        : "db-bastion",               # (Required) [key]
    description                 : "default db bastion server",
    ami                         : "ami-02609ea4f7524ebb6",    # (Required) 표준 지원 ami 검색. 참고 : https://cloud-images.ubuntu.com/locator/ec2/
    cpu_core_count              : 1                           # (Required) ami spec 에 따라 cpu 지원이 다름.
    threads_per_core            : 1                           # (Required) ami spec 에 따라 cpu 지원이 다름.
    instance_type               : "t3.micro",                 # (Required) 인스턴스 유형. 참고 : https://aws.amazon.com/ko/ec2/instance-types/
    associate_public_ip_address : false,                      # (Required) 인스턴스 자동 생성 Public IP. Public IP 필요시 associate_public_ip_address or public_ip 선택.
    public_ip                   : true                        # (Required) EIP 생성 후 연결. Public IP 필요시 associate_public_ip_address or public_ip 선택.
    user_data                   : "./data/user_data_bastion.sh",      # 인스턴스 시작 된 후 실행 될 Script
    iam_instance_profile        : "",                         # VPC 내부 리소스 접근을 위한 Role 지정
    security_group_ids          : [],                         # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name         : ["etc-db-bastion"],         # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    subnet_ids                  : "",                         # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_name                 : "pub",                      # (Required) Subnet [Key] 지정. subnet_ids or subnet_name 필수 하나만 지정.
    subnet_az                   : "b"                         # (Required) 가용 영역. a, b, c, d, e, f
    root_block_device           : [                           # (Required) EBS, snapshot_id 지정 불가
      { name : "root" ,device_name : "/dev/sda1"  ,volume_size : 30   }
    ],
    ebs_block_device            : [                           # (Required) EBS, snapshot_id 공백일 경우 자동 생성.
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
    name                    : "svc",                              # (Required) [key]
    description             : "service was auto-scale template",
    image_id                : "ami-02609ea4f7524ebb6",            # (Required) 표준 지원 ami 검색 > https://cloud-images.ubuntu.com/locator/ec2/
    cpu_core_count          : 1                                   # (Required) ami spec 에 따라 cpu 지원이 다름.
    threads_per_core        : 1                                   # (Required) ami spec 에 따라 cpu 지원이 다름.
    instance_type           : "t3.micro",                         # (Required) 인스턴스 유형. 참고 : https://aws.amazon.com/ko/ec2/instance-types/
    user_data               : "./data/user_data_tomcat.sh",              # 인스턴스 시작 된 후 실행 될 Script
    iam_instance_profile    : "",                                 # VPC 내부 리소스 접근을 위한 Role 지정
    security_group_ids      : [],                                 # (Required) SG ID 명시적 지정. security_group_ids or security_group_name 필수 하나만 지정.
    security_group_name     : ["web-svc"],                        # (Required) SG [Key] 지정. security_group_ids or security_group_name 필수 하나만 지정.
    block_device_mappings   : [                                   # (Required) EBS
      { name : "root"   ,snapshot_id : "" ,device_name : "/dev/sda1"    ,volume_size : 30   },
      { name : "home"   ,snapshot_id : "" ,device_name : "/dev/sdb"     ,volume_size : 30   },
      { name : "home01" ,snapshot_id : "" ,device_name : "/dev/sdc"     ,volume_size : 50   },
      { name : "home02" ,snapshot_id : "" ,device_name : "/dev/sdd"     ,volume_size : 200  }
    ],
    tags  : {                                                 # 리소스 태그 정책
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
    name : "svc-ec2",                     # (Required) [key]
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
    name : "svc-alb",
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
    name                    : "nlb-svc",          # (Required) [key]
    load_balancer_type      : "network",          # (Required) network or application 지정.
    security_group_ids      : [],                 # SG ID 명시적 지정. security_group_ids or security_group_name
    security_group_name     : [],                 # SG [Key] 지정. security_group_ids or security_group_name
    subnet_ids              : [],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name
    subnet_name             : ["pub"],            # (Required) Subnet [Key] 지정. subnet_ids or subnet_name
    ip_address_type         : "ipv4",             # (Required) "ipv4" or "dualstack"(Subnet IPv6 지원시 가능)
    target_group            : "svc-alb",          # (Required) Target Group Key(name) 지정.
    alb_target_group        : "alb-svc",          # (Required) NLB 리스너의 경우, ALB 의 Key(name) 지정 필요.
    certificate_arn         : "",                 # ALB 리스너의 경우, HTTPS 통신을 위한 SSL
    tags                    : {                   # 리소스 태그 정책
      TYPE_1 : "COMMON",
      TYPE_2 : "ELB"
    }
  },
  {
    name                    : "alb-svc",          # (Required) [key]
    load_balancer_type      : "application",      # (Required) network or application 지정.
    security_group_ids      : [],                 # SG ID 명시적 지정. security_group_ids or security_group_name
    security_group_name     : ["elb-svc"],        # SG [Key] 지정. security_group_ids or security_group_name
    subnet_ids              : [],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name
    subnet_name             : ["svc"],            # (Required) Subnet [Key] 지정. subnet_ids or subnet_name
    ip_address_type         : "ipv4",             # (Required) "ipv4" or "dualstack"(Subnet IPv6 지원시 가능)
    target_group            : "svc-ec2",          # (Required) Target Group Key(name) 지정.
    alb_target_group        : "",                 # (Required) NLB 리스너의 경우, ALB 의 Key(name) 지정 필요.
    certificate_arn         : ""                  # ALB 리스너의 경우, HTTPS 통신을 위한 SSL
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
    name                    : "svc",              # (Required) [key]
    desired_capacity        : 2,                  # (Required) 인스턴스 개수.
    max_size                : 2,                  # (Required) 최대 수 지정. 자동 Scale out 시 필요.
    min_size                : 1,                  # (Required) 최소 수 지정. 자동 Scale out 시 필요.
    subnet_ids              : [],                 # (Required) Subnet ID 명시적 지정. subnet_ids or subnet_name
    subnet_name             : "svc",              # (Required) Subnet [Key] 지정. subnet_ids or subnet_name
    target_group            : "svc-ec2",          # (Required) Target Group Key(name) 지정.
    launch_template         : "svc",              # (Required) Launch Template Key(name) 지정.
    tags                    : [
      { key   : "TYPE_1", value : "COMMON", propagate_at_launch : false },
      { key   : "TYPE_2", value : "ASG", propagate_at_launch : false }
    ]
  }
]