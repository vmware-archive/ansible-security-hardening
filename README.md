# ansible-security-hardening
[![Build Status](https://travis-ci.org/vmware/ansible-security-hardening.svg?branch=master)](https://travis-ci.org/vmware/ansible-security-hardening)

## Overview
Security hardening scripts as recommended by CIS, STIG etc are usually available as shell scripts. This project provides ansible playbooks for these script suites and keep it as distro agnostic as possible.

Remediation is done by regular ansible playbook runs

Validation is done by setting `-e verify=true` in command line. verification does not require additional parsing to determine outcome. This is because the verify tasks are separate and designed to provide context sensitive, granular, test style results of the form: `Failed: Reason, Expected: <expected>, Found: <found>`

## Try it out

### Prerequisites

* ansible (host)
* python3 (target)
* procps-ng (target)
* awk (target)
* iptables (target)
* cronie (target)
* openssh (target)

### Build & Run

1. Use a docker based run

There is a docker build script in examples/Dockerfile. You can use it to quickly get
the project up and running and check it out.

```
docker build examples/ -t ansible-security-hardening
```

We discuss commands and options below. All of them can be run using the docker image as follows.
Eg: to skip `notscored` tasks
```
docker run --rm  -v$(pwd):/src ansible-security-hardening:latest \
	ansible-playbook  -i /src/examples/chroots /src/cis.playbook.yml \
	--tags "cis" --skip-tags "notscored"
```

See below for further command examples.

2. To do a chroot based run, do the following (assuming PhotonOS)

create a chroot with necessary packages installed

```
rpm --root ~/testroot --initdb

#install python3 for ansible
#install shadow for cis rule 6.1.2
#install awk for cis rule 6.1.10
#install procps-ng for cis rule 3.1.1
#install iptables for cis rule 3.6.2
#install cronie for cis rule 5.1
#install openssh for cis rule 5.2
#install photon-release for cis rule 1.7.1.6
#install util-linux for cis rule 1.1.2
#install findutils for cis rule 1.1.21 
#install rpm for cis rule 1.1.21
tdnf --installroot ~/testroot \
--releasever 3.0 --nogpgcheck \
install python3 shadow awk procps-ng iptables cronie openssh photon-release util-linux findutils rpm -y
```

3. Run the cis rule 6.1.2
```
ansible-playbook  -i examples/chroots cis.playbook.yml --tags "cis.6,cis.6.1.2"

PLAY [chroots] ******************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************
ok: [/root/testroot]

TASK [cis : include_tasks] ******************************************************************************************
included: /ansible-hardening-scripts/roles/cis/tasks/6/6.1.2.yml for /root/testroot

TASK [cis : 6.1.2 Ensure permissions on /etc/passwd are configured (Scored)] ****************************************
ok: [/root/testroot]

PLAY RECAP **********************************************************************************************************
/root/testroot             : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

4. Verify the cis rule 6.1.2
```
ansible-playbook -i 'examples/chroots' cis.playbook.yml --tags "cis.6,cis.6.1.2" -e verify=true

PLAY [chroots] ******************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************
ok: [/root/testroot]

TASK [cis : include_tasks] ******************************************************************************************
included: /ansible-hardening-scripts/roles/cis/tasks/6/verify/6.1.2.yml for /root/testroot

TASK [cis : 6.1.2 verify permissions] *******************************************************************************
ok: [/root/testroot]

TASK [cis : fail] ***************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ***************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ***************************************************************************************************
skipping: [/root/testroot]

PLAY RECAP **********************************************************************************************************
/root/testroot             : ok=3    changed=0    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```

5. Force a failure and verify (notice the test style error and the return code)
```
chmod 0777 /root/testroot/etc/passwd
ansible-playbook -i 'examples/chroots' cis.playbook.yml \
--tags "cis.6,cis.6.1.2" \
-e verify=true

PLAY [chroots] ******************************************************************************************************

TASK [Gathering Facts] **********************************************************************************************
ok: [/root/testroot]

TASK [cis : include_tasks] ******************************************************************************************
included: /ansible-hardening-scripts/roles/cis/tasks/6/verify/6.1.2.yml for /root/testroot

TASK [cis : 6.1.2 verify permissions] *******************************************************************************
ok: [/root/testroot]

TASK [cis : fail] ***************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ***************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ***************************************************************************************************
fatal: [/root/testroot]:
FAILED! => {"changed": false, "msg": "6.1.2 failed to verify permissions. expected: 0644. found: 0777"}

PLAY RECAP **********************************************************************************************************
/root/testroot             : ok=3    changed=0    unreachable=0    failed=1    skipped=2    rescued=0    ignored=0

#this check will fail a verification task
root [ /ansible-hardening-scripts ]# echo $?
2

```

## Documentation
For example, to implement cis rule 6.2.1 and optional validate, the required files are:

```
roles/cis/tasks/6
roles/cis/tasks/6/tasks.yml
roles/cis/tasks/6/verify
roles/cis/tasks/6/verify/6.1.2.yml
roles/cis/tasks/6/6.1.2.yml
```

Make sure the tasks/main.yml includes the right file. In this case, the 6/tasks.yml
Note: In order to separate scored and notscored tasks,
use separate files like 1/tasksnotscored.yml
```
root [ /ansible-hardening-scripts ]# cat roles/cis/tasks/main.yml
---
- import_tasks: 1/tasksnotscored.yml
- import_tasks: 6/tasks.yml
```

Create 6/tasks like so:
```
---
- include_tasks: "{{ \"verify/{{ item }}\" if verify|bool else \"{{ item }}\" }}"
  loop:
    - 6.1.2.yml
  tags:
    - cis
    - cis.6
```

Create 6.1.2.yml under the roles/cis/tasks/6 folder

```
---
- name: "6.1.2 Ensure permissions on /etc/passwd are configured (Scored)"
  file:
      dest: /etc/passwd
      owner: root
      group: root
      mode: 0644
  when: not ansible_check_mode
  tags:
      - cis
      - cis.6
      - cis.6.1
      - cis.6.1.2
      - scored
```

Create the optional verify under roles/cis/tasks/6/verify as 6.1.2.yml
```
---
- name: "6.1.2 Verify permissions on /etc/passwd are configured (Scored)"
  block:
    - name: "6.1.2 verify permissions"
      stat:
        path: /etc/passwd
      register: etcpass
    - fail:
        msg: "6.1.2 failed to verify uid. expected: 0. found: {{ etcpass.stat.uid }}"
      when: etcpass.stat.uid != 0
    - fail:
        msg: "6.1.2 failed to verify gid. expected: 0. found: {{ etcpass.stat.gid }}"
      when: etcpass.stat.gid != 0
    - fail:
        msg: "6.1.2 failed to verify permissions. expected: 0644. found: {{ etcpass.stat.mode }}"
      when: etcpass.stat.mode != "0644"
  tags:
    - cis
    - cis.6
    - cis.6.1
    - cis.6.1.2
    - scored
```

## Contributing

The ansible-security-hardening project team welcomes contributions from the community. Before you start working with ansible-security-hardening, please
read our [Developer Certificate of Origin](https://cla.vmware.com/dco). All contributions to this repository must be
signed as described on that page. Your signature certifies that you wrote the patch or have the right to pass it on
as an open-source patch. For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## License
ansible-security-hardening is available under the [BSD-2 license](LICENSE).
