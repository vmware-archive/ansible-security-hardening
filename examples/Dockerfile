FROM photon:3.0

RUN tdnf erase toybox -qy --refresh
RUN tdnf install rpm ansible python-xml util-linux libapparmor -qy --refresh

#setup chroot as ansible target
RUN mkdir -p /root/testroot
RUN rpm --root /root/testroot --initdb

#python3 for ansible
#shadow for rule 6.1.2
#procps-ng for rule 3.1.1
#awk for rule 6.1.10
#iptables for rule 3.6.2 onwards
#audit for rules in section 4.1
#rsyslog for rules in section 4.2.1
#findutils for rules 4.1.13 and 4.2.3
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
photon-release \
util-linux \
findutils \
rpm \
grub2 \
libapparmor \
sed -qy

ENTRYPOINT ["/bin/bash"]
