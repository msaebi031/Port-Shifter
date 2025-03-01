#!/bin/bash

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
            echo "You selected IP-Tables"
            ;;
        2)
            echo "You selected GOST"
            ;;
        3)
            echo "You selected Dokodemo-Door"
            ;;
        4)
            echo "You selected HA-Proxy"
            ;;
        5)
            echo "You selected Options"
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

# شروع اجرای منو
menu
