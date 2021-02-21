#!/bin/bash
groupname=`egrep "mysql" /etc/group |awk -F: '{print $1}' |wc -l`
username=`egrep "mysql" /etc/passwd |awk -F: '{print $1}' |wc -l`
mysql1=`rpm -qa | grep -i mysql`
mkdir -p /opt/mysqldata/tmp
#����û���
if [  $groupname -ne 1 ]; then
         echo "�û��鲻���ڣ���ʼ�����û���"
            groupadd mysql
             else
                echo "�û����Ѵ��ڣ����贴��"
fi
#�½�mysql�û�ͬʱ�����û��鲢�ҽ�ֹmysql��½linux
if [  $username -ne 1 ]; then
 echo "�û������ڣ���ʼ�����û�ͬʱ�����û��鲢�ҽ�ֹmysql��½linux"
            useradd -r -s /sbin/nologin -g mysql mysql -d /usr/local/mysql
             else
                echo "�û��Ѵ��ڣ����贴��"
fi

sleep 5

#�ر�selinux����ذ�ȫ����
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
#������װ·��
if [ ! -d /opt/ ]; then
  mkdir -p /opt/
  else
  echo "�ļ����Ѿ�����"
fi

sleep 2
#����mysql�����ļ����Ŀ¼���ı�������
if [ ! -d /opt/mysqldata ]; then
    mkdir -p /opt/mysqldata
        else
                echo "��Ŀ¼�Ѵ��ڣ��ı�����"
                        chown -R mysql:mysql /opt/mysqldata
                        fi
sleep 2
#���ϵͳ�Ƿ��Ѿ���װmysql
service mysql stop
service mysqld stop
echo ${mysql1}
for RPM in ${mysql1}
do
        rpm -e --nodeps ${RPM}
done
sleep 30
#��ʼ����mysql
cd /opt/ && tar -zxvf mysql-5.6.44-linux-glibc2.12-x86_64.tar.gz 
sleep 30
               mv -n mysql-5.6.44-linux-glibc2.12-x86_64 mysql-5.6
chown -R mysql:mysql /opt/mysql-5.6

sleep 30
#---------------�޸Ļ�������
grep -w "MYSQL_HOME=/opt/mysql-5.6" /etc/profile
if [ $? -eq 0 ]; then
                echo "�����Ѵ���,����"
                 else
                        cat >> /etc/profile <<EOF
                        MYSQL_HOME=/opt/mysql-5.6
                        PATH=$PATH:$MYSQL_HOME/bin
                        export PATH MYSQL_HOME
EOF
fi

sleep 5
#----------------�༭my.cnf�ļ�

if [ -f /etc/my.cnf ]; then
           echo "�����ļ��Ѵ���"
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
#--------��mysql.server����ϵͳservice����
cp /opt/mysql-5.6/support-files/mysql.server /etc/init.d/mysql
service mysql start
service mysql status