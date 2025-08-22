# mac-init for DevOps

This repo designet to quick idempotent MacBook setup for my needs as a DevOps Engineer. It require only two steps to configure new environment on MacOS to start working.

### 1. SSH setup on New MacOS side 
Just open terminal and run:
```
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ivaniy/mac-init/HEAD/enable_ssh.sh)"
```
It enables SSH Server on MacOs side to be able to configure it via SSH with or without ansible
it tested on MacOS versions: `MacOS Monterey 12.7.4` and `MacOS Sonoma 14.7.7`

### Ansible playbook 
