#!/bin/bash

# دریافت ورودی‌ها از کاربر
echo "Enter IP Server Iran:"
read IPv4_IRAN
echo "Enter IP Server Out:"
read IPv4_KHAREJ
echo "Enter IPv6 Local Iran:"
read IPv6_IRAN
echo "Enter IPv6 Local Out:"
read IPv6_KHAREJ

# انتخاب نوع سرور
echo "Choose an option:"
echo "1 - Server Iran"
echo "2 - Server Kharej"
read option

if [ "$option" == "1" ]; then
    echo "Configuring Server Iran..."
    
    # اجرای دستورات
    ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local $IPv4_IRAN
    ip -6 addr add $IPv6_KHAREJ dev 6to4_To_KH
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
    
    # تنظیم rc.local
    echo "Updating /etc/rc.local..."
    sudo bash -c 'cat << EOF > /etc/rc.local
#!/bin/bash
ip tunnel add 6to4_To_KH mode sit remote '$IPv4_KHAREJ' local '$IPv4_IRAN'
ip -6 addr add '$IPv6_KHAREJ' dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote '$IPv6_IRAN' local '$IPv6_KHAREJ'
ip addr add 172.20.20.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 172.20.20.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 172.20.20.2
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF'
    
    sudo chmod +x /etc/rc.local
    echo "Configuration completed!"
else
    echo "Option not implemented yet."
fi
