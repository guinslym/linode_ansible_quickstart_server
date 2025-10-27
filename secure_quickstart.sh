#!/usr/bin/env bash

# Secure Linode Server Quickstart Script
# This script first hardens server security, then runs installation tasks
# Author: guinslym
# Date: October 2025

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_USER="deploy"
SSH_PORT="2236"
GITHUB_REPO="https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Secure Linode Server Setup${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

print_message "Starting secure server setup..."

# ============================================
# Phase 1: Security Hardening
# ============================================

print_message "Phase 1: Security Hardening"
echo ""

# Update system
print_message "Updating system packages..."
apt update -y
DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install essential tools
print_message "Installing essential tools..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    wget \
    curl \
    ansible \
    ufw \
    fail2ban \
    vim \
    git

# Download security playbook
print_message "Downloading security hardening playbook..."
wget --no-check-certificate --no-cache --no-cookies \
    ${GITHUB_REPO}/security_hardening.yml -O /tmp/security_hardening.yml

# Check if deploy user already exists
if id "$DEPLOY_USER" &>/dev/null; then
    print_warning "User '$DEPLOY_USER' already exists. Skipping user creation."
else
    print_message "Creating deploy user '$DEPLOY_USER'..."
    
    # Prompt for password
    while true; do
        read -sp "Enter password for deploy user: " DEPLOY_PASSWORD
        echo
        read -sp "Confirm password: " DEPLOY_PASSWORD_CONFIRM
        echo
        
        if [ "$DEPLOY_PASSWORD" = "$DEPLOY_PASSWORD_CONFIRM" ]; then
            break
        else
            print_error "Passwords do not match. Please try again."
        fi
    done
    
    # Create user
    useradd -m -s /bin/bash -G sudo "$DEPLOY_USER"
    echo "$DEPLOY_USER:$DEPLOY_PASSWORD" | chpasswd
    
    # Copy SSH keys from root
    if [ -d /root/.ssh ] && [ -f /root/.ssh/authorized_keys ]; then
        print_message "Copying SSH keys to deploy user..."
        mkdir -p /home/$DEPLOY_USER/.ssh
        cp /root/.ssh/authorized_keys /home/$DEPLOY_USER/.ssh/
        chown -R $DEPLOY_USER:$DEPLOY_USER /home/$DEPLOY_USER/.ssh
        chmod 700 /home/$DEPLOY_USER/.ssh
        chmod 600 /home/$DEPLOY_USER/.ssh/authorized_keys
    else
        print_warning "No SSH keys found in /root/.ssh/"
        print_warning "You'll need to manually add SSH keys for the deploy user"
    fi
fi

# Configure UFW before changing SSH port
print_message "Configuring firewall..."
ufw --force default deny incoming
ufw --force default allow outgoing
ufw --force allow $SSH_PORT/tcp comment 'SSH custom port'
ufw --force allow 80/tcp comment 'HTTP'
ufw --force allow 443/tcp comment 'HTTPS'
ufw --force enable

# Backup SSH config
print_message "Backing up SSH configuration..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Configure SSH security
print_message "Hardening SSH configuration..."
sed -i "s/^#\?Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/^#\?PermitRootLogin .*/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/^#\?PasswordAuthentication .*/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i "s/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sed -i "s/^#\?PermitEmptyPasswords .*/PermitEmptyPasswords no/" /etc/ssh/sshd_config
sed -i "s/^#\?X11Forwarding .*/X11Forwarding no/" /etc/ssh/sshd_config
sed -i "s/^#\?MaxAuthTries .*/MaxAuthTries 3/" /etc/ssh/sshd_config

# Add AllowUsers if not present
if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
    echo "AllowUsers $DEPLOY_USER" >> /etc/ssh/sshd_config
fi

# Validate SSH config
print_message "Validating SSH configuration..."
sshd -t

# Configure fail2ban
print_message "Configuring fail2ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

cat > /etc/fail2ban/jail.d/ssh-custom.conf <<EOF
[sshd]
enabled = true
port = $SSH_PORT
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
findtime = 10m
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Configure automatic security updates
print_message "Enabling automatic security updates..."
DEBIAN_FRONTEND=noninteractive apt install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# System hardening with sysctl
print_message "Applying system security settings..."
cat > /etc/sysctl.d/99-security.conf <<EOF
# IP Forwarding
net.ipv4.ip_forward = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Enable SYN cookies
net.ipv4.tcp_syncookies = 1

