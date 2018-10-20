FROM registry.access.redhat.com/rhel7:7.5
RUN yum update -y && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
                   https://rhel7.iuscommunity.org/ius-release.rpm && \
    yum update -y && \
    yum install -y bzip2 \
                   git2u \
                   make \
                   python2-pip \
                   python35u \
                   python-virtualenv \
                   reposync \
                   rsync \
                   vim \
                   wget && \
    yum clean all
CMD /bin/bash
