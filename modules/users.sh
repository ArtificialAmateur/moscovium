#!/bin/bash

echo $'\n[>] Users'


#-|-------------- Check /etc/passwd --------------|-

# TO-DO

    

#-|-------------- Purge accounts  --------------|-

cp_input_accounts(){
    # Clear valid_admins and valid_users
    echo '' > valid_admins
    echo '' > valid_users

    read -p '      [+] Please enter the valid admins: ' -a admins
    printf '%s\n' "${admins[@]}" >> data/valid_admins
    read -p '      [+] Please enter the valid standard users: ' -a users
    printf '%s\n' "${users[@]}" >> data/valid_users
}

cp_purge_accounts(){
    # All valid admins are also valid users
    if ! grep -wq -f data/valid_admins data/valid_users; then
    	cat data/valid_admins >> data/valid_users
    fi

    # Get system users and admins
    admins="$(grep -Po '^sudo.+:\K.*$' /etc/group | tr "," "\n")"
    users="$(cat /etc/passwd | grep bash | awk -F: '{ print $1 }')"

    # Purge users
    for i in $users; do
        if grep -Fxqs "$i" 'data/valid_users'; then
            # If user is authorized
            chage -E 01/01/2019 -m 5 -M 90 -I 30 -W 14 $i
            if [ "$i" != "$cp_my_user" ]; then
                echo "$i:"'CA935_CyberPatriots!' | chpasswd
                echo "        [+] $i password changed and chage password policy set."
            fi
            if [ "$i" = "$cp_my_user" ]; then
                chmod 0755 /home/"$cp_my_user"
                echo "      [+] $i chage password policy set."
            fi
        else
            if [ "$i" != "root" ]; then
                read -p "      [?] $i is not an authorized user. Remove them and their files? (y/n) " choice
                case "$choice" in 
                  y|Y ) userdel -r $i &>/dev/null && echo "      [+] $i removed.";;
                esac
            fi
        fi
    done

    # Purge admins
    for i in $admins; do
        if ! grep -Fxqs "$i" 'data/valid_admins'; then
            gpasswd -d $i sudo &>/dev/null
            echo "    [+] $i is not an authorized admin. $i removed from sudo group."    
        fi
    done
}

read -p "  [?] Edit and correct valid admins and users? (y/n) " choice
case "$choice" in 
  y|Y ) read -p "    [?] What is your username? " cp_my_user && cp_input_accounts && cp_purge_accounts;;
esac


#-|-------------- Lock root account --------------|-

if ! passwd -S | grep -q "root L"; then
    echo "root:"'$1$FvmieeAj$cDmFLn5RvjYphj3iL1RJZ/' | chpasswd -e
    passwd -l root 2>&1>/dev/null
    echo "  [+] Root account locked."
fi


#-|-------------- lightdm Config --------------|-

if ! grep -iq "allow-guest=false" /etc/lightdm/lightdm.conf; then
  cp -f 'data/reference/lightdm-config' '/etc/lightdm/lightdm.conf'
  echo "  [+] Disabled guest account."
fi

if ! grep -iq "greeter-hide-users=true" /etc/lightdm/lightdm.conf; then
  cp -f 'data/reference/lightdm-config' '/etc/lightdm/lightdm.conf'
  echo "  [+] Hid userlist."
fi


#-|-------------- pam.d/common-password Policy --------------|-

if ! dpkg -s libpam-cracklib >/dev/null 2>&1; then
    echo "  [+] Installing libpam-cracklib..." &&
    apt-get -qq -y install libpam-cracklib
fi

if ! grep -iq "retry=3 minlen=8 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1" /etc/pam.d/common-password; then
  cp -f 'data/reference/pamd-common-pass' '/etc/pam.d/common-password'
  echo "  [+] Password policy in /etc/pam.d/common-password set."
fi

if ! grep -iq "obscure use_authtok try_first_pass sha512 remember=5 minlen=8" /etc/pam.d/common-password; then
  cp -f 'data/reference/pamd-common-pass' '/etc/pam.d/common-password'
  echo "  [+] Password policy in /etc/pam.d/common-password set."
fi


#-|-------------- pam.d/common-auth Policy --------------|-

if ! grep -iq "deny=5 onerr=fail unlock_time=1800" /etc/pam.d/common-auth; then
    echo "auth required pam_tally2.so deny=5 onerr=fail unlock_time=1800" >> /etc/pam.d/common-auth
echo "  [+] Lockout Policy set in /etc/pam.d/common-auth."
fi   


#-|-------------- audtid Policy --------------|-

if ! dpkg -s auditd >/dev/null 2>&1; then
    echo "  [+] Installing auditd..." &&
    apt-get -qq -y install auditd
    auditctl -e 1 &>/dev/null
    echo "    [+] Audit policy set with auditd."
fi


#-|-------------- Password Policy --------------|-

if ! grep -iq "PASS_MAX_DAYS   30" /etc/login.defs; then
    sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   30' /etc/login.defs
    echo "  [+] PASS_MAX_DAYS set to 30."
fi

if ! grep -iq "PASS_MIN_DAYS   7" /etc/login.defs; then
    sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   7'  /etc/login.defs
    echo "  [+] PASS_MIN_DAYS set to 7."
fi

if ! grep -iq "PASS_WARN_AGE   14" /etc/login.defs; then
    sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   14' /etc/login.defs
    echo "  [+] PASS_WARN_AGE set to 14."
fi


#-|-------------- sudoers Config --------------|-

if grep NOPASSWD /etc/sudoers; then
	to_remove=$(grep NOPASSWD /etc/sudoers)
	sed -i "s/${to_remove}/ /g" /etc/sudoers
    echo "  [+] sudoers NOPASSWD rule(s) removed."
fi


#TO-DO- add other rogue rule smashers
# if you get locked out, pam_tally --user=<user> --reset
# check /etc/pam.d/login vs /etc/pam.d/sshd

