#!/bin/bash
#name:            init-2.sh
#description:     init linux 
#previous version:init-1.sh
#add and fix:     add lftp, net-tools


#wether is on
s_selinux=$(getenforce)
s_firewall=$(systemctl status firewalld.service | sed -n '3p'|awk -F: '{print $2}'|awk '{print $1}')
s_dvd=$(df -hT | grep "iso9660" |awk '{print $NF}')
s_yum=/etc/yum.repos.d/iso.repo
s_vim=$(rpm -qa |grep vim-enhanced)
s_bashcompletion=$(rpm -qa |grep bash-completion)
s_sshdns=$(sed -n '129p' /etc/ssh/sshd_config)
s_sshgss=$(sed -n '93p' /etc/ssh/sshd_config)

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

#something to do
echo "something to do"
if [ "$s_selinux" != "Disabled" ];then
    echo -e "\033[32mstop and disable SELinux\033[0m"
else
    echo -e "\033[31mSELinux has been disapled,no action\033[0m"
fi
if [ "$s_firewall" != "inactive" ];then
    echo -e "\033[32mstop and disable firewall\033[0m"
else
    echo -e "\033[31mfirewall has been disabled,no action\033[0m"
fi
echo -e "\033[32mset ip\033[0m"
if [ ! -f $s_yum ];then
    echo -e "\033[32mmount DVD and add yum dvd\033[0m"
else
    echo -e "\033[31myum is ok, no action\033[0m"
fi
if [ -z "$s_vim" ];then
    echo -e "\033[32minstall vim-enhanced\033[0m"
    echo -e "\033[32mset vim:set nu\033[0m"
    echo -e "\033[32mset vim:set shitwidth=4\033[0m"
else
    echo -e "\033[31mvim-enhanced has been installed, no action\033[0m"
fi
if [ -z "$s_bashcompletion" ];then
    echo -e "\033[32minstall bash-comletion and vim-enhanced\033[0m"
else
    echo -e "\033[31mbash-comletion has been installed, no action\033[0m"
fi
if [ "$s_sshdns" != "UseDNS no"  ];then
    echo -e "\033[32mdisable SSH:useDNS\033[0m"
else
    echo -e "\033[31mUseDNS is no,no action\033[0m"
fi
if [ "$s_sshgss" != "GSSAPIAuthentication no" ];then
    echo -e "\033[32mdisable SSH:GSSAPIAuthentication\033[0m"
else
    echo -e "\033[31mSSH:GSSAPIAuthentication has been disabled,no action\033[0m"
fi
echo -e "\033[32malter hostname\033[0m"
query lftp
query createrepo
query net-tools


#Press any key to continue
read -p "Press ENTER to continue" var

#firewall selinux
if [ "$s_firewall" != "inactive" ];then
systemctl stop firewalld
systemctl disable firewalld
fi
if [ "$s_selinux" != "Disabled" ];then
setenforce 0
sed --follow-symlinks -i '/^SELINUX=/c \SELINUX=disabled' /etc/selinux/config
fi

#yum
if [ "$s_dvd" != "/mnt" ];then
    echo "/dev/sr0 /mnt iso9660 defaults 0 0" >> /etc/fstab
    mount -a
fi
if [ ! -f $s_yum ];then
mkdir /etc/yum.repos.d/default
mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/default/
cat <<EOF > /etc/yum.repos.d/iso.repo
[ISO]
name=iso
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF
yum clean all
yum makecache
fi

#vim
if [ -z "$s_vim" ];then
    yum install vim-enhanced -y
    echo "set nu" >> /etc/vimrc
    echo "set shiftwidth=4" >> /etc/vimrc
fi

#tab bash
if [ -z "$s_bashcompletion" ];then
    yum install bash-completion -y
fi

#ip expect DHCP or NONE
read -p "input your choice for obtaion ip:0(no),1(dhcp),2(static)" ip_method
while true;do
    if [ "$ip_method" == "1" ];then
	#dhcp
	nmcli connection delete eno16777736
	nmcli connection add type ethernet ifname eno16777736 con-name eno16777736
	nmcli connection modify eno16777736 ipv4.method auto
	nmcli connection reload
	nmcli connection up eno16777736
	break
    elif [ "$ip_method" == "2" ];then
	#static
	nmcli connection delete eno16777736
	nmcli connection add type ethernet ifname eno16777736 con-name eno16777736
	read -p 'input ip((XXX/X)' ip
	nmcli connection modify eno16777736 ipv4.addresses "$ip"
	read -p 'input gateway' gw
	nmcli connection modify eno16777736 ipv4.gateway "$gw"
	nmcli connection modify eno16777736 ipv4.method manual
	nmcli connection reload
	nmcli connection up eno16777736
	break
    elif [ "$ip_method" == "0" ];then
	#unset ip
	break
    elif [  -z $ip_method ];then
	echo "type 0, 1 or 2 please"
	read -p "input your choice for obtaion ip:0(no),1(dhcp),2(static)" ip_method
    else
	echo 'only 0, 1 or 2 valid!'
	read -p "input your choice for obtaion ip:0(no),1(dhcp),2(static)" ip_method
    fi
done

#ssh
if [ "$s_sshdns" != "UseDNS no"  ];then
    sed -i '129c \UseDNS no' /etc/ssh/sshd_config
fi
if [ "$s_ssdgss" != "GSSAPIAuthentication no" ];then
    sed -i '93c \GSSAPIAuthentication no' /etc/ssh/sshd_config
fi

#alter hostname
echo -n -e "\033[31malter hostname or not,1(yes),2(no):\033[0m"
while true;do
    read choice
    if [ "$choice" == 1 ];then
	read host_name
	systemctl set-hostname $host_name
        break
    elif [ "$choice" == 2 ];then
	echo -n ""
        break
    else
	echo -e "\033[31mtype 1 or 2, please\033[0m"
        echo -n -e "\033[31malter hostname or not,1(yes),2(no):\033[0m"
    fi
done
install lftp
install createrepo
install net-tools


#summary
echo -e "\033[32mSELINX is $(getenforce) \033[0m"
echo -e "\033[32mFIREWALL $(systemctl status firewalld.service | sed -n '3p'|awk -F: '{print $2}'|awk '{print $1}') \033[0m"
echo -e "\033[32mDVD mounted on $(df -hT | grep "iso9660" |awk '{print $NF}') \033[0m"
echo -e "\033[32mYUM(dvd) is enabled and there are $(yum repolist iso | sed -n '/iso/p' |awk '{print $NF}') software \033[0m"
echo -e "\033[32m$(rpm -qa |grep vim-enhanced) is installed \033[0m"
echo -e "\033[32m$(rpm -qa |grep vim-enhanced) is installed \033[0m"
echo -e "\033[32m$(rpm -qa |grep bash-completion) is installed \033[0m"
echo -e "\033[32mIP $(ip address show eno16777736 | grep "brd" | sed '1d'|awk '{print $2}') by $(nmcli connection show eno16777736 | grep "ipv4.method"|awk '{print $2}') \033[0m"
echo -e "\033[32m$(sed -n -e '93s/^/SSH:/p' -e '129s/^/SSH:/p' /etc/ssh/sshd_config) \033[0m"
summerize lftp
summerize createrepo
summerize net-tools
