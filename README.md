# mac-init for DevOps

This repo designet to quick idempotent MacBook setup for my needs as a DevOps Engineer. It require only three simple steps to configure new environment on MacOS to start working.

### 1. SSH setup on New MacOS side 
Just open terminal and run:
```
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ivaniy/mac-init/HEAD/enable_ssh.sh)"
```
It enables SSH Server on MacOs side to be able to configure it via SSH with or without ansible
it tested on MacOS versions: `MacOS Monterey 12.7.4` and `MacOS Sonoma 14.7.7`

### 2. Install Command Line Tools (from another machine)
1. Clone this repo: `git clone https://github.com/ivaniy/mac-init.git`
2. Go to mac-init folder `cd mac-init`
3. Add your public `~/.ssh/id_rsa.pub` ssh key to remote host: `./add_ssh_key.sh <ssh_user> <macbook_address>` If you don't have key, script will create it.
4. Run CLT installer `./clt_install_remote.sh <ssh_user> <macbook_address>`

### 3. Apply ansible playbook
To run ansible playbook from external control machine:
1. Ensure you have ansible: `ansible --version`
2. Go to ansible folder `cd ansible`
3. Rename ansible variables example file to json and edit variables on your requirements `mv ansible_vars.json.example ansible_vars.json; nano ansible_vars.json`
4. Run ansible playbook: `ansible-playbook install_software.yml -i "<macbook_address>," -e "ansible_user=<ssh_user>" -K`
	-K will ask you sudo password on remote host.
###### Example:
```
ansible-playbook install_software.yml -i "ivans-macbook-pro.local," -e "ansible_user=Ivan.Dolyuk" -K
```

## Install without control host (locally)
If you would like to run this playbook on target machine then you need to preinstall CLT, brew and ansible:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ivaniy/mac-init/HEAD/clt_install_locally.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install ansible
```
Then repeat steps 1-4 as for remote machine, and then run ansible playbook for local machine:
```
ansible-playbook --connection=local --inventory "localhost," install_software.yml -e "ansible_user=${USER}" -K
```

