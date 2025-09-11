###### DISCLAIMER: This is an unofficial personal project. No warranty is provided. <br />Author: Ivan Dolyuk with the support of ChatGPT 5

# mac-init for DevOps

This repo designet to quick idempotent MacBook setup for my needs as a DevOps Engineer. It require only three simple steps to configure new environment on MacOS to start working on daily tasks.

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
3. Copy ansible variables example file to json and edit variables on your requirements `cp ansible_vars.json.example ansible_vars.json; nano ansible_vars.json`
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

### Tested on:
macOS Ventura 13.7.8 (Intel Core i7) - AWS MacMini Instance
macOS Sequoia 15.6.1 (Intel Core i7) - MacBook
macOS Sequoia 15.6.1 (Apple M2) - AWS MacMini Instance

### Post Deploy steps
##### To install SubLime packages is necessary to install Package Control via SubLime console:
1. Open SubLime menu -> View -> Show Console
2. Run command `from urllib.request import urlretrieve;urlretrieve(url="https://github.com/wbond/package_control/releases/latest/download/Package.Control.sublime-package", filename=sublime.installed_packages_path() + '/Package Control.sublime-package')`

##### GCloud CLI and terraform access
To use gcloud CLI in terminal run: `gcloud init` <br />
To grant access to GCP for terraform run: `gcloud auth application-default login` <br />
More info [here](https://cloud.google.com/docs/terraform/authentication)

##### AWS EKS kubernetes access
Add necessary keys or profile config and run `aws eks update-kubeconfig --region <region-code> --name <my-cluster>`

##### Connect to AWS MacOS and preconfigure
EC2 Instance require inbound TCP port `22` for SSH and inbound TCP port `5900` for VNC (Screen Sharing)
1. Connect via SSH with correct key:
```
ssh -i ~/.ssh/MacOS.pem ec2-user@<address>
```
2. For VNC (Screen Sharing) access set password
```
sudo passwd ec2-user
```
3. To enable VNC (Screen Sharing) run:
```
sudo launchctl enable system/com.apple.screensharing
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
```
4. To allow SSH via password (not recomended)
```
sudo sed -i '' -E \
  -e 's/^[[:space:]]*UsePAM[[:space:]]+no/UsePAM yes/' \
  -e 's/^[[:space:]]*PasswordAuthentication[[:space:]]+no/PasswordAuthentication yes/' \
  "/etc/ssh/sshd_config.d/050-ec2-macos.conf"
```
5. Connect via VNC: Finder menu -> Go -> Connect to Server .... -> vnc://\<address\>:5900
More details [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-mac-instance.html)

**NOTE!!!** KeePassXC doesn't displays on remote screen (VNC). To start it you need to use cli command `/Applications/KeePassXC.app/Contents/MacOS/KeePassXC --allow-screencapture`  [issue #10562](https://github.com/keepassxreboot/keepassxc/issues/10562)
