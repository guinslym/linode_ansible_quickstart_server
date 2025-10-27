# Linode Ubuntu Server Security Setup Guide

## Overview
This guide walks you through securing a fresh Ubuntu 24.04 LTS Linode server before installing additional software. The security measures include creating a non-root deployment user, configuring SSH hardening, setting up a firewall, and implementing fail2ban.

**Target Configuration:**
- OS: Ubuntu 24.04 LTS
- Deploy User: `deploy`
- SSH Port: `2236`
- Editor: vim

---

## Pre-requisites

Before starting, ensure you have:
1. Root SSH access to your Linode server
2. Your local machine's SSH public key (usually `~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub`)
3. The server's IP address

---

## Step 1: Initial Connection

Connect to your server as root:

```bash
ssh root@your_server_ip
```

---

## Step 2: Update System Packages

Always start with updated packages:

```bash
apt update && apt upgrade -y
```

---

## Step 3: Create Deploy User

Create a new user named `deploy` with sudo privileges:

```bash
# Create the user
adduser deploy

# Add to sudo group
usermod -aG sudo deploy

# Verify sudo access
groups deploy
```

When prompted, set a strong password for the deploy user.

---

## Step 4: Configure SSH Key Authentication

### Option A: Copy from Root (If you're logged in as root with key auth)

```bash
# Create .ssh directory for deploy user
mkdir -p /home/deploy/.ssh

# Copy authorized_keys from root
cp /root/.ssh/authorized_keys /home/deploy/.ssh/

# Set proper permissions
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
```

### Option B: Manual Setup (From your local machine)

On your **local machine**, copy your public key to the server:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub deploy@your_server_ip
```

Or manually:

```bash
# On the server as root
mkdir -p /home/deploy/.ssh
vim /home/deploy/.ssh/authorized_keys
# Paste your public key, save and exit

chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
```

---

## Step 5: Test Deploy User Access

**IMPORTANT:** Before continuing, test the deploy user login in a NEW terminal window:

```bash
ssh deploy@your_server_ip
sudo whoami  # Should return 'root' if sudo works
```

**Do NOT close your root session until you've verified deploy user access!**

---

## Step 6: Configure SSH Security

Edit the SSH daemon configuration:

```bash
sudo vim /etc/ssh/sshd_config
```

Update or add these settings:

```
# Change SSH port
Port 2236

# Disable root login
PermitRootLogin no

# Disable password authentication (key-only)
PasswordAuthentication no
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Disable X11 forwarding (unless needed)
X11Forwarding no

# Set max authentication attempts
MaxAuthTries 3

# Enable strict mode
StrictModes yes

# Disable challenge-response auth
ChallengeResponseAuthentication no

# Only allow specific user
AllowUsers deploy

# Set login grace time
LoginGraceTime 60

# Set max sessions
MaxSessions 2
```

Validate the configuration:

```bash
sudo sshd -t
```

If no errors, restart SSH:

```bash
sudo systemctl restart sshd
```

---

## Step 7: Update Firewall Rules

Before restarting SSH, configure UFW (Uncomplicated Firewall):

```bash
# Install UFW if not present
sudo apt install ufw -y

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow new SSH port BEFORE enabling firewall
sudo ufw allow 2236/tcp

# Allow HTTP/HTTPS if needed
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

---

## Step 8: Test New SSH Configuration

From a **NEW terminal window** on your local machine:

```bash
ssh -p 2236 deploy@your_server_ip
```

If successful, you can close the old root session.

---

## Step 9: Install and Configure Fail2Ban

Fail2ban protects against brute-force attacks:

```bash
sudo apt install fail2ban -y

# Create local configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit the configuration
sudo vim /etc/fail2ban/jail.local
```

Update these settings in `jail.local`:

```ini
[DEFAULT]
# Ban time (10 minutes)
bantime = 10m

# Find time window (10 minutes)
findtime = 10m

# Max retry attempts
maxretry = 5

# Destination email (optional)
destemail = your_email@example.com

# Action
action = %(action_mwl)s

[sshd]
enabled = true
port = 2236
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
```

Start and enable fail2ban:

```bash
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Check status
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

---

## Step 10: Configure Automatic Security Updates

Install unattended-upgrades:

```bash
sudo apt install unattended-upgrades -y

# Configure
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Edit the configuration:

