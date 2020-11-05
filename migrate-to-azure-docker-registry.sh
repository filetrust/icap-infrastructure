#!/bin/bash

loginToAcr () {
  accessToken=$(az acr login --name gwicapcontainerregistry --expose-token | jq -r '.accessToken')
  docker login gwicapcontainerregistry.azurecr.io --username 00000000-0000-0000-0000-000000000000	--password "$accessToken"
}

loginToAcr

shopt -s dotglob

find * -prune -type d | while IFS= read -r d; do
    printf "\nCurrent directory is: $d\n\n"
    cd $d

    helm template . | grep -i "image:" | while read -r line; do
        line=${line#"image: "}
        line=${line#"- image: "}
        line=${line#"baseImage: "}

        while [[ $line == *'"'* ]]; do
            line=${line#*'"'}; line=${line%'"'*};
        done

        printf "\n\nDocker registry url is $line"
        docker pull $line;

        line=${line#*"/"}
        printf "\n\nImage url is $line"

        docker tag $line gwicapcontainerregistry.azurecr.io/$line
        docker push gwicapcontainerregistry.azurecr.io/$line

        printf "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n"
      done

    cd ..
done

