FROM photon:3.0

RUN tdnf erase toybox -qy --refresh
RUN tdnf install rpm ansible python-xml -qy --refresh

#setup chroot as ansible target
RUN mkdir -p /root/testroot
RUN rpm --root /root/testroot --initdb

#python3 for ansible
#shadow for rule 6.1.2
#photon-release for rule 1.7.1.6
RUN tdnf --installroot ~/testroot \
--releasever 3.0 --nogpgcheck \
install python3 \
shadow \
photon-release -qy

CMD ["/bin/bash"]
