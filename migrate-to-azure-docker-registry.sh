#!/bin/bash

loginToAcr () {
  accessToken=$(az acr login --name gwicapcontainerregistry --expose-token | jq -r '.accessToken')
  docker login gwicapcontainerregistry.azurecr.io --username 00000000-0000-0000-0000-000000000000	--password "$accessToken"
}

loginToAcr

shopt -s dotglob

find * -prune -type d | while IFS= read -r d; do
    echo "$d"
    cd $d

    helm template . | grep -i "image:" | while read -r line; do
      sed -e "s/image: //" -e "s/baseImage: //" | while read -r line; do
        while [[ $line == *'"'* ]]; do
          line=${line#*'"'}; line=${line%'"'*};
        done

        echo "\n\nDocker registry url is $line"
        docker pull $line;
        docker tag $line gwicapcontainerregistry.azurecr.io/$line
        docker push gwicapcontainerregistry.azurecr.io/$line
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n"
      done
    done

    cd ..
done

