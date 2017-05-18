#!/bin/bash

query(){
    appname=$1
    s_app=$(rpm -qa | grep "$appname")
    if [ -z "$s_app" ];then
        echo -e "\033[32minstall $appname\033[0m"
    else
        echo -e "\033[31m$appname has been installed, no action\033[0m"
    fi  
}
install(){
    appname=$1
    s_app=$(rpm -qa | grep "$appname")
    if [ -z "$s_app"  ];then
        yum install -y $appname
    fi  
}
summerize(){
    echo -e "\033[32m$(rpm -qa |grep "$1") is installed \033[0m"
}
#check app install
#query dhcp
query tftp-server
query xinetd
query syslinux
query vsftpd

#do something
#install dhcp
yum install -y dhcp
install tftp-server
install xinetd
install syslinux
install vsftpd

#ip
nmcli connection delete eno16777736
nmcli connection add type ethernet ifname eno16777736 con-name eno16777736
nmcli connection modify eno16777736 ipv4.addresses "192.168.87.101/24"
nmcli connection modify eno16777736 ipv4.gateway "192.168.87.101"
nmcli connection modify eno16777736 ipv4.method manual
nmcli connection reload
nmcli connection up eno16777736

#config files
#vsftp
mkdir /var/ftp/centos7u2
cp -r /mnt/* /var/ftp/centos7u2
systemctl start vsftpd
systemctl enable vsftpd

#dhcp
echo "" > /etc/dhcp/dhcpd.conf
sed -i '1r /usr/share/doc/dhcp-4.2.5/dhcpd.conf.example' /etc/dhcp/dhcpd.conf
sed -i '28,$d' /etc/dhcp/dhcpd.conf
cat<<EOF >> /etc/dhcp/dhcpd.conf
subnet 192.168.87.0 netmask 255.255.255.0 {
  range 192.168.87.10 192.168.87.20;
  next-server 192.168.87.101;
  filename "pxelinux.0";
}
EOF
systemctl start dhcpd
systemctl enable dhcpd

#tftp-server
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
mkdir /var/lib/tftpboot/centos7u2
cp /mnt/isolinux/* /var/lib/tftpboot/
mv /var/lib/tftpboot/vmlinuz /var/lib/tftpboot/initrd.img /var/lib/tftpboot/centos7u2/
mkdir /var/lib/tftpboot/pxelinux.cfg
cp /var/lib/tftpboot/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default
sed -i '61,$d' /var/lib/tftpboot/pxelinux.cfg/default
chmod u+x,u+w /var/lib/tftpboot/pxelinux.cfg/default
cat<<EOF >> /var/lib/tftpboot/pxelinux.cfg/default
label centos6
  menu label ^Install CentOS 7
  kernel centos7u2/vmlinuz
  append initrd=centos7u2/initrd.img inst.stage2=ftp://192.168.87.101/centos7u2/ inst.repo=ftp://192.168.87.101/centos7u2/
EOF
sed  -i '14c \\    disable\    =\ no' /etc/xinetd.d/tftp
systemctl restart xinetd
systemctl enable xinetd
while true;do
    if [ "$p"  == "q" ];then
        break
    else
        read -p "type q to exit:" p
    fi
done
reboot
