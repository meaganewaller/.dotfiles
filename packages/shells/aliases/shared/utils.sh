#!/usr/bin/env bash

# Utility aliases

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../../'

alias ls="ls --color=auto"
alias ll="ls -asl"

# print current week number
alias week='date +%V'

# Network Diagnostics
alias ruok='
    echo "Pinging Google..."
    ping -c 2 google.com;
    echo -e "\nDNS Lookup for Google:"
    dig +short google.com;
    echo -e "\nHeaders from Google homepage:"
    curl -I http://www.google.com 2>/dev/null | head -n 1;
    echo -e "\nChecking Google reachability with wget..."
    wget -q --spider www.google.com;
    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo "NOT OKAY"
    fi
    echo -e "\nDNS Lookup for Google using nslookup:"
    nslookup google.com
'