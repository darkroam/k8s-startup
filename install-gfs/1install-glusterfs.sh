#!/bin/sh

yum install -y centos-release-gluster
yum -y install ntp device-mapper* glusterfs glusterfs-fuse
ntpdate time.windows.com
