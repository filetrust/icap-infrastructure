## ICAP Infrastructure

A collection of Helm charts to stand up a working ICAP Service within Azure AKS, using Terraform for the infrastructure, and ArgoCD or Helm for the deployments.

## Table of Contents

- [ICAP Infrastructure](#icap-infrastructure)
- [Table of Contents](#table-of-contents)
- [icap-terraform-aks-deployment](#icap-terraform-aks-deployment)
- [Pre-requisites](#pre-requisites)
- [Create Terraform Principal](#create-terraform-principal)
- [Add a Service Principle to Azure Key Vault](#add-a-service-principle-to-azure-key-vault)
- [Initialise Terraform and deploy to Azure](#initialise-terraform-and-deploy-to-azure)
  - [Create Secrets & Namespaces](#create-secrets--namespaces)
  - [Deploy services](#deploy-services)
- [How to structure values.yaml in a Helm Chart](#how-to-structure-valuesyaml-in-a-helm-chart)
 
## icap-terraform-aks-deployment

The steps below are what is required to stand up a working cluster running the latest ICAP stack. 

## Pre-requisites 

In order to follow along with this guide you will need the following:

- Helm
- Terraform
- Kubectl
- AZ CLI - with permissions to create resources
- OpenSSL
- Bash (or similar) terminal
- Cloned the repository below:
  - [Terraform AKS IaC](https://github.com/filetrust/aks-deployment-icap)

## Create Terraform Principal

Next we will need to create a service principle that Terraform will use to authenticate to Azure RBAC. You will not need to log in as the service principle but you will need to add the details that get created into the Azure Vault we created earlier on. Terraform will then use these credentials to authenticate to Azure.

The script can be found in the **./scripts/terraform_scripts/** folder and is called *createTerraformServicePrinciple.sh*. Running the script will create the following:

- Service Principle
- Update or create *provider.tf* file

When the script runs you will be prompted with 

```bash
The provider.tf file exists.  Do you want to overwrite? [Y/n]:
```

Answer "yes" and then it will create the terraform principle.

Once the script has run take note of the Username and password for the service account, and add them to the following environment variables:

```
export CLIENT_ID_SECRET=<insert secret>
export CLIENT_SECRET=<insert secret>
```

## Add a Service Principle to Azure Key Vault

The below commands will add the service principle credentials into the Azure Key Vault. Please note that the names need to match exactly otherwise the Terraform code will not be able to retrieve them.

Set the following environment variables before running the next commands:

```
export SP_USERNAME=spusername
export SP_PASSWORD=sppassword
```

Use the following to add the secrets:

```bash
az keyvault secret set --vault-name $VAULT_NAME --name $SP_USERNAME --value $CLIENT_ID_SECRET

az keyvault secret set --vault-name $VAULT_NAME --name $SP_PASSWORD --value $CLIENT_SECRET
```

## Initialise Terraform and deploy to Azure

We will next be initialising Terraform and making sure everything is ready to be deployed.

All of the below commands are run in the root folder:

```bash
terraform init
```

Next run terraform validate/refresh to check for changes within the state, and also to make sure there aren't any issues.

```bash
terraform validate
Success! The configuration is valid.

terraform refresh
```

Now you're ready to run apply and it should give you the following output

```bash
terraform apply

Plan: 1 to add, 2 to change, 1 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Enter "yes" and wait for it to complete

Once this completes you should see all the infrastructure for the AKS deployed and working.

### Create Secrets & Namespaces

Before we begin you will need to run the following command to get the details of the cluster that has just been deployed.

```bash
az aks get-credentials --name gw-icap-aks --resource-group gw-icap-aks-deploy
```

In this stage we will be deploying the helm charts to the newly created cluster. Before we jump right into deploying the charts, there is some house keeping that needs to be done. We will need to add some secrets the Kubernetes in order for some of the services to do the following:

- Access File Share in an Azure Storage account
- Pull private images from DockerHub

We can achieve this by using the script within **./scripts/k8_scripts/** *create-ns-docker-secrets-<region>.sh* which will be in the scripts folder and do the following:

- Creates all namespaces for ICAP services
- Add secrets for the following
  - Dockerhub Service Account
  - File Share account name and account key
  - Certs for TLS

Before running this script you need run the below command to create the TLS certs.

```bash
openssl req -newkey rsa:2048 -nodes -keyout tls.key -x509 -days 365 -out certificate.crt
```

You will also need to make sure that the secrets are in the relivant key vault. This can be done by using the following script and adding the secrets to the variables show:

```
SECRET01=""
SECERT02=""
SECERT03=""
```

The rest of the secrets are gained by using Azure CLI or by using commands to generate passwords.

Next run the script:

```bash
./create-ns-docker-secrets-<region>.sh
```

Once this script has completed, we can move onto deploying the services to the cluster.

### Deploy services

Next we will deploy the services using either Helm or Argocd. Both of the Readme's for each can be found below:

[ArgoCD Readme](/argocd/README.md)

[Helm Readme](/helm/README.md)

***All commands need to be run from the root directory for the paths to be correct***

## How to structure values.yaml in a Helm Chart

We've written a script (migrate-to-azure-docker-registry.sh) which migrates all our docker images to a private azure container registry.
The script expects us to define our docker image registry, repo and tag in values.yaml file in the following structure:
E.g of a busybox docker image:
 ```
imagestore:
  busybox:
    registry: ""
    repository: library/busybox
    tag: latest
 ```

We've also written another script called update-secrets.sh [https://github.com/filetrust/rancher-git-server] which dynamically replaces all secret values with values from azure vault.
This script expects us to define our secret key, value pairs in values.yaml in the following format:

 ```
secrets:
  transactionstore:
    accountName: "<<https://gw-icap-keyvault.vault.azure.net/secrets/transactionStoreAccountName>>"
    accountKey: "<<https://gw-icap-keyvault.vault.azure.net/secrets/transactionStoreAccountKey>>"
 ```

The url refers to a key on azure key vault secrets. 
The script looks up for the string "<<http url link to azure key vault secret>>" and replaces it with secret key value. 