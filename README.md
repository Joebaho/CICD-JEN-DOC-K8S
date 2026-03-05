# Jenkins + Terraform + EKS CI/CD (FastAPI)

This repository provisions:
- An **EKS cluster** with Terraform (`terraform-eks/`)
- A **Jenkins server** on EC2 with Terraform (`terraform-jenkins/`)
- A Jenkins pipeline (`Jenkinsfile`) that:
  - Builds Docker image from `app/`
  - Pushes to Docker Hub
  - Deploys to EKS with `kubectl`

## Project Structure

```bash
.
├── app/
│   ├── Dockerfile
│   ├── form.html
│   ├── main.py
│   └── requirements.txt
├── images/
│   └── architecture.png
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── terraform-eks/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── terraform-jenkins/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars
│   ├── user-data.sh
│   └── variables.tf
└── Jenkinsfile
```

## Prerequisites

Install locally:
- Terraform >= 1.0
- AWS CLI v2
- kubectl
- Docker

AWS prerequisites:
- An existing EC2 key pair in your target region
- AWS credentials with permissions for VPC, EKS, EC2, IAM, and EIP

## Step-by-Step Execution

### 1. Update Terraform variables

Edit:
- `terraform-eks/terraform.tfvars`
- `terraform-jenkins/terraform.tfvars`

Required checks:
- `region` and `aws_region` match your target region
- `cluster_name` is your desired EKS cluster name
- `key_name` is an existing EC2 key pair name

### Fast Run (No Manual Re-typing)

Use helper scripts from project root:

```bash
./scripts/deploy.sh --auto-approve
./scripts/destroy.sh --auto-approve --yes
```

### 2. Create the EKS cluster

```bash
cd terraform-eks
terraform init
terraform plan
terraform apply -auto-approve
```

Save cluster name output (or use your tfvars value).

### 3. Create the Jenkins EC2 server

```bash
cd ../terraform-jenkins
terraform init
terraform plan
terraform apply -auto-approve
```

Get access info:

```bash
terraform output
```

Use `jenkins_url` to open Jenkins in browser.

### 4. Configure Jenkins once

In Jenkins, create credentials:

1. `DOCKERHUB_USERNAME` (Secret text)
- Value: your Docker Hub username

2. `DOCKERHUB_TOKEN` (Secret text)
- Value: your Docker Hub access token/password

3. `AWS_ACCESS_KEY_ID` (Secret text)
- Value: your AWS access key ID

4. `AWS_SECRET_ACCESS_KEY` (Secret text)
- Value: your AWS secret access key

Important:
- GitHub Secrets are not automatically visible to Jenkins jobs.
- Keep the same values in Jenkins Credentials (IDs above) so the `Jenkinsfile` can read them.
- The AWS identity in `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` must have EKS access for cluster operations.
- If deployment fails with authorization errors, grant this identity cluster admin access in EKS.

### 5. Create Jenkins Pipeline job

Create a Pipeline job and point it to this repository:
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: your repo URL
- Branch: `main`
- Script Path: `Jenkinsfile`

### 6. Run pipeline

Trigger **Build Now**.

Pipeline stages:
- Checkout
- Verify Tooling
- Build Docker image (`<dockerhub-user>/fastapi-app:<build_number>`)
- Push image to Docker Hub
- Deploy manifests in `k8s/`
- Update deployment image
- Show service endpoint

### 7. Verify deployment

From Jenkins logs or any kube-configured machine:

```bash
kubectl get pods
kubectl get svc fastapi-service -o wide
```

When LoadBalancer hostname appears, open it in browser.

## Troubleshooting

1. `kubectl` unauthorized in Jenkins
- Cause: AWS identity lacks EKS access.
- Fix: grant the Jenkins AWS identity proper access to the EKS cluster.

2. Docker push fails
- Cause: wrong Docker Hub credentials (`DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`).
- Fix: recreate credential with valid Docker Hub token.

3. Jenkins cannot start pipeline tools
- Verify on Jenkins EC2:
```bash
docker --version
aws --version
kubectl version --client
```

4. Terraform apply fails in Jenkins module
- Confirm `key_name` exists in the same region.

## Cleanup

```bash
cd terraform-jenkins && terraform destroy -auto-approve
cd ../terraform-eks && terraform destroy -auto-approve
```
