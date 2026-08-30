# AWS Highly Available & Auto-Scaling Web Application
A production-style AWS architecture demonstrating high availability, fault tolerance, load balancing, self-healing infrastructure, and horizontal auto scaling using Amazon EC2, Application Load Balancer (ALB), Auto Scaling Groups (ASG), CloudWatch, and Terraform.

## Architecture

                         Internet
                            |
                            v
                +----------------------+
                | Application Load     |
                | Balancer (ALB)       |
                +----------+-----------+
                           |
                     Target Group
                       Port 8000
                           |
              +------------+------------+
              |                         |
              v                         v
       Availability Zone A       Availability Zone B
              |                         |
         EC2 Instance              EC2 Instance
              |                         |
              +------------+------------+
                           |
                  Auto Scaling Group
                           |
                    Launch Template
                           |
                       CloudWatch
                           |
                   Scaling Policy
                           |
                  Target CPU: 60%


## Project Overview
The goal of this project is to demonstrate how AWS can maintain application availability and automatically respond to changes in traffic.
The application runs across multiple Availability Zones behind an Application Load Balancer.
An Auto Scaling Group maintains the required number of EC2 instances and automatically replaces unhealthy instances.

CloudWatch metrics are used by a target-tracking scaling policy to increase or decrease EC2 capacity according to CPU utilization.

The infrastructure is completely provisioned using Terraform.

## Features

- Multi-AZ deployment
- Application Load Balancer
- EC2 Auto Scaling
- Automatic instance replacement
- ALB health checks
- Target groups
- Launch Templates
- CloudWatch monitoring
- CPU-based target tracking
- Infrastructure as Code with Terraform
- Automated EC2 configuration using user data
- IMDSv2 enforcement
- Security-group-based network isolation
- FastAPI web application
- Horizontal scaling
- Failure recovery testing
- Load testing

## AWS Services

| Service                         | Purpose                               |
| ------------------------------- | ------------------------------------- |
| Amazon VPC                      | Provides isolated networking          |
| EC2                             | Hosts the application                 |
| Application Load Balancer       | Distributes incoming requests         |
| Auto Scaling Group              | Maintains and scales EC2 capacity     |
| Launch Template                 | Defines EC2 configuration             |
| CloudWatch                      | Provides metrics used for scaling     |
| Systems Manager Parameter Store | Retrieves the latest Amazon Linux AMI |
| Internet Gateway                | Provides internet connectivity        |
| Security Groups                 | Controls network access               |

## Technology Stack
## Cloud
- AWS
## Infrastructure as Code

- Terraform
## Application
- Python
- FastAPI
- Uvicorn

## Testing

- AWS CLI
- `hey` load-testing tool

## Operating System

- Amazon Linux 2023

## Project Structure

```text
aws-ha-autoscaling/
├── app/                         FastAPI application
│   ├── main.py                  Application and health endpoint
│   └── requirements.txt         Python dependencies
├── diagrams/                    Architecture diagrams
├── scripts/
│   └── user_data.sh             EC2 bootstrap script
├── terraform/                   AWS infrastructure definitions
│   ├── alb.tf                   Load balancer and target group
│   ├── autoscaling.tf           Auto Scaling Group and policy
│   ├── launch-template.tf       EC2 launch configuration
│   ├── outputs.tf               Deployment outputs
│   ├── providers.tf             Terraform and AWS providers
│   ├── security-groups.tf       Network access rules
│   ├── variables.tf             Input variables
│   └── vpc.tf                   VPC, subnets, and routing
├── tests/
│   └── load-test.sh             Load-generation script
├── .gitignore
└── README.md                    Project documentation
```

## Network Architecture

The project creates a VPC with resources distributed across two Availability Zones.

