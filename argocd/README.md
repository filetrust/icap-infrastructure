## Guide to install and using ArgoCD

ArgoCD can be used through your CLI or a GUI - it is currently set up to manually sync new changes from the "main" branches of all the repos that contain the charts for each service. 

The future aim would be to have a "staging" environment and a "production" environment. Changes would be automatically deployed to "staging" as this would be a mirror copy of "production" - then if all was well with the upgrade on "staging" then we merge the changes to "main" branch, which is turn upgrades that cluster automatically too.

ArgoCD is very easy to install and set up - if you want to get it working on your current machine, follow the details below. 

## Table of contents

- [Guide to install and using ArgoCD](#guide-to-install-and-using-argocd)
- [Table of contents](#table-of-contents)
  - [Install ArgoCD](#install-argocd)
  - [Install ArgoCD CLI tool](#install-argocd-cli-tool)
    - [Linux](#linux)
    - [Mac](#mac)
    - [Windows](#windows)
  - [Accessing the Argo CD API Server](#accessing-the-argo-cd-api-server)
  - [Login using CLI or GUI](#login-using-cli-or-gui)
    - [CLI Login](#cli-login)
    - [GUI Login](#gui-login)
  - [Register a Cluster to Deploy apps to](#register-a-cluster-to-deploy-apps-to)
  - [How to deploy using ArgoCD](#how-to-deploy-using-argocd)
  - [Check status of ArgoCD apps](#check-status-of-argocd-apps)
    - [Sync an ArgoCD app](#sync-an-argocd-app)
  - [Commands to deploy all services using ArgoCD](#commands-to-deploy-all-services-using-argocd)
  - [ArgoCD Cheat Sheet](#argocd-cheat-sheet)
    - [Sync all apps](#sync-all-apps)
    - [Delete all apps](#delete-all-apps)
    - [Add context for easy switching between clusters](#add-context-for-easy-switching-between-clusters)


### Install ArgoCD

Installation of ArgoCD only needs to be done on a fresh cluster - this does not apply to any current clusters running ArgoCD already.

Requirements

- Installed kubectl cli tool
- Have kubeconfig files set up (default location is ~/.kube/config)

The config is easily populated using a command like below:

```bash
az aks get-credentials --name <cluster name> --resource-group <cluster resource group>
```

Next to install the required services you would use the following commands:

```bash
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

This creates the namespace "argocd" and installs all the relevant services for the Argo server to run.

### Install ArgoCD CLI tool

You can interact with ArgoCD through the CLI or the gui. To install the cli tool, follow the below instructions:

#### Linux

Set up an environment variable to assign the most recent version number

```bash
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
```

Next use curl to download the most recent Linux version:

```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
```

Lastly make the argocld CLI executable:

```bash
chmod +x /usr/local/bin/argocd
```
#### Mac

Use homebrew to install:

```bash
brew install argocd
```

#### Windows

Download With Powershell: Invoke-WebRequest¶
You can view the latest version of Argo CD at the link above or run the following command to grab the version:

```powershell
$version = (Invoke-RestMethod https://api.github.com/repos/argoproj/argo-cd/releases/latest).tag_name
Replace $version in the command below with the version of Argo CD you would like to download:
```

```powershell
$url = "https://github.com/argoproj/argo-cd/releases/download/" + $version + "/argocd-windows-amd64.exe"
$output = "argocd.exe"

Invoke-WebRequest -Uri $url -OutFile $output
```
Also please note you will probably need to move the file into your PATH.

After finishing the instructions above, you should now be able to run argocd commands

### Accessing the Argo CD API Server

In order to access the Argo CD API Server you use the following command to expose the external IP address. For future iterations of ArgoCD we can look to utilise SSO and SSL as extra layers of security. For now we are using basic http and manually adjusting passwords.

So to access you would need to use following command to change the argo-server service type to "LoadBalancer":

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Now run the following to get the public IP:

```bash
kubectl get svc -n argocd argocd-server

NAME            TYPE           CLUSTER-IP   EXTERNAL-IP    PORT(S)                      AGE
argocd-server   LoadBalancer   x.x.x.xxx   xxx.xx.xxx.xx   80:32117/TCP,443:30284/TCP   4d1h
```

Then if you go to the public IP you will be met by the login screen for ArgoCD

### Login using CLI or GUI

#### CLI Login

The password that is autogenerated to be the pod name of the Argo CD API Server. You can find this out with the following command:

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

Using the username "admin" and the password above, login using the public IP of ArgoCD

```bash
argocd login <public IP>
```

Once logged in you will need to change the password

```bash
argocd account update-password
```

Once you're logged in you have full access to all the Argocd CLI commands and can deploy new charts or sync existing charts.

#### GUI Login

Pretty simple - go to the public IP and use the username "admin" and the password from the below command:

```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

### Register a Cluster to Deploy apps to

This is required if you want to deploy to external clusters using ArgoCD. Follow the below to add clusters:

```bash
argocd cluster add
```

Choose a context name from the list and supply it to the following command:

```bash
argocd cluster add <context name>
```

The above command installs a ServiceAccount (argocd-manager), into the kube-system namespace of that kubectl context, and binds the service account to an admin-level ClusterRole. Argo CD uses this service account token to perform its management tasks (i.e. deploy/monitoring).

### How to deploy using ArgoCD

The next part will explain what you need to set up the deployment of the services. Once these are set they will remain in the apps list, where you can sync any new merges on the branch you have added.

Now you have the cluster added you can get the cluster server address using the below command:

```bash
kubectl cluster-info
Kubernetes master is running at https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443
CoreDNS is running at https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

The following command is pretty self explanatory but you can use "argocd app create --help" to see a full breakdown if needed:

```bash
argocd app create adaptation-service-main --repo https://github.com/filetrust/icap-infrastructure --path adaptation --dest-server https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443 --dest-namespace icap-adaptation --revision main
```

The above will then appear in the argocd apps list and can be synced whenever the are new updates on that repo.

### Check status of ArgoCD apps

If you want to check the status of an ArgoCD app you would use the following:
```bash
argocd app list 

NAME                        CLUSTER                                                 NAMESPACE              PROJECT  STATUS     HEALTH    SYNCPOLICY  CONDITIONS  REPO                                              PATH                   TARGET
adaptation-service-main     https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443  icap-adaptation        default  Synced     Healthy   <none>      <none>      https://github.com/filetrust/icap-infrastructure  adaptation             main
management-ui-main          https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443  management-ui          default  Synced     Healthy   <none>      <none>      https://github.com/filetrust/icap-infrastructure  management-ui          main
policy-management-api-main  https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443  icap-adaptation        default  Synced     Degraded  <none>      <none>      https://github.com/filetrust/icap-infrastructure  policy-management-api  main
rabbitmq-main               https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443  icap-adaptation        default  Synced     Healthy   <none>      <none>      https://github.com/filetrust/icap-infrastructure  rabbitmq               main
transaction-event-api-main  https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443  transaction-event-api  default  OutOfSync  Healthy   <none>      <none>      https://github.com/filetrust/icap-infrastructure  transactioneventapi    main
```

The status bar tells if you if its "synced" or "out of sync" and you can also see the health of the deployments as well.

#### Sync an ArgoCD app

When new features are added you can easily sync these to the current cluster by using the simple command below:

```bash
argocd app sync adaptation-service-main
```

This will sync the new changes that have been merged into the "main" branch of the "icap-infrastructure" repo. It will output any errors and give you a status of the app at completion.

### Commands to deploy all services using ArgoCD

Adaptation service
```bash
argocd app create adaptation-service-main --repo https://github.com/filetrust/icap-infrastructure --path adaptation --dest-server <cluster url> --dest-namespace icap-adaptation --revision main
```

Rabbitmq-operator
```bash
argocd app create rabbitmq-operator-main --repo https://github.com/filetrust/icap-infrastructure --path rabbitmq-operator --dest-server <cluster url> --dest-namespace default --revision main
```

Rabbitmq-service
```bash
argocd app create rabbitmq-service-main --repo https://github.com/filetrust/icap-infrastructure --path rabbitmq-service --dest-server <cluster url> --dest-namespace icap-adaptation --revision main
```

Icap-administration
```bash
argocd app create icap-administration-main --repo https://github.com/filetrust/icap-infrastructure --path administration --dest-server <cluster url> --dest-namespace icap-administration --revision main
 ```

Icap-ncfs
```bash
argocd app create icap-ncfs-main --repo https://github.com/filetrust/icap-infrastructure --path ncfs --dest-server <cluster url> --dest-namespace icap-ncfs --revision main
 ```

 If you want to deploy the *Develop* branch then change the *--revision* to *Develop*

### ArgoCD Cheat Sheet

#### Sync all apps 

```bash
argocd app list -o name | xargs argocd app sync
```

#### Delete all apps

```
argocd app list -o name | xargs argocd app sync
```

#### Add context for easy switching between clusters

Firstly you will need to get the public IP address of the Argocd server

```
kubectl get svc -n argocd argocd-server
```

Then you can use the following command to login but it will also add it to the context as well

```
argocd login -n <name of cluster or context> <Argo Server IP or hostname>
```
Now when you run the following it will show output the contexts you can change too. 
```
argocd context
CURRENT  NAME      SERVER
         North-Eu  xxx.xxx.xxx.xxx
         US-East   xxx.xxx.xxx.xxx
*        UK-South  xxx.xxx.xxx.xxx
```