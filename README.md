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

---

## Using Environment Variables (Automated Deployment)

The installation scripts support **environment variables** to allow **fully automated deployments** without interactive prompts.

This is recommended when deploying agents through:

- automation tools (Ansible, Terraform, etc.)
- MDM platforms
- provisioning scripts
- CI/CD pipelines

### Supported Variables

| Variable | Description |
|--------|-------------|
| `WAZUH_MANAGER` | Wazuh manager or worker hostname/IP |
| `WAZUH_REGISTRATION_SERVER` | Server used for agent enrollment |
| `WAZUH_AGENT_NAME` | Name assigned to the agent |
| `WAZUH_AGENT_GROUP` | Group assigned during enrollment |
| `WAZUH_REGISTRATION_PASSWORD` | Enrollment password (if enabled) |

---

### Example – Linux installation with variables

```bash
WAZUH_MANAGER=worker1.soc.local \
WAZUH_REGISTRATION_SERVER=worker1.soc.local \
WAZUH_AGENT_GROUP=linux \
WAZUH_AGENT_NAME=$(hostname) \
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-linux-install.sh | sudo bash
```

or using `wget`:

```bash
WAZUH_MANAGER=worker1.soc.local \
WAZUH_REGISTRATION_SERVER=worker1.soc.local \
WAZUH_AGENT_GROUP=linux \
WAZUH_AGENT_NAME=$(hostname) \
wget -qO- https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-linux-install.sh | sudo bash
```

---

### Example – macOS installation with variables

```bash
sudo WAZUH_MANAGER=worker1.soc.local \
WAZUH_REGISTRATION_SERVER=worker1.soc.local \
WAZUH_AGENT_GROUP=macos \
WAZUH_AGENT_NAME=$(scutil --get ComputerName) \
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-macos-install.sh | sudo bash -s install
```

---

## Enrollment Flow

When `WAZUH_REGISTRATION_SERVER` is defined:

1. The agent performs **enrollment (port 1515)** with the specified server.
2. The server registers the agent in the Wazuh cluster.
3. The agent then establishes the **event communication (port 1514)** with the manager defined in `WAZUH_MANAGER`.

In clustered environments this allows directing agent registrations to **specific worker nodes**.

---

## Example for clustered environments

Example DNS architecture:

```
agents-linux.soc.local   -> worker1
agents-macos.soc.local   -> worker2
agents-windows.soc.local -> worker3
```

Installation example:

```bash
WAZUH_MANAGER=agents-linux.soc.local \
WAZUH_REGISTRATION_SERVER=agents-linux.soc.local \
curl -s https://raw.githubusercontent.com/cloudfence/wazuh-utils/main/wazuh-agent-linux-install.sh | sudo bash
```

This approach allows:

- distributing agent load across workers
- simplifying deployment automation
- improving cluster scalability

---

## Option B – Clone the repository

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
