#!/usr/bin/env bash

registry="$1"

az acr delete --name $registry -y

rm -rf _images

rm _images.tgz
