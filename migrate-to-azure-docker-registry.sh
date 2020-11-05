#!/usr/bin/env bash

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
        printf "\n"
        echo "Docker registry url is $line"
        printf "\n"
        docker pull $line


        IFS="/" read -a myarray <<< $line
        domain=${myarray[0]}
        newImageUrl=0

        if [[ $domain == *"."* ]]; then
          echo "It's a domain"
          newImageUrl=${line#${domain}}
          echo "New image url: ${newImageUrl}"
          newImageUrl=${newImageUrl#"/"}
          echo "New image url without start slash: ${newImageUrl}"
        else
          echo "Not a domain"
          newImageUrl=$line
          echo "New image url: ${newImageUrl}"
        fi
        printf "\n\nImage url is $newImageUrl"

        docker tag $line gwicapcontainerregistry.azurecr.io/$newImageUrl
        docker push gwicapcontainerregistry.azurecr.io/$newImageUrl

        printf "\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n"
      done

    cd ..
done

