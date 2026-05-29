# Infrastructure Cloud AWS — Terraform & CI/CD

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About the Project</a></li>
    <li><a href="#key-features">Key Features</a></li>
    <li><a href="#built-with">Built With</a></li>
    <li><a href="#project-architecture">Project Architecture</a></li>
  </ol>
</details>

## About the Project

This project provisions a complete AWS cloud infrastructure using 
**Terraform**, **GitHub Actions**, and AWS-native services.

It demonstrates how to design, secure, monitor, and automate a 
production-grade cloud infrastructure following Infrastructure as 
Code principles.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Key Features

- Provision a complete AWS network (VPC, subnets, security groups)
- Deploy containerized applications on ECS Fargate with auto-scaling
- Manage a MySQL database on Amazon RDS with automated backups
- Secure the infrastructure with IAM least privilege and AWS Secrets Manager
- Monitor all components with CloudWatch dashboards and SNS alerts
- Automate infrastructure deployment through a CI/CD pipeline
- Manage multiple environments (dev, staging, prod) via Terraform Workspaces

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Built With

- **IaC:** Terraform ~> 6.0
- **Cloud:** AWS (eu-west-3 — Paris)
- **Compute:** Amazon ECS Fargate
- **Database:** Amazon RDS MySQL 8.0
- **Storage:** Amazon S3
- **Security:** IAM · AWS Secrets Manager
- **Monitoring:** Amazon CloudWatch · Amazon SNS
- **CI/CD:** GitHub Actions
- **State backend:** S3 + DynamoDB

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Project Architecture

### 1. Network Layer

The network is built around a **VPC (Virtual Private Cloud)** 
spanning two Availability Zones for high availability.

It is divided into two subnet tiers:

- **Public subnets** (eu-west-3a / eu-west-3b)  
  Host the Application Load Balancer only.  
  Connected to the Internet Gateway to receive incoming traffic.

- **Public subnets for ECS** (eu-west-3a / eu-west-3b)  
  Host ECS Fargate tasks with `assign_public_ip = true`.  
  This allows Docker Hub image pulls without a NAT Gateway,  
  keeping the setup within the AWS Free Tier.  
  In production, ECS would be placed in private subnets behind  
  a NAT Gateway or using ECR via VPC Endpoint.

Traffic always flows through the ALB before reaching ECS — 
containers are never directly accessible from the internet.

Each component has its own **Security Group** with strict rules:
- ALB accepts HTTP/HTTPS from the internet
- ECS accepts traffic only from the ALB security group
- RDS accepts MySQL traffic only from the ECS security group

This layered approach ensures that even if one component is 
compromised, lateral movement is limited.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
---

### 2. Compute Layer — ECS Fargate

The application runs on **Amazon ECS Fargate**, AWS's serverless 
container runtime.

Fargate was chosen over EC2 for the following reasons:
- No server management — AWS handles the underlying infrastructure
- Pay only for what you use (CPU + memory per task)
- Native auto-scaling based on CPU utilization
- Compatible with the AWS Free Tier (750 hours/month)

Each environment has its own resource configuration:

| Environment | CPU | Memory | Instances |
|---|---|---|---|
| dev | 256 | 512 MB | 1 |
| staging | 512 | 1024 MB | 2 |
| prod | 1024 | 2048 MB | 3 |

Auto-scaling is configured to trigger at 70% CPU utilization, 
allowing new tasks to start before saturation is reached.

The container image is pulled from **Docker Hub** at task startup.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
---

### 3. Database Layer — RDS MySQL

The application database runs on **Amazon RDS MySQL 8.0**.

RDS was chosen over a containerized database for the following reasons:
- Data persists independently of container restarts
- Automated daily backups with a 7-day retention window
- AWS manages patching, maintenance, and availability
- Native Multi-AZ support for production environments

The RDS instance is placed in private subnets and is only reachable 
from ECS tasks through the dedicated security group.

In the dev and staging environments, Multi-AZ is disabled to 
stay within Free Tier limits. In production it would be enabled 
for high availability across two Availability Zones.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
---

### 4. Storage — S3

S3 is used for two distinct purposes in this project.

#### Terraform state backend
A dedicated S3 bucket stores the Terraform state file remotely.
This enables team collaboration and prevents state conflicts.

Versioning is enabled so any corrupted state can be restored 
from a previous version.

A **DynamoDB table** is paired with the bucket to provide 
state locking — preventing two simultaneous `terraform apply` 
operations from corrupting the infrastructure.

#### Application storage
A second S3 bucket is provisioned by Terraform for application use 
(file uploads, exports, backups).

It is configured with:
- Public access fully blocked
- AES-256 server-side encryption
- Versioning enabled
- Lifecycle rules to transition old objects to STANDARD_IA 
  after 30 days and GLACIER after 90 days

<p align="right">(<a href="#readme-top">back to top</a>)</p>
---

### 5. Security — IAM & Secrets Manager

Security follows the **least privilege principle** throughout 
the infrastructure.

#### IAM roles

Two distinct IAM roles are assigned to ECS tasks:

