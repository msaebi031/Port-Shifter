#!/bin/bash

source /opt/Port-Shifter/scripts/path.sh
source /opt/Port-Shifter/scripts/package.sh

install_haproxy() {
    echo "Installing HAProxy..."
    sudo $PACKAGE_MANAGER install haproxy -y > /dev/null 2>&1
    sleep 1
    echo "Downloading haproxy.cfg..."
    wget -q -O /tmp/haproxy.cfg "$repository_url"/config/haproxy.cfg > /dev/null 2>&1
    sleep 1
    echo "Removing existing haproxy.cfg..."
    sudo rm /etc/haproxy/haproxy.cfg > /dev/null 2>&1
    sleep 1
    echo "Moving new haproxy.cfg to /etc/haproxy..."
    sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg
    sleep 1

    echo "HAProxy installation completed."

    while true; do
        read -p "Enter Relay-Server Free Port (1-65535): " target_iport
        if [[ "$target_iport" =~ ^[0-9]+$ ]] && [ "$target_iport" -ge 1 ] && [ "$target_iport" -le 65535 ]; then
            break
        else
            echo "Please enter a valid numeric port between 1 and 65535."
        fi
    done

    read -p "Enter Main-Server IP or Domain: " target_ip

    while true; do
        read -p "Enter Main-Server Port (1-65535): " target_port
        if [[ "$target_port" =~ ^[0-9]+$ ]] && [ "$target_port" -ge 1 ] && [ "$target_port" -le 65535 ]; then
            break
        else
            echo "Please enter a valid numeric port between 1 and 65535."
        fi
    done

    if [[ -n "$target_ip" ]]; then
        sudo sed -i "s/\$iport/$target_iport/g; s/\$IP/$target_ip/g; s/\$port/$target_port/g" /etc/haproxy/haproxy.cfg > /dev/null 2>&1
        sudo systemctl restart haproxy > /dev/null 2>&1

        status=$(sudo systemctl is-active haproxy)
        if [ "$status" = "active" ]; then
            echo "HAProxy tunnel is installed and active."
        else
            echo "HAProxy service is not active. Status: $status."
        fi
    else
        echo "Invalid IP input. Please ensure the field is filled correctly."
    fi
}

check_haproxy() {
    haproxy_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep haproxy | awk '{print $9}')
    status=$(sudo systemctl is-active haproxy)
    service_status="haproxy Service Status: $status"
    info="Service Status and Ports in Use:\n\nPorts in use:\n$haproxy_ports\n\n$service_status"
    echo -e "$info"
}

add_frontend_backend() {
    if ! systemctl is-active --quiet haproxy; then
        echo "HAProxy service is not active. Please start HAProxy before adding new configuration."
        return
    fi

    while true; do
        read -p "Enter Relay-Server Free Port (1-65535): " frontend_port
        if [[ "$frontend_port" =~ ^[0-9]+$ ]] && [ "$frontend_port" -ge 1 ] && [ "$frontend_port" -le 65535 ]; then
            if grep -q "frontend tunnel-$frontend_port" /etc/haproxy/haproxy.cfg; then
                echo "Port $frontend_port is already in use. Please choose another port."
            else
                break
            fi
        else
            echo "Please enter a valid numeric port between 1 and 65535."
        fi
    done

    read -p "Enter Main-Server IP or Domain: " backend_ip

    while true; do
        read -p "Enter Main-Server Port (1-65535): " backend_port
        if [[ "$backend_port" =~ ^[0-9]+$ ]] && [ "$backend_port" -ge 1 ] && [ "$backend_port" -le 65535 ]; then
            break
        else
            echo "Please enter a valid numeric port between 1 and 65535."
        fi
    done

    {
        echo ""
        echo "frontend tunnel-$frontend_port"
        echo "    bind :::$frontend_port"
        echo "    mode tcp"
        echo "    default_backend tunnel-$backend_port"
        echo ""
        echo "backend tunnel-$backend_port"
        echo "    mode tcp"
        echo "    server target_server $backend_ip:$backend_port"
    } | sudo tee -a /etc/haproxy/haproxy.cfg > /dev/null

    sudo systemctl restart haproxy > /dev/null 2>&1

    echo "New frontend and backend added successfully."
}

remove_frontend_backend() {
    frontends=$(grep -E '^frontend ' /etc/haproxy/haproxy.cfg | awk '{print $2}')
    echo "Select Frontend to Remove:"
    select frontend_name in $frontends; do
        if [[ -n "$frontend_name" ]]; then
            backend_name=$(grep -E "^frontend $frontend_name$" /etc/haproxy/haproxy.cfg -A 10 | grep 'default_backend' | awk '{print $2}')
            if [[ -n "$backend_name" ]]; then
                sudo sed -i "/^frontend $frontend_name$/,/^$/d" /etc/haproxy/haproxy.cfg
                sudo sed -i "/^backend $backend_name$/,/^$/d" /etc/haproxy/haproxy.cfg
                sudo systemctl restart haproxy > /dev/null 2>&1
                echo "Frontend '$frontend_name' and Backend '$backend_name' removed successfully."
            else
                echo "Could not find the default backend for frontend '$frontend_name'."
            fi
            break
        else
            echo "No frontend selected. Operation cancelled."
            break
        fi
    done
}

uninstall_haproxy() {
    read -p "Are you sure you want to uninstall HAProxy? (y/n): " choice
    if [[ "$choice" == "y" ]]; then
        echo "Stopping HAProxy service..."
        sudo systemctl stop haproxy > /dev/null 2>&1
        sleep 1
        echo "Disabling HAProxy service..."
        sudo systemctl disable haproxy > /dev/null 2>&1
        sleep 1
        echo "Removing HAProxy..."
        sudo $PACKAGE_MANAGER remove haproxy -y > /dev/null 2>&1
        echo "HAProxy Uninstalled."
    else
        echo "Uninstallation cancelled."
    fi
}
