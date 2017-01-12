#!/bin/bash

####################

# CA-935th Ubuntu Script
# @sourshane
# @ArtificialAmateur
# v 0.7
# Thanks to Connor, Joshua, Will for a lot of the code

###################


#-|-------------- Launcher --------------|-

clear

while true; do
echo $'\n[?] Select from the menu:' 
echo "
  1) Users 
  2) Networking  
  3) Software

 99) Exit
"

read -p "setup> " choice
    case "$choice" in
      1 ) modules/users.sh;;
      2 ) modules/network.sh;;
      3 ) modules/software.sh;;
      * ) exit;;
    esac
done
