#!/bin/bash

# Verify that kubectl is installed and configured to connected to kubernetes
# Assume minikube is running
eval $(minikube docker-env)

DIR=$(realpath -m "${BASH_SOURCE[0]}/..")
cd $DIR

NAME=ardana-installer-ui

mkdir -p svcs

declare -A SERVICES
SERVICES=(\
    [ui]=https://github.com/ArdanaCLM/ardana-installer-ui.git \
    [svc]=https://github.com/ArdanaCLM/ardana-service.git \
    [key]=https://github.com/GarySmith/docker-keystone.git)

set -x 
for repo in ${!SERVICES[@]}; do
    cd $DIR/svcs
    if [[ ! -d $repo ]] ; then
        git clone ${SERVICES[$repo]} $repo 
    fi
    cd $repo
    docker build -t ${NAME}-${repo} .
done

cd $DIR

# create namespace
kubectl get namespace -o name | grep -q namespace/$NAME 
if [[ $? -ne 0 ]] ; then
    kubectl create namespace $NAME
fi

# apply installation file
kubectl apply -n $NAME -f install.yml

# open port forwarding
kubectl port-forward -n $NAME service/$NAME 2209 9085
