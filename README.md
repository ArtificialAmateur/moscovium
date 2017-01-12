# Ubuntu 14 Script

#### Users

- Purge admin and standard users
- Lock root account
- Disable guest account
- Hide userlist
- `pam.d` configuration
    - Complexity requirements
    - Lockout policy
- `auditd` policy
- `login.defs` password configuration
- sudoers configuration

#### Networking
- Clear hosts file
- Fix `sshd` configuration
    - Set `PermitRootLogin` to no
    - Set sshd protocol to only 2
    - Set `X11Forwarding` to no
    - set `PermitEmptyPasswords` to no
- Configure firewall (ufw)
    - Reset then enable firewall
    - Set default behavior to deny
    - Allow and limit SSH
    - Turn logging off
- List ports*
- Turn on SYN Cookie Protection
- Disable IPv6
- Configure sysctl redirects

#### Software
- List `cron`, crontab*
- Clear `apt` sources list
- Delete unauthorized media
- Remove unwanted programs
- Stop non-critical services
- Update/upgrade the system/distro
- Check for updates daily
- Install media codecs
- Scan with lynis
- Scan with chrootkit, rkhunter, clamav*

#### TODO
- So much to do that keeping a list would be more effort than it's worth