- **Execution Role**  
  Used by the ECS agent to pull the Docker image and write 
  logs to CloudWatch. This role is managed by AWS 
  (`AmazonECSTaskExecutionRolePolicy`).

- **Task Role**  
  Used by the application container itself. It grants access 
  only to the resources the application needs:
  - Read access to the RDS secret in Secrets Manager
  - Read/write access to the application S3 bucket

This separation ensures that a compromised container cannot 
affect the ECS infrastructure itself.

#### AWS Secrets Manager

Database credentials (host, username, password, port) are 
stored in **AWS Secrets Manager** rather than passed as 
environment variables.

The ECS task retrieves the secret at runtime through the 
Task Role. The password never appears in Terraform logs, 
GitHub Actions logs, or environment variables.

<p align="right">(<a href="#readme-top">back to top</a>)</p>
---

### 6. Monitoring — CloudWatch & SNS

All infrastructure components are monitored through 
**Amazon CloudWatch**.

The following alarms are configured:

| Component | Metric | Threshold |
|---|---|---|
| ECS | CPU utilization | > 85% for 10 min |
| ECS | Memory utilization | > 85% for 10 min |
| RDS | CPU utilization | > 80% for 10 min |
| RDS | Free storage space | < 2 GB |
| RDS | Database connections | > 50 |
| ALB | HTTP 5xx errors | > 10 per minute |
| ALB | Target response time | > 2 seconds |

All alarms publish to an **SNS topic** which sends email 
notifications. An OK notification is also sent when the 
alarm returns to a normal state.

A **CloudWatch Dashboard** provides a centralized view of 
all metrics across ECS, RDS, and the ALB.

CloudWatch was chosen over Prometheus/Grafana because it 
integrates natively with all AWS services without requiring 
additional infrastructure.

---

### 7. CI/CD Pipeline — GitHub Actions

The infrastructure deployment is fully automated through 
**GitHub Actions**.

Two workflows are defined:

#### terraform-plan.yml (all branches)
Triggered on every push and pull request.

Steps:
1. `terraform fmt` — enforces consistent code formatting
2. `terraform validate` — checks syntax and configuration
3. `terraform plan` — previews infrastructure changes
4. `tfsec` — scans for security misconfigurations

This workflow runs on every branch so issues are caught 
before merging to main.

#### terraform-deploy.yml (main branch only)
Triggered on push to main or manually via `workflow_dispatch`.

Steps:
1. `terraform init` — initializes the backend and providers
2. Workspace selection — selects or creates the target environment
3. `terraform plan` — generates the execution plan
4. `terraform apply` — applies changes to AWS automatically

The `workflow_dispatch` trigger adds a manual deployment button 
in the GitHub Actions interface, allowing deployment to a specific 
environment (dev, staging, prod) on demand.

AWS credentials are stored as **GitHub Secrets** and never 
appear in logs or source code.

---

### 8. Multi-Environment Management — Terraform Workspaces

The infrastructure supports three environments managed through 
**Terraform Workspaces**.

Each workspace maintains its own isolated Terraform state:

S3 bucket (tfstate)
├── env:/dev/terraform.tfstate
├── env:/staging/terraform.tfstate
└── env:/prod/terraform.tfstate

A single configuration map drives all environment differences — 
CPU, memory, instance count, database class, and Multi-AZ — 
without duplicating any Terraform code.

---

### 9. Infrastructure Overview

Internet
↓
Internet Gateway
↓
Application Load Balancer (public subnets — 2 AZ)
↓
ECS Fargate (public subnets — assign_public_ip)
├── pulls image from Docker Hub
├── reads credentials from Secrets Manager
├── writes files to S3
└── connects to RDS MySQL (private subnets)
CloudWatch — monitors ECS, RDS, ALB → SNS alerts
GitHub Actions — terraform plan + apply on every push to main
S3 + DynamoDB — Terraform state backend

---

### 10. Project Structure

aws-infra/
├── main.tf                   # module orchestration
├── variables.tf              # global variables + per-env config
├── outputs.tf                # ALB DNS, dashboard URL
├── providers.tf              # AWS provider ~> 6.0
├── backend.tf                # S3 state + DynamoDB lock
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-deploy.yml
└── modules/
├── networking/            # VPC, subnets, security groups
├── compute/               # ECS Fargate, ALB, auto-scaling
├── database/              # RDS MySQL, S3
├── security/              # IAM, Secrets Manager
└── monitoring/            # CloudWatch, SNS

---

### 11. Getting Started

#### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured (`aws configure`)
- AWS account with sufficient permissions

#### Bootstrap (one-time setup)

```bash
# Create the S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket tfstate-aws-infra-YOURNAME \
  --region eu-west-3 \
  --create-bucket-configuration LocationConstraint=eu-west-3

aws s3api put-bucket-versioning \
  --bucket tfstate-aws-infra-YOURNAME \
  --versioning-configuration Status=Enabled

# Create the DynamoDB table for state locking
aws dynamodb create-table \
  --table-name tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-3
```

#### Deploy

```bash
terraform init

terraform workspace new dev
terraform workspace select dev

export TF_VAR_db_password="YourPassword"
export TF_VAR_alert_email="your@email.com"

terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

## Author

Louis-Hadrien Denis
