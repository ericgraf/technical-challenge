Under Docs


# Prerequisites and Setup instructions

## 1. initial setup and configuration
- Create an AWS account setup with correct permissions to EKS/S3/EBS/EC2/logs/kms.
- Create an AWS access key ans set the environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION`.
- Run the terraform bootstrap script to generate the AWS S3 terraform state bucket in the new AWS account
    - ```bash
        cd terraform/bootstrap ; \
		terraform init --upgrade; \
		terraform validate &&  \
		terraform apply -auto-approve
      ```
- Setup Cloudflare control of your domain
- Create a cloudflare api access key
    - Set the two environment variables `TF_VAR_CF_API_EMAI` and `TF_VAR_CF_API_TOKEN`
- Manually configure the domain name and other settings in the file in the two following locations
    - `/.github/env/*` 
    - `/terraform/kubernetes-config/helm-values/*-values.yaml`

## 2. GITHUB CI secretes and variables initial SETUP

Set the appropriate environment variables below and run the gh cli commands. OPTIONALY manually configure the secrets and variables in github through the web interface.

```bash
repository=https://github.com/ericgraf/technical-challenge

export TF_VAR_CF_API_EMAIL=""
export TF_VAR_CF_API_TOKEN=""
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export EKS_CLUSTER_NAME="k8s-prod"
export AWS_DEFAULT_REGION="us-east-2"


gh secret set TF_VAR_CF_API_EMAIL \
    --body "$TF_VAR_CF_API_EMAIL" \
    --repo ${REPO}
gh secret set TF_VAR_CF_API_TOKEN \
    --body "$TF_VAR_CF_API_TOKEN" \
    --repo ${REPO}

gh secret set AWS_ACCESS_KEY_ID \
    --body "$AWS_ACCESS_KEY_ID" \
    --repo ${REPO}
gh secret set AWS_SECRET_ACCESS_KEY \
    --body "$AWS_SECRET_ACCESS_KEY" \
    --repo ${REPO}

gh variable set EKS_CLUSTER_NAME \
    --body "$EKS_CLUSTER_NAME" \
    --repo ${REPO}
gh variable set AWS_DEFAULT_REGION \
    --body "$AWS_DEFAULT_REGION" \
    --repo ${REPO}

```

### 3. Manually trigger github actions to setup the infrastructure through github actions
- trigger CI-terraform-kubernetes 
 - This sets up the EKS cluster
- trigger CI-terraform-kubernetes-config workflow 
 - This sets up the kubernetes cluster with all the needed components and tools.

### 4. Install renovate github app into the repo
- Navigate to https://github.com/marketplace/renovate and install into org or personal github
- Navigate to repo setting and install github app

### 5. Setup self-hosted github runners
- Follow steps outlined here: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners

# Architecture

## Tools used
- Terraform
- Github Actions
- Docker buildx
- Amazon S3
- Kubernetes (EKS)
- Zot OCI Registry 
- Helm
- Cloudflare
- postgres-operator
- postgresdb
- symfony
- renovate

## IaC deployment Through Terraform

There are three terraform components 
- `Bootstrap` 
 - Creates the S3 tfstate bucket
- `Kubernetes` 
 - Creates the AWS EKS clusters with appropriate confitguration
- `Kubernetes config`
 - Configures kubernetes cluster and it's components.
  - Zot registry 
  - external-dns
  - postgres-operator
  - cert-manager
  - nginx ingress

## Component breakdown
## Zot Registry
https://zotregistry.dev/v2.1.0/

- OCI object store for helm and for docker images
- This does a Security Scan on the artifacts uploaded

## Postgress-operator 
- https://github.com/zalando/postgres-operator
- Createa a HA postgres database cluster for every new development environment
- A new postgres cluster is created by applying a postgresql CR

## cert-manager
- Creates a valid TLS certificate for each new ingress defined which in this case is every new deployment.

## Github Actions
- 4 workflows exist
 - terraform-destroy -> Destroys infrastructure resources
 - terraform-check-kubernetes -> Generate the AWS EKS cluster
 - terraform-check-kubernetes-config -> Configures the k8s cluster with the components
 - deploy-k8s-app -> builds and deploys the app when a new branch is created. If there is a new branch it will generate a new HA postgres db for that deployment.

## Renovate
https://www.mend.io/mend-renovate/
- Renovate updates and manages all dependencies. 




# Helpful commands

## Manually Destroy the infrastructure

```bash

export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""

cd terraform/kubernetes-config ; \
    terraform destroy -auto-approve

cd terraform/kubernetes ; \
    terraform destroy -auto-approve

cd terraform/bootstrap ; \
    terraform destroy -auto-approve

```

## Generate a local kubeconfig to the EKS cluster

```bash
export KUBECONFIG=`pwd`/eks.kubeconfig;\
cd ./terraform/kubernetes 
aws eks --region $(terraform output -raw region) update-kubeconfig \
		--name $(terraform output -raw cluster_name)
kubectl get nodes
```

# Improvements
Since this challenge is time restricted there is a list of improvements that would have been nice to implement but didn't have the time.

## Code improvements
- Run periodic cleanup
  - Use a k8s Cronjob that deletes development workspace every 24 hours
  - Configure Zot artifact keep rules
- Improve Chart and Container Release structure to fit use case
- Improve Renovate configuration to find all dependencies
- Improve Dockerfile
- Implement build avoidance/caching
- Properly flush out Makefile to help with local development

## Metrics

- Setup k8s cluster and support metrics and alerts ex:
-- loki
-- prometheus
-- grafna
-- alert-manager

## Security 

- Support SOPS secret management 
- Add signing to docker image and helm objects
  - Take advantage of the tools listed https://zotregistry.dev/v2.1.0/articles/building-ci-cd-pipeline/
- Have zot output security scan reports
- Add and configure AWS user IAM roles and groups to match company structure.
- Configure Zot registry to have login security
- Sanitize github workflow outputs.

## Documentation

- Add section on how users can do local development without having to commit to github to deploy.