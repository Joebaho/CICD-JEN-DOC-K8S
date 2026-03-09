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
├── scripts/
│   ├── deploy.sh
│   └── destroy.sh
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
- Git

AWS prerequisites:
- Optional: an existing EC2 key pair in your target region (only if you want SSH)
- AWS credentials with permissions for VPC, EKS, EC2, IAM, and EIP

## Step-by-Step Execution

### 1. Configure Terraform variables

Edit:
- `terraform-eks/terraform.tfvars`
- `terraform-jenkins/terraform.tfvars`

Required checks:
- `region` and `aws_region` match your target region
- `cluster_name` is your desired EKS cluster name
- `key_name` can be an existing EC2 key pair name, or `null` if you will use SSM only

### 2. Deploy everything automatically

Use helper scripts from project root:

```bash
./scripts/deploy.sh --auto-approve
```

This runs in order:
1. Terraform apply in `terraform-eks/`
2. Terraform apply in `terraform-jenkins/`
3. `aws eks update-kubeconfig` (if output + region are available)

### 3. Wait for Jenkins bootstrap to finish

The Jenkins EC2 uses `user-data.sh` to install Jenkins, Docker, kubectl, eksctl, Terraform, and AWS CLI.

Check status from SSM or SSH:

```bash
sudo tail -f /var/log/jenkins-user-data.log
```

Then verify tools:

```bash
docker --version
aws --version
kubectl version --client
```

### 4. Configure Jenkins credentials (one time)

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

### 5. Create Jenkins pipeline job

Create a Pipeline job and point it to this repository:
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: your repo URL
- Branch: `main`
- Script Path: `Jenkinsfile`

### 6. Run CI/CD pipeline

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

1. User-data did not install tools on Jenkins EC2
- Cause: bootstrap still running or failed.
- Fix: check `/var/log/jenkins-user-data.log` and `/var/log/cloud-init-output.log`.

2. `kubectl` unauthorized in Jenkins
- Cause: AWS identity lacks EKS access.
- Fix: grant the Jenkins AWS identity proper access to the EKS cluster.

3. Docker push fails
- Cause: wrong Docker Hub credentials (`DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN`).
- Fix: recreate credential with valid Docker Hub token.

4. Jenkins cannot start pipeline tools
- Verify on Jenkins EC2:
```bash
docker --version
aws --version
kubectl version --client
```

5. Terraform apply fails in Jenkins module
- If using SSH, confirm `key_name` exists in the same region.
- If not using SSH, set `key_name = null` and connect with SSM.

6. `docker ps` fails in SSM session without sudo
- Reconnect SSM session after bootstrap (group membership is applied at login).
- Confirm `ssm-user` is in docker group: `id ssm-user`

## Cleanup

```bash
./scripts/destroy.sh --auto-approve --yes
```

## 🤝 Contribution

Pull requests are welcome. For major changes, please open an issue first.

## 👨‍💻 Author

**Joseph Mbatchou**

• DevOps / Cloud / Platform  Engineer   
• Content Creator / AWS Builder

## 🔗 Connect With Me

🌐 Website: [https://platform.joebahocloud.com](https://platform.joebahocloud.com)

💼 LinkedIn: [https://www.linkedin.com/in/josephmbatchou/](https://www.linkedin.com/in/josephmbatchou/)

🐦 X/Twitter: [https://www.twitter.com/Joebaho237](https://www.twitter.com/Joebaho237)

▶️ YouTube: [https://www.youtube.com/@josephmbatchou5596](https://www.youtube.com/@josephmbatchou5596)

🔗 Github: [https://github.com/Joebaho](https://github.com/Joebaho)

📦 Dockerhub: [https://hub.docker.com/u/joebaho2](https://hub.docker.com/u/joebaho2)

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.