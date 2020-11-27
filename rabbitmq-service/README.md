# RabbitMQ Service

The below is a guide to standing up the Rabbitmq-Operator to work within AKS.

### Install RabbitMQ Cluster Service

**PREREQ**

You must have deployed the RabbitMQ Cluster Operator before deploying the service. Please see rabbitmq-operator chart README for details.

You can then install the service via helm or argocd

Helm
```bash
helm install ./rabbit -n icap-adaptation --generate-name
```
Argocd
```bash
argocd app create rabbitmq-service-main --repo https://github.com/filetrust/icap-infrastructure --path rabbitmq --dest-server https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443 --dest-namespace icap-adaptation --revision main
```