```text
                              Internet
                                  │
                                  ▼
                         Internet Gateway
                                  │
                                  ▼
┌──────────────────────── VPC 10.0.0.0/16 ────────────────────────┐
│                                                                 │
│                    Application Load Balancer                    │
│                           HTTP port 80                           │
│                                  │                              │
│                                  ▼                              │
│                       Target Group port 8000                     │
│                                  │                              │
│                   ┌──────────────┴──────────────┐               │
│                   │                             │               │
│                   ▼                             ▼               │
│  ┌────────────────────────────┐  ┌────────────────────────────┐ │
│  │ Availability Zone A        │  │ Availability Zone B        │ │
│  │                            │  │                            │ │
│  │ Public: 10.0.1.0/24        │  │ Public: 10.0.2.0/24        │ │
│  │ └── EC2 application        │  │ └── EC2 application        │ │
│  │                            │  │                            │ │
│  │ Private: 10.0.11.0/24      │  │ Private: 10.0.12.0/24      │ │
│  │ └── Reserved for future use│  │ └── Reserved for future use│ │
│  └────────────────────────────┘  └────────────────────────────┘ │
│                                                                 │
│           Auto Scaling Group spans both Availability Zones      │
└─────────────────────────────────────────────────────────────────┘
```

The initial cost-conscious implementation launches application instances in the public subnets while preventing direct application access through security-group rules.

The ALB accepts HTTP traffic on port `80`.

EC2 instances accept application traffic on port `8000` only from the ALB security group.

A future version can move the instances into the private subnets using NAT Gateway or appropriate VPC endpoints.

## Auto Scaling Configuration

The Auto Scaling Group uses:

Minimum capacity: 2
Desired capacity: 2
Maximum capacity: 6

Two instances provide baseline redundancy across Availability Zones.

The target-tracking policy attempts to maintain:

Average ASG CPU Utilization: 60%


When demand increases:

Traffic increases
       |
       v
CPU utilization increases
       |
       v
CloudWatch detects utilization
       |
       v
Auto Scaling increases desired capacity
       |
       v
New EC2 instances launch
       |
       v
ALB health checks succeed
       |
       v
Instances begin receiving traffic


When demand decreases, excess instances can automatically be terminated while respecting the configured minimum capacity.

## Self-Healing

The Auto Scaling Group is configured to use ELB health checks.

If an application instance becomes unhealthy:

EC2 failure
     |
     v
ALB health check fails
     |
     v
Instance marked unhealthy
     |
     v
Traffic routed to healthy instances
     |
     v
ASG replaces unhealthy instance
     |
     v
New instance launches
     |
     v
Application bootstrapped automatically
     |
     v
Health check passes
     |
     v
Instance joins target group


This demonstrates self-healing infrastructure.

## Application

The FastAPI application provides an Instance Inspector interface displaying information about the server handling the request.

Example:

```text
AWS High Availability Demo

Status: Healthy

Instance:
i-0123456789abcdef

Availability Zone:
us-east-1a

Hostname:
ip-10-0-1-25

Request Time:
2026-08-30 08:00:00 UTC
```

Refreshing the application can return responses from different instances, demonstrating that the ALB is distributing traffic across the fleet.

The application also exposes:

/health


which returns:

```json
{
  "status": "healthy"
}
```

The ALB uses this endpoint for health checks.

## Prerequisites

Install:

- AWS CLI
- Terraform
- Python 3
- Git

Verify AWS authentication:

```bash
aws sts get-caller-identity
```

Verify Terraform:

```bash
terraform version
```

Verify AWS region:

```bash
aws configure get region
```

The default region used by this project is:

```text
us-east-1
```

## Deployment

Clone the repository:

```bash
git clone <repository-url>

cd aws-ha-autoscaling/terraform
```

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt -recursive
```

Validate:

```bash
terraform validate
```

Review the infrastructure plan:

```bash
terraform plan
```

Deploy:

```bash
terraform apply
```

Confirm with:

```text
yes
```

## Access the Application

After deployment:

```bash
terraform output -raw application_url
```

Open the returned URL in a browser.

Example:

```text
http://ha-web-app-alb-xxxxxxxx.us-east-1.elb.amazonaws.com
```

## Verify EC2 Instances

```bash
aws ec2 describe-instances \
  --filters \
  "Name=tag:Name,Values=ha-web-app-asg-instance" \
  "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,AvailabilityZone,PrivateIpAddress]' \
  --output table
```

The output should show instances distributed across multiple Availability Zones.

## Verify Target Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)" \
  --query 'TargetHealthDescriptions[].[Target.Id,TargetHealth.State]' \
  --output table
```

Expected state:

