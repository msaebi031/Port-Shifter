#!/bin/bash

source /opt/Port-Shifter/scripts/path.sh
source /opt/Port-Shifter/scripts/package.sh

install_xray() {
    if systemctl is-active --quiet xray; then
        echo "Xray service is already active. Do you want to reinstall? (y/n)"
        read answer
        if [[ "$answer" != "y" ]]; then
            echo "Installation cancelled. Xray service remains active."
            return
        fi
    fi

    bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>&1

    echo "Xray installation completed!"

    echo "Enter your domain or IP:"
    read address

    while : ; do
        echo "Enter the port (numeric only 1-65535):"
        read port
        if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
            break
        else
            echo "Port must be a numeric value between 1 and 65535. Please try again."
        fi
    done

    wget -q -O /tmp/config.json "$repository_url"/config/config.json

    jq --arg address "$address" --arg port "$port" '.inbounds[1].port = ($port | tonumber) | .inbounds[1].settings.address = $address | .inbounds[1].settings.port = ($port | tonumber) | .inbounds[1].tag = "inbound-" + $port' /tmp/config.json > /usr/local/etc/xray/config.json
    clear
    sudo systemctl restart xray
    status=$(sudo systemctl is-active xray)

    if [ "$status" = "active" ]; then
        echo "Xray installed successfully!"
    else
        echo "Xray service is not active or failed."
    fi

    rm /tmp/config.json
}

check_service_xray() {
    xray_ports=$(sudo lsof -i -P -n -sTCP:LISTEN | grep xray | awk '{print $9}')
    status=$(sudo systemctl is-active xray)
    service_status="Xray Service Status: $status"
    echo -e "Service Status and Ports in Use:\n\nPorts in use:\n$xray_ports\n\n$service_status"
}

