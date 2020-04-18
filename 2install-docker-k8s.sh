#!/bin/sh

yum -y install vim ntp
yum -y install docker-ce
yum -y install --nogpgcheck kubectl kubeadm kubelet

systemctl enable docker
systemctl start docker
systemctl enable kubelet

