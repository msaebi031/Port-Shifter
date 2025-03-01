#!/bin/bash

source /opt/Port-Shifter/scripts/path.sh
source /opt/Port-Shifter/scripts/package.sh

install_gost() {
    if systemctl is-active --quiet gost; then
        echo "GOST service is already installed."
        echo "Do you want to reinstall it? (y/n)"
        read answer
        if [[ "$answer" != "y" ]]; then
            echo "Installation cancelled. GOST service remains installed."
            return
        fi
    fi

    echo "Installing GOST..."
    curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh | bash -s -- --install > /dev/null 2>&1
    sudo wget -q -O /usr/lib/systemd/system/gost.service "$repository_url"/config/gost.service > /dev/null 2>&1
    sleep 1

    echo "Enter your domain or IP:"
    read domain
    while : ; do
        echo "Enter the port number (1-65535):"
        read port
        if [[ "$port" =~ ^[0-9]+$ && "$port" -ge 1 && "$port" -le 65535 ]]; then
            break
        else
            echo "Port must be a numeric value between 1 and 65535. Please try again."
        fi
    done

    sudo sed -i "s|ExecStart=/usr/local/bin/gost -L=tcp://:\$port/\$domain:\$port|ExecStart=/usr/local/bin/gost -L=tcp://:$port/$domain:$port|g" /usr/lib/systemd/system/gost.service > /dev/null 2>&1
    sudo systemctl daemon-reload > /dev/null 2>&1
    sudo systemctl start gost > /dev/null 2>&1
    sudo systemctl enable gost > /dev/null 2>&1

    status=$(sudo systemctl is-active gost)

    if [ "$status" = "active" ]; then
        echo "GOST tunnel is installed and active."
    else
        echo "GOST service is not active. Status: $status."
    fi
}

check_port_gost() {
    gost_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep gost | awk '{print $9}')
    status=$(sudo systemctl is-active gost)
    service_status="gost Service Status: $status"
    info="Service Status and Ports in Use:\n\nPorts in use:\n$gost_ports\n\n$service_status"
    echo -e "$info"
}

add_port_gost() {
    if ! systemctl is-active --quiet gost; then
        echo "GOST service is not active. Please start GOST before adding new configuration."
        return
    fi

    last_port=$(sudo lsof -i -P -n -sTCP:LISTEN | grep gost | awk '{print $9}' | awk -F ':' '{print $NF}' | sort -n | tail -n 1)

    echo "Enter your domain or IP:"
    read new_domain

    while : ; do
        echo "Enter the port (numeric only):"
        read new_port

        if [[ "$new_port" =~ ^[0-9]+$ ]]; then
            if (( new_port >= 0 && new_port <= 65535 )); then
                if sudo lsof -i -P -n -sTCP:LISTEN | grep ":$new_port " > /dev/null 2>&1; then
                    echo "Port $new_port is already in use. Please choose another port."
                else
                    break
                fi
            else
                echo "Port number must be between 1 and 65535. Please try again."
            fi
        else
            echo "Port must be a numeric value. Please try again."
        fi
    done

    sudo sed -i "/ExecStart/s/$/ -L=tcp:\/\/:$new_port\/$new_domain:$new_port/" /usr/lib/systemd/system/gost.service > /dev/null 2>&1
    sudo systemctl daemon-reload > /dev/null 2>&1
    sudo systemctl restart gost > /dev/null 2>&1
    echo "New domain and port added."
}

remove_port_gost() {
    ports=$(grep -oP '(?<=-L=tcp://:)\d+(?=/)' /usr/lib/systemd/system/gost.service)

    if [ -z "$ports" ]; then
        echo "No ports found in the GOST configuration."
        return
    fi

    echo "Choose the port to remove from the following:"
    select port in $ports; do
        if [ -n "$port" ]; then
            line=$(grep -oP "ExecStart=.*-L=tcp://:$port/[^ ]+" /usr/lib/systemd/system/gost.service)
            domain=$(echo "$line" | grep -oP "(?<=-L=tcp://:$port/).+")
            echo "Are you sure you want to remove the port $port with domain/IP $domain? (y/n)"
            read confirm
            if [[ "$confirm" == "y" ]]; then
                sudo sed -i "\|ExecStart=.*-L=tcp://:$port/$domain|s| -L=tcp://:$port/$domain||" /usr/lib/systemd/system/gost.service
                sudo systemctl daemon-reload > /dev/null 2>&1
                sudo systemctl restart gost > /dev/null 2>&1
                echo "Port $port with domain/IP $domain has been removed from the GOST configuration."
            else
                echo "No changes made."
            fi
            break
        else
            echo "Invalid selection."
        fi
    done
}

uninstall_gost() {
    echo "Are you sure you want to uninstall GOST? (y/n)"
    read confirm
    if [[ "$confirm" == "y" ]]; then
        echo "Stopping GOST service..."
        sudo systemctl stop gost > /dev/null 2>&1
        sleep 1
        echo "Disabling GOST service..."
        sudo systemctl disable gost > /dev/null 2>&1
        sleep 1
        echo "Reloading systemctl daemon..."
        sudo systemctl daemon-reload > /dev/null 2>&1
        sleep 1
        echo "Removing GOST service and binary..."
        sudo rm -f /usr/lib/systemd/system/gost.service /usr/local/bin/gost
        echo "GOST Service Uninstalled."
    else
        echo "Uninstallation cancelled."
    fi
}