```bash
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

Ensure security updates are enabled:

```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
```

---

## Step 11: Additional Security Hardening

### Disable Unused Network Protocols

```bash
# Edit sysctl configuration
sudo vim /etc/sysctl.conf
```

Add these lines:

```
# IP Forwarding (disable if not routing)
net.ipv4.ip_forward = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log martian packets
net.ipv4.conf.all.log_martians = 1

# Ignore ICMP ping requests (optional)
# net.ipv4.icmp_echo_ignore_all = 1

# Enable SYN cookies
net.ipv4.tcp_syncookies = 1
```

Apply changes:

```bash
sudo sysctl -p
```

### Set Up Log Monitoring

```bash
# Install logwatch
sudo apt install logwatch -y

# Configure daily email reports (optional)
sudo vim /etc/cron.daily/00logwatch
```

---

## Step 12: Configure SSH Config on Local Machine

On your **local machine**, create/edit `~/.ssh/config`:

```bash
vim ~/.ssh/config
```

Add this entry:

```
Host linode-server
    HostName your_server_ip
    User deploy
    Port 2236
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Now you can connect simply with:

```bash
ssh linode-server
```

---

## Step 13: Final Security Checklist

Run through this checklist:

- [ ] Deploy user created with sudo access
- [ ] SSH key authentication working for deploy user
- [ ] Root login disabled
- [ ] Password authentication disabled
- [ ] SSH port changed to 2236
- [ ] UFW firewall enabled and configured
- [ ] Fail2ban installed and running
- [ ] Automatic security updates enabled
- [ ] Can connect via: `ssh -p 2236 deploy@your_server_ip`
- [ ] Old root SSH session closed

---

## Step 14: Run Your Quickstart Scripts

Now that the server is secured, you can safely run your installation scripts:

```bash
# As deploy user
cd ~
wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/quickstart.sh
chmod 755 quickstart.sh
sudo bash quickstart.sh
```

---

## Useful Commands for Monitoring

```bash
# Check failed login attempts
sudo grep "Failed password" /var/log/auth.log

# Check fail2ban status
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client get sshd banned

# Unban an IP
sudo fail2ban-client set sshd unbanip IP_ADDRESS

# Monitor active SSH sessions
who

# Check listening ports
sudo ss -tulpn

# Check firewall rules
sudo ufw status numbered

# View system logs
sudo journalctl -xe

# Monitor system with glances (after installation)
glances
```

---

## Troubleshooting

### Locked Out of SSH

If you get locked out:

1. Use Linode's Lish console to access your server
2. Fix SSH configuration in `/etc/ssh/sshd_config`
3. Restart SSH: `sudo systemctl restart sshd`

### Firewall Blocking Access

If UFW blocks your connection:

1. Access via Lish console
2. Disable UFW temporarily: `sudo ufw disable`
3. Check rules: `sudo ufw status numbered`
4. Add missing rule: `sudo ufw allow 2236/tcp`
5. Re-enable: `sudo ufw enable`

### Fail2ban Banned Your IP

1. Access via Lish console
2. Check ban: `sudo fail2ban-client status sshd`
3. Unban IP: `sudo fail2ban-client set sshd unbanip YOUR_IP`

---

## Security Maintenance Schedule

**Daily:**
- Review auth logs for suspicious activity
- Check fail2ban reports

**Weekly:**
- Review UFW logs
- Check for available security updates

**Monthly:**
- Review user accounts and permissions
- Audit installed packages
- Review and update firewall rules

---

## Additional Recommendations

1. **Use SSH Keys Only**: Never re-enable password authentication
2. **Regular Backups**: Set up automated backups of your Linode
3. **Two-Factor Authentication**: Consider adding 2FA to SSH
4. **Monitoring**: Set up monitoring tools (Prometheus, Grafana)
5. **Rate Limiting**: Consider additional rate limiting with iptables
6. **SELinux/AppArmor**: Enable mandatory access controls
7. **Regular Audits**: Run security audits with tools like Lynis

---

## References

- [Ubuntu Security Guide](https://ubuntu.com/security)
- [SSH Hardening Guide](https://www.ssh.com/academy/ssh/security)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Fail2ban Documentation](https://www.fail2ban.org/)
- [Linode Security Guide](https://www.linode.com/docs/guides/security/)

---

**Last Updated:** October 2025  
**Author:** guinslym  
**License:** MIT
