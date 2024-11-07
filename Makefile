#PLEASE NOTE * This file will not work but is just a basic example starting point.

SHELL := /bin/bash

REPO=https://github.com/ericgraf/technical-challenge

VERSION=0.0.0
APPNAME=php/php-demo

ifndef AWS_SECRET_ACCESS_KEY
	exit 1
endif
ifndef AWS_ACCESS_KEY_ID
	exit 1
endif
ifndef TF_VAR_CF_API_EMAIL
	exit 1
endif
ifndef TF_VAR_CF_API_TOKEN
	exit 1
endif
ifndef AWS_DEFAULT_REGION
	exit 1
endif
ifndef EKS_CLUSTER_NAME
	exit 1
endif

gh-set-secrets:
	gh secret set TF_VAR_CF_API_EMAIL \
		--body "${TF_VAR_CF_API_EMAIL}" \
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

## APPLICATION

#TODO add signing to the build process

package:
	cd php-app/charts ; \
		helm package php-app ; \
		helm push  php-app-0.1.5.tgz oci://zot1.<example>/app-charts

build:
	cd php-app/php-src ; \
		docker buildx build \
			--builder=kube \
			--platform=linux/amd64 \
			-t zot1.<example>/${APPNAME}:${VERSION} \
			--push .

deploy:
	cd php-app/charts ; \
		helm upgrade --install  --set image.tag=${VERSION} test-app ./php-app

build-and-deploy: build deploy

## INFRASTRUCTURE

bootstrap-dev:
	cd terraform/bootstrap ;\
		terraform fmt ;\
		terraform init --upgrade ; \
		terraform validate && \
		terraform apply -auto-approve


setup-k8s:
	cd terraform/kubernetes ;\
		terraform fmt ;\
		terraform init --upgrade; \
		terraform validate && \
		terraform apply -auto-approve
		
config-k8s:
	cd terraform/kubernetes-config ; \
		terraform init --upgrade; \
		terraform fmt ;\
		terraform validate &&  \
		terraform apply -auto-approve

## destroy infrastucture

destroy-resources:
	cd terraform/kubernetes-config ; \
		terraform destroy -auto-approve

	cd terraform/kubernetes ; \
		terraform destroy -auto-approve

	cd terraform/bootstrap ; \
		terraform destroy

## github actions

local-test:
	gh act -P self-hosted=-self-hosted 

local-test-app:
	gh act -P self-hosted=-self-hosted -W ./.github/workflows/deploy-k8s-app.yaml --verbose