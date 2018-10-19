FROM registry.access.redhat.com/rhel7:7.5
RUN yum update -y && \
    yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y && \
    yum install https://rhel7.iuscommunity.org/ius-release.rpm -y && \
    yum update -y && \
    yum install -y bzip2 \
                   git2u \
                   make \
                   vim && \
    yum clean all
CMD /bin/bash
