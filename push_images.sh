#!/usr/bin/env bash

main_dir="$PWD"
images_dir="$main_dir/_images"
glasswallRegistry="gwicapcontainerregistry.azurecr.io"
final_registry="$1"
echo "Final registry is:"
echo $final_registry
listofimages="$images_dir/values.yaml"

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

importImages() {

  for img in $(yq read -p p "$listofimages" 'imagestore.*'); do
    echo "List of images is:" $listofimages
    registry=$(yq read "$listofimages" "$img.registry")
    repository=$(yq read "$listofimages" "$img.repository")
    tag=$(yq read "$listofimages" "$img.tag")

    repository_name=""
    image_name=""
    image_relative_path=""
    image_absolute_path=""
    gw_image_full_name=""
    client_image_full_name=""
    client_image_name_no_tag=""
    if [[ $repository == *"/"* ]]; then
      echo "It contains '/'"
      repository_name="${repository%%/*}"
      image_name=${repository##*/}
      client_image_name_no_tag="$final_registry/$repository_name/$image_name"
      image_relative_path="$final_registry/$repository_name/$image_name:$tag"
      gw_image_full_name="$glasswallRegistry/$repository_name/$image_name:$tag"
      client_image_full_name="$final_registry/$repository_name/$image_name:$tag"
      image_absolute_path="$images_dir/$gw_image_full_name.tgz"
    else
      echo "It doesn't contain '/'"
      repository_name=""
      image_name=${repository##*/}
      client_image_name_no_tag="$final_registry/$image_name"
      image_relative_path="$final_registry/$image_name:$tag"

      if [[ $repository_name == *""* ]]; then
        gw_image_full_name="$glasswallRegistry/$image_name:$tag"
      else
        gw_image_full_name="$glasswallRegistry/$repository_name/$image_name:$tag"
      fi

      client_image_full_name="$final_registry/$image_name:$tag"
      image_absolute_path="$images_dir/$gw_image_full_name.tgz"
    fi
    echo "Final repository name:" "$repository_name"
    echo "Final image name is:" "$image_name"
    echo "Image relative path is:" "$image_relative_path"
    printf "  %s\t->\t%s\n" "$registry$repository:$tag" "$image_relative_path"

    image_relative_path="$images_dir/$gw_image_full_name.tgz"
    printf "\n  %s\t->\t%s\n" "Final file name:" "$gw_image_full_name"
    printf "\n  %s\t->\t%s\n" "Final full file name:" "$client_image_full_name"
    printf "\n  %s\t->\t%s\n\n" "Image relative path:" "$image_relative_path"
    printf "\n  %s\t->\t%s\n\n" "Image absolute path:" "$image_absolute_path"

    image_exists="$(docker images -q $client_image_name_no_tag 2> /dev/null)"
    echo "Does image exists?" $image_exists

    if [[ $image_exists == "" ]]; then
      echo "No."
      echo "Loading image..."

      docker load < "$image_absolute_path"
      echo "Image loaded:" $image_absolute_path

    else
      echo "Yes!"
      echo "Image ID is:" $image_exists
    fi

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

az acr login --name $final_registry
tar -zxvf _images.tgz

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
