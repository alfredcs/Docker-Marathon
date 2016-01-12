#!/bin/bash
set -x
[[ "$(id -u)" != 0 ]] && { echo "not root"; exit 0; }
[[ `grep mesos-repo /etc/hosts | wc -l` -lt 1 ]] &&  echo "10.0.10.237 ip-10-0-10-237.us-west-2.compute.internal mesos-repo ip-10-0-10-237" >> /etc/hosts
curl -o /tmp/hosts.tmp http://mesos-repo/hosts
grep -v ^# /tmp/hosts.tmp | while read aa
do
	bb=`echo $aa|awk '{print $1}'`
        [[ `grep $bb /etc/hosts|wc -l` -lt 1 ]] && echo $aa >> /etc/hosts
done
[[ -f /tmp/hosts.tmp ]] && rm -f /tmp/hosts.tmp
if [[ `cat /etc/lsb-release | grep ^DISTRIB_I| cut -d= -f2` == "Ubuntu" ]]; then
	# Setup
	apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
	DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
	#CODENAME=$(lsb_release -cs)
	CODENAME=vivid

	# Add the repository
	echo "deb http://repos.mesosphere.com/${DISTRO} ${CODENAME} main" | tee /etc/apt/sources.list.d/mesosphere.list
	apt-get -y update

	#Install Mesos
	[[ `dpkg -l | grep mesos | wc -l` -lt 1 ]] && apt-get -y install mesos ntp
	service zookeeper stop
	sh -c "echo manual > /etc/init/zookeeper.override"
	service stop mesos-master
	sh -c "echo manual > /etc/init/mesos-master.override"

	#Config meoss slave
	echo "zk://10.0.0.71:2181,10.0.1.50:2181,10.0.2.109:2181/mesos" > /etc/mesos/zk
	echo "5mins" > /etc/mesos-slave/executor_registration_timeout
	echo "docker,mesos" > /etc/mesos-slave/containerizers
	echo `uname -n` > /etc/mesos-slave/hostname
	#echo "server 192.168.12.20" > /etc/ntp.conf
	[[ ! -d /etc/mesos-slave/attributes ]] && mkdir -p /etc/mesos-slave/attributes
	echo $DISTRO  > /etc/mesos-slave/attributes/os
	# Install Docker daemon on the slave
	 [[ ! `docker --version` =~ "1.9.1" ]] && { curl -sSL https://test.docker.com/ | sh; }
	# update  local docker repo certificate
	curl -o /usr/local/share/ca-certificates/devdockerCA.crt http://mesos-repo/devdockerCA.crt
	chmod go-rx /usr/local/share/ca-certificates/devdockerCA.crt
	[[ ! -f /etc/ssl/certs/devdockerCA.pem ]] && ln -s /usr/local/share/ca-certificates/devdockerCA.crt /etc/ssl/certs/devdockerCA.pem
	curl -o /etc/docker.tar.gz http://mesos-repo/docker.tar.gz
	update-ca-certificates

	#start ntp and mesos-slave
	[[ `cat /etc/lsb-release | grep ^DISTRIB_RELEASE |cut -d= -f2` =~ "14.0" ]] && { service ntp restart; service docker restart; service mesos-slave restart; }
	[[ `cat /etc/lsb-release | grep ^DISTRIB_RELEASE |cut -d= -f2` =~ "15" ]] && { systemctl restart ntp ; systemctl restart docker; systemctl restart mesos-slave; }
elif [[ `cat /etc/os-release | grep ^PRETTY_NAME|cut -d= -f2` =~ "CentOS" ]]; then
	# Add the repository
	rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-3.noarch.rpm
	yum –y update;yum –y upgrade
	yum -y install mesos ntp 
	systemctl stop mesos-master.service
	systemctl disable mesos-master.service
	#Config meoss slave
        echo "zk://10.0.0.71:2181,10.0.1.50:2181,10.0.2.109:2181/mesos" > /etc/mesos/zk
        echo "5mins" > /etc/mesos-slave/executor_registration_timeout
        echo "docker,mesos" > /etc/mesos-slave/containerizers
        echo `uname -n` > /etc/mesos-slave/hostname
        #echo "server 192.168.12.20" > /etc/ntp.conf
	[[ ! -d /etc/mesos-slave/attributes ]] && mkdir -p /etc/mesos-slave/attributes
	echo `cat /etc/os-release| grep ^ID=|cut -d= -f2 |sed 's/\"//g'`  > /etc/mesos-slave/attributes/os
	# Install Docker daemon on the slave
        [[ ! `docker --version` =~ "1.9.1" ]] && { curl -sSL https://test.docker.com/ | sh; }

	# Update local docker repo certificate
	curl -o /etc/pki/ca-trust/source/anchors/devdockerCA.crt http://mesos-repo/devdockerCA.crt
	curl -o /etc/docker.tar.gz http://mesos-repo/docker.tar.gz
	update-ca-trust

	systemctl enable docker
	systemctl restart docker
	systemctl enable mesos-slave
	systemctl start mesos-slave
fi

