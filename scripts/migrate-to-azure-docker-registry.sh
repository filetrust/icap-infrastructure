script input param is acr registry url

for each helm directory
  run helm template . and grep image repos
  for each image repo
    run docker pull image repo
    run docker tag to new acr registry
    run docker push to new acr registry

