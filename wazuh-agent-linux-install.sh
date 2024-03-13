#!/bin/bash

# Program to install Wazuh manager along Open Distro for Elasticsearch
# Copyright (C) 2015-2021, Wazuh Inc.
# Copyright (C) 2022 Cloudfence Ltda
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

#prompt user for the required info
echo -n "Wazuh Manager Address: "
read WAZUH_MANAGER
echo -n "Wazuh Manager Registration Key: "
read WAZUH_PASSWORD

# Check if both parameters are provided
if [ -z "$WAZUH_MANAGER" ] || [ -z "$WAZUH_PASSWORD" ]; then
    echo "Both parameters are required."
    exit 1
fi

# check which package manager this system uses
if [ -n "$(command -v yum)" ]; then
    PKG_MGR_CMD=$(which yum)
    PKG_MGR="yum"
elif [ -n "$(command -v zypper)" ]; then
    PKG_MGR_CMD=$(which zypper)
    PKG_MGR="zypper"
elif [ -n "$(command -v apt-get)" ]; then
    PKG_MGR_CMD=$(which apt-get)
    PKG_MGR="apt-get"
else
    echo "Not supported package manager"
fi

case $PKG_MGR in
    yum)
        rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
        cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
   
    ;;
    zypper)
        rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
        cat > /etc/zypp/repos.d/wazuh.repo <<\EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
    $PKG_MGR_CMD refresh
    ;;
    apt-get)
        CURL_CMD=$(which curl)
        if [ -z "$CURL_CMD" ]; then
            echo "curl is necessary to run this script. Please install it and try again"
            exit 1
        fi
        curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
        echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
        $PKG_MGR_CMD update
    ;;
    *)
        echo "Not supported package manager"
    ;;
esac 


# Preceed to installation
$PKG_MGR_CMD install wazuh-agent

# change configuration
sed -i "s/MANAGER_IP/${WAZUH_MANAGER}/" /var/ossec/etc/ossec.conf

# if specified password 
if [ ! -z "WAZUH_PASSWORD" ]; then
    echo "$WAZUH_PASSWORD" > /var/ossec/etc/authd.pass
    chmod 644 /var/ossec/etc/authd.pass
    chown root:wazuh /var/ossec/etc/authd.pass
fi

# enable remote commands from Wazuh Manager - COMMENT IF YOU DON'T WANT THIS!!
echo "sca.remote_commands=1" >> /var/ossec/etc/local_internal_options.conf

if [ -n "$(command -v systemctl)" ]; then
    systemctl daemon-reload
    systemctl enable wazuh-agent
    systemctl start wazuh-agent
else
# Redhat based 
    if [ "$PKG_MGR" == "yum" ];then
        chkconfig --add wazuh-agent
        service wazuh-agent start
# Debian based 
    else
        update-rc.d wazuh-agent defaults 95 10
        service wazuh-agent start
    fi
fi

#Disabling automatic updates
if [ "$PKG_MGR" == "yum" ];then
    sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo
elif [ "$PKG_MGR" == "apt-get" ];then
    sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
    apt-get update
elif [ "$PKG_MGR" == "zypper" ];then
    sed -i "s/^enabled=1/enabled=0/" /etc/zypp/repos.d/wazuh.repo
else
    echo "Not supported package manager"
fi
