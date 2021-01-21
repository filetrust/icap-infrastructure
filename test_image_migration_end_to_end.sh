#!/usr/bin/env bash

az acr create --resource-group gw-icap-container-registry-resource-group \
  --name imagesmigrationtest --sku Basic
az acr login --name imagesmigrationtest

./pull_images.sh && ./push_images.sh imagesmigrationtest.azurecr.io

