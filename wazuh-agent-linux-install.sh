#!/bin/bash
#    Copyright (C) 2022 Cloudfence
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
