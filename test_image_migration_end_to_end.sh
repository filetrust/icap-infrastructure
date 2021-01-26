#!/usr/bin/env bash

registry="$1"

az acr create --resource-group gw-icap-container-registry-resource-group \
  --name $registry --sku Basic

az acr login --name $registry

./pull_images.sh && ./push_images.sh $registry.azurecr.io

