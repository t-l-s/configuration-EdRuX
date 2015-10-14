#!/bin/sh
##
## Installs the pre-requisites for running edX on a single Ubuntu 12.04
## instance.  This script is provided as a convenience and any of these
## steps could be executed manually.
##
## Note that this script requires that you have the ability to run
## commands as root via sudo.  Caveat Emptor!
##

##
## Sanity check
##
if [[ ! "$(lsb_release -d | cut -f2)" =~ $'Ubuntu 14.04' ]]; then
   echo "This script is only known to work on Ubuntu 14.04, exiting...";
   exit;
fi

##
## Update and Upgrade apt packages
##
sudo apt-get update -y
sudo apt-get upgrade -y

##
## Install system pre-requisites
##
sudo apt-get install -y build-essential software-properties-common python-software-properties curl git-core libxml2-dev libxslt1-dev python-pip python-apt python-dev
#sudo pip install --upgrade pip
sudo -H pip install --upgrade virtualenv

## Did we specify an openedx release?
if [ -n "$OPENEDX_RELEASE" ]; then
  EXTRA_VARS="-e edx_platform_version=$OPENEDX_RELEASE \
    -e certs_version=$OPENEDX_RELEASE \
    -e forum_version=$OPENEDX_RELEASE \
    -e xqueue_version=$OPENEDX_RELEASE \
    -e configuration_version=$OPENEDX_RELEASE \
  "
  CONFIG_VER=$OPENEDX_RELEASE
else
  CONFIG_VER="master"
fi

##
## Clone the configuration repository and run Ansible
##
cd /var/tmp
git clone -b release https://github.com/edx/configuration
cd configuration
git checkout $CONFIG_VER

## === Begin path of RUedx ===========
##
sed -i 's/COMMON_SSH_PASSWORD_AUTH: "no"/COMMON_SSH_PASSWORD_AUTH: "yes"/' /var/tmp/configuration/playbooks/roles/common/defaults/main.yml
sed -i 's/.so.3gf/.so.3/g' /var/tmp/configuration/playbooks/roles/edxapp/tasks/python_sandbox_env.yml
sed -i 's/{{ elasticsearch_url }}/http:\/\/download.elasticsearch.org\/elastics\/elasticsearch\/{{ elasticsearch_file }}/' main.yml
##
sudo touch /etc/update-motd.d/51-cloudguest
##
sudo ln -s /usr/include/freetype2 /usr/include/freetype
##
## === End path of RUedx ===========

##
## Install the ansible requirements
##
cd /var/tmp/configuration
sudo -H pip install -r requirements.txt

##
## Run the edx_sandbox.yml playbook in the configuration/playbooks directory
##
cd /var/tmp/configuration/playbooks && sudo ansible-playbook -c local ./edx_sandbox.yml -i "localhost," $EXTRA_VARS