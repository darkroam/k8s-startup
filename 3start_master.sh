#!/bin/sh

kubeadm init \
--apiserver-advertise-address=192.168.68.190 \
--image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version v1.18.1 \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=10.244.0.0/16
