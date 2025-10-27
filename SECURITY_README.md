# Linode Server Security Setup

A comprehensive security hardening setup for Ubuntu 24.04 LTS servers with automated Ansible playbooks.

## 📋 Overview

This repository contains scripts and playbooks to secure a fresh Linode Ubuntu server before installing additional software. It implements security best practices including user management, SSH hardening, firewall configuration, and intrusion prevention.

## 🔒 Security Features

- ✅ **Non-root deployment user** with sudo privileges
- ✅ **SSH hardening** (custom port, key-only auth, disabled root)
- ✅ **UFW firewall** configuration
- ✅ **Fail2ban** for intrusion prevention
- ✅ **Automatic security updates**
- ✅ **System hardening** via sysctl
- ✅ **Audit logging** with auditd

## 📁 Files

| File | Description |
|------|-------------|
| `SERVER_SECURITY_GUIDE.md` | Complete step-by-step security guide |
| `secure_quickstart.sh` | All-in-one automated setup script |
| `security_hardening.yml` | Ansible playbook for security hardening |
| `quickstart.yml` | Application installation playbook |
| `docker.yml` | Docker installation playbook |
| `ansible.cfg` | Ansible configuration |
| `key_uploads.sh` | SSH key management script |

## 🚀 Quick Start

### Option 1: Automated Script (Recommended)

```bash
# Download and run the secure quickstart script
wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/secure_quickstart.sh
chmod 755 secure_quickstart.sh
sudo bash secure_quickstart.sh
```

This script will:
1. Create the deploy user with password
2. Configure SSH security (port 2236)
3. Set up UFW firewall
4. Install and configure fail2ban
5. Enable automatic security updates
6. Apply system hardening
7. Install Docker and development tools

### Option 2: Manual Step-by-Step

Follow the comprehensive guide in `SERVER_SECURITY_GUIDE.md` for manual setup with detailed explanations.

### Option 3: Ansible Only

```bash
# Install Ansible
sudo apt update && sudo apt install ansible -y

# Run security hardening
export DEPLOY_PASSWORD="your_secure_password"
ansible-playbook security_hardening.yml
```

## ⚙️ Configuration

### Default Settings

```bash
DEPLOY_USER="deploy"
SSH_PORT="2236"
ALLOWED_PORTS="2236,80,443"
```

### Customization

Edit the variables in `secure_quickstart.sh` or `security_hardening.yml`:

```yaml
vars:
  deploy_user: "deploy"
  ssh_port: 2236
```

## 🔐 Post-Installation

### 1. Test SSH Connection

**IMPORTANT:** Test before closing your root session!

```bash
# From your local machine
ssh -p 2236 deploy@your_server_ip

# Test sudo access
sudo whoami  # Should return 'root'
```

### 2. Update Local SSH Config

Add to `~/.ssh/config` on your local machine:

```
Host linode-server
    HostName your_server_ip
    User deploy
    Port 2236
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Now connect with: `ssh linode-server`

### 3. Verify Security Features

```bash
# Check UFW status
sudo ufw status verbose

# Check fail2ban
sudo fail2ban-client status sshd

# Check SSH configuration
sudo sshd -t

# View listening ports
sudo ss -tulpn
```

## 🛠️ Useful Commands

### Firewall Management

```bash
# Check firewall status
sudo ufw status numbered

# Allow a new port
sudo ufw allow 8080/tcp

# Delete a rule
sudo ufw delete [rule_number]

# Disable/enable firewall
sudo ufw disable
sudo ufw enable
```

### Fail2ban Management

```bash
# Check status
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client get sshd banned

# Unban an IP
sudo fail2ban-client set sshd unbanip IP_ADDRESS

# Ban an IP manually
sudo fail2ban-client set sshd banip IP_ADDRESS
```

### SSH Troubleshooting

```bash
# Check SSH service status
sudo systemctl status sshd

# View SSH logs
sudo tail -f /var/log/auth.log

# Test SSH configuration
sudo sshd -t

# Restart SSH
sudo systemctl restart sshd
```

### Security Auditing

```bash
# View failed login attempts
sudo grep "Failed password" /var/log/auth.log

# Check who's logged in
who

# View last logins
last

# Check for rootkits (after installation)
sudo rkhunter --check

# Security audit with Lynis (after installation)
sudo lynis audit system
```

## 🆘 Troubleshooting

### Locked Out of SSH

1. Access via Linode's Lish console
2. Check SSH config: `sudo vim /etc/ssh/sshd_config`
3. Verify firewall rules: `sudo ufw status`
4. Restart SSH: `sudo systemctl restart sshd`

### Firewall Blocking Connection

```bash
# Via Lish console
sudo ufw disable
sudo ufw allow 2236/tcp
sudo ufw enable
```

### Fail2ban Banned Your IP

```bash
# Via Lish console
sudo fail2ban-client set sshd unbanip YOUR_IP
```

### SSH Key Issues

```bash
# Check permissions
ls -la ~/.ssh/
# Should be:
# drwx------ .ssh/
# -rw------- authorized_keys

# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## 📊 Security Checklist

After running the setup, verify:

- [ ] Deploy user created and has sudo access
- [ ] Can SSH as deploy user on port 2236
- [ ] Cannot SSH as root
- [ ] Password authentication disabled
- [ ] UFW firewall enabled and configured
- [ ] Fail2ban running and monitoring SSH
- [ ] Automatic security updates enabled
- [ ] System hardening applied (sysctl)
- [ ] Old SSH session works before closing

## 🔄 Maintenance

### Daily
- Review auth logs: `sudo grep "Failed password" /var/log/auth.log`
- Check fail2ban: `sudo fail2ban-client status sshd`

### Weekly
- Check for updates: `sudo apt update && apt list --upgradable`
- Review firewall logs: `sudo grep UFW /var/log/syslog`

### Monthly
- Run security audit: `sudo lynis audit system`
- Review user accounts: `cat /etc/passwd`
- Check for rootkits: `sudo rkhunter --check`

## 📚 Additional Resources

- [Ubuntu Security Guide](https://ubuntu.com/security)
- [SSH Hardening Guide](https://www.ssh.com/academy/ssh/hardening)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Fail2ban Manual](https://www.fail2ban.org/wiki/index.php/Manual)
- [Linode Security Best Practices](https://www.linode.com/docs/guides/security/)

## ⚠️ Security Warnings

1. **Always test SSH** before closing your root session
2. **Backup your SSH config** before making changes
3. **Keep your local SSH keys secure** - never share private keys
4. **Use strong passwords** for the deploy user
5. **Regular updates** - keep your system patched
6. **Monitor logs** - check for suspicious activity
7. **Backup your server** - regular backups are crucial

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements.

## 📄 License

MIT License - feel free to use and modify as needed.

## 👤 Author

**guinslym**
- GitHub: [@guinslym](https://github.com/guinslym)

---

**Last Updated:** October 2025

**Tested On:** Ubuntu 24.04 LTS

**Supports:** Linode, DigitalOcean, AWS EC2, and other VPS providers
