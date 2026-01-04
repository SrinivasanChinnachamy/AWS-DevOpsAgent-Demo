# AWS DevOps Agent Demo

This repository demonstrates AWS DevOps Agent capabilities by deploying infrastructure with **intentional issues** for investigation and resolution. Kindly interpret as outlined in this medium bog. (link) we will also use this repo to perform code review with AWS Security Agent to review code security findings (AWS and Custom) in GitHub

## 🎯 Purpose

Showcase how AWS DevOps Agent can identify and resolve common infrastructure problems:
- DynamoDB throttling issues
- Missing monitoring and alarms
- Poor CI/CD practices
- Lambda performance problems
- Security misconfigurations

## 🏗️ Architecture

- **API Gateway** → **Lambda Function** → **DynamoDB**
- CloudWatch Logs for monitoring
- GitHub Actions for CI/CD deployment

## 📁 Repository Structure

```
├── infrastructure/          # Terraform IaC files
│   ├── main.tf             # Core infrastructure resources
│   ├── providers.tf        # Provider configuration
│   ├── variables.tf        # Variable definitions
│   ├── outputs.tf          # Output values
│   └── terraform.tfvars    # Environment configuration
├── src/
│   └── get_user.py         # Lambda function (with issues)
├── scripts/
│   ├── deploy.sh           # Local deployment script
│   └── simulate_incident.py # Load testing script
├── .github/workflows/
│   └── deploy.yml          # CI/CD pipeline (with issues)
└── README.md
```

## 🚀 Quick Start

### 1. Setup AWS Credentials

Create IAM user with permissions for:
- DynamoDB, Lambda, API Gateway, IAM, CloudWatch

Add to GitHub Repository Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 2. Deploy Infrastructure

Push to main branch triggers automatic deployment:
```bash
git push origin main
```

### 3. Test the API

Get endpoint from GitHub Actions output:
```bash
curl https://[api-id].execute-api.us-east-1.amazonaws.com/demo/users/user123
```

### 4. Simulate Issues

Run load test to trigger throttling:
```bash
python scripts/simulate_incident.py
```

## 🐛 Intentional Issues

### Infrastructure Issues
- **DynamoDB**: Low provisioned capacity (5 RCU/WCU) causes throttling
- **Lambda**: No retry logic, generic error handling, high timeout
- **Monitoring**: Missing CloudWatch alarms and dashboards
- **Security**: No authentication, overly broad IAM permissions

### CI/CD Issues
- **Pipeline**: Auto-approve without plan review
- **Security**: No vulnerability scanning or security checks
- **Testing**: No automated testing or validation
- **Rollback**: No rollback mechanism

## 🔍 DevOps Agent Investigation

1. **Set up DevOps Agent workspace** pointing to your AWS account
2. **Monitor CloudWatch** for throttling and error metrics
3. **Investigate issues** using DevOps Agent's analysis capabilities
4. **Apply recommended fixes** for infrastructure and pipeline improvements

## 📊 Expected Metrics

After running `simulate_incident.py`:
- DynamoDB throttling errors
- Lambda timeout issues
- High error rates in CloudWatch
- Poor API response times

## 🛠️ Local Development

Deploy locally:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Clean up resources:
```bash
cd infrastructure
terraform destroy -auto-approve
```

## 📋 Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Python 3.11+
- GitHub repository with Actions enabled

## 🏷️ Resource Tagging

All resources tagged with:
- `Environment`: demo
- `Application`: user-api  
- `Component`: retrieve-user-api

## ⚠️ Important Notes

- This is a **demo environment** with intentional issues
- **Do not use in production** without fixing security and performance issues
- Resources will incur AWS costs (minimal for demo usage)
- Clean up resources after testing to avoid ongoing charges

## 🤝 Contributing

This is a demonstration repository. Issues and improvements should be identified and resolved using AWS DevOps Agent capabilities.

## 📄 License

This project is for demonstration purposes only.
