#!/bin/bash

# This to capture whatever the created default linux user (i.e. ubuntu, ec2-user, etc).  Assumes only one user created during build.
default_user=$(ls /home)

cd /home/$default_user

# Add private key for ssh access to all other systems
echo "${ssl_private_key}" >> .ssh/sys_admin.pem
chmod 600 .ssh/sys_admin.pem
chown $default_user:$default_user .ssh/sys_admin.pem

echo "${ssl_public_key}" >> .ssh/sys_admin.pub
chown $default_user:$default_user /home/$default_user/.ssh/sys_admin.pub

# Add system key to profile for ssh access to all nodes
runuser -l $default_user -c "touch /home/$default_user/.ssh/config"
echo 'Host *' >> /home/$default_user/.ssh/config
echo "    IdentityFile /home/$default_user/.ssh/sys_admin.pem" >> /home/$default_user/.ssh/config
echo '    StrictHostKeyChecking no' >> /home/$default_user/.ssh/config
chmod 600 /home/$default_user/.ssh/config

echo  "BETA 2 TOOLS DOWNLOAD AND INSTALL ARE GOING TO HAVE TO COME LATER - https://beta-2--chef-360.netlify.app/quickstart/cli/" >> /home/$default_user/cli-readme.txt

# Ensure ${local_fqdn} is resolvable
FQDN="${local_fqdn}"
C360_IP="${ip_address}"
if ! grep -q "$FQDN" /etc/hosts; then
  echo "$C360_IP $FQDN" | sudo tee -a /etc/hosts
fi

# Install chef-platform-auth-cli
curl -sk https://$FQDN:31000/platform/bundledtools/v1/static/install.sh |   TOOL="chef-platform-auth-cli" SERVER="https://$FQDN:31000" VERSION="latest" bash -

# Install chef-node-enrollment-cli
curl -sk https://$FQDN:31000/platform/bundledtools/v1/static/install.sh | TOOL="chef-node-enrollment-cli" SERVER="https://$FQDN:31000" VERSION="latest" bash -

# Install chef-node-management-cli
curl -sk https://$FQDN:31000/platform/bundledtools/v1/static/install.sh |   TOOL="chef-node-management-cli" SERVER="https://$FQDN:31000" VERSION="latest" bash -

# Install chef-courier-cli
curl -sk https://$FQDN:31000/platform/bundledtools/v1/static/install.sh |   TOOL="chef-courier-cli" SERVER="https://$FQDN:31000" VERSION="latest" bash -

sudo apt-get install -y bash-completion

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

echo "CLI TOLLS INSTALLED!" >> /home/$default_user/cli-readme-2.txt

###################################
# Install Powershell

# Update the list of packages
sudo apt-get update

# Install pre-requisite packages.
sudo apt-get install -y wget apt-transport-https software-properties-common

# Get the version of Ubuntu
source /etc/os-release

# Download the Microsoft repository keys
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb

# Register the Microsoft repository keys
sudo dpkg -i packages-microsoft-prod.deb

# Delete the Microsoft repository keys file
rm packages-microsoft-prod.deb

# Update the list of packages after we added packages.microsoft.com
sudo apt-get update

###################################
# Install PowerShell
sudo apt-get install -y powershell

###################################
# Install WSMan (for enter-pssession)

sudo sh -c "yes | pwsh -Command 'Install-Module -Name PSWSMan'"
sudo pwsh -Command 'Install-WSMan'

echo "POWER SHELL DONE!" >> /home/$default_user/ps-readme.txt