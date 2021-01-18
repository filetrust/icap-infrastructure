#!/usr/bin/env bash

main_dir="$PWD"
rm -R -f "$main_dir/_images"
mkdir "$main_dir/_images"
images_dir="$main_dir/_images"

final_registry="gwicapcontainerregistry.azurecr.io/"

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

registriesLogin() {
  printf "Logging into registries\n"
  accessToken=$(az acr login --name gwicapcontainerregistry --expose-token 2>/dev/null | jq -r '.accessToken')
  echo -n "$accessToken" | docker login gwicapcontainerregistry.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password-stdin >/dev/null
  dockerHubToken=$(az keyvault secret show --vault-name gw-icap-keyvault --name Docker-PAT | jq -r '.value')
  dockerHubUsername=$(az keyvault secret show --vault-name gw-icap-keyvault --name Docker-PAT-username | jq -r '.value')
  echo -n "$dockerHubToken" | docker login --username "$dockerHubUsername" --password-stdin >/dev/null
  printf "Login succeeded\n"
}

pullImages() {
  for img in $(yq read -p p values.yaml 'imagestore.*'); do
    registry=$(yq read values.yaml "$img.registry")
    repository=$(yq read values.yaml "$img.repository")
    tag=$(yq read values.yaml "$img.tag")
    printf "  %s\t->\t%s\n" "Registry" "$registry"
    printf "  %s\t->\t%s\n" "Repository" "$repository"
    printf "  %s\t->\t%s\n" "Tag" "$tag"
    printf "  %s\t->\t%s\n" "$registry$repository:$tag" "$final_registry$repository:$tag"
    docker pull -q "$registry$repository:$tag" >/dev/null
    docker tag "$registry$repository:$tag" "$final_registry$repository:$tag"

    repository_name=${repository%%/*}
    image_name=${repository##*/}
    echo "Repository name:" "$repository_name"
    echo "Image name is:" "$image_name"

    current_helm_chart_dir=$images_dir/$final_registry$repository_name
    mkdir -p $current_helm_chart_dir
    echo "Current helm chart destination directory..." "$current_helm_chart_dir"

    final_file_name="$current_helm_chart_dir/$image_name:$tag.tar"
    echo "Final file name" "$final_file_name"

    docker save $registry$repository:$tag > $final_file_name
    echo "Image saved"
    echo ""
    echo ""
    echo ""
    echo ""
  done
  # zip all images in a tar ball
  # instructions needs to be added to the support maintenance document
}

createTarFile() {
  tar_file="_images.tar"
  if [ -f "$tar_file" ]; then
    echo "Removing '_images.tar'..."
    rm _images.tar
    echo "'_images.tar' removed."
  fi

  rm -rf "$images_dir/$final_registry/*.tar" && tar -cvf _images.tar _images
}

checkPrereqs

set -e
set -o pipefail

registriesLogin

find . -maxdepth 1 -mindepth 1 -type d | while read -r d; do
  cd $d

  if [[ -f values.yaml ]]; then
    printf "\nNow processing %s\n" "$d"
    pullImages
    printf "\n"
  else
    printf "Skipping %s; no values file\n" "$d"
  fi
  cd ..
done

createTarFile