# Disable ICMP broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Enable reverse path filtering
net.ipv4.conf.all.rp_filter = 1
EOF

sysctl -p /etc/sysctl.d/99-security.conf

print_message "Security hardening complete!"
echo ""

# ============================================
# Phase 2: Application Installation
# ============================================

print_message "Phase 2: Installing applications and tools"
echo ""

# Download configuration files
print_message "Downloading configuration files..."
wget --no-check-certificate --no-cache --no-cookies \
    ${GITHUB_REPO}/ansible.cfg -O /tmp/ansible.cfg

wget --no-check-certificate --no-cache --no-cookies \
    ${GITHUB_REPO}/quickstart.yml -O /tmp/quickstart.yml

wget --no-check-certificate --no-cache --no-cookies \
    ${GITHUB_REPO}/docker.yml -O /tmp/docker.yml

# Run quickstart playbook
print_message "Running quickstart playbook..."
cd /tmp
ansible-playbook quickstart.yml

# Install additional tools
print_message "Installing additional tools..."
DEBIAN_FRONTEND=noninteractive apt install -y neofetch

# Run Docker installation
print_message "Installing Docker..."
ansible-playbook docker.yml

# Install docker-machine (if needed)
print_message "Installing docker-machine..."
curl -L https://github.com/docker/machine/releases/download/v0.13.0/docker-machine-$(uname -s)-$(uname -m) -o /tmp/docker-machine
chmod +x /tmp/docker-machine
cp /tmp/docker-machine /usr/local/bin/

# Install Oh My Zsh for deploy user
print_message "Installing Oh My Zsh for deploy user..."
su - $DEPLOY_USER -c 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'

# Add neofetch to bash login for deploy user
if ! grep -q "neofetch" /home/$DEPLOY_USER/.bash_login 2>/dev/null; then
    echo 'neofetch' >> /home/$DEPLOY_USER/.bash_login
fi

# Cleanup
print_message "Cleaning up..."
rm -f /tmp/security_hardening.yml
rm -f /tmp/quickstart.yml
rm -f /tmp/docker.yml
rm -f /tmp/docker-machine
rm -f /tmp/ansible.cfg

# ============================================
# Final Summary
# ============================================

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: Before closing this session!${NC}"
echo ""
echo -e "1. Test SSH connection in a NEW terminal:"
echo -e "   ${GREEN}ssh -p $SSH_PORT $DEPLOY_USER@\$(hostname -I | awk '{print \$1}')${NC}"
echo ""
echo -e "2. Verify sudo access:"
echo -e "   ${GREEN}sudo whoami${NC} (should return 'root')"
echo ""
echo -e "3. Security features enabled:"
echo -e "   - SSH Port: ${GREEN}$SSH_PORT${NC}"
echo -e "   - Root Login: ${RED}Disabled${NC}"
echo -e "   - Password Auth: ${RED}Disabled${NC}"
echo -e "   - UFW Firewall: ${GREEN}Enabled${NC}"
echo -e "   - Fail2ban: ${GREEN}Enabled${NC}"
echo -e "   - Auto Updates: ${GREEN}Enabled${NC}"
echo ""
echo -e "4. Add this to your local ${GREEN}~/.ssh/config${NC}:"
echo ""
echo -e "   ${GREEN}Host linode-server${NC}"
echo -e "   ${GREEN}    HostName \$(hostname -I | awk '{print \$1}')${NC}"
echo -e "   ${GREEN}    User $DEPLOY_USER${NC}"
echo -e "   ${GREEN}    Port $SSH_PORT${NC}"
echo -e "   ${GREEN}    IdentityFile ~/.ssh/id_rsa${NC}"
echo ""
echo -e "${YELLOW}DO NOT close this session until you've verified SSH access!${NC}"
echo ""
echo -e "${GREEN}Press Enter to restart SSH and apply changes...${NC}"
read -r

# Restart SSH
systemctl restart sshd

echo -e "${GREEN}SSH restarted. Test your connection now!${NC}"
echo ""
