#!/bin/bash

####################

# CA-935th Ubuntu Script
# @sourshane
# @ArtificialAmateur
# v 0.8
# Thanks to Connor, Joshua, Will for a lot of the work

###################


#-|-------------- Launcher --------------|-

clear

while true; do
echo $'\n[?] Select from the menu:' 
echo "
  1) Users 
  2) Software
  3) Networking  

 99) Exit
"

read -p "setup> " choice
    case "$choice" in
      1 ) modules/users.sh;;
      2 ) modules/software.sh;;
      3 ) modules/network.sh;;
      * ) exit;;
    esac
done
