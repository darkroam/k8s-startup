# How to Startup Gulsterfs and Heketi

## Setup

perpare env

```bash
yum install -y centos-release-gluster
yum -y install ntp device-mapper* glusterfs glusterfs-fuse

ntpdate time.windows.com

systemctl restart docker

docker pull gluster/gluster-centos

modprobe dm_snapshot
modprobe dm_mirror
modprobe dm_thin_pool

 lsmod | grep dm_snapshot		#show
 lsmod | grep dm_mirror
 lsmod | grep dm_thin_pool
```

target the node of glusterfs a label

```bash
kubectl label node k8s-node3 storagenode=glusterfs
kubectl label node k8s-node4 storagenode=glusterfs
kubectl label node k8s-node5 storagenode=glusterfs

 kubectl get nodes --show-labels  	#show
```

## build by glusterfs-kubernetes

```bash
kubectl create namespace storage

./gk-deploy -g -n storage --admin-key 'PASSWORD' --user-key 'PASSWORD'

./gk-deploy --abort -g -n storage --admin-key "PASSWORD" --user-key "PASSWORD"
```

## process of buildup

0. Checking for pre-existing resources...
  GlusterFS, deploy-heketi, heketi, gluster-s3 pods ...
```bash
kubectl get pods -n storage --selector=glusterfs=pod
kubectl get pods -n storage --selector=deploy-heketi=pod
kubectl get pods -n storage --selector=heketi=pod
kubectl get pods -n storage --selector=glusterfs=s3-pod
```

1. Creating initial resources ...
```bash
kubectl -n storage create -f heketi-service-account.yaml
kubectl -n storage create clusterrolebinding heketi-sa-view --clusterrole=edit --serviceaccount=storage:heketi-service-account
kubectl -n storage label --overwrite clusterrolebinding heketi-sa-view glusterfs=heketi-sa-view heketi=sa-view
```

2. Marking 'k8s-node5', 'k8s-node4', and 'k8s-node3' as a GlusterFS nodes.
```bash
kubectl -n storage label nodes k8s-node5 storagenode=glusterfs --overwrite 
kubectl -n storage label nodes k8s-node4 storagenode=glusterfs --overwrite
kubectl -n storage label nodes k8s-node3 storagenode=glusterfs --overwrite
```

3. Deploying GlusterFS pods.
```bash
sed -e 's/storagenode\: glusterfs/storagenode\: 'glusterfs'/g' glusterfs-daemonset.yaml | kubectl -n storage create -f - 
```

4. Waiting for GlusterFS pods to start ...
```bash
kubectl get pods -n storage --selector=glusterfs=pod
```

glusterfs-bsscq   1/1   Running   0     65s
glusterfs-cjhjx   1/1   Running   0     65s
glusterfs-zxrx4   1/1   Running   0     65s

```bash
sed -e "s/\${HEKETI_EXECUTOR}/kubernetes/" -e "s#\${HEKETI_FSTAB}#${FSTAB}#" -e "s/\${SSH_PORT}/22/" -e "s/\${SSH_USER}/root/" -e "s/\${SSH_SUDO}/false/" heketi.json.template > heketi.json
kubectl -n storage create secret generic heketi-config-secret --from-file=private_key=/dev/null --from-file=./heketi.json --from-file=topology.json=../topology.json
kubectl -n storage label --overwrite secret heketi-config-secret glusterfs=heketi-config-secret heketi=config-secret
sed -e 's/\${HEKETI_EXECUTOR}/kubernetes/' -e 's#\${HEKETI_FSTAB}#/var/lib/heketi/fstab#' -e 's/\${HEKETI_ADMIN_KEY}/PASSWORD/' -e 's/\${HEKETI_USER_KEY}/PASSWORD/' /root/a/k8s-startup/install-gfs/kube-templates/deploy-heketi-deployment.yaml | kubectl -n storage create -f - 
```

5. Waiting for deploy-heketi pod to start ...
```bash
kubectl get pods -n storage --selector=deploy-heketi=pod
```

deploy-heketi-689f995694-7hlpd   1/1   Running   0     6s

```bash
kubectl -n storage exec -i deploy-heketi-689f995694-7hlpd -- heketi-cli -s http://localhost:8080 --user admin --secret 'PASSWORD' topology load --json=/etc/heketi/topology.json 
```

Creating cluster ... ID: 4dadfa39688b310ee5626feca90614cc
Allowing file volumes on cluster.
Allowing block volumes on cluster.
Creating node k8s-node5 ... ID: bfcefad2bb672c5d4f4dfab1937983e6
Adding device /dev/vdb ... OK
Creating node k8s-node4 ... ID: 04c5a783e913c72c5f209c3aada34a79
Adding device /dev/vdb ... OK
Creating node k8s-node3 ... ID: 6fa353df1750412239ae435b2f4497a7
Adding device /dev/vdb ... OK

heketi topology loaded.

6. Persistent heketi configuration
```bash
kubectl -n storage exec -i deploy-heketi-689f995694-7hlpd -- heketi-cli -s http://localhost:8080 --user admin --secret 'PASSWORD' setup-openshift-heketi-storage --listfile=/tmp/heketi-storage.json  
```
Saving /tmp/heketi-storage.json

```bash
kubectl -n storage exec -i deploy-heketi-689f995694-7hlpd -- cat /tmp/heketi-storage.json | kubectl -n storage create -f - 

kubectl get pods -n storage --selector=job-name=heketi-storage-copy-job
```

heketi-storage-copy-job-r4wzv   0/1   Completed   0     6s

```bash
kubectl -n storage label --overwrite svc heketi-storage-endpoints glusterfs=heketi-storage-endpoints heketi=storage-endpoints

kubectl -n storage delete all,service,jobs,deployment,secret --selector="deploy-heketi"

sed -e 's/\${HEKETI_EXECUTOR}/kubernetes/' -e 's#\${HEKETI_FSTAB}#/var/lib/heketi/fstab#' -e 's/\${HEKETI_ADMIN_KEY}/PASSWORD/' -e 's/\${HEKETI_USER_KEY}/PASSWORD/' heketi-deployment.yaml | kubectl -n storage create -f - 
```

7.  Done
Waiting for heketi pod to start ...
```bash
kubectl get pods -n storage --selector=heketi=pod

kubectl describe svc/heketi -n storage | grep Endpoints | awk '{print $2}'
kubectl get pod --no-headers --selector="heketi" -n storage | awk '{print $1}'
```

heketi is now running and accessible via http://10.244.2.19:8080 . To run
administrative commands you can install 'heketi-cli' and use it as follows:

  # heketi-cli -s http://10.244.2.19:8080 --user admin --secret '<ADMIN_KEY>' cluster list

use it from within the heketi pod:

  # /usr/bin/kubectl -n storage exec -i heketi-f5f5db468-pphv2 -- heketi-cli -s http://localhost:8080 --user admin --secret '<ADMIN_KEY>' cluster list


## Reference

<https://www.infvie.com/ops-notes/kubernetes-glusterfs-heketi.html>
<https://www.cnblogs.com/ssgeek/p/11725648.html>
<https://github.com/fabric8io/fabric8/issues/6840>
<https://www.cnblogs.com/breezey/p/8849466.html>
<https://www.cnblogs.com/netonline/p/10288219.html>
<https://blog.csdn.net/weixin_34281537/article/details/93427253>
<https://github.com/heketi/heketi>
<https://www.cnblogs.com/sirdong/p/12053429.html>
<http://www.manongjc.com/detail/13-pzrgtlhvlawobtf.html>

