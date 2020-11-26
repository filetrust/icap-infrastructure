### Deploy services using helm

Guide to deploy the charts using Helm, please follow commands below:

***All commands need to be run from the root directory for the paths to be correct***

You will also need:

- Helm installed
- Kubectl installed
- CLI Access

#### Adaptation & RabbitMQService

```bash
helm install ./adaptation -n icap-adaptation --generate-name
```
The adaptation service does tend to restart 5/6 times before it hits *Running* status.

#### RabbitMQ Service

```bash
helm install ./rabbitmq -n icap-adaptation --generate-name
```

#### Administration Services

```bash
helm install ./administration -n icap-administration --generate-name
```

#### Check services

Once they have all been installed you can check them all using Kubectl:

```bash
kubectl get pods -A
```

## Optional Items

The below can also be used to enable plugins for the rabbitmq management console.
```bash
kubectl exec -it -n icap-adaptation rabbitmq-controller-<pod name> -- /bin/bash -c "rabbitmq-plugins enable rabbitmq_management"
```

The below command will forward a connection to the rabbitmq management console.

```bash
kubectl port-forward -n icap-adaptation rabbitmq-controller-<pod name> 8080:15672
```

Then you can access it via [http://localthost:8080/](http://localthost:8080/)