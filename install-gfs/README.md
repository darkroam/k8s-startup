# How to Startup Gulsterfs and Heketi

## Setup

perpare

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

## build by Heketi

### part A

```bash
kubectl apply -f glusterfs-daemonset.json

 scp /etc/docker/daemon.json k8s-node1:/etc/docker/
 systemctl restart docker
 docker pull gluster/gluster-centos	#by hand

kubectl apply -f heketi-service-account.json

kubectl create clusterrolebinding heketi-gluster-admin --clusterrole=edit --serviceaccount=dafault:heketi-service-account

kubectl create secret generic heketi-config-secret --from-file=./heketi.json

kubectl apply -f heketi-service-account-rbac.yaml

kubectl create -f heketi-bootstrap.json

kubectl apply -f heketi-deployment.json

cp heketi-cli /usr/local/bin/

 heketi-cli -v

 kubectl get svc|grep heketi

 curl http://10.1.98.149:8080/hello
 curl http://{deploy-heketi}:8080/hello

export HEKETI_CLI_SERVER=http://10.1.98.149:8080

 echo $HEKETI_CLI_SERVER

heketi-cli -s $HEKETI_CLI_SERVER --user admin --secret 'My Secret' topology load --json=../topology.json

 kubectl get pod
 kubectl logs -f deploy-heketi-7bcd7888b-tbqp2
```

### part B

```bash
heketi-cli -s $HEKETI_CLI_SERVER --user admin --secret 'My Secret' setup-openshift-heketi-storage Saving heketi-storage.json

kubectl apply -f heketi-storage.json

kubectl delete all,svc,jobs,deployment,secret --selector="deploy-heketi"

kubectl apply -f heketi-deployment.json
```

## build by hand

```bash
yum install -y centos-release-gluster
yum install -y glusterfs glusterfs-server glusterfs-fuse glusterfs-rdma
systemctl start glusterd

gluster peer probe k8s-node3
gluster peer probe k8s-node4
```

## output by gk-deploy

```
Using Kubernetes CLI.
Using namespace "storage".
Checking for pre-existing resources...
  GlusterFS pods ... not found.
  deploy-heketi pod ... not found.
  heketi pod ... not found.
  gluster-s3 pod ... not found.
Creating initial resources ... serviceaccount/heketi-service-account created
clusterrolebinding.rbac.authorization.k8s.io/heketi-sa-view created
clusterrolebinding.rbac.authorization.k8s.io/heketi-sa-view labeled
OK
node/k8s-node5 labeled
node/k8s-node4 labeled
node/k8s-node3 labeled
daemonset.apps/glusterfs created
Waiting for GlusterFS pods to start ... OK
secret/heketi-config-secret created
secret/heketi-config-secret labeled
service/deploy-heketi created
deployment.apps/deploy-heketi created
Waiting for deploy-heketi pod to start ... OK
Creating cluster ... ID: 8dfd15256c94c7871d60b54bf64dce39
Allowing file volumes on cluster.
Allowing block volumes on cluster.
Creating node k8s-node5 ... ID: 3bd6b2fa168d481f6d5b30be2b33f8b9
Adding device /dev/vdb ... OK
Creating node k8s-node4 ... ID: b9315bf05552f699be0ec31b1e508318
Adding device /dev/vdb ... OK
Creating node k8s-node3 ... ID: 292a88320447d18b9f83f99fa6d93223
Adding device /dev/vdb ... OK
heketi topology loaded.
Saving /tmp/heketi-storage.json
secret/heketi-storage-secret created
endpoints/heketi-storage-endpoints created
service/heketi-storage-endpoints created
job.batch/heketi-storage-copy-job created
service/heketi-storage-endpoints labeled
pod "deploy-heketi-6d769d5dfb-86chq" deleted
service "deploy-heketi" deleted
deployment.apps "deploy-heketi" deleted
replicaset.apps "deploy-heketi-6d769d5dfb" deleted
job.batch "heketi-storage-copy-job" deleted
secret "heketi-storage-secret" deleted
service/heketi created
deployment.apps/heketi created
Waiting for heketi pod to start ... OK

heketi is now running and accessible via http://10.244.2.16:8080 . To run
administrative commands you can install 'heketi-cli' and use it as follows:

  # heketi-cli -s http://10.244.2.16:8080 --user admin --secret '<ADMIN_KEY>' cluster list

You can find it at https://github.com/heketi/heketi/releases . Alternatively,
use it from within the heketi pod:

  # /usr/bin/kubectl -n storage exec -i heketi-7656cd7ffd-w8zng -- heketi-cli -s http://localhost:8080 --user admin --secret '<ADMIN_KEY>' cluster list

For dynamic provisioning, create a StorageClass similar to this:

---
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: glusterfs-storage
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://10.244.2.16:8080"
  restuser: "user"
  restuserkey: "PASSWORD"


Deployment complete!
```

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

