

# ansible-security-hardening

## Overview
Security hardening scripts as recommended by CIS, STIG etc are usually available as shell scripts. This project provides ansible playbooks for these script suites and keep it as distro agnostic as possible.

Remediation is done by regular ansible playbook runs

Validation is done using --check and does not require additional parsing to determine outcome. This is because the check mode tasks are separate and designed to provide context sensitive, granular, test style Failed: Reason, Expected: <expected>, Found: <found>

## Try it out

### Prerequisites

* ansible

### Build & Run

1. To do a chroot based run, do the following (assuming PhotonOS)

create a chroot with necessary packages installed

```
rpm --root ~/testroot --initdb

tdnf --installroot ~/testroot \
--releasever 3.0 --nogpgcheck \
install python3 shadow -y
```

2. Run the cis rule 6.1.2
```
ansible-playbook -c chroot -i 'examples/chroots' cis.playbook.yml --tags "cis,6.1.2"

root [ /ansible-hardening-scripts ]# ansible-playbook -c chroot -i 'examples/chroots' cis.playbook.yml --tags "cis,6.1.2"

PLAY [chroots] *********************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [/root/testroot]

TASK [cis : 6.1.2 Ensure permissions on /etc/passwd are configured (Scored)] *******************************************
ok: [/root/testroot]

TASK [cis : 6.1.2 verify permissions] **********************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ******************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ******************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ******************************************************************************************************
skipping: [/root/testroot]

PLAY RECAP *************************************************************************************************************
/root/testroot             : ok=2    changed=0    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0

```

3. Verify the cis rule 6.1.2
```
root [ /ansible-hardening-scripts ]# ansible-playbook -c chroot -i 'examples/chroots' cis.playbook.yml --tags "cis,6.1.2" --check

PLAY [chroots] *****************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************
ok: [/root/testroot]

TASK [cis : 6.1.2 Ensure permissions on /etc/passwd are configured (Scored)] ***************************************************
skipping: [/root/testroot]

TASK [cis : 6.1.2 verify permissions] ******************************************************************************************
ok: [/root/testroot]

TASK [cis : fail] **************************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] **************************************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] **************************************************************************************************************
skipping: [/root/testroot]

PLAY RECAP *********************************************************************************************************************
/root/testroot             : ok=2    changed=0    unreachable=0    failed=0    skipped=4    rescued=0    ignored=0
```

4. Force a failure (notice the test style error and the return code)
```
root [ /ansible-hardening-scripts ]# chmod 0777 /root/testroot/etc/passwd
root [ /ansible-hardening-scripts ]# ansible-playbook -c chroot -i 'examples/chroots' cis.playbook.yml --tags "cis,6.1.2" --check

PLAY [chroots] ***************************************************************************************

TASK [Gathering Facts] *******************************************************************************
ok: [/root/testroot]

TASK [cis : 6.1.2 Ensure permissions on /etc/passwd are configured (Scored)] *************************
skipping: [/root/testroot]

TASK [cis : 6.1.2 verify permissions] ****************************************************************
ok: [/root/testroot]

TASK [cis : fail] ************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ************************************************************************************
skipping: [/root/testroot]

TASK [cis : fail] ************************************************************************************
fatal: [/root/testroot]: FAILED! => {"changed": false, "msg": "6.1.2 failed to verify permissions. expected: 0644. found: 0777"}

PLAY RECAP *******************************************************************************************
/root/testroot             : ok=2    changed=0    unreachable=0    failed=1    skipped=3    rescued=0    ignored=0

#this check will fail a verification task
root [ /ansible-hardening-scripts ]# echo $?
2

```

## Documentation
Create tasks using the following template

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
      - scored
      - 6
      - 6.1
      - 6.1.2

- name: "6.1.2 Verify permissions on /etc/passwd are configured (Scored)"
  block:
    - name: "6.1.2 verify permissions"
      stat:
        path: /etc/passwd
      register: etcpass
    - fail:
        msg: "6.1.2 failed to verify. expected uid: 0. found uid: {{ etcpass.stat.uid }}"
      when: etcpass.stat.uid != 0
    - fail:
        msg: "6.1.2 failed to verify. expected gid: 0. found gid: {{ etcpass.stat.gid }}"
      when: etcpass.stat.gid != 0
    - fail:
        msg: "6.1.2 failed to verify. expected permissions: 0644. found permissions: {{ etcpass.stat.mode }} {{ etcpass.stat.pw_name }} "
      when: etcpass.stat.mode != "0644"
  when: ansible_check_mode
  tags:
      - cis
      - scored
      - 6
      - 6.1
      - 6.1.2
```

## Contributing

The ansible-security-hardening project team welcomes contributions from the community. Before you start working with ansible-security-hardening, please
read our [Developer Certificate of Origin](https://cla.vmware.com/dco). All contributions to this repository must be
signed as described on that page. Your signature certifies that you wrote the patch or have the right to pass it on
as an open-source patch. For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## License
