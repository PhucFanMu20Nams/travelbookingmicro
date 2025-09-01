# Online Boutique Microservices Deployment with GitLab, Terraform & EKS

This project demonstrates how to deploy the **Online Boutique** microservice application using a **polyrepo approach**, leveraging **GitLab CI/CD**, **GitLab Container Registry**, **Terraform**, **Helm**, and **Amazon EKS**.  

It is part of a tutorial series I recorded for my **YouTube channel** (📺 link will be added here once published). The goal of this repository and its related projects is to serve as both a **learning resource** and a **practical guide** for engineers who want to explore modern DevOps practices with GitLab and AWS.

## 📌 Project Overview

- **Source Code**: Cloned from the [GoogleCloudPlatform microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo).
- **Repositories**:
  - 11 repositories created (one for each microservice).
  - 1 repository for **Helm charts**.
  - 1 repository for **EKS infrastructure**.
  - 1 repository for **OIDC Terraform setup**.
- **Workflow**:
  - Each microservice builds and pushes Docker images to the GitLab Container Registry.
  - The Helm repo `values.yaml` is updated with the new image URL and tag.
  - The Helm repo runs `helm lint` before merging changes into `main`.
  - Deployments target **Amazon EKS** with Terraform-managed infrastructure.
- **Authentication**: GitLab pipelines authenticate with AWS via **OIDC** (no static keys).
- **Add-ons**: AWS Load Balancer Controller and kube-prometheus-stack installed with `eks-addons`.

## 🏗 Architecture

The architecture of the deployment is documented in the [`architecture`](https://github.com/seunayolu/online-boutique/tree/main/architecture) folder.  

### Architecture Diagram
![Online Boutique Architecture](https://github.com/seunayolu/online-boutique/blob/main/architecture/online-boutique-arch.png?raw=true)

Key components include:

- **GitLab**: CI/CD pipelines, polyrepo management, triggers.
- **Terraform**: EKS cluster, VPC, OIDC, and add-ons.
- **Helm**: Chart templates for microservices deployment.
- **AWS EKS**: Managed Kubernetes cluster.
- **AWS Load Balancer Controller**: Provides ALB integration for SSL termination and ingress.
- **Prometheus & Grafana**: Installed via kube-prometheus-stack for observability.

## 📂 Repository Structure

| Repository / Folder | Purpose |
|----------------------|---------|
| `oidc-setup` | Terraform code to configure GitLab OIDC authentication with AWS. |
| `eksinfra` | Terraform code for deploying EKS, VPC, and add-ons. |
| `helm` | Helm charts for all 11 microservices. |
| `microservices/*` | Each of the 11 GitLab repositories for the microservices. |
| `architecture` | Architecture diagrams and design documentation. |

## ⚙️ CI/CD Workflows

Each microservice project contains a `.gitlab-ci.yml` pipeline with the following flow:

1. **Build & Push**  
   - Build Docker image.  
   - Push to GitLab Container Registry.

2. **Update Helm Repo**  
   - Clone Helm repo.  
   - Checkout feature branch (`feature/boutique-helm`).  
   - Update `values.yaml` with new image URL and tag (`$CI_COMMIT_SHORT_SHA`).  
   - Commit and push changes.

3. **Trigger Helm Lint**  
   - Helm repo pipeline is triggered automatically.  
   - Runs `helm lint` on the updated charts.  
   - On success, merge to `main` triggers deployment to EKS.

4. **SonarCloud Scanning**  
   - Static code analysis integrated via SonarCloud.

### Example Workflow Rule (Helm repo)
```yaml
workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH == "feature/boutique-helm" && $CI_PIPELINE_SOURCE == "pipeline"'
```

## 🚀 Deployment Steps

1. **Setup OIDC for GitLab → AWS**

   * Terraform configuration in [`oidc-setup`](https://github.com/seunayolu/online-boutique/tree/main/oidc-setup).
   * Removes the need for static IAM access keys.

2. **Deploy EKS Infrastructure**

   * Terraform code in [`eksinfra`](https://github.com/seunayolu/online-boutique/tree/main/eksinfra).
   * Uses:

     * `terraform-aws-eks` module
     * `terraform-aws-vpc` module
     * `eks-addons` for LB controller & monitoring stack

3. **Deploy Microservices via Helm**

   * Helm repo receives updated values from microservice pipelines.
   * `helm lint` validates charts.
   * Merge to `main` triggers deployment.

4. **Access Application**

   * Ingress managed via AWS Load Balancer Controller.
   * SSL termination configured on the ALB.
   * Application exposed with secure HTTPS endpoints.

## 🎯 Learning Objectives

This project helps you learn:

1. How to implement **GitLab polyrepo deployments**.
2. CI/CD for multiple programming languages (C#, Go, NodeJS, Python, Java).
3. How to use **GitLab trigger functions** for downstream pipelines.
4. Leveraging **Helm** for Kubernetes deployments in CI/CD.
5. Managing inter-repo updates (one repo updates another repo’s pipeline).
6. Using **eks-addons** to install Kubernetes tools.
7. Configuring SSL access via ALB and Load Balancer Controller.

## 🛠 Tech Stack & References

### C\#

* [Microsoft Artifact Registry](https://mcr.microsoft.com/en-us/)
* [.NET CLI Reference](https://learn.microsoft.com/en-us/dotnet/core/tools/)
* [NuGet Packages](https://www.nuget.org/)

### Go

* [Go Docker Image](https://hub.docker.com/_/golang)
* [Go CLI Reference](https://pkg.go.dev/cmd/go)

### NodeJS

* [Node Docker Image](https://hub.docker.com/_/node)
* [NPM CLI](https://docs.npmjs.com/cli/v11/commands)

### Python

* [Python Docker Image](https://hub.docker.com/_/python)
* [Python CLI Reference](https://docs.python.org/3/using/cmdline.html)
* [PyPI](https://pypi.org/)

### Java

* [OpenJDK Docker Image](https://hub.docker.com/_/openjdk) *(deprecated)*
* [Amazon Corretto](https://hub.docker.com/_/amazoncorretto)
* [Eclipse Temurin](https://hub.docker.com/_/eclipse-temurin)
* [Gradle CLI](https://docs.gradle.org/8.5/userguide/command_line_interface_basics.html)

### SonarCloud

* [SonarCloud](https://sonarcloud.io)
* [Sonar Scanner Docker](https://hub.docker.com/r/sonarsource/sonar-scanner-cli)
* [GitLab Integration Docs](https://docs.sonarsource.com/sonarqube-cloud/managing-your-projects/administering-your-projects/devops-platform-integration/gitlab/)

### Helm

* [ArtifactHub](https://artifacthub.io/)

## 🖥 How to Reproduce

1. Clone the repo:

   ```bash
   git clone https://github.com/seunayolu/online-boutique.git
   ```

2. Setup Terraform backends and initialize:

   ```bash
   cd eksinfra
   terraform init
   terraform apply
   ```

3. Configure GitLab OIDC → AWS roles using the `oidc-setup` folder.

4. Run CI/CD pipelines in GitLab for each microservice repo.

5. Deploy via Helm repo (triggered automatically).

---

## 🎥 Video Walkthrough

📺 *A detailed step-by-step walkthrough is available on my [YouTube Channel](https://youtube.com/).*
*(Link will be updated once the video is published.)*