```text
healthy
```

## High Availability Test

One of the main experiments in this project is deliberately terminating an EC2 instance.

List the instances:

```bash
aws ec2 describe-instances \
  --filters \
  "Name=tag:Name,Values=ha-web-app-asg-instance" \
  "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text
```

Terminate one:

```bash
aws ec2 terminate-instances \
  --instance-ids <INSTANCE-ID>
```

The application should remain available through the ALB.

The Auto Scaling Group should detect the capacity reduction and automatically launch a replacement instance.

Check ASG status:

```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ha-web-app-asg \
  --query 'AutoScalingGroups[0].Instances[].[InstanceId,LifecycleState,HealthStatus]' \
  --output table
```

This test demonstrates:

- Fault tolerance
- Load balancer health checking
- Automatic traffic rerouting
- Automatic EC2 replacement
- Self-healing infrastructure

## Load Test

The project can also demonstrate horizontal scalability using `hey`.

Set the application URL:

```bash
URL=$(terraform output -raw application_url)
```

Generate load:

```bash
hey -z 10m -c 200 "$URL/"
```

Monitor the Auto Scaling Group from another terminal:

```bash
watch -n 10 '
aws autoscaling describe-auto-scaling-groups \
--auto-scaling-group-names ha-web-app-asg \
--query "AutoScalingGroups[0].[DesiredCapacity,Instances[].InstanceId]" \
--output table
'
```

Under sufficient CPU load, the desired capacity can increase from:

```text
2
```

to:

```text
3
```

or more, up to the configured maximum of:

```text
6
```

After the load test ends and utilization decreases, Auto Scaling can remove excess instances and return toward the minimum capacity.

## Security

The architecture uses separate security groups for the ALB and application servers.

### ALB

Inbound:

```text
HTTP 80
Source: 0.0.0.0/0
```

### EC2

Inbound:

```text
TCP 8000
Source: ALB Security Group
```

The application port is therefore not directly exposed to arbitrary internet clients.

EC2 Instance Metadata Service is configured to require IMDSv2.

## Infrastructure as Code

All AWS infrastructure is managed through Terraform.

This provides:

- Reproducible deployments
- Version-controlled infrastructure
- Easier environment recreation
- Consistent configuration
- Automated dependency management
- Simple infrastructure cleanup

## Destroying the Infrastructure

AWS resources created by this project may incur charges.

After testing:

```bash
cd terraform

terraform destroy
```

Review the resources and confirm:

```text
yes
```

Verify the Terraform state afterward:

```bash
terraform state list
```

## What This Project Demonstrates

This project demonstrates practical knowledge of:

### AWS

- EC2
- VPC
- ALB
- Target Groups
- Auto Scaling Groups
- Launch Templates
- CloudWatch
- Security Groups
- Multi-AZ architecture
- EC2 metadata

### Cloud Architecture

- High availability
- Horizontal scalability
- Fault tolerance
- Self-healing systems
- Health checking
- Traffic distribution

### DevOps

- Terraform
- Infrastructure as Code
- Automated server provisioning
- Load testing
- Failure testing
- AWS CLI

## Future Improvements

Planned improvements include:

- Move EC2 instances into private subnets
- AWS Systems Manager Session Manager instead of SSH
- HTTPS with AWS Certificate Manager
- Route 53 custom domain
- GitHub Actions CI/CD
- CloudWatch dashboards
- CloudWatch alarms
- SNS notifications
- AWS WAF
- Application logs in CloudWatch
- Custom AMI creation with Packer
- Blue/green deployments
- Terraform remote state with S3
- DynamoDB state locking where applicable

## Learning Outcomes

The key lesson from this project is that high availability is not simply running multiple servers.

A highly available architecture requires multiple components working together:

```text
ALB
+
Multiple Availability Zones
+
Health Checks
+
Auto Scaling
+
Automated Provisioning
+
Monitoring
=
Highly Available and Scalable Application
```

The ALB distributes traffic and removes unhealthy targets from service, while the Auto Scaling Group maintains capacity, replaces failed instances, and adjusts the number of servers according to demand.

## Author

Charles Opuba

Cloud Engineering | AWS | DevOps | Infrastructure as Code
