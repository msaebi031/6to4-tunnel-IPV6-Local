#!/bin/bash

# تابع بررسی دسترسی sudo 
check_sudo() {
    if sudo -n true 2>/dev/null; then
        echo "This user has sudo permissions"
    else
        echo "This user does not have sudo permissions"
        exit 1
    fi
}

# تابع نصب بسته‌ها
install_package() {
    package=$1
    if ! command -v $package &> /dev/null; then
        echo "Installing $package..."
        sudo apt-get install -y $package
        echo "$package installed ✓"
    else
        echo "$package is already installed ✓"
    fi
}

# تابع تنظیمات تونل از ایران به خارج
setup_iran_to_kharej() {
    echo "Enter the IPv4 address of Kharej: "
    read IPv4_KHAREJ
    echo "Enter the IPv4 address of Iran: "
    read IPv4_IRAN
    echo "Enter the IPv6 address of Kharej: "
    read IPv6_KHAREJ
    echo "Enter the IPv6 address of Iran: "
    read IPv6_IRAN

    echo "Setting up tunnel from Iran to Kharej..."
    ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local $IPv4_IRAN
    ip -6 addr add $IPv6_IRAN/64 dev 6to4_To_KH
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up

    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote $IPv6_KHAREJ local $IPv6_IRAN
    ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up

    sysctl net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
    iptables -t nat -A POSTROUTING -j MASQUERADE
    echo "Setup completed!"
}

# تابع تنظیمات تونل از خارج به ایران
setup_kharej_to_iran() {
    echo "Enter the IPv4 address of Kharej: "
    read IPv4_KHAREJ
    echo "Enter the IPv4 address of Iran: "
    read IPv4_IRAN
    echo "Enter the IPv6 address of Kharej: "
    read IPv6_KHAREJ
    echo "Enter the IPv6 address of Iran: "
    read IPv6_IRAN

    echo "Setting up tunnel from Kharej to Iran..."
    ip tunnel add 6to4_To_IR mode sit remote $IPv4_IRAN local $IPv4_KHAREJ
    ip -6 addr add $IPv6_KHAREJ/64 dev 6to4_To_IR
    ip link set 6to4_To_IR mtu 1480
    ip link set 6to4_To_IR up

    ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote $IPv6_IRAN local $IPv6_KHAREJ
    ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
    ip link set GRE6Tun_To_IR mtu 1436
    ip link set GRE6Tun_To_IR up
    echo "Setup completed!"
}

# تابع تنظیمات اولیه rc.local - ir
add_to_rc_local_ir() {
    sudo bash -c "cat > /etc/rc.local" <<EOF
#!/bin/bash
ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local <IPv4-IRAN>
ip -6 addr add $IPv6_IRAN/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote $IPv6_KHAREJ local $IPv6_IRAN
ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
iptables -t nat -A POSTROUTING -j MASQUERADE 
EOF
}

# تابع تنظیمات اولیه rc.local out
add_to_rc_local_out() {
    sudo bash -c "cat > /etc/rc.local" <<EOF
#!/bin/bash
ip tunnel add 6to4_To_IR mode sit remote $IPv4_IRAN local $IPv4_KHAREJ
ip -6 addr add $IPv4_KHAREJ/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up

ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote $IPv6_IRAN local $IPv6_KHAREJ
ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up
EOF
}

# تابع منوی اصلی
main_menu() {
    echo "Welcome to Tunnel Setup"
    echo "Please choose an option:"
    echo "1. Set up tunnel from Iran to Kharej"
    echo "2. Set up tunnel from Kharej to Iran"
    echo "3. Exit"
    read -p "Enter the number of your choice: " choice

    case $choice in
        1)
            setup_iran_to_kharej
            add_to_rc_local
            ;;
        2)
            setup_kharej_to_iran
            add_to_rc_local
            ;;
        3)
            echo "Exiting script..."
            exit 0
            ;;
        *)
            echo "Invalid option! Please select a valid option."
            main_menu
            ;;
    esac
}

# شروع منو
main_menu
