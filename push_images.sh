#!/usr/bin/env bash

main_dir="$PWD"
images_dir="$main_dir/_images"
glasswallRegistry="gwicapcontainerregistry.azurecr.io/"
finalRegistry="$1"
echo "Final registry is:"
echo $finalRegistry

checkPrereqs() {
  declare -a tools=("az yq find docker")
  for tool in ${tools[@]}; do
    printf "Checking for $tool..."
    toolpath=$(which $tool)
    if [[ $? != 0 ]]; then
      printf "%b" "\e[1;31m not found\e[0m\n"
    else
      printf "%b" "\e[1;36m $toolpath\e[0m\n"
    fi
  done
}

#registriesLogin() {
#  printf "Logging into registries\n"
#  accessToken=$(az acr login --name gwicapcontainerregistry --expose-token 2>/dev/null | jq -r '.accessToken')
#  echo -n "$accessToken" | docker login gwicapcontainerregistry.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin >/dev/null
#  dockerHubToken=$(az keyvault secret show --vault-name gw-icap-keyvault --name Docker-PAT | jq -r '.value')
#  dockerHubUsername=$(az keyvault secret show --vault-name gw-icap-keyvault --name Docker-PAT-username | jq -r '.value')
#  echo -n "$dockerHubToken" | docker login --username "$dockerHubUsername" --password-stdin >/dev/null
#  printf "Login succeeded\n"
#}

importImages() {

  for img in $(yq read -p p values.yaml 'imagestore.*'); do
    registry=$(yq read values.yaml "$img.registry")
    repository=$(yq read values.yaml "$img.repository")
    tag=$(yq read values.yaml "$img.tag")
    repository_name=${repository%%/*}
    image_name=${repository##*/}

    echo "Repository name:" "$repository_name"
    echo "Image name is:" "$image_name"
    printf "  %s\t->\t%s\n" "$registry$repository:$tag" "gwicapcontainerregistry.azurecr.io/$repository:$tag"

    images_directory="_images"
    gw_image_full_name="$glasswallRegistry$repository_name/$image_name:$tag"
    client_image_full_name="$finalRegistry/$repository_name/$image_name:$tag"
    image_relative_path="$images_dir/$gw_image_full_name.tgz"
    printf "\n  %s\t->\t%s\n" "Final file name:" "$gw_image_full_name"
    printf "\n  %s\t->\t%s\n\n" "Image imported:" "$image_relative_path"

    echo ""
    echo "$PWD"
    echo ""
    docker import "$image_relative_path" $gw_image_full_name
    echo "Image imported:" $gw_image_full_name

    docker tag "$gw_image_full_name" "$client_image_full_name"
    echo "Image tagged:" $client_image_full_name

    docker push $client_image_full_name
    echo "Image pushed:" $client_image_full_name
    echo ""
    echo ""
    echo ""
    echo ""
  done
}

checkPrereqs

set -e
set -o pipefail

#registriesLogin

#tar -zxvf _images.tgz

find . -maxdepth 1 -mindepth 1 -type d | while read -r d; do
  cd $d

  if [[ -f values.yaml ]]; then
    printf "\nNow processing %s\n" "$d"
    importImages
    printf "\n"
  else
    printf "Skipping %s; no values file\n" "$d"
  fi
  cd ..
done
