#!/usr/bin/env bash

main_dir="$PWD"
rm -R -f "$main_dir/_images"
mkdir "$main_dir/_images"
images_dir="$main_dir/_images"
touch "$main_dir/values.yaml"

final_registry="gwicapcontainerregistry.azurecr.io"

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

pullImages() {
  for img in $(yq read -p p values.yaml 'imagestore.*'); do
    registry=$(yq read values.yaml "$img.registry")
    repository=$(yq read values.yaml "$img.repository")
    tag=$(yq read values.yaml "$img.tag")
    printf "  %s\t->\t%s\n" "Registry" "$registry"
    printf "  %s\t->\t%s\n" "Repository" "$repository"
    printf "  %s\t->\t%s\n" "Tag" "$tag"

    helm_chart_name=${PWD##*/}

    repository_name=""
    image_relative_path=""
    image_absolute_path=""

    if [[ $repository == *"/"* ]]; then
      echo "It contains '/'"
      repository_name="${repository%%/*}"
      image_name=${repository##*/}
      image_relative_path="$final_registry/$repository_name/$image_name:$tag"
      image_absolute_path="$images_dir/$final_registry/$repository_name/"
    else
      echo "It doesn't contain '/'"
      repository_name=""
      image_name=${repository##*/}
      image_relative_path="$final_registry/$image_name:$tag"
      image_absolute_path="$images_dir/$final_registry/"
    fi
    img_new_name="$img--$helm_chart_name"
    yq_registry="$img_new_name.registry."
    echo "YQ Registry is:" $yq_registry

    yq_repository="$img_new_name.repository."
    echo "YQ Registry is:" $yq_repository

    yq_tag="$img_new_name.tag."
    echo "YQ Registry is:" $yq_tag

    $(yq write --inplace -- ../values.yaml "$yq_registry" "$final_registry")

    $(yq write --inplace -- ../values.yaml "$yq_repository" "$repository")

    $(yq write --inplace -- ../values.yaml $yq_tag "$tag")

   echo "Final repository name:" "$repository_name"
   echo "Final image name is:" "$image_name"
   echo "Image relative path is:" "$image_relative_path"
   printf "  %s\t->\t%s\n" "$registry$repository:$tag" "$image_relative_path"


   docker pull -q "$registry$repository:$tag" >/dev/null
   docker tag "$registry$repository:$tag" "$image_relative_path"


   mkdir -p $image_absolute_path
   echo "Current image absolute path" "$image_absolute_path"

   final_file_name="$image_absolute_path$image_name:$tag.tgz"
   echo "Final file name" "$final_file_name"

   docker save $registry$repository:$tag > $final_file_name
   echo "Image saved"
   echo ""
   echo ""
   echo ""
   echo ""
  done
}

createTarFile() {
  tar_file="_images.tgz"
  if [ -f "$tar_file" ]; then
    echo "Removing old '_images.tgz'..."
    rm _images.tgz
    echo "Old '_images.tgz' removed."
  fi

  sleep 5
  echo "Main dir is:" $main_dir

  mv $main_dir/values.yaml $images_dir
  rm -rf "$images_dir/$final_registry/*.tgz" && tar cvfz _images.tgz _images
}

checkPrereqs

set -e
set -o pipefail

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
