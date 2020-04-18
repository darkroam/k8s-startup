#!/bin/sh

kubectl label node k8s-node3 storagenode=glusterfs
kubectl label node k8s-node4 storagenode=glusterfs
kubectl label node k8s-node5 storagenode=glusterfs

kubectl create namespace storage
