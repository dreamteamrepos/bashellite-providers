FROM registry.access.redhat.com/rhel7
RUN yum update -y
RUN yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
RUN yum install https://rhel7.iuscommunity.org/ius-release.rpm -y
RUN yum update -y 
RUN yum install git2u -y
RUN yum install vim -y
RUN yum install bzip2 -y
CMD /bin/bash
