#!/bin/bash

echo $'\n[>] Users'


#-|-------------- Check /etc/passwd --------------|-

# TO-DO

    

#-|-------------- Purge accounts  --------------|-

cp_input_accounts(){
    read -p '  [+] Please enter the valid admins: ' -a admins
    printf '%s\n' "${admins[@]}" >> data/valid_admins
    read -p '  [+] Please enter the valid standard users: ' -a users
    printf '%s\n' "${users[@]}" >> data/valid_users
}

cp_purge_accounts(){
    # Clear valid_admins and valid_users
    > valid_admins
    > valid_users

    # All valid admins are also valid users
    if ! grep -fw data/valid_admins data/valid_users; then
    	cat data/valid_admins >> data/valid_users
    fi

    # Get system users and admins
    admins="$(grep -Po '^sudo.+:\K.*$' /etc/group | tr "," "\n")"
    users="$(cat /etc/passwd | grep bash | awk -F: '{ print $1 }')"

    # Purge users
    for i in $users; do
        if grep -Fxq "$i" 'data/valid_users'; then
            # If user is authorized
            chage -E 01/01/2019 -m 5 -M 90 -I 30 -W 14 $i
            if [ "$i" != "$cp_my_user" ]; then
                echo "$i:"'CA935_CyberPatriots!' | chpasswd
                echo "    [+] $i password changed and chage password policy set."
            fi
            if [ "$i" = "$cp_my_user" ]; then
                echo "    [+] $i chage password policy set."
            fi
        else
            if [ "$i" != "root" ]; then
                read -p "    [?] $i is not an authorized user. Remove them and their files? (y/n) " choice
                case "$choice" in 
                  y|Y ) userdel -r $i &>/dev/null && echo "    [+] $i removed.";;
                  * ) echo "    [-] $i not removed.";;
                esac
            fi
        fi
    done

    # Purge admins
    for i in $admins; do
        if ! grep -Fxq "$i" 'data/valid_admins'; then
            gpasswd -d $i sudo &>/dev/null
            echo "    [+] $i is not an authorized admin. $i removed from sudo group."    
        fi
    done
}

read -p "  [?] Edit and correct valid admins and users? (y/n) " choice
case "$choice" in 
  y|Y ) read -p "  [?] What is your username? " cp_my_user && cp_input_accounts && echo "  [+] Valid admins and users edited." && cp_purge_accounts;;
esac


#-|-------------- Lock root account --------------|-

if ! passwd -S | grep -q "root L"; then
    echo "root:"'$1$FvmieeAj$cDmFLn5RvjYphj3iL1RJZ/' | chpasswd -e
    passwd -l root 2>&1>/dev/null
    echo "  [+] Root account locked."
fi


#-|-------------- Guest Account, Userlist --------------|-

sed -i 's/allow-guest=true/allow-guest-false/g' /etc/lightdm/lightdm.conf 2>&1>/dev/null
if grep -q "allow-guest=false" /etc/lightdm/lightdm.conf; then
	cat <<-EOF > /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
		[SeatDefaults]
		greeter-session=unity-greeter
		user-session=ubuntu
        greeter-hide-users=true
		allow-guest=false
		EOF
    echo "  [-] Guest account already disabled, but updated anyway just in case."
else
    echo "allow-guest=false" >> /etc/lightdm/lightdm.conf
	cat <<-EOF > /usr/share/lightdm/lightdm.conf.d/50-unity-greeter.conf
		[SeatDefaults]
		greeter-session=unity-greeter
		user-session=ubuntu
        greeter-hide-users=true
		allow-guest=false
		EOF
echo "  [+] Guest account disabled, userlist hidden."
fi


#-|-------------- pam.d Policy --------------|-

echo "  [+] Installing libpam-cracklib..."
apt-get install libpam-cracklib -y &> /dev/null

# Set common-password configuration
echo "password requisite pam_cracklib.so retry=3 minlen=6 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1" >> /etc/pam.d/common-password
echo "#auth optional pam_tally.so deny=5 unlock_time=900 onerr=fail audit silent " >> /etc/pam.d/common-auth
echo "#password requisite pam_pwhistory.so use_authtok remember=24" >>  /etc/pam.d/common-password
echo "    [+] /etc/pam.d/common-password set."

# Set common-auth configuration
if ! grep -q "pam_tally2.so deny=5 onerr=fail unlock_time=1800" /etc/pam.d/common-auth; then
    echo "auth    required                        pam_tally2.so deny=5 onerr=fail unlock_time=1800" >> /etc/pam.d/common-auth
echo "    [+] Lockout Policy set in /etc/common-auth."
fi   

#-|-------------- audtid Policy --------------|-

# Set auditd policy configuration
echo "  [+] Installing/updating auditd..."
echo 'y' | apt-get install auditd &>/dev/null
auditctl -e 1 &>/dev/null
echo "    [+] Audit policy set with auditd."


#-|-------------- Password Policy --------------|-

sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   30' /etc/login.defs
sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   7'  /etc/login.defs
sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   14' /etc/login.defs


#-|-------------- sudoers Config --------------|-

if grep NOPASSWD /etc/sudoers; then
	to_remove=$(grep NOPASSWD /etc/sudoers)
	sed -i "s/${to_remove}/ /g" /etc/sudoers
    echo "  [+] sudoers NOPASSWD rule(s) removed."
fi

#TO-DO- add other rogue rule smashers
# if you get locked out, pam_tally --user=<user> --reset
# check /etc/pam.d/login vs /etc/pam.d/sshd

