#script input param is acr registry url, glasswall registry username, password
#
#for each helm directory
#  run helm template . and grep image repos
#  for each image repo
#    if docker registry is glasswallsolutions then we have to do docker login
#    run docker pull image repo
#    run docker tag to new acr registry
#    run docker push to new acr registry


#!/bin/bash
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
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n"
      done
    done

    cd ..
done
