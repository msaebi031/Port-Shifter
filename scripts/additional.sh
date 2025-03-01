#!/bin/bash

source /opt/Port-Shifter/scripts/path.sh
source /opt/Port-Shifter/scripts/package.sh

configure_dns() {
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    sudo rm /etc/resolv.conf > /dev/null 2>&1

    echo "Enter DNS Server 1 (like 8.8.8.8):"
    read dns1

    if [ -z "$dns1" ]; then
        echo "Operation cancelled or invalid input. Restoring default DNS configuration."
        restore_dns
        exit 1
    fi

    echo "Enter DNS Server 2 (like 8.8.4.4):"
    read dns2

    if [ -z "$dns2" ]; then
        echo "Operation cancelled or invalid input. Restoring default DNS configuration."
        restore_dns
        exit 1
    fi

    echo "nameserver $dns1" | sudo tee -a /etc/resolv.conf > /dev/null
    echo "nameserver $dns2" | sudo tee -a /etc/resolv.conf > /dev/null

    echo "DNS Configuration completed."
    clear
}

restore_dns() {
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf > /dev/null
}

update_server() {
    echo "Updating server..."
    sudo $PACKAGE_MANAGER update -y
    echo "Update completed."
    clear
}

ping_websites() {
    websites=("github.com" "google.com" "www.cloudflare.com")
    results_file=$(mktemp)

    for website in "${websites[@]}"; do
        echo "Pinging $website..."
        success=false

        for _ in {1..5}; do
            sleep 1  
            echo "Pinging $website..."
            if ping -c 1 $website &> /dev/null; then
                success=true
                break
            fi
        done

        if $success; then
            result="Ping successful"
        else
            result="Ping failed"
        fi

        echo -e "\nPing results for $website: $result" >> "$results_file"
    done

    cat "$results_file"
    clear

    rm "$results_file"
}
