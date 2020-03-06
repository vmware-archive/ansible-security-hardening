#!/bin/bash
mount --rbind /dev /root/testroot/dev
pushd /src
ansible-playbook  -i examples/chroots cis.playbook.yml --tags "cis" \
&& \
ansible-playbook  -i examples/chroots cis.playbook.yml --tags "cis" -e verify=true
popd
