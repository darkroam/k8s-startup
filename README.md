keeping some bash scripts. it is for building 1.18.1 k8s.


1. config network
2. init.sh : close firewall, disable selinux, disable swap, and add bridge for k8s
3. cp conf/*.repo /etc/yum.conf.d/ , then `yum update`
4. cp conf/daemon.json to /etc/docker/
5. install-docker-k8s.sh : install docker and k8s
6. ntpdate time.windows.com
7. start master or join master
8. mkdir .kube for master
9. deploy flannel on master
11. deploy dashboard by kubernetes-dashboard.yaml
12. create admin-user for dashboard by dashboard-adminuser.yaml
13. get dashboard token
14.

yaml info:
1. yaml/kubernetes-dashboard.yaml : v2.0.0-rc7 , add NodePort :30001
2. yaml/dashboard-adminuser.yaml :
3. yaml/kube-flannel.yaml : for release v0.12.0-* , just backup

reference:
1. [k8s-dashboard](github.com/kubernetes/dashboard)
2. [flannel](github.com/coreos/flannel/)