trafficstat() {
    if ! systemctl is-active --quiet xray; then
        echo "Xray service is not active. Please start Xray before checking traffic."
        return
    fi
    
    local RESET=$1
    local APISERVER="127.0.0.1:10085"
    local XRAY="/usr/local/bin/xray"
    local ARGS=""
    
    if [[ "$RESET" == "reset" ]]; then
        ARGS="reset: true"
    fi

    local DATA=$($XRAY api statsquery --server="$APISERVER" "$ARGS" | awk '
    {
        if (match($1, /"name":/)) {
            f=1; gsub(/^"|link"|,$/, "", $2);
            split($2, p,  ">>>");
            printf "%s:%s->%s\t", p[1], p[2], p[4];
        } else if (match($1, /"value":/) && f) {
            f=0;
            gsub(/"/, "", $2);
            printf "%.0f\n\n", $2;
        } else if (match($0, /}/) && f) {
            f=0; 
            print 0;
        }
    }')

    local PREFIX="inbound"
    local SORTED=$(echo "$DATA" | grep "^${PREFIX}" | grep -v "inbound:api" | sort -r)
    local TOTAL_UP=0
    local TOTAL_DOWN=0

    while IFS= read -r LINE; do
        if [[ "$LINE" == *"->up"* ]]; then
            SIZE=$(echo "$LINE" | awk '{print $2}')
            TOTAL_UP=$((TOTAL_UP + SIZE))
        elif [[ "$LINE" == *"->down"* ]]; then
            SIZE=$(echo "$LINE" | awk '{print $2}')
            TOTAL_DOWN=$((TOTAL_DOWN + SIZE))
        fi
    done <<< "$SORTED"

    local OUTPUT=$(echo -e "${SORTED}\n" | numfmt --field=2 --suffix=B --to=iec | column -t)
    local TOTAL_UP_FMT=$(numfmt --to=iec <<< $TOTAL_UP)
    local TOTAL_DOWN_FMT=$(numfmt --to=iec <<< $TOTAL_DOWN)

    echo -e "Inbound Traffic Statistics:\n\n${OUTPUT}\nTotal Up: ${TOTAL_UP_FMT}\nTotal Down: ${TOTAL_DOWN_FMT}"
}

add_another_inbound() {
    if ! systemctl is-active --quiet xray; then
        echo "Xray service is not active. Please start Xray before adding new configuration."
        return
    fi
    echo "Enter the new address:"
    read addressnew
    exit_status=$?
    if [ $exit_status != 0 ]; then
        echo "Operation cancelled. Returning to menu."
        return
    fi

    while : ; do
        echo "Enter the new port (numeric only):"
        read portnew
        exit_status=$?
        if [ $exit_status != 0 ]; then
            echo "Operation cancelled. Returning to menu."
            return
        fi
        
        if ! [[ "$portnew" =~ ^[0-9]+$ ]] || ! (( portnew >= 1 && portnew <= 65535 )); then
            echo "Port must be a numeric value between 1 and 65535. Please try again."
            continue
        fi

        if jq --arg port "$portnew" '.inbounds[] | select(.port == ($port | tonumber))' /usr/local/etc/xray/config.json | grep -q .; then
            echo "The port $portnew is already in use. Please enter a different port."
        else
            break
        fi
    done

    if jq --arg address "$addressnew" --arg port "$portnew" '.inbounds += [{ "listen": null, "port": ($port | tonumber), "protocol": "dokodemo-door", "settings": { "address": $address, "followRedirect": false, "network": "tcp,udp", "port": ($port | tonumber) }, "tag": ("inbound-" + $port) }]' /usr/local/etc/xray/config.json > /tmp/config.json.tmp; then
        sudo mv /tmp/config.json.tmp /usr/local/etc/xray/config.json
        sudo systemctl restart xray
        echo "Additional inbound added."
    else
        echo "Error: Failed to add inbound configuration."
    fi
}

remove_inbound() {
    inbounds=$(jq -r '.inbounds[] | select(.tag != "api") | "\(.tag):\(.port)"' /usr/local/etc/xray/config.json)
    
    if [ -z "$inbounds" ]; then
        echo "No inbound configurations found."
        return
    fi
    
    echo "Select the inbound configuration to remove:"
    echo "$inbounds" | nl -w2 -s ' '
    read selected

    if [ -n "$selected" ]; then
        port=$(echo "$inbounds" | sed -n "${selected}p" | awk -F ':' '{print $2}')
        
        echo "Are you sure you want to remove the inbound configuration for port $port? (y/n)"
        read response
        if [ "$response" = "y" ]; then
            remove_inbound_by_port "$port"
        else
            echo "Inbound configuration removal canceled."
        fi
    fi
}

remove_inbound_by_port() {
    port=$1
    if jq --arg port "$port" 'del(.inbounds[] | select(.port == ($port | tonumber)))' /usr/local/etc/xray/config.json > /tmp/config.json.tmp; then
        sudo mv /tmp/config.json.tmp /usr/local/etc/xray/config.json
        sudo systemctl restart xray
        if grep -q "\"port\": $port" /usr/local/etc/xray/config.json; then
            echo "Failed to remove inbound configuration."
        else
            echo "Inbound configuration removed successfully!"
        fi
    else
        echo "Failed to remove inbound configuration."
    fi
}

uninstall_xray() {
    echo "Are you sure you want to uninstall Xray? (y/n)"
    read response
    if [ "$response" = "y" ]; then
        (
        echo "10" "Removing Xray configuration..."
        sudo rm /usr/local/etc/xray/config.json > /dev/null 2>&1
        sleep 1
        echo "30" "Stopping and disabling Xray service..."
        sudo systemctl stop xray && sudo systemctl disable xray > /dev/null 2>&1
        sleep 1
        echo "70" "Uninstalling Xray..."
        sudo bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove > /dev/null 2>&1
        sleep 1
        echo "100" "Xray Uninstallation completed!"
        sleep 1
        ) 
        echo "Xray Uninstallation completed!"
        clear
    else
        echo "Uninstallation cancelled."
        clear
    fi
}
