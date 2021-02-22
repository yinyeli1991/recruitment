#!/bin/bash
groupname=`egrep "mysql" /etc/group |awk -F: '{print $1}' |wc -l`
username=`egrep "mysql" /etc/passwd |awk -F: '{print $1}' |wc -l`
mysql1=`rpm -qa | grep -i mysql`
mkdir -p /opt/mysqldata/tmp
#添加用户组
if [  $groupname -ne 1 ]; then
         echo "用户组不存在，开始创建用户组"
            groupadd mysql
             else
                echo "用户组已存在，无需创建"
fi
#新建mysql用户同时加入用户组并且禁止mysql登陆linux
if [  $username -ne 1 ]; then
 echo "用户不存在，开始创建用户同时加入用户组并且禁止mysql登陆linux"
            useradd -r -s /sbin/nologin -g mysql mysql -d /usr/local/mysql
             else
                echo "用户已存在，无需创建"
fi

sleep 5

#关闭selinux及相关安全策略
iptables -F
iptables -X
iptables -Z
service iptables stop
sed -i '/^SELINUX=/s/enforcing/disabled/' /etc/selinux/config
chkconfig iptables off
chkconfig ip6tables off
chkconfig NetworkManager off
service iptables stop
service ip6tables stop
chkconfig ip6tables off
chkconfig NetworkManager off
service iptables stop
service ip6tables stop
service NetworkManager stop
setenforce 0

sleep 5
#创建安装路径
if [ ! -d /opt/ ]; then
  mkdir -p /opt/
  else
  echo "文件夹已经存在"
fi

sleep 2
#创建mysql数据文件存放目录并改变所有者
if [ ! -d /opt/mysqldata ]; then
    mkdir -p /opt/mysqldata
        else
                echo "该目录已存在，改变属组"
                        chown -R mysql:mysql /opt/mysqldata
                        fi
sleep 2
#检查系统是否已经安装mysql
service mysql stop
service mysqld stop
echo ${mysql1}
for RPM in ${mysql1}
do
        rpm -e --nodeps ${RPM}
done
sleep 30
#开始部署mysql
cd /opt/ && tar -zxvf mysql-5.6.44-linux-glibc2.12-x86_64.tar.gz 
sleep 30
               mv -n mysql-5.6.44-linux-glibc2.12-x86_64 mysql-5.6
chown -R mysql:mysql /opt/mysql-5.6

sleep 30
#---------------修改环境变量
grep -w "MYSQL_HOME=/opt/mysql-5.6" /etc/profile
if [ $? -eq 0 ]; then
                echo "变量已存在,跳过"
                 else
                        cat >> /etc/profile <<EOF
                        MYSQL_HOME=/opt/mysql-5.6
                        PATH=$PATH:$MYSQL_HOME/bin
                        export PATH MYSQL_HOME
EOF
fi
source /etc/profile
sleep 5
#----------------编辑my.cnf文件

if [ -f /etc/my.cnf ]; then
           echo "配置文件已存在"
            else
cat > /etc/my.cnf <<EOF
[client]
port = 3306
socket =  /opt/mysqldata/tmp/mysql.sock
[mysqld]
socket = /opt/mysqldata/tmp/mysql.sock
pid-file =  /opt/mysqldata/mysql.pid
basedir =  /opt/mysql-5.6
datadir =  /opt/mysqldata/
tmpdir =  /opt/mysqldata/tmp
EOF
fi
#--------将mysql.server加入系统service管理
cp /opt/mysql-5.6/support-files/mysql.server /etc/init.d/mysql
service mysql start
service mysql status
