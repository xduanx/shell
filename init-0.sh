#!/bin/bash

#something to do
echo "something to do"
echo -e "\033[32mstop and disable SELinux\033[0m"
echo -e "\033[32mstop and disable firewall\033[0m"
echo -e "\033[32mset ip\033[0m"
echo -e "\033[32mmount DVD and add yum dvd\033[0m"
echo -e "\033[32minstall bash-comletion and vim-enhanced\033[0m"
echo -e "\033[32m set vim:set nu\033[0m"
echo -e "\033[32mdisable SSH:use DNS,GSSAPIAuthentication\033[0m"

#Press any key to continue
get_char()
    {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
    }
echo "Press any key to continue!"
char=`get_char`


#firewall selinux
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed --follow-symlinks -i '/^SELINUX=/c \SELINUX=disabled' /etc/selinux/config

#yum
mkdir /etc/yum.repos.d/default
mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/default/
echo "/dev/sr0 /mnt iso9660 defaults 0 0" >> /etc/fstab
mount -a
cat <<EOF > /etc/yum.repos.d/iso.repo
[ISO]
name=iso
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF
yum clean all
yum makecache

#vim
yum install vim-enhanced -y
echo "set nu" >> /etc/vimrc

#tab bash
yum install bash-completion -y


#ip expect DHCP or NONE
read -p "input your choice:1(dhcp),2(static)" ip_method
if [ $ip_method -eq 1 ];then
    #dhcp
    nmcli connection delete eno16777736
    nmcli connection add type ethernet ifname eno16777736 con-name eno16777736
    nmcli connection modify eno16777736 ipv4.method auto
    nmcli connection reload
    nmcli connection up eno16777736
elif [ $ip_method -eq 2 ];then
    #static
    nmcli connection delete eno16777736
    nmcli connection add type ethernet ifname eno16777736 con-name eno16777736
    read -p 'input ip((XXX/X)' ip
    nmcli connection modify eno16777736 ipv4.addresses $ip
    read -p 'input gateway' gw
    nmcli connection modify eno16777736 ipv4.gateway $gw
    nmcli connection modify eno16777736 ipv4.method manual
    nmcli connection reload
    nmcli connection up eno16777736
else
    echo 'only 1 or 2 valid!'
fi

#ssh
sed -i '129c \Use DNS no' /etc/ssh/sshd_config
sed -i '93c \GSSAPIAuthentication no' /etc/ssh/sshd_config

#summary
echo -e "\033[32mSELINX is $(getenforce) \033[0m"
echo -e "\033[32mFIREWALL $(systemctl status firewalld.service | sed -n '3p'|awk -F: '{print $2}'|awk '{print $1}') \033[0m"
echo -e "\033[32mDVD mounted on $(df -hT | grep "iso9660" |awk '{print $NF}') \033[0m"
echo -e "\033[32mYUM(dvd) is enabled and there are $(yum repolist iso | sed -n '/iso/p' |awk '{print $NF}') software \033[0m"
echo -e "\033[32m$(rpm -qa |grep vim-enhanced) is installed \033[0m"
echo -e "\033[32m$(rpm -qa |grep bash-completion) is installed \033[0m"
echo -e "\033[32mIP $(ip address show eno16777736 | grep "brd" | sed '1d'|awk '{print $2}') by $(nmcli connection show eno16777736 | grep "ipv4.method"|awk '{print $2}') \033[0m"
echo -e "\033[32m$(sed -n -e '93s/^/SSH:/p' -e '129s/^/SSH:/p' /etc/ssh/sshd_config) \033[0m"

