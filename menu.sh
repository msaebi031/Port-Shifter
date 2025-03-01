#!/bin/bash
for script in /opt/Port-Shifter/scripts/*.sh; do
  source "$script"
done

# تابع منوی اصلی
menu() {
    clear
    echo "Welcome to Port-Shifter"
    echo "Please choose your tunnel mode:"
    echo "1. IP-Tables - Manage IP-Tables Tunnel"
    echo "2. GOST - Manage GOST Tunnel"
    echo "3. Dokodemo-Door - Manage Dokodemo-Door Tunnel"
    echo "4. HA-Proxy - Manage HA-Proxy Tunnel"
    echo "5. Options - Additional Configuration Options"
    echo "6. Quit - Exit From The Script"
    echo -n "Enter the number of your choice: "
    read choice

    case $choice in
        1)
            iptables_menu
            ;;
        2)
            gost_menu
            ;;
        3)
            dokodemo_menu
            ;;
        4)
            haproxy_menu
            ;;
        5)
            other_options_menu
            ;;
        6)
            exit 0
            ;;
        *)
            echo "Invalid option, please enter a valid number."
            menu
            ;;
    esac
}

# تابع مدیریت IP-Tables
iptables_menu() {
    clear
    echo "IP-Tables Menu"
    echo "1. Install - Install IP-Tables Rules"
    echo "2. Status - Check Ports In Use"
    echo "3. Uninstall - Uninstall IP-Tables Rules"
    echo "4. Back - Back To Main Menu"
    echo -n "Enter the number of your choice: "
    read choice

    case $choice in
        1)
            install_iptables
            ;;
        2)
            check_port_iptables
            ;;
        3)
            uninstall_iptables
            ;;
        4)
            menu
            ;;
        *)
            echo "Invalid option, please enter a valid number."
            iptables_menu
            ;;
    esac
}

# تابع مدیریت GOST
gost_menu() {
    clear
    echo "GOST Menu"
    echo "1. Install - Install GOST"
    echo "2. Status - Check GOST Port And Status"
    echo "3. Add - Add Another Port And Domain"
    echo "4. Remove - Remove Port And Domain"
    echo "5. Uninstall - Uninstall GOST"
    echo "6. Back - Back To Main Menu"
    echo -n "Enter the number of your choice: "
    read choice

    case $choice in
        1)
            install_gost
            ;;
        2)
            check_port_gost
            ;;
        3)
            add_port_gost
            ;;
        4)
            remove_port_gost
            ;;
        5)
            uninstall_gost
            ;;
        6)
            menu
            ;;
        *)
            echo "Invalid option, please enter a valid number."
            gost_menu
            ;;
    esac
}

# تابع مدیریت Dokodemo-Door
dokodemo_menu() {
    clear
    echo "Dokodemo-Door Menu"
    echo "1. Install - Install Xray For Dokodemo-Door And Add Inbound"
    echo "2. Status - Check Xray Service Status"
    echo "3. Traffic - Inbound Traffic Statistics"
    echo "4. Add - Add Another Inbound"
    echo "5. Remove - Remove an Inbound Configuration"
    echo "6. Uninstall - Uninstall Xray And Tunnel"
    echo "7. Back - Back To Main Menu"
    echo -n "Enter the number of your choice: "
    read choice

    case $choice in
        1)
            install_xray
            ;;
        2)
            check_service_xray
            ;;
        3)
            trafficstat
            ;;
        4)
            add_another_inbound
            ;;
        5)
            remove_inbound
            ;;
        6)
            uninstall_xray
            ;;
        7)
            menu
            ;;
        *)
            echo "Invalid option, please enter a valid number."
            dokodemo_menu
            ;;
    esac
}

# تابع مدیریت HA-Proxy
haproxy_menu() {
    clear
    echo "HA-Proxy Menu"
    echo "1. Install - Install HA-Proxy"
    echo "2. Status - Check HA-Proxy Port and Status"
    echo "3. Add - Add more tunnel Configuration"
    echo "4. Remove - Remove tunnel Configuration"
    echo "5. Uninstall - Uninstall HAProxy"
    echo "6. Back - Back To Main Menu"
    echo -n "Enter the number of your choice: "
    read choice

    case $choice in
        1)
            install_haproxy
            ;;
        2)
            check_haproxy
            ;;
        3)
            add_frontend_backend
            ;;
        4)
            remove_frontend_backend
            ;;
        5)
            uninstall_haproxy
            ;;
        6)
            menu
            ;;
        *)
            echo "Invalid option, please enter a valid number."
            haproxy_menu
            ;;
    esac
}

# تابع مدیریت گزینه‌های دیگر
other_options_menu() {
    clear
    echo "Other Options"
    echo "1. DNS - Configure DNS"
    echo "2. Update - Update Server"
    echo "3. Ping - Ping to check internet connectivity"
    echo "4. Back - Return to Main Menu"
    echo -n "Enter the number of your choice: "
    read other_choice

    case $other_choice in
        1)
            configure_dns
            ;;
        2)
            update_server
            ;;
        3)
            ping_websites
            ;;
        4)
            menu
            ;;
        *)
            echo "Invalid option, please enter a valid number."
            other_options_menu
            ;;
    esac
}

# شروع اجرای منو
menu
