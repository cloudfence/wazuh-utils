# Wazuh Utils

Helper scripts for installing and managing **Wazuh agents** on Linux and macOS.

These utilities simplify deployments, standardize installation steps, and reduce configuration errors across environments.

---

## Contents

- **wazuh-agent-linux-install.sh**  
  Installs the Wazuh agent on supported Linux distributions.

- **wazuh-agent-macos-install.sh**  
  Installs or uninstalls the Wazuh agent on macOS.

---

## Requirements

Before using the scripts:

- A reachable **Wazuh Manager** (IP or hostname)  
- Root or sudo privileges  
- (Optional) Enrollment password or group configuration  

---

## Getting Started

You can either use a **one-liner install** (recommended for most cases) or clone the repository manually.

### Option A – Quick install (one-liner)

Run directly from the CLI without cloning the repo.

#### Linux

```bash
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-linux-install.sh | sudo bash
```

or with `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-linux-install.sh | sudo bash
```

#### macOS

Install:

```bash
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-macos-install.sh | sudo bash -s install
```

Uninstall:

```bash
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-macos-install.sh | sudo bash -s uninstall
```

### Option B – Clone the repository

```bash
git clone https://github.com/cloudfence/wazuh-utils.git
cd wazuh-utils
```

Make the scripts executable if needed:

```bash
chmod +x wazuh-agent-*.sh
```

---

# 1. Linux Agent Installation  
## `wazuh-agent-linux-install.sh`

This script automates:

- Adding the Wazuh package repository  
- Installing the Wazuh agent  
- Configuring the manager connection  
- Enabling and starting the agent service  

### Usage (one-liner)

```bash
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-linux-install.sh | sudo bash
```

or, after cloning the repo:

```bash
sudo ./wazuh-agent-linux-install.sh
```

You may be prompted for:

- Manager IP/hostname  
- Agent name  
- Agent group  
- Enrollment password  

### Verify status

```bash
sudo systemctl status wazuh-agent
```

### Uninstalling the agent

**Debian/Ubuntu**

```bash
sudo systemctl stop wazuh-agent
sudo apt-get remove --purge wazuh-agent
sudo rm -rf /var/ossec
```

**RHEL/CentOS/Rocky/Alma**

```bash
sudo systemctl stop wazuh-agent
sudo yum remove -y wazuh-agent
sudo rm -rf /var/ossec
```

---

# 2. macOS Agent Installation  
## `wazuh-agent-macos-install.sh`

Manages installation and removal of the Wazuh agent on macOS.

### Install (one-liner)

```bash
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-macos-install.sh | sudo bash -s install
```

or, after cloning the repo:

```bash
sudo ./wazuh-agent-macos-install.sh install
```

### Uninstall (one-liner)

```bash
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-macos-install.sh | sudo bash -s uninstall
```

or, after cloning the repo:

```bash
sudo ./wazuh-agent-macos-install.sh uninstall
```

### Check status

```bash
sudo /Library/Ossec/bin/wazuh-control status
```

### Notes for macOS

Depending on version, macOS may require:

- Approving installer in **System Settings → Privacy & Security**
- Allowing system extensions

---

# Troubleshooting

### Agent not appearing in Wazuh

Check service:

```bash
sudo systemctl status wazuh-agent
sudo /Library/Ossec/bin/wazuh-control status
```

Test connectivity:

```bash
ping <manager-ip>
```

View logs:

```bash
sudo tail -n 50 /var/ossec/logs/ossec.log
```

### Version mismatch

Ensure agent version is equal to or lower than the manager version.

### Proxy/offline environments

Set proxy if needed:

```bash
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
```

Use offline packages when required.
