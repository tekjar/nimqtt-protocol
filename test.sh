#! /bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

for f in nimqtt/*.nim; do
    echo "${red}Testing: $f${reset}"
    nim c -r $f -o:bin/test
done
