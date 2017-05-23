#!/bin/bash

####################

# @sourshane
# @ArtificialAmateur
# v 0.9
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
      1 | Users | users ) modules/users.sh;;
      2 | Software | software ) modules/software.sh;;
      3 | Networking | networking ) modules/network.sh;;
      * ) exit;;
    esac
done
