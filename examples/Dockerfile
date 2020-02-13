FROM photon:3.0

RUN tdnf erase toybox -qy --refresh
RUN tdnf install rpm ansible python-xml -qy --refresh

#setup chroot as ansible target
RUN mkdir -p /root/testroot
RUN rpm --root /root/testroot --initdb

#python3 for ansible
#shadow for rule 6.1.2
#procps-ng for rule 3.1.1
#awk for rule 6.1.10
#iptables for rule 3.6.2 onwards
#photon-release for rule 1.7.1.6
RUN tdnf --installroot ~/testroot \
--releasever 3.0 --nogpgcheck \
install python3 \
shadow \
procps-ng \
awk \
iptables \
cronie \
openssh \
audit \
rsyslog \
findutils \
photon-release -qy

ENTRYPOINT ["/bin/bash"]
