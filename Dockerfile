FROM centos:7.4.1708

#Enable the extras Repo
RUN yum -y install epel-release && \
    rm  -rf rm /var/log/lastlog

#Standard 64 bit packages
RUN yum -y install audit-libs-devel \
                   autoconf.noarch \
                   automake \
                   bc \
                   doxygen \
                   e2fsprogs-devel \
                   file \
                   fipscheck-devel \
                   gcc \
                   gettext \
                   git \
                   groff \
                   gtk2-devel \
                   krb5-devel \
                   lksctp-tools-devel \
                   libedit-devel \
                   libX11-devel \
                   make \
                   nss_wrapper \
                   openldap-devel \
                   pam-devel \
                   patch \
                   prelink \
                   python-pip \
                   rpm-build \
                   rpm-sign \
                   sudo \
                   systemd-devel \
                   tcp_wrappers-devel \
                   vim \
                   wget \
                   xauth \
                   zlib \
                   zlib-devel && \
    rm  -rf rm /var/log/lastlog

#32 bit packages for cross compiling
RUN yum -y install e2fsprogs-devel.i686 \
                   glibc-devel.i686 \
                   krb5-devel.i686 \
                   libgcc.i686 \
                   openldap-devel.i686 \
                   pam-devel.i686 \
                   zlib-devel.i686 && \
    rm  -rf rm /var/log/lastlog

#Install python Packages
RUN pip install pexpect

#installing the centos 6 CUnit packages because Centos 7 doesn't have i686 version
#while not a common rpm build package, some tests from rpmbuilding require CUnit.
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/Packages/c/CUnit-2.1.2-6.el6.i686.rpm
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/Packages/c/CUnit-devel-2.1.2-6.el6.i686.rpm
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/Packages/c/CUnit-2.1.2-6.el6.x86_64.rpm
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/Packages/c/CUnit-devel-2.1.2-6.el6.x86_64.rpm
RUN yum localinstall -y CUnit*

#Fix locale info
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

#Sudoers for wheel
COPY wheel-sudoers /etc/sudoers.d/

#Add non-root user and set it as default user/workdir
RUN useradd -d /rpmbuilder -s /bin/bash -G adm,wheel,systemd-journal rpmbuilder

#RPM macros for signing / nosigning
COPY rpmmacros_sign.template /tmp/
COPY rpmmacros_nosign.template /tmp/
RUN chmod 444 /tmp/rpmmacros_sign.template /tmp/rpmmacros_nosign.template

#NSS Wrapper items
ENV NSS_WRAPPER_PASSWD=/tmp/passwd
ENV NSS_WRAPPER_GROUP=/tmp/group
ENV USER_NAME=rpmbuilder
ENV GROUP_NAME=rpmbuilder
ENV HOME=/rpmbuilder
ADD passwd.template /tmp/passwd.template
ADD group.template /tmp/group.template
RUN chmod 755 /tmp/passwd.template /tmp/group.template

#Setuid on nss wrapper lib
#You need this setuid flag set for sudo to load this
RUN chmod 4755 /usr/lib64/libnss_wrapper.so

#Private copy of sudoers
COPY sudoers /etc/sudoers

#Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#Default user
USER rpmbuilder

#Workdir
WORKDIR /rpmbuilder
