# RabbitMQ operator 

The below is a guide to standing up the Rabbitmq-Operator to work within AKS.

### Install RabbitMQ Cluster Operator

The below command will install the operator for you:

```bash
helm install ./rabbit-operator --generate-name
```

Once this has been created, you can then install the service via helm or argocd

Helm
```bash
helm install ./rabbit-service -n icap-adaptation --generate-name
```
Argocd
```bash
argocd app create rabbitmq-service-main --repo https://github.com/filetrust/icap-infrastructure --path rabbitmq --dest-server https://gw-icap-k8s-f17703a9.hcp.uksouth.azmk8s.io:443 --dest-namespace icap-adaptation --revision main
```