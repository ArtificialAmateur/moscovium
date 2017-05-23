#!/bin/bash

echo $'\n[>] Networking'


#-|-------------- Hosts File --------------|-

echo '127.0.0.1' $HOSTNAME >> data/references/hosts
cp /etc/hosts data/backup_files/hosts.backup
cp -f data/references/hosts /etc/hosts
echo "  [+] Cleaned hosts file."


#-|-------------- SSHD Config --------------|-

cp /etc/ssh/ssh_config data/backup_files/ssh_config.backup
cp -f data/references/ssh_config /etc/ssh/ssh_config

cp /etc/ssh/sshd_config data/backup_files/sshd_config.backup
cp -f data/references/sshd_config /etc/ssh/sshd_config
echo "  [+] Secured ssh settings."


#-|-------------- Firewall --------------|-

if ! dpkg -s ufw >/dev/null 2>&1; then 
    echo "    [+] Installing ufw..."
    apt -qq -y install ufw
fi
echo "y" | ufw reset >/dev/null
ufw default deny >/dev/null 2>&1
ufw logging on >/dev/null 2>&1

services_length="$(sed -n '$=' data/valid_admins)"
for ((i=1; i<=services_length; i++)); do
	service="$(awk 'FNR == $i { print; exit }' data/critical_services | tr '[:lower:]' '[:upper:]')"
	ufw allow $service >/dev/null 2>&1
	if [ "$service" = "SSH" ]; then
		ufw limit SSH >/dev/null 2>&1
	fi
done
ufw enable >/dev/null 2>&1
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

if [ -e /etc/apache2/apache2.conf ]; then
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
	echo "  [+] SYN cookie protection enabled."
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


#TO-DO: monitor el open connections
#TO-DO: use tcpdump
#TO-DO: make apache2, wordpress, mysql reference files.
