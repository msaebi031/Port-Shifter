#!/bin/bash

# دستور برای نمایش منو ساده
show_menu() {
    clear
    echo "====================================="
    echo "    Port-Shifter Menu"
    echo "====================================="
    echo "1) Install IP-Tables"
    echo "2) Check Ports In Use (IP-Tables)"
    echo "3) Uninstall IP-Tables"
    echo "4) Install GOST"
    echo "5) Check GOST Port And Status"
    echo "6) Add Another Port And Domain (GOST)"
    echo "7) Remove Port And Domain (GOST)"
    echo "8) Uninstall GOST"
    echo "9) Install Xray for Dokodemo-Door"
    echo "10) Check Xray Service Status"
    echo "11) Inbound Traffic Statistics"
    echo "12) Add Another Inbound"
    echo "13) Remove an Inbound Configuration"
    echo "14) Uninstall Xray and Tunnel"
    echo "15) Install HA-Proxy"
    echo "16) Check HA-Proxy Port and Status"
    echo "17) Add More Tunnel Configuration (HA-Proxy)"
    echo "18) Remove Tunnel Configuration (HA-Proxy)"
    echo "19) Uninstall HA-Proxy"
    echo "20) Additional Configuration Options"
    echo "21) Quit"
    echo "====================================="
    echo -n "Select an option (1-21): "
}

# اجراهای مختلف برای هر گزینه
handle_choice() {
    case $1 in
        1) install_iptables ;;
        2) check_port_iptables ;;
        3) uninstall_iptables ;;
        4) install_gost ;;
        5) check_port_gost ;;
        6) add_port_gost ;;
        7) remove_port_gost ;;
        8) uninstall_gost ;;
        9) install_xray ;;
        10) check_service_xray ;;
        11) trafficstat ;;
        12) add_another_inbound ;;
        13) remove_inbound ;;
        14) uninstall_xray ;;
        15) install_haproxy ;;
        16) check_haproxy ;;
        17) add_frontend_backend ;;
        18) remove_frontend_backend ;;
        19) uninstall_haproxy ;;
        20) other_options_menu ;;
        21) exit 0 ;;
        *) echo "Invalid option!" ;;
    esac
}

# منوی اصلی برای وارد کردن گزینه‌ها
while true; do
    show_menu
    read -r choice
    handle_choice "$choice"
    echo "Press Enter to continue..."
    read -r
done
