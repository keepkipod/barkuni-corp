# Barkuni Corp App

A DevOps demonstration repository for building, deploying, and managing a containerized Flask API using modern DevOps tools. This project provisions AWS infrastructure with Terragrunt, deploys a Kubernetes cluster (locally with Kind or on AWS EKS), and automates CI/CD with GitHub Actions.

## Overview

This repository showcases:
- **Flask API Application:** A simple Python REST API that displays a welcome message and an endpoint (`/api/pods`) to list pods running in the `kube-system` namespace.
- **Containerization & CI/CD:** Dockerizing the application and automating image builds and pushes using GitHub Actions.
- **Infrastructure as Code:** Provisioning an AWS EKS cluster, VPC, ALB, and Route53 records using Terraform modules and Terragrunt configuration.
- **Kubernetes Deployment:** Deploying the application with Helm charts and Kubernetes manifests.
- **EC2 Provisioning Script:** A Python (boto3) script for interactively launching EC2 instances in a specific subnet with a chosen OS.
- **Task Automation:** A Taskfile that orchestrates the local development setup, from cluster creation with Kind to deploying the application.
- **Initial AWS Setup:** A shell script (`initial-aws-setup.sh`) that creates the necessary IAM role (expected by Terragrunt) to manage AWS resources.

## Repository Structure

```
barkuni-corp/
├── app/                  # Flask API source, Dockerfile, and requirements for the API container
├── ec2-script/          # Python script (using boto3) to launch an EC2 instance interactively
├── infra/               # Terraform/Terragrunt configurations for AWS infrastructure (EKS, ALB, Route53, etc.)
├── k8s/                 # Helm chart and Kubernetes manifests for deploying the app
├── Makefile              # Makefile for installing dependencies (Taskfile, Kind)
├── Taskfile.yml          # Tasks for setting up and deploying the local cluster and application
├── kind-config.yaml      # Kind cluster configuration file for local testing
├── ing.yaml              # Ingress manifest for exposing the app via ALB / Route53
├── build-and-push.yaml   # GitHub Actions workflow for Docker image build and push
├── initial-aws-setup.sh  # Shell script to create the IAM role expected by Terragrunt
└── README.md             # This documentation file
```

## Prerequisites

- **Local Environment:** Docker, Kind, Helm, Terraform, Terragrunt, and Python 3.x.
- **AWS:** AWS CLI configured with proper credentials and permissions.
- **Additional Tools:** Git for version control and GitHub Actions for CI/CD.

## Setup and Deployment

### Local Development Using Kind

1. **Install Dependencies:**
   Run the following command to install Taskfile and Kind if they aren’t already installed:
   ```bash
   make
   ```

2. **Deploy the Local Cluster and Application:**
   Execute the full deployment task:
   ```bash
   task deploy-all
   ```
   If you don't already have it, [install Task first](https://taskfile.dev/).  
   
   This command will:
   - Create a local Kind cluster.
   - Wait for the cluster nodes to be ready.
   - Set up required Helm repositories and deploy the ingress controller.
   - Build the Docker image for the Flask API and load it into the Kind cluster.
   - Deploy the application via Helm, and set up port forwarding for local access.

### AWS Infrastructure Deployment

- Use the configurations in the `infra/` directory (Terragrunt/Terraform) to provision AWS resources (EKS, VPC, ALB, Route53).
- Adjust variables in the Terragrunt files as needed.
- Run the deployment with:
  ```bash
  terragrunt apply-all
  ```

### EC2 Instance Launch Script

1. **Install Dependencies:**
   ```bash
   pip install -r ec2-script/requirements.txt
   ```

2. **Run the Script:**
   Execute the EC2 launcher by running:
   ```bash
   python ec2-script/ec2.py
   ```
   Follow the interactive prompts to select a subnet, security groups, and OS type, then launch an EC2 instance.

### Initial AWS Setup Script

Before provisioning your infrastructure with Terragrunt, run the `initial-aws-setup.sh` script. Its purpose is to create the required IAM role (with appropriate policies) that Terragrunt expects to exist for managing AWS resources.

## Accessing the Application

- **Locally:** After using `task deploy-all`, access the Flask API at [http://localhost:8000](http://localhost:8000).
- **On AWS:** The ALB and Route53 settings expose the application at a DNS (e.g., `test.vicarius.xyz`), which shows the welcome page and API endpoints.

## CI/CD Pipeline

- The GitHub Actions workflow (`build-and-push.yaml`) builds the Docker image, pushes it to AWS ECR, updates the Helm chart image tag, and commits changes back to the repository.