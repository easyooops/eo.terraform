## Terraform Guide (Windows+Intellij version)

### 1. Terraform Install
1. **Download** : https://developer.hashicorp.com/terraform/downloads
2. Project 생성 및 경로 생성.
3. 압축 해제 후 "terraform.exe" 테라폼 실행 루트 경로 이동.
4. Terraform 실행 확인. (Windows PS 하위 경로 실행시 "./" 붙여서 실행 필요.)
 ```powershell
$ ./terraform
```

### 2. Workspace (Production)
```powershell
# workspace help
    ./terraform workspace -h
    
# workspace 목록 (default)
    ./terraform workspace list
    
# workspace 생성
    ./terraform workspace new example_all_dev

# workspace 선택
    ./terraform workspace select example_all_dev
        
# workspace 삭제
    ./terraform workspace delete example_all_dev
```

### 3. Terraform Run
- [주의] Terraform import 참조 코드 가져올 경우에만 조심해서 사용. "*.tfstate" 파일 기준 인프라 자동 변경/삭제가 발생 됨.
```powershell
# 1) 모듈 설치
    ./terraform init
    
# 2) 계획
    ./terraform plan -var-file="example_all_dev.tfvars" -out=tfplan
    
# 3) 생성
    ./terraform apply tfplan
    
# 4) 삭제
    ./terraform destroy -var-file="example_all_dev.tfvars"
```

### 4. Terraform Package Structure
```powershell
[root]
├───.terraform
│   ├───modules
│   └───providers
├───data
├───modules
│   ├───EC2
│   │   ├───ASG
│   │   ├───Instances
│   │   ├───LaunchTemplates
│   │   ├───LoadBalancers
│   │   └───TargetGroups
│   ├───Security
│   │   ├───ACLs
│   │   └───SG
│   ├───Storage
│   │   ├───ElastiCache
│   │   ├───RDS
│   │   └───S3
│   └───VPC
│       ├───IGW
│       ├───NAT
│       ├───PrefixLists
│       ├───Routes
│       ├───Subnets
│       └───VPCs
└───terraform.tfstate.d
    ├───example_all_dev
    ├───example_all_stg
    └───example_part_dev

```

### 5. Help / Question
- ssu0416@gmail.com