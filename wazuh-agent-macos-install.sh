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
#find mac CPU arch
arch=$(uname -m)
#set to your preferred version
version="4.7.5-1"
# set Wazuh vars before running the script
WAZUH_MANAGER=""
WAZUH_REGISTRATION_PASSWORD=""
WAZUH_AGENT_GROUP=""

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

#install and register agent
registration(){
    echo "$WAZUH_MANAGER" > /tmp/wazuh_envs
    echo "$WAZUH_REGISTRATION_PASSWORD" >> /tmp/wazuh_envs
    echo "$WAZUH_AGENT_GROUP" >> /tmp/wazuh_envs
    installer -pkg ${pkg_file} -target /
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

# Update - Call functions to update FE
case $FUNCTION in
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
        echo "Usage $0: (install|unistall)
    ;;
esac
