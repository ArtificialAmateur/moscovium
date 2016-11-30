#!/bin/bash

echo $'\n[>] Networking'


#-|-------------- Hosts File --------------|-

if [ -a /etc/hosts ]; then
	echo 127.0.0.1	localhost > /etc/hosts
	(echo 127.0.1.1  "$(hostname)"
	echo ::1     ip6-localhost ip6-loopback
	echo fe00::0 ip6-localnet
	echo ff00::0 ip6-mcastprefix
	echo ff02::1 ip6-allnodes 
	echo ff02::2 ip6-allrouters) >> /etc/hosts
   	echo "  [+] Hosts file cleaned."
fi


#-|-------------- SSHD Config --------------|-

if grep -iqs "PermitRootLogin yes" /etc/ssh/sshd_config; then
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
   	echo "  [+] SSHD PermitRootLogin set to no."
fi

if  grep -iqs "Protocol 1" /etc/ssh/sshd_config; then
    sed -i 's/Protocol 2,1/Protocol 2/g' /etc/ssh/sshd_config
    sed -i 's/Protocol 1,2/Protocol 2/g' /etc/ssh/sshd_config
   	echo "  [+] SSHD set to use exclusively 2."
fi
if grep -iqs "X11Forwarding yes" /etc/ssh/sshd_config; then
    sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
   	echo "  [+] SSHD X11Forwarding set to no."
fi

if grep -iqs "PermitEmptyPasswords yes" /etc/ssh/sshd_config; then
    sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
   	echo "  [+] SSHD PermitEmptyPasswords set to no."
fi


#-|-------------- Firewall --------------|-

echo "y" | ufw reset >/dev/null
ufw enable | sed 's/^/  [+] /' | sed 's/[^.]$/&./'
(ufw default deny
ufw allow SSH
ufw limit SSH
ufw logging off) &>/dev/null
echo "  [+] Firewall configured."


#-|-------------- Ports? --------------|-

cp_ports(){
    echo $'\n[>] Open Ports'

    # Shows all listening ports, as well as the services running on them. If
    # the service isn't required, you should remove it.

    rm ./open_ports 2>&1>/dev/null
    echo "   [+] Open ports:"
    netstat -tulpnwa | grep 'LISTEN\|ESTABLISHED' | grep -v "tcp6\|udp6" | awk '{ print $4 " - " $7 }' | awk -F: '{ print "	IPV4 - " $2 }' >> ./open_ports
    netstat -tulpnwa | grep 'LISTEN\|ESTABLISHED' | grep "tcp6\|udp6" | awk '{ print $4 " - " $7 }' | awk -F: '{ print "	IPV6 - " $4 }' >> ./open_ports

    while read l; do
        echo $l
        pid=$(echo $l | awk '{ print $5 }' | awk -F/ '{ print $1 }')
        #printf "\tRunning from: $(ls -la /proc/$pid/exe | awk '{ print $11 }')\n"
        command="$(cat /proc/$pid/cmdline | sed 's/\x0/ /g' | sed 's/.$//')"
        #echo "$command"
        if [[ "$command" == *"nc -l"* ]]; then
            for i in $(grep -s -r --exclude-dir={proc,lib,tmp,usr,var,libproc,sys,run,dev} "$command" $(ls -l /proc/$pid/cwd | awk '{ print $11 }') | awk -F: '{ print $1 }'); do
                printf "   [!]  $i\n"
            done
        fi
    done < ./open_ports | sed 's/^/        /' 

    # Monitor network

    echo $'\n[>] Listening Network Connections'
    netstat -ntulp | sed 's/^/        /' 

}

#-|-------------- apache2 Config --------------|-

if [ -a /etc/apache2/apache2.conf ]; then
	echo '<Directory>' >> /etc/apache2/apache2.conf
	echo -e ' \t AllowOverride None' >> /etc/apache2/apache2.conf
	echo -e ' \t Order Deny,Allow' >> /etc/apache2/apache2.conf
	echo -e ' \t Deny from all' >> /etc/apache2/apache2.conf
	echo '<Directory/>' >> /etc/apache2/apache2.conf
	echo UserDir disabled root >> /etc/apache2/apache2.conf
	echo "  [+] apache2 configured."
fi


#-|-------------- Miscellaneous Network Settings --------------|-

# SYN Cookie Protection
if grep -q 0 /proc/sys/net/ipv4/tcp_syncookies; then 
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies
	echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
	echo "  [+] syn cookie protection enabled."
fi

# Disable IPv6
if grep -q 0 /proc/sys/net/ipv6/conf/all/disable_ipv6; then
	echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
	echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
	echo "  [+] IPv6 Disabled."
fi 

# Don't act as router
(sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0 )  &>/dev/null

# Make sure no one can alter the routing tables
(sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
sysctl -w net.ipv4.conf.all.secure_redirects=0
sysctl -w net.ipv4.conf.default.secure_redirects=0)  &>/dev/null
echo "  [+] sysctl configured."


#TO-DO: monitor el open connections
#TO-DO: add ipv6 iptables rules

