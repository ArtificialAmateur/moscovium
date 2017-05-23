#!/bin/bash

echo $'\n[>] Users'


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
                echo "$i:"'MyExamplePassword' | chpasswd
                echo "        [+] $i password changed and chage password policy set."
            fi
            if [ "$i" = "$cp_my_user" ]; then
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
  y|Y ) read -p "    [?] What is your username? " cp_my_user && cp_input_accounts && cp_create_accounts && cp_purge_accounts;;
esac

#-|-------------- Lock root account --------------|-

if ! passwd -S | grep -q "root L"; then
    echo "root:"'$1$FvmieeAj$cDmFLn5RvjYphj3iL1RJZ/' | chpasswd -e
    passwd -l root 2>&1>/dev/null
    echo "  [+] Root account locked."
fi


#-|-------------- lightdm Config --------------|-

cp /etc/lightdm/lightdm.conf data/backup_files/lightdm.conf
cp -f data/references/lightdm.conf /etc/lightdm/lightdm.conf
echo "  [+] Lightdm file secured."


#-|-------------- sudoers Config --------------|-

cp /etc/sudoers data/backup_files/sudoers.backup
cp -f data/references/sudoers /etc/sudoers
echo "  [+] Sudoers file secured."


#-|-------------- Password Policy --------------|-

if ! dpkg -s libpam-cracklib >/dev/null 2>&1; then
    echo "  [+] Installing libpam-cracklib..." &&
    apt -qq -y install libpam-cracklib
fi

cp /etc/login.defs data/backup_files/login.defs.backup
cp -f data/references/login.defs /etc/login.defs

cp /etc/pam.d/common-password data/backup_files/common-password.backup
cp -f data/references/common-password /etc/pam.d/common-password

cp /etc/pam.d/common-auth data/backup_files/common-auth.backup
cp -f data/references/common-auth /etc/pam.d/common-auth

echo "  [+] Password policy set."

#-|-------------- audtid Policy --------------|-

if ! dpkg -s auditd >/dev/null 2>&1; then
    echo "  [+] Installing auditd..." &&
    apt -qq -y install auditd
    auditctl -e 1 &>/dev/null
    echo "    [+] Audit policy set with auditd."
fi


#TO-DO- add other rogue rule smashers
# if you get locked out, pam_tally --user=<user> --reset
# check /etc/pam.d/login vs /etc/pam.d/sshd

