#!/bin/bash

# دریافت اطلاعات از کاربر
read -p "Enter IP Server Iran: " IPv4_IRAN
read -p "Enter IP Server Out: " IPv4_KHAREJ
read -p "Enter IPv6 Local Iran: " IPv6_IRAN
read -p "Enter IPv6 Local Out: " IPv6_KHAREJ

# ارائه گزینه‌ها
echo "Choose an option:"
echo "1 - Server Iran"
echo "2 - Server Kharej"
read -p "Enter your choice (1/2): " CHOICE

# حذف prefix از IPv6 (در صورت وجود)
IPv6_IRAN=$(echo "$IPv6_IRAN" | cut -d'/' -f1)
IPv6_KHAREJ=$(echo "$IPv6_KHAREJ" | cut -d'/' -f1)

if [ "$CHOICE" == "1" ]; then
    echo "Setting up tunnel from Iran to Kharej..."

    ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local $IPv4_IRAN
    ip -6 addr add $IPv6_KHAREJ/64 dev 6to4_To_KH
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up

    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote $IPv6_IRAN local $IPv6_KHAREJ
    ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up

    sysctl net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
    iptables -t nat -A POSTROUTING -j MASQUERADE

    echo "Adding to /etc/rc.local..."
    sudo bash -c "cat > /etc/rc.local" <<EOF
#!/bin/bash
ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local $IPv4_IRAN
ip -6 addr add $IPv6_KHAREJ/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote $IPv6_IRAN local $IPv6_KHAREJ
ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF

elif [ "$CHOICE" == "2" ]; then
    echo "Setting up tunnel from Kharej to Iran..."

    ip tunnel add 6to4_To_IR mode sit remote $IPv4_IRAN local $IPv4_KHAREJ
    ip -6 addr add $IPv6_IRAN/64 dev 6to4_To_IR
    ip link set 6to4_To_IR mtu 1480
    ip link set 6to4_To_IR up

    ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote $IPv6_KHAREJ local $IPv6_IRAN
    ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
    ip link set GRE6Tun_To_IR mtu 1436
    ip link set GRE6Tun_To_IR up

    echo "Adding to /etc/rc.local..."
    sudo bash -c "cat > /etc/rc.local" <<EOF
#!/bin/bash
ip tunnel add 6to4_To_IR mode sit remote $IPv4_IRAN local $IPv4_KHAREJ
ip -6 addr add $IPv6_IRAN/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up

ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote $IPv6_KHAREJ local $IPv6_IRAN
ip addr add 172.20.20.2/30 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up
EOF

else
    echo "Invalid option! Exiting..."
    exit 1
fi

# دادن مجوز اجرایی به تمامی فایل‌های rc.local و اسکریپت‌ها
sudo chmod +x /etc/rc.local
sudo chmod +x install.sh  # مجوز اجرایی برای فایل نصب

echo "Setup completed!"
