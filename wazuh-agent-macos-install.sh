#!/bin/bash
#    Copyright (C) 2024 Cloudfence
#    Copyright (C) 2015-2024 Wazuh Inc
#    All rights reserved.
#
#    Redistribution and use in source and binary forms, with or without
#    modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.#
#
#    2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
#    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
#    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
#    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#    POSSIBILITY OF SUCH DAMAGE.

#install and register agent
registration(){
    #find mac CPU arch
    arch=$(uname -m)
    #set to your preferred agent version
    version="4.7.5-1"
    # set Wazuh vars before running the script
    manager_address=""
    reg_password=""
    agent_group=""

    if [ -z "$manager_address" ] && [ -z "$reg_password" ] && [ -z "$agent_group" ];then
        echo "Please set the Wazuh Manager and Registration Password and Agent Group before try instaling agent"
        exit 1
    fi



    # intel or silicon
    if [ "$arch" == "x86_64" ];then
        pkg_file="wazuh-agent-${version}.arm64.pkg"
        curl -O https://packages.wazuh.com/4.x/macos/${pkg_file} 
    elif [ "$arch" == "arm64" ];then
        pkg_file="wazuh-agent-${version}.arm64.pkg"
        curl -O https://packages.wazuh.com/4.x/macos/${pkg_file} 
    else
        echo "Unknown architecture: $arch"
        exit 1
    fi
    
    #run install
    installer -pkg ${pkg_file} -target /
    /Library/Ossec/bin/agent-auth -m "$manager_address" -P $reg_password -G $agent_group
    # Save the registration password to the authd.pass file
    echo $reg_password | sudo tee /Library/Ossec/etc/authd.pass > /dev/null
    # Update the ossec.conf file with the manager IP
    sudo sed -i '' "s|<address>MANAGER_IP</address>|<address>${manager_address}</address>|g" /Library/Ossec/etc/ossec.conf
    # Start the Wazuh agent service
    /Library/Ossec/bin/wazuh-control start
}

#uninstall 
uninstall(){
    /Library/Ossec/bin/wazuh-control stop
    /bin/rm -r /Library/Ossec
    /bin/rm -f /Library/LaunchDaemons/com.wazuh.agent.plist
    /bin/rm -rf /Library/StartupItems/WAZUH
    /usr/bin/dscl . -delete "/Users/wazuh"
    /usr/bin/dscl . -delete "/Groups/wazuh"
    /usr/sbin/pkgutil --forget com.wazuh.pkg.wazuh-agent
}

#get arg
function="$1"

# Check if the script is running with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 
   exit 1
fi

# Update - Call functions to update FE
case $function in
    install)
        registration
    ;;
    registration)
        registration
    ;;
    uninstall)
        uninstall
    ;;
    *)
        echo "Usage $0: (install|uninstall)"
    ;;
esac