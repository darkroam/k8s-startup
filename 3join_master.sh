#!/bin/sh

kubeadm join 192.168.68.190:6443 --token 2nstae.7xqhxa7i8izacwpq \
    --discovery-token-ca-cert-hash sha256:9913dd5b8c2a15be1d498e7bc3ebfae2805f95683a00b780488e5317c9d99df1

